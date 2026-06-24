<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\DestroyPushDeviceRequest;
use App\Http\Requests\Api\StorePushDeviceRequest;
use App\Models\PushDevice;
use Illuminate\Http\Response;

class PushDeviceController extends Controller
{
    public function store(StorePushDeviceRequest $request): Response
    {
        $validated = $request->validated();

        PushDevice::query()->updateOrCreate(
            [
                'platform' => $validated['platform'],
                'environment' => $validated['environment'],
                'token' => $validated['token'],
            ],
            [
                'user_id' => $request->user()->id,
                'device_name' => $validated['device_name'] ?? null,
                'last_seen_at' => now(),
                'revoked_at' => null,
            ]
        );

        return response()->noContent();
    }

    public function destroy(DestroyPushDeviceRequest $request): Response
    {
        $validated = $request->validated();

        PushDevice::query()
            ->where('user_id', $request->user()->id)
            ->where('platform', $validated['platform'])
            ->where('environment', $validated['environment'])
            ->where('token', $validated['token'])
            ->delete();

        return response()->noContent();
    }
}
