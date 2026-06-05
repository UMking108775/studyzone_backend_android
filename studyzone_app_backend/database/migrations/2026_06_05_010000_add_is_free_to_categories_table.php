<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Adds a free/paid flag to categories. Free categories are open to all
     * registered users automatically; paid categories stay locked until an
     * admin grants the user access. New categories default to paid (false).
     */
    public function up(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->boolean('is_free')->default(false)->after('level');
        });
    }

    public function down(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->dropColumn('is_free');
        });
    }
};
