<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A user's subscription purchase request. The user pays via a local method and
 * submits proof; an admin verifies and approves, which sets the active window
 * (starts_at..ends_at). While approved & unexpired it unlocks all content.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('subscription_plan_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('payment_method_id')->nullable()->constrained('payment_methods')->nullOnDelete();
            $table->string('status')->default('pending'); // pending | approved | rejected

            // Snapshots so history survives plan edits/deletes.
            $table->string('plan_name')->nullable();
            $table->unsignedInteger('duration_days')->nullable();
            $table->decimal('amount', 10, 2)->default(0);
            $table->string('currency', 8)->default('PKR');

            // What the user submitted as payment proof.
            $table->string('sender_name')->nullable();
            $table->string('sender_account')->nullable();
            $table->string('transaction_reference')->nullable();
            $table->string('proof_path')->nullable();

            // Active window (set on approval).
            $table->timestamp('starts_at')->nullable();
            $table->timestamp('ends_at')->nullable();

            $table->text('admin_note')->nullable();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index(['status', 'ends_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscriptions');
    }
};
