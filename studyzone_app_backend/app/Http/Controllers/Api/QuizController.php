<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\QuizResource;
use App\Models\Quiz;
use App\Models\QuizAttempt;
use App\Services\AchievementService;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;

class QuizController extends Controller
{
    use ApiResponse;

    public function __construct(private AchievementService $achievements)
    {
    }

    /** List active quizzes (with question counts + the user's best score). */
    public function index(Request $request)
    {
        $user = $request->user();

        $quizzes = Quiz::active()
            ->whereHas('questions')
            ->with('category')
            ->withCount('questions')
            // Single query for the user's best score per quiz (no N+1).
            ->withMax(['attempts as best_score' => fn ($q) => $q->where('user_id', $user->id)], 'score')
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get()
            // Only show quizzes for programs/categories the user can access.
            // Quizzes with no category are general and shown to everyone.
            ->filter(fn ($quiz) => $quiz->category_id === null
                || $user->hasAccessToCategoryAndParents($quiz->category_id))
            ->values();

        return $this->successResponse(
            QuizResource::collection($quizzes),
            'Quizzes retrieved successfully'
        );
    }

    /** A single quiz with its questions. */
    public function show(Request $request, $id)
    {
        $userId = $request->user()->id;

        $quiz = Quiz::active()
            ->with(['category', 'questions'])
            ->withCount('questions')
            ->withMax(['attempts as best_score' => fn ($q) => $q->where('user_id', $userId)], 'score')
            ->find($id);

        if (!$quiz) {
            return $this->notFoundResponse('Quiz not found');
        }

        if ($quiz->category_id !== null
            && !$request->user()->hasAccessToCategoryAndParents($quiz->category_id)) {
            return $this->forbiddenResponse('You do not have access to this quiz');
        }

        return $this->successResponse(
            new QuizResource($quiz),
            'Quiz retrieved successfully'
        );
    }

    /** Record a completed attempt and return updated stats. */
    public function attempt(Request $request, $id)
    {
        $user = $request->user();
        $quiz = Quiz::active()->find($id);

        if (!$quiz) {
            return $this->notFoundResponse('Quiz not found');
        }

        $validated = $request->validate([
            'score' => 'required|integer|min:0',
            'total' => 'required|integer|min:1',
        ]);

        // Clamp to the quiz's real size so a client can't inflate stats.
        $questionCount = max($quiz->questions()->count(), 1);
        $total = min($validated['total'], $questionCount);
        $score = min($validated['score'], $total);

        QuizAttempt::create([
            'user_id' => $user->id,
            'quiz_id' => $quiz->id,
            'score' => $score,
            'total' => $total,
        ]);

        return $this->successResponse(
            $this->achievements->stats($user),
            'Attempt saved'
        );
    }

    /** Current user's quiz stats (streak + de-duplicated totals). */
    public function stats(Request $request)
    {
        return $this->successResponse(
            $this->achievements->stats($request->user()),
            'Stats retrieved successfully'
        );
    }

    /** Full achievements payload: summary + program progress + badges. */
    public function achievements(Request $request)
    {
        return $this->successResponse(
            $this->achievements->achievements($request->user()),
            'Achievements retrieved successfully'
        );
    }
}
