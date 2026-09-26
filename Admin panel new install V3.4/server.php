<?php

/**
 * Laravel - A PHP Framework For Web Artisans
 *
 * @package  Laravel
 * @author   Taylor Otwell <taylor@laravel.com>
 */

$uri = urldecode(
    parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH)
);

// This file allows us to emulate Apache's "mod_rewrite" functionality from the
// built-in PHP web server. This provides a convenient way to test a Laravel
// application without having installed a "real" web server software here.
$publicUri = $uri;
if (strpos($uri, '/public/') === 0) {
    $publicUri = substr($uri, 7); // leaves /assets/...
}

if ($publicUri !== '/' && file_exists(__DIR__.'/public'.$publicUri)) {
    $filePath = __DIR__.'/public'.$publicUri;
    
    // Check if it's a file (could be via a symlink like storage)
    if (is_file($filePath)) {
        $mime = mime_content_type($filePath) ?: 'text/plain';
        
        $ext = pathinfo($filePath, PATHINFO_EXTENSION);
        if ($ext === 'css') $mime = 'text/css';
        if ($ext === 'js') $mime = 'application/javascript';
        if ($ext === 'svg') $mime = 'image/svg+xml';
        if ($ext === 'png') $mime = 'image/png';
        if ($ext === 'jpg' || $ext === 'jpeg') $mime = 'image/jpeg';
        if ($ext === 'gif') $mime = 'image/gif';
        if ($ext === 'webp') $mime = 'image/webp';
        
        header("Content-Type: $mime");
        readfile($filePath);
        exit;
    }
    
    return false;
}

require_once __DIR__.'/public/index.php';
