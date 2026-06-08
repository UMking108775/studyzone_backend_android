@extends('admin.layouts.app')

@section('title', 'Assign Subscription Plan')
@section('page-title', 'Assign Subscription Plan')

@section('content')
<div class="max-w-3xl mx-auto">
    <div class="mb-6">
        <a href="{{ route('admin.subscriptions.index') }}" class="text-blue-600 hover:text-blue-800 flex items-center text-sm">
            <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path>
            </svg>
            Back to Subscriptions
        </a>
    </div>

    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h1 class="text-2xl font-bold text-gray-800 mb-1">Assign a Plan Manually</h1>
        <p class="text-sm text-gray-500 mb-6">Grant a user full access without payment verification. The subscription is activated immediately.</p>

        @if($errors->any())
            <div class="mb-4 bg-red-100 border border-red-300 text-red-800 px-4 py-3 rounded-lg">
                <ul class="list-disc list-inside text-sm">
                    @foreach($errors->all() as $error)<li>{{ $error }}</li>@endforeach
                </ul>
            </div>
        @endif

        @if($plans->isEmpty())
            <div class="bg-yellow-50 border border-yellow-200 text-yellow-800 px-4 py-3 rounded-lg text-sm">
                No active subscription plans found.
                <a href="{{ route('admin.subscription-plans.index') }}" class="underline font-medium">Create a plan</a> first.
            </div>
        @else
        <form method="POST" action="{{ route('admin.subscriptions.store') }}" class="space-y-5">
            @csrf

            {{-- User --}}
            <div>
                <label for="user_id" class="block text-sm font-medium text-gray-700 mb-2">User *</label>
                <select name="user_id" id="user_id" required
                    class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent @error('user_id') border-red-500 @enderror">
                    <option value="">— Select a user —</option>
                    @foreach($users as $u)
                        <option value="{{ $u->id }}" {{ (string) old('user_id', $selectedUserId) === (string) $u->id ? 'selected' : '' }}>
                            {{ $u->name }} ({{ $u->email }})
                        </option>
                    @endforeach
                </select>
            </div>

            {{-- Plan --}}
            <div>
                <label for="subscription_plan_id" class="block text-sm font-medium text-gray-700 mb-2">Plan *</label>
                <select name="subscription_plan_id" id="subscription_plan_id" required onchange="syncPlan()"
                    class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent @error('subscription_plan_id') border-red-500 @enderror">
                    <option value="">— Select a plan —</option>
                    @foreach($plans as $p)
                        <option value="{{ $p->id }}"
                            data-days="{{ $p->duration_days }}"
                            data-price="{{ $p->price }}"
                            {{ (string) old('subscription_plan_id') === (string) $p->id ? 'selected' : '' }}>
                            {{ $p->name }} — {{ $p->currency }} {{ number_format($p->price, 0) }} / {{ $p->duration_days }} days
                        </option>
                    @endforeach
                </select>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                {{-- Start date --}}
                <div>
                    <label for="starts_at" class="block text-sm font-medium text-gray-700 mb-2">Start date</label>
                    <input type="date" name="starts_at" id="starts_at" value="{{ old('starts_at') }}"
                        class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <p class="text-xs text-gray-400 mt-1">Defaults to today.</p>
                </div>
                {{-- Duration override --}}
                <div>
                    <label for="duration_days" class="block text-sm font-medium text-gray-700 mb-2">Duration (days)</label>
                    <input type="number" min="1" name="duration_days" id="duration_days" value="{{ old('duration_days') }}"
                        placeholder="plan default"
                        class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <p class="text-xs text-gray-400 mt-1">Override the plan length.</p>
                </div>
                {{-- Amount override --}}
                <div>
                    <label for="amount" class="block text-sm font-medium text-gray-700 mb-2">Amount</label>
                    <input type="number" step="0.01" min="0" name="amount" id="amount" value="{{ old('amount') }}"
                        placeholder="plan price"
                        class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    <p class="text-xs text-gray-400 mt-1">Recorded for history.</p>
                </div>
            </div>

            {{-- Admin note --}}
            <div>
                <label for="admin_note" class="block text-sm font-medium text-gray-700 mb-2">Admin note</label>
                <textarea name="admin_note" id="admin_note" rows="2"
                    placeholder="Optional — e.g. complimentary access, promo, manual bank transfer #..."
                    class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">{{ old('admin_note') }}</textarea>
            </div>

            <div class="flex gap-3 pt-2">
                <button type="submit" class="bg-green-600 hover:bg-green-700 text-white px-6 py-2 rounded-lg font-medium">Assign &amp; activate</button>
                <a href="{{ route('admin.subscriptions.index') }}" class="bg-gray-500 hover:bg-gray-600 text-white px-6 py-2 rounded-lg font-medium">Cancel</a>
            </div>
        </form>
        @endif
    </div>
</div>

<script>
    function syncPlan() {
        const sel = document.getElementById('subscription_plan_id');
        if (!sel || sel.selectedIndex < 0) return;
        const opt = sel.options[sel.selectedIndex];
        const days = opt.getAttribute('data-days');
        const price = opt.getAttribute('data-price');
        if (days) document.getElementById('duration_days').placeholder = days + ' (plan default)';
        if (price) document.getElementById('amount').placeholder = price + ' (plan price)';
    }
    document.addEventListener('DOMContentLoaded', syncPlan);
</script>
@endsection
