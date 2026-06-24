<?php

namespace App\Providers;

use App\Models\User;
use Illuminate\Support\Facades\Gate;
use Laravel\Horizon\HorizonApplicationServiceProvider;
use Symfony\Component\HttpFoundation\IpUtils;

class HorizonServiceProvider extends HorizonApplicationServiceProvider
{
    /**
     * Register the Horizon gate.
     *
     * This gate determines who can access Horizon in non-local environments.
     */
    protected function gate(): void
    {
        Gate::define('viewHorizon', function (?User $user = null): bool {
            return $this->requestIsFromAllowedIp()
                || ($user !== null && in_array($user->email, config('services.libero.admin_emails', []), true));
        });
    }

    private function requestIsFromAllowedIp(): bool
    {
        $requestIp = request()->ip();

        if ($requestIp === null) {
            return false;
        }

        /** @var array<int, string> $allowedIps */
        $allowedIps = config('horizon.allowed_ips', []);

        foreach ($allowedIps as $allowedIp) {
            if (IpUtils::checkIp($requestIp, $allowedIp)) {
                return true;
            }
        }

        return false;
    }
}
