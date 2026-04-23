<?php
header('Content-Type: application/json');

$health = [
    'status' => 'healthy',
    'timestamp' => date('c'),
    'php_version' => phpversion(),
    'hostname' => gethostname(),
    'uptime' => shell_exec('uptime -p') ?: 'N/A'
];

http_response_code(200);
echo json_encode($health, JSON_PRETTY_PRINT);// This line was added live
