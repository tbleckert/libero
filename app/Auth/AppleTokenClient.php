<?php

namespace App\Auth;

use App\Support\AppleJwtSigner;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class AppleTokenClient
{
    private const ClientSecretTtlSeconds = 15_552_000;

    private const TokenEndpoint = 'https://appleid.apple.com/auth/token';

    private const RevokeEndpoint = 'https://appleid.apple.com/auth/revoke';

    public function __construct(private AppleJwtSigner $jwtSigner) {}

    public function exchangeAuthorizationCode(string $authorizationCode, string $clientId): ?string
    {
        $response = Http::asForm()
            ->acceptJson()
            ->connectTimeout(5)
            ->timeout(10)
            ->post(self::TokenEndpoint, $this->tokenPayload($authorizationCode, $clientId))
            ->throw();

        $refreshToken = $response->json('refresh_token');

        return is_string($refreshToken) && $refreshToken !== '' ? $refreshToken : null;
    }

    public function revokeRefreshToken(string $refreshToken, string $clientId): void
    {
        Http::asForm()
            ->acceptJson()
            ->connectTimeout(5)
            ->timeout(10)
            ->post(self::RevokeEndpoint, [
                'client_id' => $clientId,
                'client_secret' => $this->clientSecret($clientId),
                'token' => $refreshToken,
                'token_type_hint' => 'refresh_token',
            ])
            ->throw();
    }

    /**
     * @return array<string, string>
     */
    private function tokenPayload(string $authorizationCode, string $clientId): array
    {
        $payload = [
            'client_id' => $clientId,
            'client_secret' => $this->clientSecret($clientId),
            'code' => $authorizationCode,
            'grant_type' => 'authorization_code',
        ];

        $redirectUri = $this->redirectUri($clientId);

        if ($redirectUri) {
            $payload['redirect_uri'] = $redirectUri;
        }

        return $payload;
    }

    private function redirectUri(string $clientId): ?string
    {
        if ($clientId !== (string) config('services.apple.client_ids.web')) {
            return null;
        }

        $webUrl = config('services.libero.web_url');

        if (! is_string($webUrl) || $webUrl === '') {
            return null;
        }

        return rtrim($webUrl, '/').'/auth/apple/callback';
    }

    private function clientSecret(string $clientId): string
    {
        $now = now();

        return $this->jwtSigner->sign(
            [
                'alg' => 'ES256',
                'kid' => $this->configValue('services.apple.key_id'),
            ],
            [
                'iss' => $this->configValue('services.apple.team_id'),
                'iat' => $now->timestamp,
                'exp' => $now->copy()->addSeconds(self::ClientSecretTtlSeconds)->timestamp,
                'aud' => 'https://appleid.apple.com',
                'sub' => $clientId,
            ],
            $this->configValue('services.apple.private_key_base64'),
        );
    }

    private function configValue(string $key): string
    {
        $value = config($key);

        if (! is_string($value) || $value === '') {
            throw new RuntimeException("Missing Apple configuration value [{$key}].");
        }

        return $value;
    }
}
