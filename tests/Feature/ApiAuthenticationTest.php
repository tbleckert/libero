<?php

use App\Auth\AppleIdentityToken;
use App\Auth\AppleIdentityTokenVerifier;
use App\Models\User;
use App\Models\UserIdentity;
use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\URL;

test('the v1 health endpoint is available', function () {
    $this->getJson('/api/v1/health')
        ->assertSuccessful()
        ->assertJsonPath('status', 'ok');
});

test('a user can register and receives an email verification notification', function () {
    Notification::fake();

    $response = $this->postJson('/api/v1/auth/register', [
        'name' => 'Ada Lovelace',
        'email' => 'ADA@example.com',
        'password' => 'password',
        'password_confirmation' => 'password',
        'device_name' => 'Ada iPhone',
    ]);

    $response
        ->assertCreated()
        ->assertJsonPath('data.user.email', 'ada@example.com')
        ->assertJsonPath('data.user.needs_email_verification', true);

    $user = User::query()->where('email', 'ada@example.com')->firstOrFail();

    expect($response->json('data.token'))->toBeString()->not->toBeEmpty()
        ->and($user->hasVerifiedEmail())->toBeFalse();

    Notification::assertSentTo($user, VerifyEmail::class);
});

test('a user can create and revoke a current auth token', function () {
    $user = User::factory()->create([
        'email' => 'user@example.com',
        'password' => 'password',
    ]);

    $token = $this->postJson('/api/v1/auth/tokens', [
        'email' => 'USER@example.com',
        'password' => 'password',
        'device_name' => 'iPhone',
    ])
        ->assertSuccessful()
        ->assertJsonPath('data.user.email', 'user@example.com')
        ->json('data.token');

    expect($token)->toBeString()->not->toBeEmpty();

    $this->withToken($token)
        ->deleteJson('/api/v1/auth/tokens/current')
        ->assertNoContent();

    expect($user->tokens()->count())->toBe(0);
});

test('a signed email verification link verifies the user', function () {
    $user = User::factory()->unverified()->create();
    $url = URL::temporarySignedRoute('verification.verify', now()->addMinutes(60), [
        'id' => $user->id,
        'hash' => sha1($user->getEmailForVerification()),
    ]);

    $this->getJson($url)
        ->assertSuccessful()
        ->assertJsonPath('data.user.needs_email_verification', false);

    expect($user->refresh()->hasVerifiedEmail())->toBeTrue();
});

test('a user can authenticate with apple', function () {
    $this->app->instance(AppleIdentityTokenVerifier::class, new class extends AppleIdentityTokenVerifier
    {
        public function verify(string $identityToken, ?string $expectedNonce = null): AppleIdentityToken
        {
            return new AppleIdentityToken(
                subject: 'apple-user-123',
                audience: 'com.example.Libero',
                email: 'apple@example.com',
                emailVerified: true,
                nonce: $expectedNonce,
            );
        }
    });

    $response = $this->postJson('/api/v1/auth/apple', [
        'identity_token' => 'fake.identity.token',
        'device_name' => 'Jane iPhone',
        'name' => 'Jane Appleseed',
        'nonce' => 'nonce-value',
    ]);

    $response
        ->assertSuccessful()
        ->assertJsonPath('data.user.email', 'apple@example.com')
        ->assertJsonPath('data.user.needs_email_verification', false);

    $user = User::query()->where('email', 'apple@example.com')->firstOrFail();
    $identityExists = UserIdentity::query()
        ->where('user_id', $user->id)
        ->where('provider', UserIdentity::ProviderApple)
        ->where('provider_user_id', 'apple-user-123')
        ->exists();

    expect($response->json('data.token'))->toBeString()->not->toBeEmpty()
        ->and($identityExists)->toBeTrue();
});
