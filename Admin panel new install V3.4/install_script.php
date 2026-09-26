<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

\App\Models\User::create([
    'id' => \Ramsey\Uuid\Uuid::uuid4(),
    'first_name' => 'Admin',
    'last_name' => 'User',
    'email' => 'admin@admin.com',
    'user_type' => 'super-admin',
    'password' => bcrypt('12345678'),
    'phone' => '1234567890',
    'is_active' => 1,
    'created_at' => now(),
    'updated_at' => now()
]);

$previousRouteServiceProvier = base_path('app/Providers/RouteServiceProvider.php');
$newRouteServiceProvier = base_path('app/Providers/RouteServiceProvider.txt');
copy($newRouteServiceProvier, $previousRouteServiceProvier);

$modules = ['Auth', 'UserManagement', 'ZoneManagement', 'CategoryManagement', 'PromotionManagement', 'ServiceManagement', 'ProviderManagement', 'PaymentModule', 'BusinessSettingsModule', 'BookingModule', 'SMSModule', 'TransactionModule', 'ReviewModule', 'CartModule', 'AdminModule', 'CustomerModule', 'ServicemanModule', 'ChattingModule', 'BidModule', 'AddonModule', 'AI'];
foreach ($modules as $module) {
    \Illuminate\Support\Facades\Artisan::call('module:enable', ['module' => $module]);
}
echo 'Done';
