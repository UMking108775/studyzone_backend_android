<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Minimal, dependency-free Firebase Cloud Messaging (HTTP v1) sender.
 *
 * Authenticates with a Google service-account JSON (signs a JWT with the
 * account's private key, exchanges it for a short-lived OAuth token, caches
 * it) and posts messages to the FCM v1 endpoint. No Composer package required.
 *
 * Every send is a SILENT NO-OP until the service-account file is present, so
 * the app keeps working before Firebase is configured.
 */
class FcmService
{
    /** Whether a usable service-account file is configured. */
    public function isConfigured(): bool
    {
        $path = $this->credentialsPath();

        return is_string($path) && is_file($path) && extension_loaded('openssl');
    }

    /**
     * Broadcast to every device subscribed to [$topic] (e.g. "all").
     * Returns ['ok' => bool, 'status' => ?int, 'error' => ?string].
     */
    public function sendToTopic(string $topic, string $title, string $body, array $data = []): array
    {
        return $this->send(['topic' => $topic] + $this->payload($title, $body, $data));
    }

    /** Send to specific device tokens (per-user targeting). One result per token. */
    public function sendToTokens(array $tokens, string $title, string $body, array $data = []): array
    {
        $results = [];
        foreach (array_unique(array_filter($tokens)) as $token) {
            $results[] = $this->send(['token' => $token] + $this->payload($title, $body, $data));
        }
        return $results;
    }

    private function credentialsPath(): ?string
    {
        return config('services.fcm.credentials');
    }

    private function credentials(): array
    {
        return json_decode((string) file_get_contents($this->credentialsPath()), true) ?: [];
    }

    /** FCM data values must be strings. */
    private function payload(string $title, string $body, array $data): array
    {
        $stringData = [];
        foreach ($data as $key => $value) {
            $stringData[$key] = (string) $value;
        }

        return [
            'notification' => ['title' => $title, 'body' => $body],
            'data' => $stringData,
            'android' => [
                'priority' => 'high',
                'notification' => [
                    'channel_id' => 'studyzone_notifications',
                    'sound' => 'default',
                ],
            ],
        ];
    }

    private function send(array $message): array
    {
        if (! $this->isConfigured()) {
            return ['ok' => false, 'status' => null, 'error' => 'not_configured'];
        }

        try {
            $creds = $this->credentials();
            $projectId = $creds['project_id'] ?? null;
            if (! $projectId) {
                return ['ok' => false, 'status' => null, 'error' => 'missing_project_id'];
            }

            $response = Http::withToken($this->accessToken($creds))
                ->post(
                    "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send",
                    ['message' => $message]
                );

            if ($response->successful()) {
                return ['ok' => true, 'status' => $response->status(), 'error' => null];
            }

            Log::warning('FCM send failed', [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);

            $json = $response->json();
            $error = is_array($json)
                ? ($json['error']['message'] ?? $json['error']['status'] ?? 'unknown')
                : 'unknown';

            return ['ok' => false, 'status' => $response->status(), 'error' => $error];
        } catch (\Throwable $e) {
            Log::warning('FCM send error: ' . $e->getMessage());
            return ['ok' => false, 'status' => null, 'error' => $e->getMessage()];
        }
    }

    /** OAuth2 access token from the service account, cached just under 1h. */
    private function accessToken(array $creds): string
    {
        return Cache::remember('fcm_access_token', 3000, function () use ($creds) {
            $now = time();
            $jwt = $this->encodeJwt([
                'iss' => $creds['client_email'],
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                'aud' => 'https://oauth2.googleapis.com/token',
                'iat' => $now,
                'exp' => $now + 3600,
            ], $creds['private_key']);

            $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $jwt,
            ]);

            return (string) $response->json('access_token');
        });
    }

    private function encodeJwt(array $claims, string $privateKey): string
    {
        $segments = [
            $this->base64Url(json_encode(['alg' => 'RS256', 'typ' => 'JWT'])),
            $this->base64Url(json_encode($claims)),
        ];

        $signature = '';
        openssl_sign(implode('.', $segments), $signature, $privateKey, OPENSSL_ALGO_SHA256);
        $segments[] = $this->base64Url($signature);

        return implode('.', $segments);
    }

    private function base64Url(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
}
