<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeviceToken;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;

class DeviceTokenController extends Controller
{
    use ApiResponse;

    /**
     * Register (or re-assign) the caller's FCM token. Token is unique, so the
     * same device logging in as a different user just moves ownership.
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'token' => 'required|string|max:255',
            'platform' => 'nullable|string|max:16',
        ]);

        DeviceToken::updateOrCreate(
            ['token' => $data['token']],
            [
                'user_id' => $request->user()->id,
                'platform' => $data['platform'] ?? 'android',
            ]
        );

        return $this->successResponse(null, 'Device registered for notifications');
    }

    /**
     * Remove a token (called on logout so a shared device stops receiving the
     * previous user's pushes).
     */
    public function destroy(Request $request)
    {
        $data = $request->validate([
            'token' => 'required|string|max:255',
        ]);

        DeviceToken::where('token', $data['token'])->delete();

        return $this->successResponse(null, 'Device unregistered');
    }
}
