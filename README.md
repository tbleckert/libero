# Libero for Laravel

Libero for Laravel is a small backend starter kit for native apps. It starts with iOS and gives you a Laravel API with email-verified users, Sign in with Apple, Sanctum API tokens, Filament admin, APNs push notifications, versioned endpoints, and Horizon queues.

## Getting Started

```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
npm install
npm run build
```

Run the app and queue worker:

```bash
php artisan serve
php artisan horizon
```

Create an admin user for Filament:

```bash
php artisan make:filament-user
```

The admin panel is available at `/admin`. The API starts at `/api/v1`.

## Main Endpoints

- `GET /api/v1/health`
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/tokens`
- `POST /api/v1/auth/apple`
- `POST /api/v1/auth/forgot-password`
- `POST /api/v1/auth/reset-password`
- `GET /api/v1/user`
- `PATCH /api/v1/user`
- `PUT /api/v1/user/password`
- `POST /api/v1/push-devices`
- `DELETE /api/v1/push-devices`

Authenticated requests use a Sanctum bearer token:

```http
Authorization: Bearer <token>
```

## Apple Setup

In Apple Developer, create or select an explicit App ID for your iOS app. Enable **Sign in with Apple** and **Push Notifications** for that App ID.

Set these values in `.env`:

```env
APPLE_TEAM_ID=
APPLE_IOS_CLIENT_ID=com.example.App
APPLE_KEY_ID=
APPLE_PRIVATE_KEY_BASE64=

APNS_TEAM_ID="${APPLE_TEAM_ID}"
APNS_KEY_ID=
APNS_PRIVATE_KEY_BASE64=
APNS_BUNDLE_ID="${APPLE_IOS_CLIENT_ID}"

LIBERO_ADMIN_EMAILS=admin@example.com
LIBERO_EMAIL_VERIFIED_URL=https://example.com/email-verified
LIBERO_PASSWORD_RESET_URL=https://example.com/reset-password
```

### Sign in with Apple

1. Create an explicit App ID with your app bundle ID, for example `com.example.App`.
2. Enable **Sign in with Apple** on that App ID.
3. Create a **Sign in with Apple** private key.
4. Copy the key ID into `APPLE_KEY_ID`.
5. Base64 encode the downloaded `.p8` key into `APPLE_PRIVATE_KEY_BASE64`:

```bash
base64 < AuthKey_XXXXXXXXXX.p8 | tr -d '\n'
```

For native iOS, `APPLE_IOS_CLIENT_ID` is your app bundle ID. If you later add web Sign in with Apple, create a Services ID and put it in `APPLE_WEB_CLIENT_ID`.

### Push Notifications

1. Enable **Push Notifications** on the same App ID.
2. Create an APNs auth key.
3. Copy the APNs key ID into `APNS_KEY_ID`.
4. Base64 encode the downloaded `.p8` key into `APNS_PRIVATE_KEY_BASE64`.
5. Set `APNS_BUNDLE_ID` to the app bundle ID that receives notifications.

Never commit `.env` or `.p8` files.

## Queues

Horizon requires Redis. Use `QUEUE_CONNECTION=redis` for normal development and production.

```bash
php artisan horizon
```

## Testing

```bash
php artisan test
```

## Apple References

- [Register an App ID](https://developer.apple.com/help/account/identifiers/register-an-app-id)
- [Enable app capabilities](https://developer.apple.com/help/account/identifiers/enable-app-capabilities)
- [Create a Sign in with Apple private key](https://developer.apple.com/help/account/capabilities/create-a-sign-in-with-apple-private-key)
- [Configure Sign in with Apple for the web](https://developer.apple.com/help/account/capabilities/configure-sign-in-with-apple-for-the-web)
- [Communicate with APNs using authentication tokens](https://developer.apple.com/help/account/capabilities/communicate-with-apns-using-authentication-tokens)
