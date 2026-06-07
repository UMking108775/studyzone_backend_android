<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\MailConfigurator;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;

/**
 * Password reset via a 6-digit OTP emailed to the user.
 *
 * Flow: forgotPassword (send) → verifyOtp (check, non-destructive) →
 * resetPassword (set new password). The OTP (hashed) lives in Laravel's
 * password_reset_tokens table; a wrong-attempt counter invalidates the code
 * after [MAX_ATTEMPTS] tries so it can't be brute-forced.
 */
class PasswordResetController extends Controller
{
    use ApiResponse;

    private const OTP_TTL_MINUTES = 10;
    private const MAX_ATTEMPTS = 8;

    /** Step 1: email an OTP if the account exists. */
    public function forgotPassword(Request $request)
    {
        $request->validate(['email' => 'required|email']);
        $email = strtolower(trim($request->email));

        // Generic message either way so we don't reveal which emails exist.
        $generic = 'If an account exists for that email, a 6-digit code has been sent.';

        $user = User::whereRaw('LOWER(email) = ?', [$email])->first();
        if (!$user) {
            return $this->successResponse(['ttl_minutes' => self::OTP_TTL_MINUTES], $generic);
        }

        if (!MailConfigurator::isConfigured()) {
            return $this->errorResponse(
                'Email sending is not set up yet. Please contact support.',
                null,
                503
            );
        }

        $otp = (string) random_int(100000, 999999);

        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $email],
            ['token' => Hash::make($otp), 'attempts' => 0, 'created_at' => now()]
        );

        try {
            MailConfigurator::apply();
            Mail::html($this->otpEmailHtml($user->name, $otp), function ($message) use ($email) {
                $message->to($email)->subject('Your Study Zone password reset code');
            });
        } catch (\Throwable $e) {
            return $this->errorResponse(
                'Could not send the email right now. Please try again later.',
                config('app.debug') ? $e->getMessage() : null,
                500
            );
        }

        return $this->successResponse(['ttl_minutes' => self::OTP_TTL_MINUTES], $generic);
    }

    /** Step 2: verify the OTP without consuming it (so step 3 can use it). */
    public function verifyOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'otp' => 'required|string',
        ]);
        $email = strtolower(trim($request->email));

        $check = $this->checkOtp($email, trim($request->otp));
        if ($check !== true) {
            return $check; // an error response
        }

        return $this->successResponse(['verified' => true], 'Code verified.');
    }

    /** Step 3: verify the OTP and set a new password. */
    public function resetPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'otp' => 'required|string',
            'password' => 'required|string|min:8|confirmed',
        ]);
        $email = strtolower(trim($request->email));

        $check = $this->checkOtp($email, trim($request->otp));
        if ($check !== true) {
            return $check;
        }

        $user = User::whereRaw('LOWER(email) = ?', [$email])->first();
        if (!$user) {
            return $this->errorResponse('Account not found.', null, 404);
        }

        $user->update(['password' => Hash::make($request->password)]);

        // Burn the OTP and sign out everywhere for safety.
        DB::table('password_reset_tokens')->where('email', $email)->delete();
        $user->tokens()->delete();

        return $this->successResponse(null, 'Your password has been reset. Please log in.');
    }

    /**
     * Validate an OTP for [$email]. Returns true when valid; otherwise returns
     * a ready-to-send error response. Counts wrong attempts and invalidates the
     * code after MAX_ATTEMPTS. Does NOT consume a valid code.
     */
    private function checkOtp(string $email, string $otp)
    {
        $row = DB::table('password_reset_tokens')->where('email', $email)->first();
        if (!$row) {
            return $this->errorResponse('Invalid or expired code. Please request a new one.', null, 422);
        }

        if (abs(Carbon::parse($row->created_at)->diffInMinutes(now())) >= self::OTP_TTL_MINUTES) {
            DB::table('password_reset_tokens')->where('email', $email)->delete();
            return $this->errorResponse('This code has expired. Please request a new one.', null, 422);
        }

        if (($row->attempts ?? 0) >= self::MAX_ATTEMPTS) {
            DB::table('password_reset_tokens')->where('email', $email)->delete();
            return $this->errorResponse('Too many attempts. Please request a new code.', null, 429);
        }

        if (!Hash::check($otp, $row->token)) {
            DB::table('password_reset_tokens')->where('email', $email)->increment('attempts');
            $left = self::MAX_ATTEMPTS - (($row->attempts ?? 0) + 1);
            $msg = $left > 0
                ? "Invalid code. $left attempt(s) left."
                : 'Too many attempts. Please request a new code.';
            return $this->errorResponse($msg, null, 422);
        }

        return true;
    }

    private function otpEmailHtml(string $name, string $otp): string
    {
        $ttl = self::OTP_TTL_MINUTES;
        $safeName = e($name);

        return <<<HTML
<div style="font-family: Arial, Helvetica, sans-serif; max-width: 480px; margin: 0 auto; padding: 24px; color: #1f2937;">
  <h2 style="color:#2563eb; margin:0 0 12px;">Study Zone</h2>
  <p>Hi {$safeName},</p>
  <p>Use this code to reset your password:</p>
  <div style="font-size: 32px; font-weight: bold; letter-spacing: 8px; background:#f3f4f6; padding:16px; text-align:center; border-radius:8px; margin:16px 0;">{$otp}</div>
  <p style="color:#6b7280; font-size: 14px;">This code expires in {$ttl} minutes. If you didn't request a password reset, you can safely ignore this email.</p>
</div>
HTML;
    }
}
