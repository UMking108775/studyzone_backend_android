<?php

namespace App\Services;

use App\Models\DeviceToken;
use App\Models\Notification;
use Illuminate\Support\Carbon;

/**
 * Decides who a freshly-created Notification should reach and sends it via
 * FcmService. Invoked automatically by the Notification model's "created"
 * event, so EVERY notification — admin-authored, new material, new category —
 * pushes through one path. Safe no-op until Firebase is configured.
 */
class NotificationPusher
{
    public function __construct(private FcmService $fcm)
    {
    }

    public function push(Notification $notification): void
    {
        if (! $notification->is_active) {
            return;
        }
        if ($notification->scheduled_at && Carbon::parse($notification->scheduled_at)->isFuture()) {
            return; // future-scheduled: deliver later via a scheduled command
        }
        if (! $this->fcm->isConfigured()) {
            return;
        }

        $data = [
            'notification_id' => $notification->id,
            'type' => $notification->type ?? 'info',
            'action_url' => $notification->action_url ?? '',
        ];

        if ($notification->user_id) {
            $tokens = DeviceToken::where('user_id', $notification->user_id)->pluck('token')->all();
            $this->fcm->sendToTokens($tokens, $notification->title, $notification->message, $data);
        } else {
            // Global → broadcast topic every install is subscribed to.
            $this->fcm->sendToTopic(
                config('services.fcm.topic', 'all'),
                $notification->title,
                $notification->message,
                $data
            );
        }
    }
}
