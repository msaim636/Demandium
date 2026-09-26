<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

copy(base_path('app/Providers/RouteServiceProvider.txt'), base_path('app/Providers/RouteServiceProvider.php'));

$modules = ['Auth', 'UserManagement', 'ZoneManagement', 'CategoryManagement', 'PromotionManagement', 'ServiceManagement', 'ProviderManagement', 'PaymentModule', 'BusinessSettingsModule', 'BookingModule', 'SMSModule', 'TransactionModule', 'ReviewModule', 'CartModule', 'AdminModule', 'CustomerModule', 'ServicemanModule', 'ChattingModule', 'BidModule', 'AddonModule', 'AI'];
foreach ($modules as $module) {
    \Illuminate\Support\Facades\Artisan::call('module:enable', ['module' => $module]);
    echo "Enabled $module\n";
}
echo 'Done';
