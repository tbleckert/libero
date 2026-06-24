<?php

namespace Database\Factories;

use App\Models\PushDevice;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<PushDevice>
 */
class PushDeviceFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'platform' => 'ios',
            'environment' => 'sandbox',
            'token' => fake()->regexify('[a-f0-9]{64}'),
            'device_name' => fake()->optional()->words(2, true),
            'last_seen_at' => now(),
            'revoked_at' => null,
        ];
    }
}
