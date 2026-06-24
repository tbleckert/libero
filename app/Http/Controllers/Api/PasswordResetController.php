<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\ForgotPasswordRequest;
use App\Http\Requests\Api\ResetPasswordRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class PasswordResetController extends Controller
{
    public function forgot(ForgotPasswordRequest $request): Response
    {
        $status = Password::sendResetLink($request->safe()->only('email'));

        if ($status === Password::ResetLinkSent || $status === Password::InvalidUser) {
            return response()->noContent();
        }

        throw ValidationException::withMessages([
            'email' => [__($status)],
        ]);
    }

    public function reset(ResetPasswordRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $resetUser = null;

        $status = Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function (User $user, string $password) use (&$resetUser): void {
                $user->forceFill([
                    'password' => $password,
                    'remember_token' => Str::random(60),
                ])->save();

                $user->tokens()->delete();

                event(new PasswordReset($user));

                $resetUser = $user;
            }
        );

        if ($status !== Password::PasswordReset || ! $resetUser) {
            throw ValidationException::withMessages([
                'email' => [__($status)],
            ]);
        }

        $token = $resetUser->createToken($validated['device_name']);

        return response()->json([
            'data' => [
                'token' => $token->plainTextToken,
                'user' => UserResource::make($resetUser)->resolve($request),
            ],
        ]);
    }
}
