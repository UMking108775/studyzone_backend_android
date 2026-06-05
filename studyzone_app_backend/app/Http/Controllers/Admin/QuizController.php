<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Quiz;
use App\Services\QuizAiGenerator;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class QuizController extends Controller
{
    public function index()
    {
        $quizzes = Quiz::with('category')
            ->withCount('questions')
            ->orderBy('sort_order')
            ->orderByDesc('id')
            ->paginate(20);

        return view('admin.quizzes.index', compact('quizzes'));
    }

    public function create()
    {
        return view('admin.quizzes.create', [
            'categoryOptions' => $this->categoryOptions(),
        ]);
    }

    public function store(Request $request)
    {
        $data = $this->validateQuiz($request);

        $quiz = Quiz::create([
            'title' => $data['title'],
            'description' => $data['description'] ?? null,
            'category_id' => $data['category_id'] ?? null,
            'difficulty' => $data['difficulty'],
            'sort_order' => $data['sort_order'] ?? 0,
            'is_active' => $request->has('is_active'),
        ]);

        $this->saveQuestions($quiz, $request);

        return $this->redirectAfterSave($quiz, 'Quiz created. Add or refine questions below.');
    }

    public function edit(string $id)
    {
        $quiz = Quiz::with('questions')->findOrFail($id);

        return view('admin.quizzes.edit', [
            'quiz' => $quiz,
            'categoryOptions' => $this->categoryOptions(),
        ]);
    }

    public function update(Request $request, string $id)
    {
        $quiz = Quiz::findOrFail($id);
        $data = $this->validateQuiz($request);

        $quiz->update([
            'title' => $data['title'],
            'description' => $data['description'] ?? null,
            'category_id' => $data['category_id'] ?? null,
            'difficulty' => $data['difficulty'],
            'sort_order' => $data['sort_order'] ?? $quiz->sort_order,
            'is_active' => $request->has('is_active'),
        ]);

        $this->saveQuestions($quiz, $request);

        return $this->redirectAfterSave($quiz, 'Quiz updated successfully.');
    }

    /**
     * Redirect after a save. A quiz with no valid questions is forced to draft
     * (it would otherwise vanish from the app, which gates on whereHas questions).
     */
    private function redirectAfterSave(Quiz $quiz, string $message)
    {
        if ($quiz->questions()->count() === 0) {
            if ($quiz->is_active) {
                $quiz->update(['is_active' => false]);
            }
            return redirect()->route('admin.quizzes.edit', $quiz->id)->with(
                'warning',
                'Saved as a hidden draft — this quiz has no questions yet. Add at least one question with 2+ options to publish it.'
            );
        }
        return redirect()->route('admin.quizzes.edit', $quiz->id)->with('success', $message);
    }

    public function destroy(string $id)
    {
        Quiz::findOrFail($id)->delete();

        return redirect()->route('admin.quizzes.index')
            ->with('success', 'Quiz deleted.');
    }

    /** Show the "Generate with AI" form. */
    public function generateForm()
    {
        return view('admin.quizzes.generate', [
            'categoryOptions' => $this->categoryOptions(),
            'configured' => QuizAiGenerator::isConfigured(),
        ]);
    }

    /** Generate a quiz with AI, then open it for review/editing. */
    public function generate(Request $request, QuizAiGenerator $generator)
    {
        $validated = $request->validate([
            'category_id' => 'nullable|exists:categories,id',
            'topic' => 'nullable|string|max:255',
            'count' => 'required|integer|min:1|max:20',
            'difficulty' => 'required|in:easy,medium,hard',
        ]);

        if (!QuizAiGenerator::isConfigured()) {
            return back()->withErrors([
                'ai' => 'AI is not configured. Set ANTHROPIC_API_KEY in your .env.',
            ])->withInput();
        }

        try {
            $quiz = $generator->generate(
                categoryId: $validated['category_id'] ?? null,
                topic: $validated['topic'] ?? null,
                count: $validated['count'],
                difficulty: $validated['difficulty'],
            );
        } catch (\Throwable $e) {
            return back()->withErrors([
                'ai' => 'AI generation failed: ' . $e->getMessage(),
            ])->withInput();
        }

        return redirect()->route('admin.quizzes.edit', $quiz->id)
            ->with('success', 'AI generated a draft quiz. Review and edit it below, then activate it.');
    }

    // ── helpers ─────────────────────────────────────────────────────────

    private function validateQuiz(Request $request): array
    {
        return $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'category_id' => 'nullable|exists:categories,id',
            'difficulty' => 'required|in:easy,medium,hard',
            'sort_order' => 'nullable|integer|min:0',
            'is_active' => 'boolean',
        ]);
    }

    /**
     * Recreate the quiz's questions from the submitted `questions` array.
     * Empty questions (no text or <2 options) are skipped.
     */
    private function saveQuestions(Quiz $quiz, Request $request): void
    {
        $questions = $request->input('questions', []);
        if (!is_array($questions)) {
            $questions = [];
        }

        DB::transaction(function () use ($quiz, $questions) {
            $quiz->questions()->delete();

            $order = 0;
            foreach ($questions as $q) {
                if (!is_array($q)) {
                    continue;
                }
                $text = trim((string) ($q['question'] ?? ''));
                $rawOptions = (isset($q['options']) && is_array($q['options'])) ? $q['options'] : [];
                $options = array_values(array_filter(
                    array_map(fn ($o) => trim((string) $o), $rawOptions),
                    fn ($o) => $o !== ''
                ));
                if ($text === '' || count($options) < 2) {
                    continue;
                }
                $correct = (int) ($q['correct_index'] ?? 0);
                if ($correct < 0 || $correct >= count($options)) {
                    $correct = 0;
                }

                $quiz->questions()->create([
                    'question' => $text,
                    'options' => $options,
                    'correct_index' => $correct,
                    'explanation' => trim((string) ($q['explanation'] ?? '')) ?: null,
                    'sort_order' => $order++,
                ]);
            }
        });
    }

    /** Build [id => "Parent / Child" path] options for the category select. */
    private function categoryOptions(): array
    {
        $all = Category::orderBy('title')->get()->keyBy('id');
        $labels = [];
        foreach ($all as $cat) {
            $path = [$cat->title];
            $parentId = $cat->parent_id;
            $guard = 0;
            while ($parentId && isset($all[$parentId]) && $guard++ < 10) {
                array_unshift($path, $all[$parentId]->title);
                $parentId = $all[$parentId]->parent_id;
            }
            $labels[$cat->id] = implode(' / ', $path);
        }
        asort($labels);
        return $labels;
    }
}
