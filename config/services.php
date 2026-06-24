<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'apple' => [
        'team_id' => env('APPLE_TEAM_ID'),
        'key_id' => env('APPLE_KEY_ID'),
        'private_key_base64' => env('APPLE_PRIVATE_KEY_BASE64'),
        'client_ids' => [
            'ios' => env('APPLE_IOS_CLIENT_ID'),
            'web' => env('APPLE_WEB_CLIENT_ID'),
        ],
    ],

    'apns' => [
        'team_id' => env('APNS_TEAM_ID') ?: env('APPLE_TEAM_ID'),
        'key_id' => env('APNS_KEY_ID'),
        'private_key_base64' => env('APNS_PRIVATE_KEY_BASE64'),
        'bundle_id' => env('APNS_BUNDLE_ID', env('APPLE_IOS_CLIENT_ID', 'com.example.Libero')),
        'sandbox_url' => env('APNS_SANDBOX_URL', 'https://api.sandbox.push.apple.com'),
        'production_url' => env('APNS_PRODUCTION_URL', 'https://api.push.apple.com'),
    ],

    'libero' => [
        'admin_emails' => array_values(array_filter(array_map('trim', explode(',', env('LIBERO_ADMIN_EMAILS', ''))))),
        'email_verified_url' => env('LIBERO_EMAIL_VERIFIED_URL', env('APP_URL', 'http://localhost')),
        'password_reset_url' => env('LIBERO_PASSWORD_RESET_URL', rtrim(env('APP_URL', 'http://localhost'), '/').'/reset-password'),
        'web_url' => env('LIBERO_WEB_URL', env('APP_URL', 'http://localhost')),
    ],

];
