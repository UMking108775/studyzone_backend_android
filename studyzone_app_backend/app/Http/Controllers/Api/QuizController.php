<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\QuizResource;
use App\Models\Quiz;
use App\Models\QuizAttempt;
use App\Models\User;
use App\Traits\ApiResponse;
use Carbon\Carbon;
use Illuminate\Http\Request;

class QuizController extends Controller
{
    use ApiResponse;

    // Day-boundary timezone for streaks (primary audience: Pakistan, UTC+5).
    private const TZ = 'Asia/Karachi';

    /** List active quizzes (with question counts + the user's best score). */
    public function index(Request $request)
    {
        $userId = $request->user()->id;

        $quizzes = Quiz::active()
            ->whereHas('questions')
            ->with('category')
            ->withCount('questions')
            // Single query for the user's best score per quiz (no N+1).
            ->withMax(['attempts as best_score' => fn ($q) => $q->where('user_id', $userId)], 'score')
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();

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
            $this->computeStats($user),
            'Attempt saved'
        );
    }

    /** Current user's quiz stats (streak + totals). */
    public function stats(Request $request)
    {
        return $this->successResponse(
            $this->computeStats($request->user()),
            'Stats retrieved successfully'
        );
    }

    /**
     * Compute streak + totals from the user's attempt history.
     * A "study day" is any day with at least one attempt.
     */
    private function computeStats(User $user): array
    {
        $attempts = QuizAttempt::where('user_id', $user->id)->get();

        // Bucket attempts into "study days" in the audience timezone (created_at
        // is stored in UTC), so day boundaries match the user's local midnight.
        $dates = $attempts
            ->map(fn ($a) => $a->created_at->copy()->setTimezone(self::TZ)->toDateString())
            ->unique()
            ->sort()
            ->values();

        $daySet = $dates->flip();

        // Current streak: count back from today (or yesterday if nothing today).
        $current = 0;
        if ($daySet->has(Carbon::now(self::TZ)->toDateString())) {
            $cursor = Carbon::now(self::TZ)->startOfDay();
        } elseif ($daySet->has(Carbon::now(self::TZ)->subDay()->toDateString())) {
            $cursor = Carbon::now(self::TZ)->subDay()->startOfDay();
        } else {
            $cursor = null;
        }
        if ($cursor) {
            while ($daySet->has($cursor->toDateString())) {
                $current++;
                $cursor = $cursor->subDay();
            }
        }

        // Longest streak across history.
        $longest = 0;
        $run = 0;
        $prev = null;
        foreach ($dates as $d) {
            if ($prev !== null && $prev->copy()->addDay()->toDateString() === $d) {
                $run++;
            } else {
                $run = 1;
            }
            $longest = max($longest, $run);
            $prev = Carbon::parse($d);
        }

        return [
            'current_streak' => $current,
            'longest_streak' => $longest,
            'total_quizzes' => $attempts->count(),
            'total_correct' => (int) $attempts->sum('score'),
            'total_questions' => (int) $attempts->sum('total'),
            'last_active' => $dates->last(),
        ];
    }
}
