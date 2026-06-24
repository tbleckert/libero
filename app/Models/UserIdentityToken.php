<?php

namespace App\Models;

use Database\Factories\UserIdentityTokenFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['provider_client_id', 'refresh_token'])]
#[Hidden(['refresh_token'])]
class UserIdentityToken extends Model
{
    /** @use HasFactory<UserIdentityTokenFactory> */
    use HasFactory;

    public function identity(): BelongsTo
    {
        return $this->belongsTo(UserIdentity::class, 'user_identity_id');
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'refresh_token' => 'encrypted',
        ];
    }
}
