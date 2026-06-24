<?php

namespace App\Http\Requests\Api;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StorePushDeviceRequest extends FormRequest
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
            'platform' => ['required', 'string', Rule::in(['ios'])],
            'environment' => ['required', 'string', Rule::in(['sandbox', 'production'])],
            'token' => ['required', 'string', 'min:32', 'max:255'],
            'device_name' => ['nullable', 'string', 'max:255'],
        ];
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'platform' => mb_strtolower(trim((string) $this->input('platform'))),
            'environment' => mb_strtolower(trim((string) $this->input('environment'))),
            'token' => trim((string) $this->input('token')),
            'device_name' => $this->filled('device_name')
                ? trim((string) $this->input('device_name'))
                : null,
        ]);
    }
}
