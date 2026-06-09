<?php

namespace App\Services;

use App\Models\Setting;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Support\Facades\Log;

/**
 * Grants a free trial to a freshly-registered user when the feature is enabled.
 *
 * A trial is modelled as an auto-approved {@see Subscription} (status=approved,
 * ends_at = now + trial_days) so it reuses the entire access system — an active
 * trial unlocks all paid categories/content exactly like a paid plan, and lapses
 * on its own when the window passes.
 *
 * Anti-abuse: the granting device id (Android ID) and IP are stored on the
 * trial. The same device can never claim a second trial (even via a new
 * account). IP is always recorded; when `trial_strict_ip` is on, a repeat IP is
 * blocked too (off by default — carrier-grade NAT means many real users can
 * share one IP).
 */
class TrialService
{
    public const PLAN_NAME = 'Free Trial';

    public function isEnabled(): bool
    {
        return Setting::getBool(Setting::TRIAL_ENABLED, false) && $this->days() > 0;
    }

    public function days(): int
    {
        return max(0, (int) Setting::getValue(Setting::TRIAL_DAYS, '3'));
    }

    /**
     * Grant a trial to $user if eligible. Returns the created Subscription, or
     * null when the feature is off or the device/IP has already used a trial.
     * Never throws — a failure here must not break registration.
     */
    public function grantIfEligible(User $user, ?string $deviceId, ?string $ip): ?Subscription
    {
        try {
            if (! $this->isEnabled()) {
                return null;
            }

            $deviceId = $deviceId !== null ? trim($deviceId) : '';
            $ip = $ip !== null ? trim($ip) : '';

            // A user gets at most one trial, ever.
            if ($user->subscriptions()->where('is_trial', true)->exists()) {
                return null;
            }

            // Same physical device can't farm trials across accounts.
            if ($deviceId !== ''
                && Subscription::where('is_trial', true)->where('device_id', $deviceId)->exists()) {
                return null;
            }

            // No device id (older app / lookup failed) → fall back to IP dedupe.
            if ($deviceId === '' && $ip !== ''
                && Subscription::where('is_trial', true)->where('ip_address', $ip)->exists()) {
                return null;
            }

            // Optional strict IP block (off by default).
            if ($ip !== ''
                && Setting::getBool(Setting::TRIAL_STRICT_IP, false)
                && Subscription::where('is_trial', true)->where('ip_address', $ip)->exists()) {
                return null;
            }

            $days = $this->days();

            return Subscription::create([
                'user_id' => $user->id,
                'status' => 'approved',
                'is_trial' => true,
                'device_id' => $deviceId !== '' ? $deviceId : null,
                'ip_address' => $ip !== '' ? $ip : null,
                'plan_name' => self::PLAN_NAME,
                'duration_days' => $days,
                'amount' => 0,
                'currency' => 'PKR',
                'starts_at' => now(),
                'ends_at' => now()->addDays($days),
                'reviewed_at' => now(),
                'admin_note' => 'Auto-granted free trial on registration.',
            ]);
        } catch (\Throwable $e) {
            Log::warning('Trial grant failed: ' . $e->getMessage());
            return null;
        }
    }
}
