<?php

namespace App\Notifications\Channels;

use App\Models\PushDevice;
use App\Support\ApplePushNotifications;
use Illuminate\Http\Client\RequestException;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Log;

class ApplePushChannel
{
    public function __construct(private ApplePushNotifications $pushNotifications) {}

    public function send(object $notifiable, Notification $notification): void
    {
        if (! method_exists($notification, 'toApplePush')) {
            return;
        }

        $payload = $notification->toApplePush($notifiable);

        if (! is_array($payload)) {
            return;
        }

        $this->devicesFor($notifiable, $notification)
            ->each(fn (PushDevice $device) => $this->sendToDevice($device, $payload, $notification::class));
    }

    /**
     * @return Collection<int, PushDevice>
     */
    private function devicesFor(object $notifiable, Notification $notification): Collection
    {
        if (! method_exists($notifiable, 'routeNotificationFor')) {
            return collect();
        }

        $devices = $notifiable->routeNotificationFor('applePush', $notification);

        if ($devices instanceof PushDevice) {
            return collect([$devices]);
        }

        return collect($devices)
            ->filter(fn (mixed $device): bool => $device instanceof PushDevice)
            ->values();
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    private function sendToDevice(PushDevice $device, array $payload, string $notification): void
    {
        if ($device->revoked_at) {
            return;
        }

        try {
            $this->pushNotifications->send($device, $payload);
        } catch (RequestException $exception) {
            if (! $this->pushNotifications->shouldRevokeToken($exception)) {
                Log::warning('Unable to send Apple push notification.', [
                    'push_device_id' => $device->id,
                    'user_id' => $device->user_id,
                    'environment' => $device->environment,
                    'notification' => $notification,
                    'status' => $exception->response?->status(),
                    'reason' => $exception->response?->json('reason'),
                ]);

                throw $exception;
            }

            $device->update([
                'revoked_at' => now(),
            ]);

            Log::info('Revoked Apple push device token reported by APNs.', [
                'push_device_id' => $device->id,
                'user_id' => $device->user_id,
                'environment' => $device->environment,
                'notification' => $notification,
                'status' => $exception->response?->status(),
                'reason' => $exception->response?->json('reason'),
            ]);
        }
    }
}
