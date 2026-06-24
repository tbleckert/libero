<?php

use App\Models\PushDevice;
use App\Models\User;
use Laravel\Sanctum\Sanctum;

test('an authenticated user can register and delete an ios push device', function () {
    $user = User::factory()->create();
    Sanctum::actingAs($user);

    $payload = [
        'platform' => 'IOS',
        'environment' => 'sandbox',
        'token' => str_repeat('a', 64),
        'device_name' => 'Ada iPhone',
    ];

    $this->postJson('/api/v1/push-devices', $payload)
        ->assertNoContent();

    $device = PushDevice::query()
        ->where('user_id', $user->id)
        ->where('platform', 'ios')
        ->where('environment', 'sandbox')
        ->where('token', $payload['token'])
        ->firstOrFail();

    expect($device->device_name)->toBe('Ada iPhone')
        ->and($device->last_seen_at)->not->toBeNull();

    $this->deleteJson('/api/v1/push-devices', [
        'platform' => 'ios',
        'environment' => 'sandbox',
        'token' => $payload['token'],
    ])->assertNoContent();

    expect($device->fresh())->toBeNull();
});
