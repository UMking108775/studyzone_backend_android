@extends('admin.layouts.app')

@section('title', 'Review Subscription')
@section('page-title', 'Review Subscription')

@section('content')
@php
    $badge = [
        'pending' => 'bg-yellow-100 text-yellow-800',
        'approved' => 'bg-green-100 text-green-800',
        'rejected' => 'bg-red-100 text-red-800',
    ];
    $s = $subscription;
@endphp
<div class="max-w-3xl mx-auto space-y-6">
    <a href="{{ route('admin.subscriptions.index') }}" class="text-blue-600 hover:text-blue-800 text-sm">← Back to Requests</a>

    @if(session('success'))
        <div class="bg-green-100 border border-green-300 text-green-800 px-4 py-3 rounded-lg">{{ session('success') }}</div>
    @endif

    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div class="flex items-start justify-between">
            <div>
                <h2 class="text-xl font-bold text-gray-900">{{ $s->plan_name ?? optional($s->plan)->name ?? 'Subscription' }}</h2>
                <p class="text-sm text-gray-500">{{ $s->currency }} {{ number_format($s->amount, 0) }} · {{ $s->duration_days ?? optional($s->plan)->duration_days }} days</p>
            </div>
            <span class="px-3 py-1 rounded-full text-sm font-medium {{ $badge[$s->status] ?? 'bg-gray-100 text-gray-700' }}">{{ ucfirst($s->status) }}</span>
        </div>

        @if($s->status === 'approved' && $s->ends_at)
            <div class="mt-3 bg-green-50 border border-green-200 text-green-800 text-sm px-4 py-2 rounded-lg">
                Active from {{ optional($s->starts_at)->format('M d, Y') }} to <strong>{{ $s->ends_at->format('M d, Y') }}</strong>.
            </div>
        @endif

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-5 text-sm">
            <div>
                <div class="text-xs text-gray-400">User</div>
                <div class="font-medium text-gray-900">{{ $s->user->name ?? 'Unknown' }}</div>
                <div class="text-gray-500">{{ $s->user->email ?? '' }}</div>
                <div class="text-gray-500">{{ $s->user->phone_number ?? '' }}</div>
            </div>
            <div>
                <div class="text-xs text-gray-400">Paid via</div>
                <div class="font-medium text-gray-900">{{ optional($s->paymentMethod)->name ?? '—' }}</div>
                <div class="text-gray-500">{{ optional($s->paymentMethod)->account_number }}</div>
            </div>
            <div>
                <div class="text-xs text-gray-400">Sender name</div>
                <div class="text-gray-900">{{ $s->sender_name ?? '—' }}</div>
            </div>
            <div>
                <div class="text-xs text-gray-400">Sender account / number</div>
                <div class="text-gray-900">{{ $s->sender_account ?? '—' }}</div>
            </div>
            <div>
                <div class="text-xs text-gray-400">Transaction / reference</div>
                <div class="text-gray-900">{{ $s->transaction_reference ?? '—' }}</div>
            </div>
            <div>
                <div class="text-xs text-gray-400">Requested</div>
                <div class="text-gray-900">{{ $s->created_at->format('M d, Y g:i A') }}</div>
            </div>
        </div>

        @if($s->proof_path)
            <div class="mt-5">
                <div class="text-xs text-gray-400 mb-2">Payment proof</div>
                <a href="{{ asset('storage/' . $s->proof_path) }}" target="_blank" rel="noopener">
                    <img src="{{ asset('storage/' . $s->proof_path) }}" alt="Payment proof"
                        class="max-h-80 rounded-lg border border-gray-200">
                </a>
                <p class="text-xs text-gray-400 mt-1">Click to open full size.</p>
            </div>
        @else
            <div class="mt-5 text-sm text-gray-400">No proof image attached.</div>
        @endif

        @if($s->admin_note)
            <div class="mt-4 text-sm">
                <span class="text-xs text-gray-400">Admin note:</span> {{ $s->admin_note }}
            </div>
        @endif
    </div>

    @if($s->status !== 'pending')
        <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 space-y-6">
            <div>
                <h3 class="text-sm font-semibold text-gray-800">Manage access (admin)</h3>
                <p class="text-xs text-gray-500 mt-0.5">Renew, change the plan, or revoke this user's access.</p>
            </div>

            {{-- Renew / extend --}}
            <form method="POST" action="{{ route('admin.subscriptions.renew', $s->id) }}"
                  onsubmit="return confirm('Renew / extend this subscription?');"
                  class="flex flex-col sm:flex-row sm:items-end gap-3 border-t border-gray-100 pt-4">
                @csrf
                <div class="flex-1">
                    <label class="block text-xs font-medium text-gray-600 mb-1">Renew / extend</label>
                    <input type="number" min="1" name="duration_days"
                        placeholder="{{ $s->duration_days ?? optional($s->plan)->duration_days ?? 30 }} days (default)"
                        class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm">
                    <p class="text-[11px] text-gray-400 mt-1">Adds days from {{ $s->ends_at && $s->ends_at->isFuture() ? 'the current end date' : 'today' }}.</p>
                </div>
                <button type="submit" class="bg-green-600 hover:bg-green-700 text-white px-5 py-2 rounded-lg font-medium text-sm whitespace-nowrap">Renew</button>
            </form>

            {{-- Upgrade / change plan --}}
            <form method="POST" action="{{ route('admin.subscriptions.upgrade', $s->id) }}"
                  onsubmit="return confirm('Change plan? This starts a fresh term from today.');"
                  class="flex flex-col sm:flex-row sm:items-end gap-3 border-t border-gray-100 pt-4">
                @csrf
                <div class="flex-1">
                    <label class="block text-xs font-medium text-gray-600 mb-1">Upgrade / change plan</label>
                    <select name="subscription_plan_id" required class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm bg-white">
                        <option value="">— Select a plan —</option>
                        @foreach($plans as $p)
                            <option value="{{ $p->id }}" {{ (int) $s->subscription_plan_id === (int) $p->id ? 'selected' : '' }}>
                                {{ $p->name }} — {{ $p->currency }} {{ number_format($p->price, 0) }} / {{ $p->duration_days }} days
                            </option>
                        @endforeach
                    </select>
                    <p class="text-[11px] text-gray-400 mt-1">Sets a fresh term of the new plan's length from today.</p>
                </div>
                <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white px-5 py-2 rounded-lg font-medium text-sm whitespace-nowrap">Change plan</button>
            </form>

            {{-- Revoke + Delete --}}
            <div class="flex flex-col sm:flex-row gap-3 border-t border-gray-100 pt-4">
                @if($s->is_active)
                <form method="POST" action="{{ route('admin.subscriptions.revoke', $s->id) }}"
                      onsubmit="return confirm('Revoke access now? The user will immediately lose premium access.');" class="flex-1">
                    @csrf
                    <button type="submit" class="w-full bg-red-600 hover:bg-red-700 text-white px-5 py-2 rounded-lg font-medium text-sm">Revoke access</button>
                </form>
                @endif
                <form method="POST" action="{{ route('admin.subscriptions.destroy', $s->id) }}"
                      onsubmit="return confirm('Permanently delete this subscription record? This cannot be undone.');" class="flex-1">
                    @csrf
                    @method('DELETE')
                    <button type="submit" class="w-full bg-gray-700 hover:bg-gray-800 text-white px-5 py-2 rounded-lg font-medium text-sm">Delete record</button>
                </form>
            </div>
        </div>
    @endif

    @if($s->status === 'pending')
        <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h3 class="text-sm font-semibold text-gray-800 mb-3">Decision</h3>
            <form method="POST" action="{{ route('admin.subscriptions.approve', $s->id) }}" class="space-y-3"
                  onsubmit="return confirm('Approve this subscription and grant full access?');">
                @csrf
                <textarea name="admin_note" rows="2" placeholder="Optional note (e.g. verified transaction #...)"
                    class="w-full px-3 py-2 border border-gray-300 rounded-lg"></textarea>
                <div class="flex gap-3">
                    <button type="submit" class="bg-green-600 hover:bg-green-700 text-white px-6 py-2 rounded-lg font-medium">Approve &amp; grant access</button>
                    <button type="submit" formaction="{{ route('admin.subscriptions.reject', $s->id) }}"
                        formnovalidate
                        onclick="return confirm('Reject this request?');"
                        class="bg-red-600 hover:bg-red-700 text-white px-6 py-2 rounded-lg font-medium">Reject</button>
                </div>
            </form>
        </div>
    @endif
</div>
@endsection
