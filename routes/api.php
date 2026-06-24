<?php

use App\Http\Controllers\Api\AppleAuthController;
use App\Http\Controllers\Api\AuthTokenController;
use App\Http\Controllers\Api\EmailVerificationController;
use App\Http\Controllers\Api\PasswordResetController;
use App\Http\Controllers\Api\PushDeviceController;
use App\Http\Controllers\Api\RegisteredUserController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::get('/health', fn (): array => [
        'status' => 'ok',
    ])->name('api.v1.health');

    Route::get('/auth/email/verify/{id}/{hash}', [EmailVerificationController::class, 'verify'])
        ->middleware(['signed', 'throttle:6,1'])
        ->name('verification.verify');

    Route::name('api.v1.')->group(function (): void {
        Route::post('/auth/tokens', [AuthTokenController::class, 'store'])
            ->middleware('throttle:5,1')
            ->name('auth.tokens.store');

        Route::post('/auth/apple', [AppleAuthController::class, 'store'])
            ->middleware('throttle:5,1')
            ->name('auth.apple.store');

        Route::post('/auth/register', [RegisteredUserController::class, 'store'])
            ->middleware('throttle:5,1')
            ->name('auth.register');

        Route::post('/auth/forgot-password', [PasswordResetController::class, 'forgot'])
            ->middleware('throttle:5,1')
            ->name('auth.password.forgot');

        Route::post('/auth/reset-password', [PasswordResetController::class, 'reset'])
            ->middleware('throttle:5,1')
            ->name('auth.password.reset');

        Route::middleware('auth:sanctum')->group(function (): void {
            Route::delete('/auth/tokens/current', [AuthTokenController::class, 'destroy'])
                ->name('auth.tokens.current.destroy');

            Route::post('/auth/email/verification-notification', [EmailVerificationController::class, 'resend'])
                ->middleware('throttle:6,1')
                ->name('auth.email.verification-notification');

            Route::get('/user', [UserController::class, 'show'])
                ->name('user');

            Route::patch('/user', [UserController::class, 'update'])
                ->name('user.update');

            Route::put('/user/password', [UserController::class, 'updatePassword'])
                ->name('user.password.update');

            Route::post('/push-devices', [PushDeviceController::class, 'store'])
                ->name('push-devices.store');

            Route::delete('/push-devices', [PushDeviceController::class, 'destroy'])
                ->name('push-devices.destroy');
        });
    });
});
