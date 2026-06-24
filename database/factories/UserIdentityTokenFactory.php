<?php

namespace Database\Factories;

use App\Models\UserIdentity;
use App\Models\UserIdentityToken;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<UserIdentityToken>
 */
class UserIdentityTokenFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_identity_id' => UserIdentity::factory(),
            'provider_client_id' => 'com.example.Libero',
            'refresh_token' => fake()->sha256(),
        ];
    }
}
