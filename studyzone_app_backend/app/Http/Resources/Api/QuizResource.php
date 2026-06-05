<?php

namespace App\Http\Resources\Api;

use App\Models\QuizAttempt;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class QuizResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'difficulty' => $this->difficulty,
            'category' => $this->category ? [
                'id' => $this->category->id,
                'title' => $this->category->title,
            ] : null,
            'question_count' => $this->questions_count
                ?? $this->whenLoaded('questions', fn () => $this->questions->count()),
            'best_score' => $this->bestScore(),
            // Only present when questions are eager-loaded (detail endpoint).
            'questions' => QuizQuestionResource::collection($this->whenLoaded('questions')),
        ];
    }

    private function bestScore(): ?int
    {
        // Prefer the value eager-loaded via withMax('attempts as best_score')
        // in the controller (avoids an N+1 query per quiz in a list).
        if (array_key_exists('best_score', $this->resource->getAttributes())) {
            return $this->best_score !== null ? (int) $this->best_score : null;
        }

        $user = auth('sanctum')->user();
        if (!$user) {
            return null;
        }
        return QuizAttempt::where('user_id', $user->id)
            ->where('quiz_id', $this->id)
            ->max('score');
    }
}
