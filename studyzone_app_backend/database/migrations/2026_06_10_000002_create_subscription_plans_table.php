<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Subscription plans the admin defines (name, any duration, price, features).
 * An active subscription unlocks ALL locked content for the user.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscription_plans', function (Blueprint $table) {
            $table->id();
            $table->string('name');                          // e.g. "Monthly", "3 Months"
            $table->text('description')->nullable();
            $table->unsignedInteger('duration_days');        // any duration, in days
            $table->decimal('price', 10, 2)->default(0);
            $table->string('currency', 8)->default('PKR');
            $table->json('features')->nullable();            // array of feature strings
            $table->boolean('is_active')->default(true);
            $table->integer('sort_order')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscription_plans');
    }
};
