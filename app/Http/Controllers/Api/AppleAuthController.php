<?php

namespace App\Http\Controllers\Api;

use App\Auth\AppleIdentityToken;
use App\Auth\AppleIdentityTokenVerifier;
use App\Auth\AppleTokenClient;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreAppleAuthTokenRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Models\UserIdentity;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use Throwable;

class AppleAuthController extends Controller
{
    public function store(
        StoreAppleAuthTokenRequest $request,
        AppleIdentityTokenVerifier $verifier,
        AppleTokenClient $appleTokens,
    ): JsonResponse {
        $validated = $request->validated();
        $appleToken = $verifier->verify($validated['identity_token'], $validated['nonce'] ?? null);
        $providerRefreshToken = $this->exchangeProviderRefreshToken(
            $appleTokens,
            $appleToken,
            $validated['authorization_code'] ?? null,
        );

        try {
            $user = DB::transaction(function () use ($appleToken, $providerRefreshToken, $validated): User {
                $identity = UserIdentity::query()
                    ->where('provider', UserIdentity::ProviderApple)
                    ->where('provider_user_id', $appleToken->subject)
                    ->first();

                if ($identity) {
                    $this->refreshIdentity($identity, $appleToken, $providerRefreshToken);

                    return $identity->user()->firstOrFail();
                }

                $user = $this->findExistingUser($appleToken) ?? $this->createUser($appleToken, $validated);

                $identity = $user->identities()->create([
                    'provider' => UserIdentity::ProviderApple,
                    'provider_user_id' => $appleToken->subject,
                    'email' => $appleToken->email ? Str::lower($appleToken->email) : null,
                    'email_verified_at' => $appleToken->emailVerified ? now() : null,
                ]);

                $this->storeIdentityToken($identity, $appleToken, $providerRefreshToken);

                return $user;
            });
        } catch (Throwable $exception) {
            $this->revokeMintedProviderRefreshToken($appleTokens, $appleToken, $providerRefreshToken);

            throw $exception;
        }

        $token = $user->createToken($validated['device_name']);

        return response()->json([
            'data' => [
                'token' => $token->plainTextToken,
                'user' => UserResource::make($user)->resolve($request),
            ],
        ]);
    }

    private function exchangeProviderRefreshToken(
        AppleTokenClient $appleTokens,
        AppleIdentityToken $appleToken,
        ?string $authorizationCode,
    ): ?string {
        if (! $authorizationCode) {
            return null;
        }

        return $appleTokens->exchangeAuthorizationCode($authorizationCode, $appleToken->audience);
    }

    private function revokeMintedProviderRefreshToken(
        AppleTokenClient $appleTokens,
        AppleIdentityToken $appleToken,
        ?string $providerRefreshToken,
    ): void {
        if (! $providerRefreshToken) {
            return;
        }

        try {
            $appleTokens->revokeRefreshToken($providerRefreshToken, $appleToken->audience);
        } catch (Throwable $exception) {
            report($exception);
        }
    }

    private function findExistingUser(AppleIdentityToken $appleToken): ?User
    {
        if (! $appleToken->email || ! $appleToken->emailVerified) {
            return null;
        }

        $user = User::query()
            ->where('email', Str::lower($appleToken->email))
            ->first();

        if ($user && ! $user->email_verified_at) {
            $user->forceFill(['email_verified_at' => now()])->save();
        }

        return $user;
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    private function createUser(AppleIdentityToken $appleToken, array $validated): User
    {
        if (! $appleToken->email || ! $appleToken->emailVerified) {
            throw ValidationException::withMessages([
                'identity_token' => ['Apple did not provide a verified email address.'],
            ]);
        }

        return User::query()->create([
            'name' => $this->userName($appleToken, $validated['name'] ?? null),
            'email' => Str::lower($appleToken->email),
            'email_verified_at' => now(),
            'password' => Str::random(64),
        ]);
    }

    private function userName(AppleIdentityToken $appleToken, ?string $name): string
    {
        if ($name) {
            return $name;
        }

        $emailName = Str::of((string) $appleToken->email)
            ->before('@')
            ->replace(['.', '-', '_'], ' ')
            ->squish()
            ->title()
            ->value();

        return $emailName ?: 'Libero User';
    }

    private function refreshIdentity(
        UserIdentity $identity,
        AppleIdentityToken $appleToken,
        ?string $providerRefreshToken,
    ): void {
        $attributes = [];

        if ($appleToken->email) {
            $attributes['email'] = Str::lower($appleToken->email);
            $attributes['email_verified_at'] = $appleToken->emailVerified ? now() : null;
        }

        if ($attributes !== []) {
            $identity->update($attributes);
        }

        $this->storeIdentityToken($identity, $appleToken, $providerRefreshToken);
    }

    private function storeIdentityToken(
        UserIdentity $identity,
        AppleIdentityToken $appleToken,
        ?string $providerRefreshToken,
    ): void {
        if (! $providerRefreshToken) {
            return;
        }

        $identity->tokens()->updateOrCreate([
            'provider_client_id' => $appleToken->audience,
        ], [
            'refresh_token' => $providerRefreshToken,
        ]);
    }
}
