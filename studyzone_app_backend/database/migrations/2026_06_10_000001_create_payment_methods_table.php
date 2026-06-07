<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Local payment methods the admin offers (bank account, EasyPaisa, JazzCash …)
 * that users send money to, then submit proof for a subscription.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payment_methods', function (Blueprint $table) {
            $table->id();
            $table->string('name');                       // e.g. "EasyPaisa", "HBL Bank"
            $table->string('type')->default('bank');      // bank | easypaisa | jazzcash | other
            $table->string('account_title')->nullable();  // account holder name
            $table->string('account_number')->nullable(); // IBAN / number / mobile no.
            $table->text('instructions')->nullable();     // extra notes for the user
            $table->boolean('is_active')->default(true);
            $table->integer('sort_order')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_methods');
    }
};
