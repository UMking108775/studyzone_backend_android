<?php

namespace App\Http\Resources\Api;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CategoryResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'image' => $this->image ? asset('storage/' . $this->image) : null,
            'parent_id' => $this->parent_id,
            'level' => $this->level,
            'is_active' => $this->is_active,
            'is_free' => (bool) $this->is_free,
            // True if this category (or any ancestor) is paid. User-independent,
            // so the app can gate cached/offline items once a plan lapses.
            'requires_subscription' => $this->requiresSubscription(),
            // Locked = an authenticated user without access to this category (or
            // one of its ancestors). Guests are never "locked" (they preview).
            'is_locked' => $this->resolveLocked(),
            'parent' => $this->when($this->parent, new CategoryResource($this->parent)),
            // Full nested tree when childrenRecursive is loaded, else one level.
            'children' => $this->relationLoaded('childrenRecursive')
                ? CategoryResource::collection($this->childrenRecursive)
                : CategoryResource::collection($this->whenLoaded('children')),
            'has_children' => $this->when(
                $this->relationLoaded('childrenRecursive') || $this->relationLoaded('children'),
                fn () => $this->relationLoaded('childrenRecursive')
                    ? $this->childrenRecursive->isNotEmpty()
                    : $this->children->isNotEmpty()
            ),
            'contents_count' => $this->when(isset($this->contents_count), $this->contents_count),
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
        ];
    }

    /** Whether the current (authenticated) user is locked out of this category. */
    private function resolveLocked(): bool
    {
        if ((bool) $this->is_free) {
            return false;
        }
        $user = auth('sanctum')->user();
        if (!$user) {
            return false; // guests preview, not "locked"
        }
        return !$user->hasAccessToCategoryAndParents($this->id);
    }
}

