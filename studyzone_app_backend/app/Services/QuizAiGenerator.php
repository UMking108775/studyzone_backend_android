<?php

namespace App\Services;

use App\Models\Category;
use App\Models\Content;
use App\Models\Quiz;
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

    /** The provider to use: explicit AI_PROVIDER if its key is set, else the
     *  first configured of anthropic → openai → gemini. Null if none. */
    public static function activeProvider(): ?string
    {
        $forced = config('services.ai_provider');
        if ($forced && !empty(config("services.$forced.key"))) {
            return $forced;
        }
        foreach (['anthropic', 'openai', 'gemini'] as $p) {
            if (!empty(config("services.$p.key"))) {
                return $p;
            }
        }
        return null;
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

    public function generate(?int $categoryId, ?string $topic, int $count, string $difficulty): Quiz
    {
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

        $questions = $this->callModel($subject, $material->all(), $count, $difficulty);

        return DB::transaction(function () use ($subject, $categoryId, $difficulty, $questions) {
            $quiz = Quiz::create([
                'title' => "$subject — Quiz",
                'description' => 'AI-generated draft. Review the questions, then activate.',
                'category_id' => $categoryId,
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
    private function callModel(string $subject, array $materialTitles, int $count, string $difficulty): array
    {
        $system = <<<'SYS'
You are an expert exam question writer for a student study app.
You write clear, unambiguous multiple-choice questions (MCQs) with exactly 4 options,
exactly one correct answer, and a short explanation.
Rules:
- Questions must be factually correct and self-contained.
- Difficulty must match the requested level.
- Avoid trick questions, negatives like "which is NOT", and "all of the above".
- Output STRICT JSON only — no prose, no markdown fences.
SYS;

        $materialBlock = empty($materialTitles)
            ? ''
            : "\n\nThe program includes study material titled:\n- " . implode("\n- ", $materialTitles);

        $user = <<<USR
Generate {$count} {$difficulty} multiple-choice questions about: "{$subject}".{$materialBlock}

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
            'anthropic' => $this->requestAnthropic($system, $user),
            'openai' => $this->requestOpenAI($system, $user),
            'gemini' => $this->requestGemini($system, $user),
            default => throw new RuntimeException('No AI provider configured.'),
        };

        $data = $this->parseJson($text);
        $questions = $data['questions'] ?? (is_array($data) ? $data : []);
        if (!is_array($questions) || empty($questions)) {
            throw new RuntimeException('Could not parse questions from the AI response.');
        }
        return $questions;
    }

    private function requestAnthropic(string $system, string $user): string
    {
        $response = Http::withHeaders([
            'x-api-key' => config('services.anthropic.key'),
            'anthropic-version' => '2023-06-01',
            'content-type' => 'application/json',
        ])->timeout(90)->post('https://api.anthropic.com/v1/messages', [
            'model' => config('services.anthropic.model', 'claude-haiku-4-5-20251001'),
            'max_tokens' => 4096,
            'temperature' => 0.7,
            // Prompt caching on the (stable) system prompt.
            'system' => [[
                'type' => 'text',
                'text' => $system,
                'cache_control' => ['type' => 'ephemeral'],
            ]],
            'messages' => [['role' => 'user', 'content' => $user]],
        ]);
        if (!$response->successful()) {
            throw new RuntimeException('Anthropic API error ' . $response->status() . ': ' . $response->body());
        }
        return (string) $response->json('content.0.text', '');
    }

    private function requestOpenAI(string $system, string $user): string
    {
        $response = Http::withHeaders([
            'Authorization' => 'Bearer ' . config('services.openai.key'),
            'content-type' => 'application/json',
        ])->timeout(90)->post('https://api.openai.com/v1/chat/completions', [
            'model' => config('services.openai.model', 'gpt-4o-mini'),
            'temperature' => 0.7,
            'response_format' => ['type' => 'json_object'],
            'messages' => [
                ['role' => 'system', 'content' => $system],
                ['role' => 'user', 'content' => $user],
            ],
        ]);
        if (!$response->successful()) {
            throw new RuntimeException('OpenAI API error ' . $response->status() . ': ' . $response->body());
        }
        return (string) $response->json('choices.0.message.content', '');
    }

    private function requestGemini(string $system, string $user): string
    {
        $model = config('services.gemini.model', 'gemini-2.0-flash');
        $key = config('services.gemini.key');
        $response = Http::withHeaders(['content-type' => 'application/json'])
            ->timeout(90)
            ->post("https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$key}", [
                'systemInstruction' => ['parts' => [['text' => $system]]],
                'contents' => [
                    ['role' => 'user', 'parts' => [['text' => $user]]],
                ],
                'generationConfig' => [
                    'responseMimeType' => 'application/json',
                    'temperature' => 0.7,
                ],
            ]);
        if (!$response->successful()) {
            throw new RuntimeException('Gemini API error ' . $response->status());
        }
        return (string) $response->json('candidates.0.content.parts.0.text', '');
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
