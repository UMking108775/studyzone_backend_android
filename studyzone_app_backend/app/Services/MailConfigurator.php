<?php

namespace App\Services;

use App\Models\Setting;
use Illuminate\Support\Facades\Config;

/**
 * Applies the admin-configured SMTP mailer (from the Settings table) to the
 * runtime mail config, so OTP / transactional email is sent through whatever
 * mailer the admin set up in the panel — no .env edits or redeploys needed.
 */
class MailConfigurator
{
    /** True when enough SMTP settings exist to attempt sending. */
    public static function isConfigured(): bool
    {
        return Setting::hasValue(Setting::MAIL_HOST)
            && Setting::hasValue(Setting::MAIL_FROM_ADDRESS);
    }

    /** Override the runtime mail config from the admin settings. */
    public static function apply(): void
    {
        if (!self::isConfigured()) {
            return;
        }

        $encryption = Setting::getValue(Setting::MAIL_ENCRYPTION, 'tls');
        $encryption = in_array($encryption, ['tls', 'ssl'], true) ? $encryption : null;
        $port = (int) (Setting::getValue(Setting::MAIL_PORT) ?: 587);

        Config::set('mail.default', 'smtp');
        Config::set('mail.mailers.smtp.transport', 'smtp');
        Config::set('mail.mailers.smtp.host', Setting::getValue(Setting::MAIL_HOST));
        Config::set('mail.mailers.smtp.port', $port);
        Config::set('mail.mailers.smtp.username', Setting::getValue(Setting::MAIL_USERNAME) ?: null);
        Config::set('mail.mailers.smtp.password', Setting::getSecret(Setting::MAIL_PASSWORD));
        Config::set('mail.mailers.smtp.encryption', $encryption);
        Config::set('mail.from.address', Setting::getValue(Setting::MAIL_FROM_ADDRESS));
        Config::set('mail.from.name', Setting::getValue(Setting::MAIL_FROM_NAME, 'Study Zone'));
    }
}
