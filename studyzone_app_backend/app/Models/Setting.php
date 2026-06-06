<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Simple key/value app settings (e.g. whether users may download audio/video).
 */
class Setting extends Model
{
    protected $fillable = ['key', 'value'];

    // Known keys + their defaults.
    public const ALLOW_AUDIO_DOWNLOAD = 'allow_audio_download';
    public const ALLOW_VIDEO_DOWNLOAD = 'allow_video_download';

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
}
