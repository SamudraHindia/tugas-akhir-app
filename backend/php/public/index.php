<?php

declare(strict_types=1);

require __DIR__ . '/../src/api.php';

$allowedOrigin = getenv('CORS_ALLOW_ORIGIN') ?: '*';
header('Access-Control-Allow-Origin: ' . $allowedOrigin);
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Authorization, X-Requested-With');
header('Access-Control-Max-Age: 86400');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

try {
    route_request();
} catch (InvalidArgumentException $exception) {
    json_response(['error' => $exception->getMessage()], 400);
} catch (Throwable $exception) {
    error_log((string) $exception);
    json_response([
        'error' => 'Terjadi kesalahan pada server. Silakan coba lagi.',
    ], 500);
}
