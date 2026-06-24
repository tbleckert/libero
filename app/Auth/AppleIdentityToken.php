<?php

namespace App\Auth;

final readonly class AppleIdentityToken
{
    public function __construct(
        public string $subject,
        public string $audience,
        public ?string $email,
        public bool $emailVerified,
        public ?string $nonce,
    ) {}

    /**
     * @param  array<string, mixed>  $payload
     */
    public static function fromPayload(array $payload): self
    {
        return new self(
            subject: (string) $payload['sub'],
            audience: (string) $payload['aud'],
            email: isset($payload['email']) ? (string) $payload['email'] : null,
            emailVerified: self::booleanClaim($payload['email_verified'] ?? false),
            nonce: isset($payload['nonce']) ? (string) $payload['nonce'] : null,
        );
    }

    private static function booleanClaim(mixed $value): bool
    {
        if (is_bool($value)) {
            return $value;
        }

        return is_string($value) && strtolower($value) === 'true';
    }
}
