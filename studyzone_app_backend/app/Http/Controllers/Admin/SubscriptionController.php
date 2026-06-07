<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Subscription;
use Illuminate\Http\Request;

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

    public function show(string $id)
    {
        $subscription = Subscription::with(['user', 'plan', 'paymentMethod'])->findOrFail($id);
        return view('admin.subscriptions.show', compact('subscription'));
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
}
