<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PaymentMethod;
use App\Models\Subscription;
use App\Models\SubscriptionPlan;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;

class SubscriptionController extends Controller
{
    use ApiResponse;

    /** Public: active subscription plans. */
    public function plans()
    {
        $plans = SubscriptionPlan::active()
            ->orderBy('sort_order')->orderBy('id')->get()
            ->map(fn ($p) => [
                'id' => $p->id,
                'name' => $p->name,
                'description' => $p->description,
                'duration_days' => $p->duration_days,
                'price' => (float) $p->price,
                'currency' => $p->currency,
                'features' => $p->features ?? [],
            ]);

        return $this->successResponse($plans, 'Plans retrieved successfully');
    }

    /** Auth: payment methods the user can pay to. */
    public function paymentMethods()
    {
        $methods = PaymentMethod::active()
            ->orderBy('sort_order')->orderBy('id')->get()
            ->map(fn ($m) => [
                'id' => $m->id,
                'name' => $m->name,
                'type' => $m->type,
                'account_title' => $m->account_title,
                'account_number' => $m->account_number,
                'instructions' => $m->instructions,
            ]);

        return $this->successResponse($methods, 'Payment methods retrieved successfully');
    }

    /** Auth: submit a subscription purchase request with proof. */
    public function store(Request $request)
    {
        $request->validate([
            'subscription_plan_id' => 'required|exists:subscription_plans,id',
            'payment_method_id' => 'nullable|exists:payment_methods,id',
            'sender_name' => 'nullable|string|max:255',
            'sender_account' => 'nullable|string|max:255',
            'transaction_reference' => 'nullable|string|max:255',
            'proof' => 'nullable|image|mimes:jpeg,jpg,png,webp|max:6144',
        ]);

        $user = $request->user();

        // One pending request at a time.
        if ($user->subscriptions()->where('status', 'pending')->exists()) {
            return $this->errorResponse(
                'You already have a pending subscription request awaiting approval.',
                null,
                422
            );
        }

        $plan = SubscriptionPlan::active()->find($request->subscription_plan_id);
        if (!$plan) {
            return $this->errorResponse('That plan is not available.', null, 422);
        }

        $proofPath = null;
        if ($request->hasFile('proof')) {
            $proofPath = $request->file('proof')->store('subscription-proofs', 'public');
        }

        $subscription = Subscription::create([
            'user_id' => $user->id,
            'subscription_plan_id' => $plan->id,
            'payment_method_id' => $request->payment_method_id,
            'status' => 'pending',
            'plan_name' => $plan->name,
            'duration_days' => $plan->duration_days,
            'amount' => $plan->price,
            'currency' => $plan->currency,
            'sender_name' => $request->sender_name,
            'sender_account' => $request->sender_account,
            'transaction_reference' => $request->transaction_reference,
            'proof_path' => $proofPath,
        ]);

        return $this->successResponse(
            $this->serialize($subscription),
            'Request submitted. We will verify your payment and activate your subscription shortly.',
            201
        );
    }

    /** Auth: the user's subscription status (active + pending + history). */
    public function mine(Request $request)
    {
        $user = $request->user();

        $active = $user->activeSubscription();
        $pending = $user->subscriptions()->where('status', 'pending')->latest()->first();
        $history = $user->subscriptions()->latest()->limit(10)->get()
            ->map(fn ($s) => $this->serialize($s));

        return $this->successResponse([
            'has_active_subscription' => $active !== null,
            'active' => $active ? $this->serialize($active) : null,
            'pending' => $pending ? $this->serialize($pending) : null,
            'history' => $history,
        ], 'Subscription status retrieved successfully');
    }

    private function serialize(Subscription $s): array
    {
        return [
            'id' => $s->id,
            'plan_name' => $s->plan_name,
            'status' => $s->status,
            'is_trial' => (bool) $s->is_trial,
            'amount' => (float) $s->amount,
            'currency' => $s->currency,
            'duration_days' => $s->duration_days,
            'starts_at' => optional($s->starts_at)->toIso8601String(),
            'ends_at' => optional($s->ends_at)->toIso8601String(),
            'admin_note' => $s->admin_note,
            'created_at' => optional($s->created_at)->toIso8601String(),
        ];
    }
}
