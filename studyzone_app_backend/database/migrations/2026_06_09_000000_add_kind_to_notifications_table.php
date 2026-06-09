<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Add a semantic "kind" so the app can pick the right icon deterministically
     * instead of guessing from the title/message text (which mis-fired, e.g. a
     * support reply whose ticket subject contained "video" showed a video icon).
     *
     * Values: a content type (pdf/video/audio/quiz/doc/ppt/image/zip/link),
     * 'category', 'support', 'subscription', 'announcement', or 'custom'.
     */
    public function up(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            $table->string('kind')->nullable()->after('type');
        });
    }

    public function down(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            $table->dropColumn('kind');
        });
    }
};
