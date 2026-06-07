<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Subscription extends Model
{
    protected $fillable = [
        'user_id',
        'subscription_plan_id',
        'payment_method_id',
        'status',
        'plan_name',
        'duration_days',
        'amount',
        'currency',
        'sender_name',
        'sender_account',
        'transaction_reference',
        'proof_path',
        'starts_at',
        'ends_at',
        'admin_note',
        'reviewed_at',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'duration_days' => 'integer',
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
        'reviewed_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function plan(): BelongsTo
    {
        return $this->belongsTo(SubscriptionPlan::class, 'subscription_plan_id');
    }

    public function paymentMethod(): BelongsTo
    {
        return $this->belongsTo(PaymentMethod::class);
    }

    /** Approved and still within its active window. */
    public function getIsActiveAttribute(): bool
    {
        return $this->status === 'approved'
            && $this->ends_at !== null
            && $this->ends_at->isFuture();
    }

    /** Approved subscriptions that haven't expired. */
    public function scopeActive($query)
    {
        return $query->where('status', 'approved')
            ->whereNotNull('ends_at')
            ->where('ends_at', '>', now());
    }
}
