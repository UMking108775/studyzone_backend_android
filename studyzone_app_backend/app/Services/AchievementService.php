<?php

namespace App\Services;

use App\Models\Category;
use App\Models\Quiz;
use App\Models\QuizAttempt;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Collection;

/**
 * Single source of truth for a user's quiz progress, streaks and achievements.
 *
 * Achievements/progress are based on DISTINCT quizzes PASSED (best attempt
 * >= 60%), never on raw attempt counts — so re-taking a quiz never inflates
 * progress. Program progress groups a user's accessible quizzes by their
 * top-level program (degree), giving a clear, sequenced goal.
 */
class AchievementService
{
    private const TZ = 'Asia/Karachi';
    private const PASS_RATIO = 0.6;

    /** Summary used by the streak card / quiz-stats endpoint. */
    public function stats(User $user): array
    {
        $attempts = QuizAttempt::where('user_id', $user->id)->get();
        $derived = $this->derive($attempts);
        $streak = $this->streak($attempts);

        $accuracy = $derived['totalQuestions'] > 0
            ? (int) round($derived['totalCorrect'] / $derived['totalQuestions'] * 100)
            : 0;

        return [
            'current_streak' => $streak['current'],
            'longest_streak' => $streak['longest'],
            // Kept for backwards compatibility (raw attempts).
            'total_quizzes' => $attempts->count(),
            'total_correct' => $derived['totalCorrect'],
            'total_questions' => $derived['totalQuestions'],
            // The meaningful, de-duplicated metrics.
            'quizzes_passed' => count($derived['passedQuizIds']),
            'quizzes_attempted' => count($derived['attemptedQuizIds']),
            'perfect_scores' => count($derived['perfectQuizIds']),
            'accuracy' => $accuracy,
        ];
    }

    /** Full achievements payload: summary + per-program progress + badges. */
    public function achievements(User $user): array
    {
        $attempts = QuizAttempt::where('user_id', $user->id)->get();
        $derived = $this->derive($attempts);
        $streak = $this->streak($attempts);

        $passedSet = array_flip($derived['passedQuizIds']);
        $passedCount = count($derived['passedQuizIds']);
        $perfectCount = count($derived['perfectQuizIds']);

        $programs = $this->programs($user, $passedSet);

        return [
            'summary' => [
                'current_streak' => $streak['current'],
                'longest_streak' => $streak['longest'],
                'quizzes_passed' => $passedCount,
                'perfect_scores' => $perfectCount,
            ],
            'programs' => $programs,
            'achievements' => $this->buildAchievements($passedCount, $perfectCount, $streak, $programs),
        ];
    }

    // ── derivation ──────────────────────────────────────────────────────

    /** Distinct passed / attempted / perfect quiz ids + totals. */
    private function derive(Collection $attempts): array
    {
        $attempted = [];
        $passed = [];
        $perfect = [];
        $totalCorrect = 0;
        $totalQuestions = 0;

        foreach ($attempts as $a) {
            $attempted[$a->quiz_id] = true;
            $totalCorrect += (int) $a->score;
            $totalQuestions += (int) $a->total;
            if ($a->total > 0) {
                if ($a->score >= self::PASS_RATIO * $a->total) {
                    $passed[$a->quiz_id] = true;
                }
                if ($a->score >= $a->total) {
                    $perfect[$a->quiz_id] = true;
                }
            }
        }

        return [
            'attemptedQuizIds' => array_keys($attempted),
            'passedQuizIds' => array_keys($passed),
            'perfectQuizIds' => array_keys($perfect),
            'totalCorrect' => $totalCorrect,
            'totalQuestions' => $totalQuestions,
        ];
    }

    /** Consecutive-day streak (in the audience timezone). */
    private function streak(Collection $attempts): array
    {
        $dates = $attempts
            ->map(fn ($a) => $a->created_at->copy()->setTimezone(self::TZ)->toDateString())
            ->unique()->sort()->values();
        $set = $dates->flip();

        $current = 0;
        if ($set->has(Carbon::now(self::TZ)->toDateString())) {
            $cursor = Carbon::now(self::TZ)->startOfDay();
        } elseif ($set->has(Carbon::now(self::TZ)->subDay()->toDateString())) {
            $cursor = Carbon::now(self::TZ)->subDay()->startOfDay();
        } else {
            $cursor = null;
        }
        if ($cursor) {
            while ($set->has($cursor->toDateString())) {
                $current++;
                $cursor = $cursor->subDay();
            }
        }

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

        return ['current' => $current, 'longest' => $longest];
    }

