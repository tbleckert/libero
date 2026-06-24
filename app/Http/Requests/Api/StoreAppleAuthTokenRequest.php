<?php

namespace App\Http\Requests\Api;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;

class StoreAppleAuthTokenRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'identity_token' => ['required', 'string'],
            'authorization_code' => ['nullable', 'string', 'max:4096'],
            'device_name' => ['required', 'string', 'max:255'],
            'name' => ['nullable', 'string', 'max:255'],
            'nonce' => ['nullable', 'string', 'max:255'],
        ];
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'authorization_code' => trim((string) $this->input('authorization_code')) ?: null,
            'device_name' => trim((string) $this->input('device_name')),
            'name' => Str::squish((string) $this->input('name')) ?: null,
            'nonce' => trim((string) $this->input('nonce')) ?: null,
        ]);
    }
}
