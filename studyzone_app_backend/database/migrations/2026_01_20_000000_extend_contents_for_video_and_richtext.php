<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Adds support for new content types (video, rich_text). The media URL is
     * no longer required (rich text has no file), and a `body` column stores
     * rich-text/HTML content (e.g. admission & fee structure pages).
     */
    public function up(): void
    {
        Schema::table('contents', function (Blueprint $table) {
            // enum -> string so any content type can be added
            $table->string('content_type')->default('pdf')->change();
            // URL optional (rich text has no file)
            $table->string('backblaze_url')->nullable()->change();
            // Rich-text / HTML body
            $table->longText('body')->nullable()->after('backblaze_url');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('contents', function (Blueprint $table) {
            $table->dropColumn('body');
            $table->string('backblaze_url')->nullable(false)->change();
            $table->enum('content_type', ['pdf', 'audio'])->default('pdf')->change();
        });
    }
};
