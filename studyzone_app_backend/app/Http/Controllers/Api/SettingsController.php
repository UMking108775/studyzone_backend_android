<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use App\Traits\ApiResponse;

class SettingsController extends Controller
{
    use ApiResponse;

    /** Public app settings the mobile app needs (download permissions, …). */
    public function index()
    {
        return $this->successResponse([
            'allow_audio_download' => Setting::getBool(Setting::ALLOW_AUDIO_DOWNLOAD, true),
            'allow_video_download' => Setting::getBool(Setting::ALLOW_VIDEO_DOWNLOAD, true),
        ], 'Settings retrieved successfully');
    }
}
