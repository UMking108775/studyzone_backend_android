<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use App\Services\MailConfigurator;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;

class SettingsController extends Controller
{
    public function index()
    {
        return view('admin.settings.index', [
            'allowAudio' => Setting::getBool(Setting::ALLOW_AUDIO_DOWNLOAD, true),
            'allowVideo' => Setting::getBool(Setting::ALLOW_VIDEO_DOWNLOAD, true),
            // Free trial
            'trialEnabled' => Setting::getBool(Setting::TRIAL_ENABLED, false),
            'trialDays' => (int) Setting::getValue(Setting::TRIAL_DAYS, '3'),
            'trialStrictIp' => Setting::getBool(Setting::TRIAL_STRICT_IP, false),
            // AI: never expose the raw keys — only whether one is set + the model.
            'aiProvider' => Setting::getValue(Setting::AI_PROVIDER, 'auto'),
            'hasAnthropic' => Setting::hasValue(Setting::AI_ANTHROPIC_KEY) || !empty(config('services.anthropic.key')),
            'hasOpenai' => Setting::hasValue(Setting::AI_OPENAI_KEY) || !empty(config('services.openai.key')),
            'hasGemini' => Setting::hasValue(Setting::AI_GEMINI_KEY) || !empty(config('services.gemini.key')),
            'anthropicModel' => Setting::getValue(Setting::AI_ANTHROPIC_MODEL, ''),
            'openaiModel' => Setting::getValue(Setting::AI_OPENAI_MODEL, ''),
            'geminiModel' => Setting::getValue(Setting::AI_GEMINI_MODEL, ''),
            // Mailer (SMTP) — password never exposed, only whether it's set.
            'mailHost' => Setting::getValue(Setting::MAIL_HOST, ''),
            'mailPort' => Setting::getValue(Setting::MAIL_PORT, '587'),
            'mailUsername' => Setting::getValue(Setting::MAIL_USERNAME, ''),
            'hasMailPassword' => Setting::hasValue(Setting::MAIL_PASSWORD),
            'mailEncryption' => Setting::getValue(Setting::MAIL_ENCRYPTION, 'tls'),
            'mailFromAddress' => Setting::getValue(Setting::MAIL_FROM_ADDRESS, ''),
            'mailFromName' => Setting::getValue(Setting::MAIL_FROM_NAME, 'Study Zone'),
            'mailConfigured' => MailConfigurator::isConfigured(),
        ]);
    }

    public function update(Request $request)
    {
        // Downloads
        Setting::setValue(Setting::ALLOW_AUDIO_DOWNLOAD, $request->has('allow_audio_download') ? '1' : '0');
        Setting::setValue(Setting::ALLOW_VIDEO_DOWNLOAD, $request->has('allow_video_download') ? '1' : '0');

        // Free trial for new registrations.
        Setting::setValue(Setting::TRIAL_ENABLED, $request->has('trial_enabled') ? '1' : '0');
        $trialDays = (int) $request->input('trial_days', 3);
        $trialDays = max(0, min($trialDays, 365)); // clamp 0..365
        Setting::setValue(Setting::TRIAL_DAYS, (string) $trialDays);
        Setting::setValue(Setting::TRIAL_STRICT_IP, $request->has('trial_strict_ip') ? '1' : '0');

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

        // Mailer (SMTP) settings.
        Setting::setValue(Setting::MAIL_HOST, trim((string) $request->input('mail_host', '')));
        Setting::setValue(Setting::MAIL_PORT, trim((string) $request->input('mail_port', '587')));
        Setting::setValue(Setting::MAIL_USERNAME, trim((string) $request->input('mail_username', '')));
        $enc = $request->input('mail_encryption', 'tls');
        Setting::setValue(Setting::MAIL_ENCRYPTION, in_array($enc, ['tls', 'ssl', 'none'], true) ? $enc : 'tls');
        Setting::setValue(Setting::MAIL_FROM_ADDRESS, trim((string) $request->input('mail_from_address', '')));
        Setting::setValue(Setting::MAIL_FROM_NAME, trim((string) $request->input('mail_from_name', 'Study Zone')));
        // Password: blank keeps existing; the "clear" checkbox removes it.
        if ($request->boolean('clear_mail_password')) {
            Setting::setSecret(Setting::MAIL_PASSWORD, '');
        } elseif ($request->filled('mail_password')) {
            Setting::setSecret(Setting::MAIL_PASSWORD, trim((string) $request->input('mail_password')));
        }

        return redirect()->route('admin.settings.index')
            ->with('success', 'App settings updated.');
    }

    /** Send a test email to the logged-in admin using the saved SMTP settings. */
    public function testMail(Request $request)
    {
        if (!MailConfigurator::isConfigured()) {
            return back()->with('error', 'Set the SMTP host and "from" address first, then save.');
        }

        $to = $request->user()->email;

        try {
            MailConfigurator::apply();
            Mail::html(
                '<p style="font-family:Arial,sans-serif">✅ Your Study Zone mailer is working. This is a test email.</p>',
                function ($message) use ($to) {
                    $message->to($to)->subject('Study Zone — test email');
                }
            );
        } catch (\Throwable $e) {
            return back()->with('error', 'Test failed: ' . $e->getMessage());
        }

        return back()->with('success', "Test email sent to {$to}. Check the inbox (and spam).");
    }
}
