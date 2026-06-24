<?php

namespace App\Support;

use RuntimeException;

class AppleJwtSigner
{
    /**
     * @param  array<string, mixed>  $header
     * @param  array<string, mixed>  $payload
     */
    public function sign(array $header, array $payload, string $privateKeyBase64): string
    {
        $segments = [
            $this->base64UrlEncode(json_encode($header, JSON_THROW_ON_ERROR)),
            $this->base64UrlEncode(json_encode($payload, JSON_THROW_ON_ERROR)),
        ];
        $signingInput = implode('.', $segments);

        if (! openssl_sign($signingInput, $signature, $this->privateKey($privateKeyBase64), OPENSSL_ALGO_SHA256)) {
            throw new RuntimeException('Unable to sign Apple JWT.');
        }

        $segments[] = $this->base64UrlEncode($this->ecdsaDerToJose($signature));

        return implode('.', $segments);
    }

    /**
     * @return resource|\OpenSSLAsymmetricKey
     */
    private function privateKey(string $privateKeyBase64): mixed
    {
        $key = base64_decode($privateKeyBase64, true);

        if (! is_string($key) || $key === '') {
            throw new RuntimeException('The Apple private key must be base64 encoded.');
        }

        $privateKey = openssl_pkey_get_private($key);

        if (! $privateKey) {
            throw new RuntimeException('The Apple private key is invalid.');
        }

        return $privateKey;
    }

    private function ecdsaDerToJose(string $signature): string
    {
        $offset = 0;

        if ($signature === '' || ord($signature[$offset++]) !== 0x30) {
            throw new RuntimeException('The Apple JWT signature is invalid.');
        }

        $this->readDerLength($signature, $offset);

        if (ord($signature[$offset++]) !== 0x02) {
            throw new RuntimeException('The Apple JWT signature is invalid.');
        }

        $rLength = $this->readDerLength($signature, $offset);
        $r = substr($signature, $offset, $rLength);
        $offset += $rLength;

        if (ord($signature[$offset++]) !== 0x02) {
            throw new RuntimeException('The Apple JWT signature is invalid.');
        }

        $sLength = $this->readDerLength($signature, $offset);
        $s = substr($signature, $offset, $sLength);

        return $this->normalizeInteger($r).$this->normalizeInteger($s);
    }

    private function readDerLength(string $der, int &$offset): int
    {
        $length = ord($der[$offset++]);

        if ($length < 0x80) {
            return $length;
        }

        $byteCount = $length & 0x7F;

        if ($byteCount === 0 || $byteCount > 2) {
            throw new RuntimeException('The Apple JWT signature length is invalid.');
        }

        $length = 0;

        for ($i = 0; $i < $byteCount; $i++) {
            $length = ($length << 8) | ord($der[$offset++]);
        }

        return $length;
    }

    private function normalizeInteger(string $integer): string
    {
        $integer = ltrim($integer, "\x00");

        if (strlen($integer) > 32) {
            throw new RuntimeException('The Apple JWT signature integer is invalid.');
        }

        return str_pad($integer, 32, "\x00", STR_PAD_LEFT);
    }

    private function base64UrlEncode(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }
}
