<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\RegisterUserRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;

class RegisteredUserController extends Controller
{
    public function store(RegisterUserRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $user = User::query()->create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => $validated['password'],
        ]);

        $user->sendEmailVerificationNotification();

        $token = $user->createToken($validated['device_name']);

        return response()->json([
            'data' => [
                'token' => $token->plainTextToken,
                'user' => UserResource::make($user)->resolve($request),
            ],
        ], 201);
    }
}
