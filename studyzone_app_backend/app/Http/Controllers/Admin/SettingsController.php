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
            // AI: never expose the raw keys — only whether one is set + the model.
            'aiProvider' => Setting::getValue(Setting::AI_PROVIDER, 'auto'),
            'hasAnthropic' => Setting::hasValue(Setting::AI_ANTHROPIC_KEY) || !empty(config('services.anthropic.key')),
            'hasOpenai' => Setting::hasValue(Setting::AI_OPENAI_KEY) || !empty(config('services.openai.key')),
            'hasGemini' => Setting::hasValue(Setting::AI_GEMINI_KEY) || !empty(config('services.gemini.key')),
            'anthropicModel' => Setting::getValue(Setting::AI_ANTHROPIC_MODEL, ''),
            'openaiModel' => Setting::getValue(Setting::AI_OPENAI_MODEL, ''),
            'geminiModel' => Setting::getValue(Setting::AI_GEMINI_MODEL, ''),
        ]);
    }

    public function update(Request $request)
    {
        // Downloads
        Setting::setValue(Setting::ALLOW_AUDIO_DOWNLOAD, $request->has('allow_audio_download') ? '1' : '0');
        Setting::setValue(Setting::ALLOW_VIDEO_DOWNLOAD, $request->has('allow_video_download') ? '1' : '0');

        // AI provider selection.
        $provider = $request->input('ai_provider', 'auto');
        if (!in_array($provider, ['auto', 'anthropic', 'openai', 'gemini'], true)) {
            $provider = 'auto';
        }
        Setting::setValue(Setting::AI_PROVIDER, $provider);

        // Models (optional).
        Setting::setValue(Setting::AI_ANTHROPIC_MODEL, trim((string) $request->input('ai_anthropic_model', '')));
        Setting::setValue(Setting::AI_OPENAI_MODEL, trim((string) $request->input('ai_openai_model', '')));
        Setting::setValue(Setting::AI_GEMINI_MODEL, trim((string) $request->input('ai_gemini_model', '')));

        // API keys: only overwrite when a new value is typed; a "clear" checkbox
        // removes a stored key. Empty input keeps the existing key.
        $keyMap = [
            'anthropic' => Setting::AI_ANTHROPIC_KEY,
            'openai' => Setting::AI_OPENAI_KEY,
            'gemini' => Setting::AI_GEMINI_KEY,
        ];
        foreach ($keyMap as $provider => $settingKey) {
            if ($request->boolean("clear_{$provider}_key")) {
                Setting::setSecret($settingKey, '');
            } elseif ($request->filled("ai_{$provider}_key")) {
                Setting::setSecret($settingKey, trim((string) $request->input("ai_{$provider}_key")));
            }
        }

        return redirect()->route('admin.settings.index')
            ->with('success', 'App settings updated.');
    }
}
