<?php

namespace App\Http\Resources\Api;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ContentResource extends JsonResource
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
            'content_type' => $this->content_type,
            'backblaze_url' => $this->backblaze_url,
            // Generic media URL alias (pdf/audio/video) + rich-text body.
            'url' => $this->backblaze_url,
            'body' => $this->body,
            'is_active' => $this->is_active,
            // True if this item sits anywhere under a paid category. Lets the
            // app refuse to open it (even a downloaded copy) once the user's
            // subscription has lapsed, without needing the network.
            'requires_subscription' => $this->category ? $this->category->requiresSubscription() : true,
            'category' => [
                'id' => $this->category->id,
                'title' => $this->category->title,
                'level' => $this->category->level,
            ],
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
        ];
    }
}

