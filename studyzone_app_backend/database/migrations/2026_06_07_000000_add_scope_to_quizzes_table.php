<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Adds a "scope" to quizzes:
 *  - 'program' (default): a program/degree quiz shown in "Test your knowledge".
 *  - 'lesson':  a lesson-specific quiz shown INSIDE its category as content.
 * Existing quizzes default to 'program' so nothing changes for them.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('quizzes', function (Blueprint $table) {
            $table->string('scope')->default('program')->after('category_id');
        });
    }

    public function down(): void
    {
        Schema::table('quizzes', function (Blueprint $table) {
            $table->dropColumn('scope');
        });
    }
};
