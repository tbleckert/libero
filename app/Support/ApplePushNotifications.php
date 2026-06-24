<?php

namespace App\Support;

use App\Models\PushDevice;
use Illuminate\Http\Client\RequestException;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class ApplePushNotifications
{
    public function __construct(private AppleJwtSigner $jwtSigner) {}

    /**
     * @param  array<string, mixed>  $payload
     */
    public function send(PushDevice $device, array $payload): void
    {
        if (! $this->isConfigured()) {
            return;
        }

        Http::acceptJson()
            ->asJson()
            ->withOptions(['version' => 2.0])
            ->withToken($this->providerToken())
            ->withHeaders([
                'apns-topic' => $this->configValue('services.apns.bundle_id'),
                'apns-push-type' => 'alert',
                'apns-priority' => '10',
            ])
            ->connectTimeout(5)
            ->timeout(10)
            ->post($this->url($device), $payload)
            ->throw();
    }

    public function shouldRevokeToken(RequestException $exception): bool
    {
        $reason = $exception->response?->json('reason');

        return in_array($reason, ['BadDeviceToken', 'Unregistered'], true);
    }

    private function isConfigured(): bool
    {
        foreach ([
            'services.apns.team_id',
            'services.apns.key_id',
            'services.apns.private_key_base64',
            'services.apns.bundle_id',
        ] as $key) {
            $value = config($key);

            if (! is_string($value) || $value === '') {
                return false;
            }
        }

        return true;
    }

    private function providerToken(): string
    {
        return $this->jwtSigner->sign(
            [
                'alg' => 'ES256',
                'kid' => $this->configValue('services.apns.key_id'),
            ],
            [
                'iss' => $this->configValue('services.apns.team_id'),
                'iat' => now()->timestamp,
            ],
            $this->configValue('services.apns.private_key_base64'),
        );
    }

    private function url(PushDevice $device): string
    {
        $baseUrl = match ($device->environment) {
            'production' => $this->configValue('services.apns.production_url'),
            'sandbox' => $this->configValue('services.apns.sandbox_url'),
            default => throw new RuntimeException("Unsupported APNs environment [{$device->environment}]."),
        };

        return rtrim($baseUrl, '/').'/3/device/'.$device->token;
    }

    private function configValue(string $key): string
    {
        $value = config($key);

        if (! is_string($value) || $value === '') {
            throw new RuntimeException("Missing APNs configuration value [{$key}].");
        }

        return $value;
    }
}
