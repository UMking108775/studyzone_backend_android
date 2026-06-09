<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Free-trial support. A trial is just an auto-approved subscription (so it
 * reuses the whole access system), tagged with `is_trial` and stamped with the
 * device id + IP it was granted from so the same phone can't farm trials by
 * making new accounts.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('subscriptions', function (Blueprint $table) {
            $table->boolean('is_trial')->default(false)->after('status');
            $table->string('device_id')->nullable()->after('is_trial');
            $table->string('ip_address', 45)->nullable()->after('device_id');

            $table->index(['is_trial', 'device_id']);
            $table->index(['is_trial', 'ip_address']);
        });
    }

    public function down(): void
    {
        Schema::table('subscriptions', function (Blueprint $table) {
            $table->dropIndex(['is_trial', 'device_id']);
            $table->dropIndex(['is_trial', 'ip_address']);
            $table->dropColumn(['is_trial', 'device_id', 'ip_address']);
        });
    }
};
