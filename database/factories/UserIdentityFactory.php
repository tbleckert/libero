<?php

namespace Database\Factories;

use App\Models\UserIdentity;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<UserIdentity>
 */
class UserIdentityFactory extends Factory
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
            'provider' => UserIdentity::ProviderApple,
            'provider_user_id' => fake()->uuid(),
            'email' => fake()->safeEmail(),
            'email_verified_at' => now(),
        ];
    }
}
