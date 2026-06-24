<?php

namespace App\Providers;

use App\Models\User;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        ResetPassword::createUrlUsing(function (object $notifiable, string $token): string {
            $email = $notifiable instanceof User
                ? $notifiable->getEmailForPasswordReset()
                : '';

            return rtrim((string) config('services.libero.password_reset_url'), '/')
                .'?'.http_build_query([
                    'token' => $token,
                    'email' => $email,
                ]);
        });
    }
}