    /** Per-program progress (passed/total distinct quizzes) for the user. */
    private function programs(User $user, array $passedSet): array
    {
        $quizzes = Quiz::active()
            ->whereHas('questions')
            ->whereNotNull('category_id')
            ->get(['id', 'category_id']);

        if ($quizzes->isEmpty()) {
            return [];
        }

        $cats = Category::get(['id', 'parent_id', 'title'])->keyBy('id');
        $topOf = function ($categoryId) use ($cats) {
            $cur = $cats->get($categoryId);
            $guard = 0;
            while ($cur && $cur->parent_id && $cats->get($cur->parent_id) && $guard++ < 50) {
                $cur = $cats->get($cur->parent_id);
            }
            return $cur;
        };

        $groups = [];
        foreach ($quizzes as $q) {
            if (!$user->hasAccessToCategoryAndParents($q->category_id)) {
                continue;
            }
            $top = $topOf($q->category_id);
            if (!$top) {
                continue;
            }
            $pid = $top->id;
            if (!isset($groups[$pid])) {
                $groups[$pid] = ['id' => $pid, 'title' => $top->title, 'total' => 0, 'passed' => 0];
            }
            $groups[$pid]['total']++;
            if (isset($passedSet[$q->id])) {
                $groups[$pid]['passed']++;
            }
        }

        $out = array_map(function ($g) {
            $percent = $g['total'] > 0 ? (int) round($g['passed'] / $g['total'] * 100) : 0;
            return [
                'id' => $g['id'],
                'title' => $g['title'],
                'total' => $g['total'],
                'passed' => $g['passed'],
                'percent' => $percent,
                'completed' => $g['total'] > 0 && $g['passed'] === $g['total'],
            ];
        }, array_values($groups));

        usort($out, fn ($a, $b) => $b['percent'] <=> $a['percent']);
        return $out;
    }

    /** Skill + streak + per-program achievement definitions with earned state. */
    private function buildAchievements(int $passed, int $perfect, array $streak, array $programs): array
    {
        $a = [];
        $make = function ($id, $title, $description, $kind, $earned, $current = null, $target = null) {
            return [
                'id' => $id,
                'title' => $title,
                'description' => $description,
                'kind' => $kind,
                'earned' => (bool) $earned,
                'progress' => $target !== null ? ['current' => min($current, $target), 'target' => $target] : null,
            ];
        };

        $a[] = $make('first_pass', 'First Steps', 'Pass your first quiz', 'skill', $passed >= 1, $passed, 1);
        $a[] = $make('passed_5', 'Getting Serious', 'Pass 5 different quizzes', 'skill', $passed >= 5, $passed, 5);
        $a[] = $make('passed_15', 'Dedicated Learner', 'Pass 15 different quizzes', 'skill', $passed >= 15, $passed, 15);
        $a[] = $make('perfect', 'Perfectionist', 'Score 100% on a quiz', 'skill', $perfect >= 1, $perfect, 1);
        $a[] = $make('streak_3', 'On a Roll', 'Reach a 3-day streak', 'streak', $streak['longest'] >= 3, $streak['longest'], 3);
        $a[] = $make('streak_7', 'Week Warrior', 'Reach a 7-day streak', 'streak', $streak['longest'] >= 7, $streak['longest'], 7);
        $a[] = $make('streak_30', 'Unstoppable', 'Reach a 30-day streak', 'streak', $streak['longest'] >= 30, $streak['longest'], 30);

        foreach ($programs as $p) {
            $a[] = $make(
                'program_master:' . $p['id'],
                $p['title'] . ' Master',
                'Pass all ' . $p['total'] . ' quizzes in ' . $p['title'],
                'program',
                $p['completed'],
                $p['passed'],
                $p['total']
            );
        }

        return $a;
    }
}
