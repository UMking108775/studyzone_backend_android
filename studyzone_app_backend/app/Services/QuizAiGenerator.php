<?php

namespace App\Services;

use App\Models\Category;
use App\Models\Content;
use App\Models\Quiz;
use App\Models\Setting;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * Generates a draft quiz (MCQs) with an LLM (Anthropic Claude, OpenAI or Google
 * Gemini — whichever is configured), grounded on a program/category and the
 * titles of its study material. The result is saved as an INACTIVE draft so an
 * admin can review/edit before publishing.
 */
class QuizAiGenerator
{
    public static function isConfigured(): bool
    {
        return self::activeProvider() !== null;
    }

    /** The provider to use: the admin-selected one (if it has a key), else the
     *  first configured of anthropic → openai → gemini. Null if none. */
    public static function activeProvider(): ?string
    {
        $forced = Setting::getValue(Setting::AI_PROVIDER) ?: config('services.ai_provider');
        if ($forced && $forced !== 'auto' && !empty(self::keyFor($forced))) {
            return $forced;
        }
        foreach (['anthropic', 'openai', 'gemini'] as $p) {
            if (!empty(self::keyFor($p))) {
                return $p;
            }
        }
        return null;
    }

    /** API key for a provider: admin Settings (encrypted) first, then env. */
    public static function keyFor(string $provider): ?string
    {
        $map = [
            'anthropic' => Setting::AI_ANTHROPIC_KEY,
            'openai' => Setting::AI_OPENAI_KEY,
            'gemini' => Setting::AI_GEMINI_KEY,
        ];
        $fromDb = isset($map[$provider]) ? Setting::getSecret($map[$provider]) : null;
        return !empty($fromDb) ? $fromDb : config("services.$provider.key");
    }

    /** Model for a provider: admin Settings first, then env/default. */
    public static function modelFor(string $provider): string
    {
        $map = [
            'anthropic' => Setting::AI_ANTHROPIC_MODEL,
            'openai' => Setting::AI_OPENAI_MODEL,
            'gemini' => Setting::AI_GEMINI_MODEL,
        ];
        $fromDb = isset($map[$provider]) ? Setting::getValue($map[$provider]) : null;
        return !empty($fromDb) ? $fromDb : (string) config("services.$provider.model");
    }

    public static function providerLabel(): ?string
    {
        return match (self::activeProvider()) {
            'anthropic' => 'Anthropic Claude',
            'openai' => 'OpenAI',
            'gemini' => 'Google Gemini',
            default => null,
        };
    }

    /**
     * Generate a draft quiz.
     *
     * @param  string       $scope         'program' | 'lesson' — saved on the quiz.
     * @param  array|null   $document      An uploaded PDF sent natively to the model:
     *                                      ['data' => base64, 'mime' => 'application/pdf', 'name' => filename].
     * @param  string|null  $customPrompt  Extra admin instructions for the model.
     */
    public function generate(
        ?int $categoryId,
        ?string $topic,
        int $count,
        string $difficulty,
        string $scope = 'program',
        ?array $document = null,
        ?string $customPrompt = null,
    ): Quiz {
        $category = $categoryId ? Category::find($categoryId) : null;
        $subject = $topic ?: ($category?->title ?? 'General Knowledge');

        // Ground the model on real material titles from this program (and its
        // sub-categories) so questions stay relevant to what users study.
        $material = collect();
        if ($category) {
            $ids = $this->descendantIds($category);
            $material = Content::whereIn('category_id', $ids)
                ->pluck('title')
                ->filter()
                ->take(40)
                ->values();
        }

        $questions = $this->callModel(
            $subject,
            $material->all(),
            $count,
            $difficulty,
            $document,
            $customPrompt,
        );

        return DB::transaction(function () use ($subject, $categoryId, $scope, $difficulty, $questions) {
            $quiz = Quiz::create([
                'title' => "$subject — Quiz",
                'description' => 'AI-generated draft. Review the questions, then activate.',
                'category_id' => $categoryId,
                'scope' => $scope,
                'difficulty' => $difficulty,
                'is_active' => false,
                'sort_order' => 0,
            ]);

            $order = 0;
            foreach ($questions as $q) {
                if (!is_array($q)) {
                    continue;
                }
                $rawOptions = (isset($q['options']) && is_array($q['options'])) ? $q['options'] : [];
                $options = array_values(array_filter(
                    array_map(fn ($o) => trim((string) $o), $rawOptions),
                    fn ($o) => $o !== ''
                ));
                $text = is_array($q['question'] ?? null) ? '' : trim((string) ($q['question'] ?? ''));
                if ($text === '' || count($options) < 2) {
                    continue;
                }
                $correct = (int) ($q['correct_index'] ?? 0);
                if ($correct < 0 || $correct >= count($options)) {
                    $correct = 0;
                }
                $explanation = is_array($q['explanation'] ?? null)
                    ? null
                    : (trim((string) ($q['explanation'] ?? '')) ?: null);
                $quiz->questions()->create([
                    'question' => $text,
                    'options' => $options,
                    'correct_index' => $correct,
                    'explanation' => $explanation,
                    'sort_order' => $order++,
                ]);
            }

            if ($quiz->questions()->count() === 0) {
                throw new RuntimeException('The AI did not return any valid questions. Please try again.');
            }

            return $quiz;
        });
    }

