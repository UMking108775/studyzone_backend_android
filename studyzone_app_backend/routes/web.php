<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\AuthController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\CategoryController;
use App\Http\Controllers\Admin\ContentController;
use App\Http\Controllers\Admin\ImportantLinkController;

Route::get('/', function () {
    return redirect()->route('admin.login');
});

// Admin Authentication Routes
Route::prefix('admin')->name('admin.')->group(function () {
    // Public routes (no auth required)
    Route::get('/login', [AuthController::class, 'showLoginForm'])->name('login');
    Route::post('/login', [AuthController::class, 'login'])->name('login.post');
    Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

    // Protected routes (require admin auth)
    Route::middleware(['auth', 'admin'])->group(function () {
        Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
        
        // Category routes
        Route::post('/categories/{id}/move-up', [CategoryController::class, 'moveUp'])->name('categories.move-up');
        Route::post('/categories/{id}/move-down', [CategoryController::class, 'moveDown'])->name('categories.move-down');
        Route::resource('categories', CategoryController::class);
        
        // Content routes
        Route::resource('contents', ContentController::class);
        
        // User Management routes
        Route::post('/users/bulk-category-access', [\App\Http\Controllers\Admin\UserController::class, 'bulkCategoryAccess'])->name('users.bulk-category-access');
        Route::resource('users', \App\Http\Controllers\Admin\UserController::class);
        Route::get('/users/{id}/category-access', [\App\Http\Controllers\Admin\UserController::class, 'categoryAccess'])->name('users.category-access');
        Route::put('/users/{id}/category-access', [\App\Http\Controllers\Admin\UserController::class, 'updateCategoryAccess'])->name('users.update-category-access');
        
        // Help & Support routes
        Route::resource('faqs', \App\Http\Controllers\Admin\FaqController::class);
        Route::get('/support', [\App\Http\Controllers\Admin\SupportController::class, 'index'])->name('support.index');
        Route::get('/support/{id}', [\App\Http\Controllers\Admin\SupportController::class, 'show'])->name('support.show');
        Route::put('/support/{id}', [\App\Http\Controllers\Admin\SupportController::class, 'update'])->name('support.update');
        Route::patch('/support/{id}/status', [\App\Http\Controllers\Admin\SupportController::class, 'updateStatus'])->name('support.update-status');
        
        // Notifications routes
        Route::resource('notifications', \App\Http\Controllers\Admin\NotificationController::class);
        
        // Important Links routes
        Route::resource('important-links', ImportantLinkController::class);

        // Home Banners / Slider routes
        Route::post('/banners/{id}/toggle', [\App\Http\Controllers\Admin\BannerController::class, 'toggle'])->name('banners.toggle');
        Route::resource('banners', \App\Http\Controllers\Admin\BannerController::class);

        // Subscriptions: payment methods, plans, and purchase approvals
        Route::resource('payment-methods', \App\Http\Controllers\Admin\PaymentMethodController::class)->except(['show']);
        Route::resource('subscription-plans', \App\Http\Controllers\Admin\SubscriptionPlanController::class)->except(['show']);
        Route::get('/subscriptions', [\App\Http\Controllers\Admin\SubscriptionController::class, 'index'])->name('subscriptions.index');
        // Manual assignment by admin (static paths must be declared before the {id} route)
        Route::get('/subscriptions/assign', [\App\Http\Controllers\Admin\SubscriptionController::class, 'create'])->name('subscriptions.create');
        Route::post('/subscriptions/assign', [\App\Http\Controllers\Admin\SubscriptionController::class, 'store'])->name('subscriptions.store');
        Route::get('/subscriptions/{id}', [\App\Http\Controllers\Admin\SubscriptionController::class, 'show'])->name('subscriptions.show');
        Route::post('/subscriptions/{id}/approve', [\App\Http\Controllers\Admin\SubscriptionController::class, 'approve'])->name('subscriptions.approve');
        Route::post('/subscriptions/{id}/reject', [\App\Http\Controllers\Admin\SubscriptionController::class, 'reject'])->name('subscriptions.reject');
        // Manage an existing subscription: renew, change plan, revoke, delete
        Route::post('/subscriptions/{id}/renew', [\App\Http\Controllers\Admin\SubscriptionController::class, 'renew'])->name('subscriptions.renew');
        Route::post('/subscriptions/{id}/upgrade', [\App\Http\Controllers\Admin\SubscriptionController::class, 'upgrade'])->name('subscriptions.upgrade');
        Route::post('/subscriptions/{id}/revoke', [\App\Http\Controllers\Admin\SubscriptionController::class, 'revoke'])->name('subscriptions.revoke');
        Route::delete('/subscriptions/{id}', [\App\Http\Controllers\Admin\SubscriptionController::class, 'destroy'])->name('subscriptions.destroy');

        // Admin profile (name / email / password)
        Route::get('/profile', [\App\Http\Controllers\Admin\ProfileController::class, 'edit'])->name('profile.edit');
        Route::put('/profile', [\App\Http\Controllers\Admin\ProfileController::class, 'update'])->name('profile.update');

        // App settings (download permissions, AI keys, mailer …)
        Route::get('/settings', [\App\Http\Controllers\Admin\SettingsController::class, 'index'])->name('settings.index');
        Route::put('/settings', [\App\Http\Controllers\Admin\SettingsController::class, 'update'])->name('settings.update');
        Route::post('/settings/test-mail', [\App\Http\Controllers\Admin\SettingsController::class, 'testMail'])->name('settings.test-mail');

        // Quizzes (manual CRUD + AI generation)
        Route::get('/quizzes/generate', [\App\Http\Controllers\Admin\QuizController::class, 'generateForm'])->name('quizzes.generate.form');
        Route::post('/quizzes/generate', [\App\Http\Controllers\Admin\QuizController::class, 'generate'])->name('quizzes.generate');
        Route::resource('quizzes', \App\Http\Controllers\Admin\QuizController::class)->except(['show']);

        // API Documentation
        Route::get('/api-docs', [\App\Http\Controllers\Admin\ApiController::class, 'index'])->name('api.index');
    });
});
