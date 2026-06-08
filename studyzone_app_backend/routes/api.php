<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Mobile App API Routes - Version 1
| Base URL: /api/v1
|
*/

// API Version 1
Route::prefix('v1')->group(function () {
    
    // Public Routes (No Authentication Required)
    Route::prefix('auth')->group(function () {
        // Sensitive / email-sending actions — kept tight.
        Route::middleware('throttle:5,1')->group(function () {
            Route::post('/register', [AuthController::class, 'register'])->name('api.register');
            Route::post('/login', [AuthController::class, 'login'])->name('api.login');
            Route::post('/forgot-password', [\App\Http\Controllers\Api\PasswordResetController::class, 'forgotPassword'])->name('api.forgot-password');
        });
        // OTP verify / reset — more permissive (auto-submit may retry), but the
        // per-OTP attempt cap in the controller is the real brute-force guard.
        Route::middleware('throttle:20,1')->group(function () {
            Route::post('/verify-otp', [\App\Http\Controllers\Api\PasswordResetController::class, 'verifyOtp'])->name('api.verify-otp');
            Route::post('/reset-password', [\App\Http\Controllers\Api\PasswordResetController::class, 'resetPassword'])->name('api.reset-password');
        });
    });

    // Categories (Publicly accessible for guest mode)
    Route::prefix('categories')->group(function () {
        Route::get('/', [\App\Http\Controllers\Api\CategoryController::class, 'index'])->name('api.categories.index');
        Route::get('/tree', [\App\Http\Controllers\Api\CategoryController::class, 'tree'])->name('api.categories.tree');
        Route::get('/{id}', [\App\Http\Controllers\Api\CategoryController::class, 'show'])->name('api.categories.show');
        Route::get('/{parentId}/subcategories', [\App\Http\Controllers\Api\CategoryController::class, 'subcategories'])->name('api.categories.subcategories');
    });
    
    // Contents/Materials (Publicly accessible for guest mode)
    Route::prefix('contents')->group(function () {
        Route::get('/', [\App\Http\Controllers\Api\ContentController::class, 'all'])->name('api.contents.all');
        Route::get('/search', [\App\Http\Controllers\Api\ContentController::class, 'search'])->name('api.contents.search');
        Route::get('/type/{type}', [\App\Http\Controllers\Api\ContentController::class, 'byType'])->name('api.contents.by-type');
        Route::get('/{id}', [\App\Http\Controllers\Api\ContentController::class, 'show'])->name('api.contents.show');
    });

    // Get contents by category (works for all 3 levels)
    Route::get('/categories/{categoryId}/contents', [\App\Http\Controllers\Api\ContentController::class, 'index'])->name('api.categories.contents');
    
    // Important Links (Publicly accessible)
    Route::get('/important-links', [\App\Http\Controllers\Api\ImportantLinkController::class, 'index'])->name('api.important-links.index');

    // Home banners (Publicly accessible)
    Route::get('/banners', [\App\Http\Controllers\Api\BannerController::class, 'index'])->name('api.banners.index');

    // App settings (Publicly accessible) — e.g. download permissions
    Route::get('/app-settings', [\App\Http\Controllers\Api\SettingsController::class, 'index'])->name('api.app-settings');

    // Subscription plans (Publicly accessible so users can see pricing)
    Route::get('/subscription-plans', [\App\Http\Controllers\Api\SubscriptionController::class, 'plans'])->name('api.subscription-plans');

    // Protected Routes (Require Authentication)
    Route::middleware(['auth:sanctum', 'throttle:60,1'])->group(function () {
        
        // Authentication & User Profile
        Route::prefix('auth')->group(function () {
            Route::post('/logout', [AuthController::class, 'logout'])->name('api.logout');
            Route::post('/logout-all', [AuthController::class, 'logoutAll'])->name('api.logout-all');
            Route::post('/refresh-token', [AuthController::class, 'refreshToken'])->name('api.refresh-token');
            Route::get('/user', [AuthController::class, 'user'])->name('api.user');
            Route::post('/update-profile', [AuthController::class, 'updateProfile'])->name('api.update-profile');
        });
        
        // Help & Support
        Route::prefix('support')->group(function () {
            Route::get('/faqs', [\App\Http\Controllers\Api\SupportController::class, 'faqs'])->name('api.support.faqs');
            Route::post('/submit', [\App\Http\Controllers\Api\SupportController::class, 'submit'])->name('api.support.submit');
            Route::get('/tickets', [\App\Http\Controllers\Api\SupportController::class, 'myTickets'])->name('api.support.tickets');
            Route::get('/tickets/{id}', [\App\Http\Controllers\Api\SupportController::class, 'show'])->name('api.support.show');
        });
        
        // Notifications
        Route::prefix('notifications')->group(function () {
            Route::get('/', [\App\Http\Controllers\Api\NotificationController::class, 'index'])->name('api.notifications.index');
            Route::get('/count', [\App\Http\Controllers\Api\NotificationController::class, 'count'])->name('api.notifications.count');
            Route::post('/mark-all-read', [\App\Http\Controllers\Api\NotificationController::class, 'markAllAsRead'])->name('api.notifications.mark-all-read');
            Route::post('/{id}/mark-read', [\App\Http\Controllers\Api\NotificationController::class, 'markAsRead'])->name('api.notifications.mark-read');
            Route::get('/{id}', [\App\Http\Controllers\Api\NotificationController::class, 'show'])->name('api.notifications.show');
        });

        // Device tokens for real-time push (FCM)
        Route::post('/device-token', [\App\Http\Controllers\Api\DeviceTokenController::class, 'store'])->name('api.device-token.store');
        Route::delete('/device-token', [\App\Http\Controllers\Api\DeviceTokenController::class, 'destroy'])->name('api.device-token.destroy');

        // Subscriptions (local-payment): pay-to options, submit proof, my status
        Route::get('/payment-methods', [\App\Http\Controllers\Api\SubscriptionController::class, 'paymentMethods'])->name('api.payment-methods');
        Route::post('/subscriptions', [\App\Http\Controllers\Api\SubscriptionController::class, 'store'])->name('api.subscriptions.store');
        Route::get('/subscriptions/me', [\App\Http\Controllers\Api\SubscriptionController::class, 'mine'])->name('api.subscriptions.me');

        // Quizzes & Flashcards
        Route::get('/quiz-stats', [\App\Http\Controllers\Api\QuizController::class, 'stats'])->name('api.quizzes.stats');
        Route::get('/achievements', [\App\Http\Controllers\Api\QuizController::class, 'achievements'])->name('api.achievements');
        Route::prefix('quizzes')->group(function () {
            Route::get('/', [\App\Http\Controllers\Api\QuizController::class, 'index'])->name('api.quizzes.index');
            Route::get('/{id}', [\App\Http\Controllers\Api\QuizController::class, 'show'])->name('api.quizzes.show');
            Route::post('/{id}/attempts', [\App\Http\Controllers\Api\QuizController::class, 'attempt'])->name('api.quizzes.attempt');
        });
    });
});

// API Health Check
Route::get('/health', function () {
    return response()->json([
        'success' => true,
        'message' => 'API is running',
        'version' => 'v1',
        'timestamp' => now()->toIso8601String(),
    ]);
})->name('api.health');