    /** This category id plus all descendant category ids. */
    private function descendantIds(Category $root): array
    {
        $all = Category::select('id', 'parent_id')->get();
        $byParent = $all->groupBy('parent_id');
        $ids = [$root->id];
        $stack = [$root->id];
        $seen = [$root->id => true]; // guard against parent_id cycles
        while ($stack) {
            $pid = array_pop($stack);
            foreach ($byParent->get($pid, collect()) as $child) {
                if (isset($seen[$child->id])) {
                    continue;
                }
                $seen[$child->id] = true;
                $ids[] = $child->id;
                $stack[] = $child->id;
            }
        }
        return $ids;
    }

    /** Build the prompt, call the active AI provider, and parse JSON questions. */
    private function callModel(
        string $subject,
        array $materialTitles,
        int $count,
        string $difficulty,
        ?array $document = null,
        ?string $customPrompt = null,
    ): array {
        $system = <<<'SYS'
You are an expert exam question writer for a student study app.
You write clear, unambiguous multiple-choice questions (MCQs) with exactly 4 options,
exactly one correct answer, and a short explanation.
Rules:
- Questions must be factually correct and self-contained.
- Difficulty must match the requested level.
- Avoid trick questions, negatives like "which is NOT", and "all of the above".
- When a PDF/document is attached, READ it and base EVERY question strictly on its content.
- Output STRICT JSON only — no prose, no markdown fences.
SYS;

        $materialBlock = empty($materialTitles)
            ? ''
            : "\n\nThe program includes study material titled:\n- " . implode("\n- ", $materialTitles);

        // When a PDF is attached it is sent natively to the model (below); just
        // tell the model to read it.
        $docBlock = $document !== null
            ? "\n\nA PDF document is attached. Read it and base EVERY question strictly on its content."
            : '';

        $promptBlock = '';
        $cp = $customPrompt !== null ? trim($customPrompt) : '';
        if ($cp !== '') {
            $promptBlock = "\n\nAdditional instructions from the admin: {$cp}";
        }

        $user = <<<USR
Generate {$count} {$difficulty} multiple-choice questions about: "{$subject}".{$materialBlock}{$docBlock}{$promptBlock}

Return ONLY a JSON object in EXACTLY this shape:
{
  "questions": [
    {
      "question": "string",
      "options": ["string", "string", "string", "string"],
      "correct_index": 0,
      "explanation": "string"
    }
  ]
}
correct_index is the 0-based index of the correct option. Provide exactly {$count} questions.
USR;

        $text = match (self::activeProvider()) {
            'anthropic' => $this->requestAnthropic($system, $user, $document),
            'openai' => $this->requestOpenAI($system, $user, $document),
            'gemini' => $this->requestGemini($system, $user, $document),
            default => throw new RuntimeException('No AI provider configured.'),
        };

        $data = $this->parseJson($text);
        $questions = $data['questions'] ?? (is_array($data) ? $data : []);
        if (!is_array($questions) || empty($questions)) {
            throw new RuntimeException('Could not parse questions from the AI response.');
        }
        return $questions;
    }

    private function requestAnthropic(string $system, string $user, ?array $document = null): string
    {
        // Native PDF: a document content block before the text instruction.
        $content = $document !== null
            ? [
                [
                    'type' => 'document',
                    'source' => [
                        'type' => 'base64',
                        'media_type' => $document['mime'] ?? 'application/pdf',
                        'data' => $document['data'],
                    ],
                ],
                ['type' => 'text', 'text' => $user],
            ]
            : $user;

        $response = $this->sendWithRetry(fn () => Http::withHeaders([
            'x-api-key' => self::keyFor('anthropic'),
            'anthropic-version' => '2023-06-01',
            'content-type' => 'application/json',
        ])->timeout(180)->post('https://api.anthropic.com/v1/messages', [
            'model' => self::modelFor('anthropic'),
            'max_tokens' => 8192,
            'temperature' => 0.7,
            // Prompt caching on the (stable) system prompt.
            'system' => [[
                'type' => 'text',
                'text' => $system,
                'cache_control' => ['type' => 'ephemeral'],
            ]],
            'messages' => [['role' => 'user', 'content' => $content]],
        ]));
        if (!$response->successful()) {
            throw new RuntimeException($this->httpError('Anthropic', $response));
        }
        return (string) $response->json('content.0.text', '');
    }

