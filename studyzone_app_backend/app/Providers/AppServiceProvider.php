<?php

namespace App\Providers;

use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\View;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Pending-subscription badge for the admin sidebar (safe before migrate).
        View::composer('admin.components.sidebar', function ($view) {
            $count = 0;
            try {
                if (Schema::hasTable('subscriptions')) {
                    $count = \App\Models\Subscription::where('status', 'pending')->count();
                }
            } catch (\Throwable $e) {
                $count = 0;
            }
            $view->with('subscriptionPending', $count);
        });
    }
}
