<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\DeviceToken;
use App\Models\Notification;
use App\Services\FcmService;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class NotificationController extends Controller
{
    /**
     * Display a listing of notifications.
     */
    public function index(Request $request)
    {
        $status = $request->get('status', 'all');
        $type = $request->get('type', 'all');

        $query = Notification::query();

        if ($status === 'active') {
            $query->where('is_active', true);
        } elseif ($status === 'inactive') {
            $query->where('is_active', false);
        }

        if ($type !== 'all') {
            $query->where('type', $type);
        }

        $notifications = $query->ordered()->paginate(15);

        $stats = [
            'all' => Notification::count(),
            'active' => Notification::where('is_active', true)->count(),
            'inactive' => Notification::where('is_active', false)->count(),
        ];

        $deviceCount = DeviceToken::count();

        return view('admin.notifications.index', compact('notifications', 'status', 'type', 'stats', 'deviceCount'));
    }

    /**
     * Fire a one-off test push to the broadcast topic and report exactly what
     * happened, so the admin can pinpoint why pushes aren't arriving.
     */
    public function testPush()
    {
        $fcm = app(FcmService::class);
        $tokens = DeviceToken::pluck('token')->all();
        $deviceCount = count($tokens);

        if (! $fcm->isConfigured()) {
            return back()->with('error',
                'Push is NOT configured on the server: the Firebase service-account file is missing at '
                . 'storage/app/firebase/service-account.json. Upload it there, then run `php artisan config:clear`. '
                . "(Registered devices: {$deviceCount}.)");
        }

        $title = '🔔 Test push';
        $body = 'If this appears in your notification bar, push notifications are working!';
        $data = ['type' => 'info'];

        // Broadcast (topic) AND direct-to-token, so we can tell which path works.
        $topic = $fcm->sendToTopic(config('services.fcm.topic', 'all'), $title, $body, $data);

        $tokenOk = 0;
        foreach ($fcm->sendToTokens($tokens, $title, $body, $data) as $r) {
            if (! empty($r['ok'])) {
                $tokenOk++;
            }
        }

        if (! empty($topic['ok'])) {
            $msg = 'Firebase ACCEPTED the broadcast (topic "' . config('services.fcm.topic', 'all') . '"). ';
            $msg .= $deviceCount > 0
                ? "Also delivered directly to {$tokenOk}/{$deviceCount} registered device(s)."
                : 'But NO devices are registered yet — install the new build, log in, and open the app so it registers, then test again.';

            return back()->with('success', $msg);
        }

        return back()->with('error',
            'Firebase REJECTED the broadcast: ' . ($topic['error'] ?? 'unknown')
            . ' (HTTP ' . ($topic['status'] ?? '—') . "). Registered devices: {$deviceCount}.");
    }

    /**
     * Show the form for creating a new notification.
     */
    public function create()
    {
        return view('admin.notifications.create');
    }

    /**
     * Store a newly created notification.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'type' => 'required|in:info,success,warning,error,announcement',
            'action_url' => 'nullable|url|max:255',
            'action_text' => 'nullable|string|max:50',
            'is_active' => 'boolean',
            'scheduled_at' => 'nullable|date|after_or_equal:now',
            'expires_at' => 'nullable|date|after:scheduled_at',
            'priority' => 'nullable|integer|min:0|max:100',
        ]);

        $validated['is_active'] = $request->has('is_active');
        $validated['priority'] = $validated['priority'] ?? 0;

        $notification = Notification::create($validated);

        // Push it to devices in real time via FCM (no-op until configured).
        $this->dispatchPush($notification);

        return redirect()->route('admin.notifications.index')
            ->with('success', 'Notification created successfully!');
    }

    /**
     * Send a freshly-published notification to devices via FCM. Global ones go
     * to the "all" topic (every install is subscribed); user-specific ones go
     * to that user's registered device tokens. Future-scheduled notifications
     * are skipped here (deliver them later via a scheduled command). Safe no-op
     * until the Firebase service account is configured.
     */
    private function dispatchPush(Notification $notification): void
    {
        if (! $notification->is_active) {
            return;
        }

        $scheduledAt = $notification->scheduled_at;
        if ($scheduledAt && Carbon::parse($scheduledAt)->isFuture()) {
            return;
        }

        $fcm = app(FcmService::class);
        if (! $fcm->isConfigured()) {
            return;
        }

        $data = [
            'notification_id' => $notification->id,
            'type' => $notification->type ?? 'info',
            'action_url' => $notification->action_url ?? '',
        ];

        if ($notification->user_id) {
            $tokens = DeviceToken::where('user_id', $notification->user_id)->pluck('token')->all();
            $fcm->sendToTokens($tokens, $notification->title, $notification->message, $data);
        } else {
            $fcm->sendToTopic(
                config('services.fcm.topic', 'all'),
                $notification->title,
                $notification->message,
                $data
            );
        }
    }

    /**
     * Show the form for editing the specified notification.
     */
    public function edit(string $id)
    {
        $notification = Notification::findOrFail($id);
        return view('admin.notifications.edit', compact('notification'));
    }

    /**
     * Update the specified notification.
     */
    public function update(Request $request, string $id)
    {
        $notification = Notification::findOrFail($id);

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'type' => 'required|in:info,success,warning,error,announcement',
            'action_url' => 'nullable|url|max:255',
            'action_text' => 'nullable|string|max:50',
            'is_active' => 'boolean',
            'scheduled_at' => 'nullable|date',
            'expires_at' => 'nullable|date|after:scheduled_at',
            'priority' => 'nullable|integer|min:0|max:100',
        ]);

        $validated['is_active'] = $request->has('is_active');
        $validated['priority'] = $validated['priority'] ?? $notification->priority;

        $notification->update($validated);

        return redirect()->route('admin.notifications.index')
            ->with('success', 'Notification updated successfully!');
    }

    /**
     * Remove the specified notification.
     */
    public function destroy(string $id)
    {
        $notification = Notification::findOrFail($id);
        $notification->delete();

        return redirect()->route('admin.notifications.index')
            ->with('success', 'Notification deleted successfully!');
    }
}

