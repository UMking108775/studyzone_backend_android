<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Crypt;

/**
 * Simple key/value app settings (downloads, AI provider keys, …).
 * Secret values (API keys) are stored encrypted.
 */
class Setting extends Model
{
    protected $fillable = ['key', 'value'];

    // Known keys + their defaults.
    public const ALLOW_AUDIO_DOWNLOAD = 'allow_audio_download';
    public const ALLOW_VIDEO_DOWNLOAD = 'allow_video_download';

    // Free trial for new registrations.
    public const TRIAL_ENABLED = 'trial_enabled';     // bool
    public const TRIAL_DAYS = 'trial_days';           // int (days)
    public const TRIAL_STRICT_IP = 'trial_strict_ip'; // bool: also block repeat IPs

    // AI quiz generator settings (keys stored encrypted).
    public const AI_PROVIDER = 'ai_provider';
    public const AI_ANTHROPIC_KEY = 'ai_anthropic_key';
    public const AI_ANTHROPIC_MODEL = 'ai_anthropic_model';
    public const AI_OPENAI_KEY = 'ai_openai_key';
    public const AI_OPENAI_MODEL = 'ai_openai_model';
    public const AI_GEMINI_KEY = 'ai_gemini_key';
    public const AI_GEMINI_MODEL = 'ai_gemini_model';

    // Mailer (SMTP) settings — for sending OTP / transactional email.
    // Password stored encrypted.
    public const MAIL_HOST = 'mail_host';
    public const MAIL_PORT = 'mail_port';
    public const MAIL_USERNAME = 'mail_username';
    public const MAIL_PASSWORD = 'mail_password';
    public const MAIL_ENCRYPTION = 'mail_encryption'; // tls | ssl | none
    public const MAIL_FROM_ADDRESS = 'mail_from_address';
    public const MAIL_FROM_NAME = 'mail_from_name';

    public static function getValue(string $key, ?string $default = null): ?string
    {
        return static::query()->where('key', $key)->value('value') ?? $default;
    }

    public static function getBool(string $key, bool $default = true): bool
    {
        $row = static::query()->where('key', $key)->value('value');
        if ($row === null) {
            return $default;
        }
        return in_array($row, ['1', 'true', true, 1], true);
    }

    public static function setValue(string $key, string $value): void
    {
        static::query()->updateOrCreate(['key' => $key], ['value' => $value]);
    }

    public static function hasValue(string $key): bool
    {
        return !empty(static::getValue($key));
    }

    /** Read an encrypted secret (returns null if unset or undecryptable). */
    public static function getSecret(string $key): ?string
    {
        $raw = static::getValue($key);
        if ($raw === null || $raw === '') {
            return null;
        }
        try {
            return Crypt::decryptString($raw);
        } catch (\Throwable $e) {
            return null;
        }
    }

    /** Store a secret encrypted (empty string clears it). */
    public static function setSecret(string $key, string $value): void
    {
        static::setValue($key, $value === '' ? '' : Crypt::encryptString($value));
    }
}
