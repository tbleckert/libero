<?php

test('the foundation stack is configured', function () {
    expect(config('scout.driver'))->toBe('meilisearch')
        ->and(config('scout.queue'))->toBeTrue()
        ->and(config('ai.default'))->toBe('openai')
        ->and(config('ai.default_for_images'))->toBe('openai')
        ->and(config('broadcasting.default'))->toBeNull()
        ->and(config('broadcasting.connections.reverb.driver'))->toBe('reverb')
        ->and(config('reverb.default'))->toBe('reverb');
});