    private function requestOpenAI(string $system, string $user, ?array $document = null): string
    {
        // Native PDF: a file content part (base64 data URL) before the text.
        $content = $document !== null
            ? [
                [
                    'type' => 'file',
                    'file' => [
                        'filename' => $document['name'] ?? 'document.pdf',
                        'file_data' => 'data:' . ($document['mime'] ?? 'application/pdf') . ';base64,' . $document['data'],
                    ],
                ],
                ['type' => 'text', 'text' => $user],
            ]
            : $user;

        $response = $this->sendWithRetry(fn () => Http::withHeaders([
            'Authorization' => 'Bearer ' . self::keyFor('openai'),
            'content-type' => 'application/json',
        ])->timeout(180)->post('https://api.openai.com/v1/chat/completions', [
            'model' => self::modelFor('openai'),
            'temperature' => 0.7,
            'response_format' => ['type' => 'json_object'],
            'messages' => [
                ['role' => 'system', 'content' => $system],
                ['role' => 'user', 'content' => $content],
            ],
        ]));
        if (!$response->successful()) {
            throw new RuntimeException($this->httpError('OpenAI', $response));
        }
        return (string) $response->json('choices.0.message.content', '');
    }

    private function requestGemini(string $system, string $user, ?array $document = null): string
    {
        $model = self::modelFor('gemini');
        $key = self::keyFor('gemini');

        // Native PDF: inline_data part before the text instruction. Gemini reads
        // the PDF (including scanned/image pages) directly.
        $parts = $document !== null
            ? [
                ['inline_data' => ['mime_type' => $document['mime'] ?? 'application/pdf', 'data' => $document['data']]],
                ['text' => $user],
            ]
            : [['text' => $user]];

        $response = $this->sendWithRetry(fn () => Http::withHeaders(['content-type' => 'application/json'])
            ->timeout(180)
            ->post("https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$key}", [
                'systemInstruction' => ['parts' => [['text' => $system]]],
                'contents' => [
                    ['role' => 'user', 'parts' => $parts],
                ],
                'generationConfig' => [
                    'responseMimeType' => 'application/json',
                    'temperature' => 0.7,
                ],
            ]));
        if (!$response->successful()) {
            throw new RuntimeException($this->httpError('Gemini', $response));
        }
        return (string) $response->json('candidates.0.content.parts.0.text', '');
    }

    /**
     * Send an HTTP request, retrying transient rate-limit/overload responses
     * (429 / 503) a couple of times with a short backoff. Returns the final
     * Response (the caller decides whether it's an error).
     *
     * @param  callable():\Illuminate\Http\Client\Response  $send
     */
    private function sendWithRetry(callable $send)
    {
        $attempt = 0;
        while (true) {
            $response = $send();
            $status = $response->status();
            $attempt++;
            if (($status === 429 || $status === 503) && $attempt < 3) {
                sleep(2 * $attempt); // 2s, then 4s
                continue;
            }
            return $response;
        }
    }

    /** Turn a failed API response into a clear, actionable message. */
    private function httpError(string $provider, $response): string
    {
        $status = $response->status();
        $body = trim((string) $response->body());

        if ($status === 429) {
            return "$provider rate limit / quota exceeded (429). The API key looks like it is "
                . "on a free tier or has no remaining quota — enable billing on the key's "
                . "Google Cloud project, wait a minute and retry, or pick a different model in "
                . "Admin → App Settings. Details: $body";
        }
        if ($status === 401 || $status === 403) {
            return "$provider auth error ($status) — the API key is invalid or lacks access. "
                . "Check the key in Admin → App Settings. Details: $body";
        }

        return "$provider API error $status: $body";
    }

    /** Robustly extract a JSON object/array from the model's text. */
    private function parseJson(string $text): array
    {
        $text = trim($text);
        // Strip ``` fences if present.
        $text = preg_replace('/^```(?:json)?|```$/m', '', $text);
        $decoded = json_decode($text, true);
        if (is_array($decoded)) {
            return $decoded;
        }
        // Fallback: grab from first { to last }.
        $start = strpos($text, '{');
        $end = strrpos($text, '}');
        if ($start !== false && $end !== false && $end > $start) {
            $decoded = json_decode(substr($text, $start, $end - $start + 1), true);
            if (is_array($decoded)) {
                return $decoded;
            }
        }
        throw new RuntimeException('AI response was not valid JSON.');
    }
}
