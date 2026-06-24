<?php

namespace App\Auth;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Validation\ValidationException;

class AppleIdentityTokenVerifier
{
    private const AppleIssuer = 'https://appleid.apple.com';

    private const AppleKeysCacheKey = 'apple.sign_in.keys';

    private const AppleKeysUrl = 'https://appleid.apple.com/auth/keys';

    public function verify(string $identityToken, ?string $expectedNonce = null): AppleIdentityToken
    {
        [$header, $payload, $signedPayload, $signature] = $this->decodeToken($identityToken);

        if (($header['alg'] ?? null) !== 'RS256' || ! is_string($header['kid'] ?? null)) {
            $this->fail();
        }

        $publicKey = $this->publicKeyFor($header['kid']);

        if (openssl_verify($signedPayload, $signature, $publicKey, OPENSSL_ALGO_SHA256) !== 1) {
            $this->fail();
        }

        $this->validatePayload($payload, $expectedNonce);

        return AppleIdentityToken::fromPayload($payload);
    }

    /**
     * @return array{array<string, mixed>, array<string, mixed>, string, string}
     */
    private function decodeToken(string $identityToken): array
    {
        $parts = explode('.', $identityToken);

        if (count($parts) !== 3) {
            $this->fail();
        }

        [$encodedHeader, $encodedPayload, $encodedSignature] = $parts;
        $header = $this->decodeJsonPart($encodedHeader);
        $payload = $this->decodeJsonPart($encodedPayload);
        $signature = $this->base64UrlDecode($encodedSignature);

        if ($signature === '') {
            $this->fail();
        }

        return [$header, $payload, "{$encodedHeader}.{$encodedPayload}", $signature];
    }

    /**
     * @return array<string, mixed>
     */
    private function decodeJsonPart(string $value): array
    {
        $decoded = json_decode($this->base64UrlDecode($value), true);

        if (! is_array($decoded)) {
            $this->fail();
        }

        return $decoded;
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    private function validatePayload(array $payload, ?string $expectedNonce): void
    {
        $now = now()->timestamp;
        $audience = $payload['aud'] ?? null;

        if (($payload['iss'] ?? null) !== self::AppleIssuer) {
            $this->fail();
        }

        if (! is_string($payload['sub'] ?? null) || $payload['sub'] === '') {
            $this->fail();
        }

        if (! is_string($audience) || ! in_array($audience, $this->allowedAudiences(), true)) {
            $this->fail();
        }

        if (! is_numeric($payload['exp'] ?? null) || (int) $payload['exp'] < $now) {
            $this->fail();
        }

        if (isset($payload['nbf']) && (! is_numeric($payload['nbf']) || (int) $payload['nbf'] > $now)) {
            $this->fail();
        }

        if ($expectedNonce !== null && ($payload['nonce'] ?? null) !== $expectedNonce) {
            $this->fail();
        }
    }

    /**
     * @return array<int, string>
     */
    private function allowedAudiences(): array
    {
        return collect(config('services.apple.client_ids', []))
            ->filter(fn (mixed $clientId): bool => is_string($clientId) && $clientId !== '')
            ->values()
            ->all();
    }

    private function publicKeyFor(string $kid): string
    {
        $jwk = $this->findJwk($kid, $this->appleKeys());

        if (! $jwk) {
            Cache::forget(self::AppleKeysCacheKey);
            $jwk = $this->findJwk($kid, $this->appleKeys());
        }

        if (! $jwk) {
            $this->fail();
        }

        return $this->rsaJwkToPem($jwk);
    }

    /**
     * @return array<int, array<string, mixed>>
     */
    private function appleKeys(): array
    {
        return Cache::remember(self::AppleKeysCacheKey, now()->addDay(), function (): array {
            $keys = Http::acceptJson()
                ->connectTimeout(2)
                ->timeout(5)
                ->get(self::AppleKeysUrl)
                ->throw()
                ->json('keys');

            return is_array($keys) ? $keys : [];
        });
    }

    /**
     * @param  array<int, array<string, mixed>>  $keys
     * @return array<string, mixed>|null
     */
    private function findJwk(string $kid, array $keys): ?array
    {
        foreach ($keys as $key) {
            if (($key['kid'] ?? null) === $kid && ($key['kty'] ?? null) === 'RSA') {
                return $key;
            }
        }

        return null;
    }

    /**
     * @param  array<string, mixed>  $jwk
     */
    private function rsaJwkToPem(array $jwk): string
    {
        if (! is_string($jwk['n'] ?? null) || ! is_string($jwk['e'] ?? null)) {
            $this->fail();
        }

        $modulus = $this->base64UrlDecode($jwk['n']);
        $exponent = $this->base64UrlDecode($jwk['e']);

        if ($modulus === '' || $exponent === '') {
            $this->fail();
        }

        $rsaPublicKey = $this->derSequence(
            $this->derInteger($modulus).$this->derInteger($exponent)
        );

        $rsaEncryptionAlgorithm = hex2bin('300D06092A864886F70D0101010500');
        $subjectPublicKeyInfo = $this->derSequence(
            $rsaEncryptionAlgorithm.$this->derBitString($rsaPublicKey)
        );

        return "-----BEGIN PUBLIC KEY-----\n"
            .chunk_split(base64_encode($subjectPublicKeyInfo), 64, "\n")
            ."-----END PUBLIC KEY-----\n";
    }

    private function derSequence(string $value): string
    {
        return "\x30".$this->derLength(strlen($value)).$value;
    }

    private function derInteger(string $value): string
    {
        $value = $this->unsignedInteger($value);

        return "\x02".$this->derLength(strlen($value)).$value;
    }

    private function derBitString(string $value): string
    {
        return "\x03".$this->derLength(strlen($value) + 1)."\x00".$value;
    }

    private function derLength(int $length): string
    {
        if ($length < 128) {
            return chr($length);
        }

        $bytes = ltrim(pack('N', $length), "\x00");

        return chr(0x80 | strlen($bytes)).$bytes;
    }

    private function unsignedInteger(string $value): string
    {
        if ($value === '' || ord($value[0]) < 0x80) {
            return $value;
        }

        return "\x00".$value;
    }

    private function base64UrlDecode(string $value): string
    {
        $remainder = strlen($value) % 4;

        if ($remainder > 0) {
            $value .= str_repeat('=', 4 - $remainder);
        }

        $decoded = base64_decode(strtr($value, '-_', '+/'), true);

        return $decoded === false ? '' : $decoded;
    }

    private function fail(): never
    {
        throw ValidationException::withMessages([
            'identity_token' => ['The Apple sign-in token could not be verified.'],
        ]);
    }
}
