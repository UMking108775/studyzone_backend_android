<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\Request;

class SettingsController extends Controller
{
    public function index()
    {
        return view('admin.settings.index', [
            'allowAudio' => Setting::getBool(Setting::ALLOW_AUDIO_DOWNLOAD, true),
            'allowVideo' => Setting::getBool(Setting::ALLOW_VIDEO_DOWNLOAD, true),
        ]);
    }

    public function update(Request $request)
    {
        Setting::setValue(Setting::ALLOW_AUDIO_DOWNLOAD, $request->has('allow_audio_download') ? '1' : '0');
        Setting::setValue(Setting::ALLOW_VIDEO_DOWNLOAD, $request->has('allow_video_download') ? '1' : '0');

        return redirect()->route('admin.settings.index')
            ->with('success', 'App settings updated.');
    }
}
