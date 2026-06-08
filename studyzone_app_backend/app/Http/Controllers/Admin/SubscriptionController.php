<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Subscription;
use App\Models\SubscriptionPlan;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class SubscriptionController extends Controller
{
    public function index(Request $request)
    {
        $query = Subscription::with(['user', 'plan', 'paymentMethod'])->latest();

        if ($request->filled('status') && in_array($request->status, ['pending', 'approved', 'rejected'], true)) {
            $query->where('status', $request->status);
        }
        if ($request->filled('search')) {
            $s = trim($request->search);
            $query->whereHas('user', function ($q) use ($s) {
                $q->where('name', 'like', "%$s%")->orWhere('email', 'like', "%$s%");
            });
        }

        $subscriptions = $query->paginate(20)->withQueryString();
        $pendingSubscriptions = Subscription::where('status', 'pending')->count();

        return view('admin.subscriptions.index', compact('subscriptions', 'pendingSubscriptions'));
    }

    /** Show the manual "assign a plan to a user" form. */
    public function create(Request $request)
    {
        $users = User::orderBy('name')->get(['id', 'name', 'email']);
        $plans = SubscriptionPlan::where('is_active', true)->orderBy('sort_order')->get();
        $selectedUserId = $request->query('user');

        return view('admin.subscriptions.create', compact('users', 'plans', 'selectedUserId'));
    }

    /** Store a manually-assigned subscription (activated immediately, no payment proof). */
    public function store(Request $request)
    {
        $data = $request->validate([
            'user_id' => ['required', 'exists:users,id'],
            'subscription_plan_id' => ['required', 'exists:subscription_plans,id'],
            'starts_at' => ['nullable', 'date'],
            'duration_days' => ['nullable', 'integer', 'min:1', 'max:3650'],
            'amount' => ['nullable', 'numeric', 'min:0'],
            'admin_note' => ['nullable', 'string', 'max:1000'],
        ]);

        $plan = SubscriptionPlan::findOrFail($data['subscription_plan_id']);
        $days = $data['duration_days'] ?? $plan->duration_days ?? 30;
        $start = !empty($data['starts_at']) ? Carbon::parse($data['starts_at']) : now();

        $subscription = Subscription::create([
            'user_id' => $data['user_id'],
            'subscription_plan_id' => $plan->id,
            'payment_method_id' => null,
            'status' => 'approved',
            'plan_name' => $plan->name,
            'duration_days' => $days,
            'amount' => $data['amount'] ?? $plan->price,
            'currency' => $plan->currency,
            'starts_at' => $start,
            'ends_at' => $start->copy()->addDays($days),
            'admin_note' => $data['admin_note'] ?? 'Manually assigned by admin.',
            'reviewed_at' => now(),
        ]);

        return redirect()->route('admin.subscriptions.show', $subscription->id)
            ->with('success', 'Plan assigned. ' . ($subscription->user->name ?? 'The user') . ' now has full access until ' . $subscription->ends_at->format('M d, Y') . '.');
    }

    public function show(string $id)
    {
        $subscription = Subscription::with(['user', 'plan', 'paymentMethod'])->findOrFail($id);
        $plans = SubscriptionPlan::where('is_active', true)->orderBy('sort_order')->get();

        return view('admin.subscriptions.show', compact('subscription', 'plans'));
    }

    /** Approve a request → activate the subscription window. */
    public function approve(Request $request, string $id)
    {
        $subscription = Subscription::findOrFail($id);

        $days = $subscription->duration_days
            ?? optional($subscription->plan)->duration_days
            ?? 30;

        $subscription->update([
            'status' => 'approved',
            'starts_at' => now(),
            'ends_at' => now()->addDays($days),
            'admin_note' => $request->input('admin_note'),
            'reviewed_at' => now(),
        ]);

        return redirect()->route('admin.subscriptions.show', $subscription->id)
            ->with('success', 'Subscription approved. The user now has full access until ' . $subscription->ends_at->format('M d, Y') . '.');
    }

    /** Reject a request. */
    public function reject(Request $request, string $id)
    {
        $subscription = Subscription::findOrFail($id);

        $subscription->update([
            'status' => 'rejected',
            'admin_note' => $request->input('admin_note'),
            'reviewed_at' => now(),
        ]);

        return redirect()->route('admin.subscriptions.show', $subscription->id)
            ->with('success', 'Subscription request rejected.');
    }

    /** Renew / extend an existing subscription window. */
    public function renew(Request $request, string $id)
    {
        $subscription = Subscription::findOrFail($id);

        $data = $request->validate([
            'duration_days' => ['nullable', 'integer', 'min:1', 'max:3650'],
            'admin_note' => ['nullable', 'string', 'max:1000'],
        ]);

        $days = $data['duration_days']
            ?? $subscription->duration_days
            ?? optional($subscription->plan)->duration_days
            ?? 30;

        // Extend from the current end date if still active, otherwise start fresh from today.
        $base = ($subscription->ends_at && $subscription->ends_at->isFuture())
            ? $subscription->ends_at->copy()
            : now();

        $subscription->update([
            'status' => 'approved',
            'starts_at' => $subscription->starts_at ?? now(),
            'ends_at' => $base->addDays($days),
            'duration_days' => $days,
            'admin_note' => $data['admin_note'] ?? $subscription->admin_note,
            'reviewed_at' => now(),
        ]);

        return redirect()->route('admin.subscriptions.show', $subscription->id)
            ->with('success', 'Subscription renewed. Access now valid until ' . $subscription->ends_at->format('M d, Y') . '.');
    }

    /** Upgrade / change the plan → starts a fresh term of the new plan's length. */
    public function upgrade(Request $request, string $id)
    {
        $subscription = Subscription::findOrFail($id);

        $data = $request->validate([
            'subscription_plan_id' => ['required', 'exists:subscription_plans,id'],
            'admin_note' => ['nullable', 'string', 'max:1000'],
        ]);

        $plan = SubscriptionPlan::findOrFail($data['subscription_plan_id']);
        $days = $plan->duration_days ?? 30;

        $subscription->update([
            'subscription_plan_id' => $plan->id,
            'plan_name' => $plan->name,
            'duration_days' => $days,
            'amount' => $plan->price,
            'currency' => $plan->currency,
            'status' => 'approved',
            'starts_at' => now(),
            'ends_at' => now()->addDays($days),
            'admin_note' => $data['admin_note'] ?? ('Plan changed to ' . $plan->name . ' by admin.'),
            'reviewed_at' => now(),
        ]);

        return redirect()->route('admin.subscriptions.show', $subscription->id)
            ->with('success', 'Plan changed to ' . $plan->name . '. Fresh term runs until ' . $subscription->ends_at->format('M d, Y') . '.');
    }

    /** Revoke access immediately (keeps the record for history). */
    public function revoke(Request $request, string $id)
    {
        $subscription = Subscription::findOrFail($id);

        $data = $request->validate([
            'admin_note' => ['nullable', 'string', 'max:1000'],
        ]);

        $subscription->update([
            'status' => 'rejected',
            'ends_at' => now(),
            'admin_note' => $data['admin_note'] ?? 'Access revoked by admin.',
            'reviewed_at' => now(),
        ]);

        return redirect()->route('admin.subscriptions.show', $subscription->id)
            ->with('success', 'Subscription revoked. The user no longer has premium access.');
    }

    /** Permanently delete a subscription record. */
    public function destroy(string $id)
    {
        $subscription = Subscription::findOrFail($id);
        $subscription->delete();

        return redirect()->route('admin.subscriptions.index')
            ->with('success', 'Subscription record deleted.');
    }
}
