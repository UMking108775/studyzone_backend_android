@extends('admin.layouts.app')

@section('title', 'Subscriptions')
@section('page-title', 'Subscription Requests')

@section('content')
@php
    $badge = [
        'pending' => 'bg-yellow-100 text-yellow-800',
        'approved' => 'bg-green-100 text-green-800',
        'rejected' => 'bg-red-100 text-red-800',
    ];
@endphp
<div class="space-y-6">
    <div>
        <h2 class="text-2xl font-bold text-gray-900">Subscription Requests</h2>
        <p class="text-sm text-gray-500 mt-1">
            Verify payments and approve to grant full access.
            @if($pendingSubscriptions > 0)<span class="text-yellow-700 font-medium">{{ $pendingSubscriptions }} pending.</span>@endif
        </p>
    </div>

    @if(session('success'))
        <div class="bg-green-100 border border-green-300 text-green-800 px-4 py-3 rounded-lg">{{ session('success') }}</div>
    @endif

    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
        <form method="GET" class="flex flex-col sm:flex-row gap-3">
            <input type="text" name="search" value="{{ request('search') }}" placeholder="Search by user name or email…"
                class="flex-1 px-3 py-2 border border-gray-300 rounded-lg">
            <select name="status" class="px-3 py-2 border border-gray-300 rounded-lg bg-white">
                <option value="">All statuses</option>
                @foreach(['pending' => 'Pending', 'approved' => 'Approved', 'rejected' => 'Rejected'] as $val => $lbl)
                    <option value="{{ $val }}" {{ request('status') === $val ? 'selected' : '' }}>{{ $lbl }}</option>
                @endforeach
            </select>
            <button type="submit" class="px-5 py-2 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700">Filter</button>
            @if(request('search') || request('status'))
                <a href="{{ route('admin.subscriptions.index') }}" class="px-4 py-2 text-gray-600 rounded-lg hover:bg-gray-100">Clear</a>
            @endif
        </form>
    </div>

    <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">User</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Plan</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Amount</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Requested</th>
                        <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Action</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    @forelse($subscriptions as $s)
                        <tr class="hover:bg-gray-50">
                            <td class="px-6 py-4">
                                <div class="text-sm font-medium text-gray-900">{{ $s->user->name ?? 'Unknown' }}</div>
                                <div class="text-xs text-gray-500">{{ $s->user->email ?? '' }}</div>
                            </td>
                            <td class="px-6 py-4 text-sm text-gray-700">{{ $s->plan_name ?? optional($s->plan)->name ?? '—' }}</td>
                            <td class="px-6 py-4 text-sm text-gray-700">{{ $s->currency }} {{ number_format($s->amount, 0) }}</td>
                            <td class="px-6 py-4">
                                <span class="px-2.5 py-0.5 rounded-full text-xs font-medium {{ $badge[$s->status] ?? 'bg-gray-100 text-gray-700' }}">{{ ucfirst($s->status) }}</span>
                                @if($s->status === 'approved' && $s->ends_at)
                                    <div class="text-[10px] text-gray-500 mt-1">till {{ $s->ends_at->format('M d, Y') }}</div>
                                @endif
                            </td>
                            <td class="px-6 py-4 text-sm text-gray-500">{{ $s->created_at->format('M d, Y') }}</td>
                            <td class="px-6 py-4 text-right text-sm">
                                <a href="{{ route('admin.subscriptions.show', $s->id) }}" class="text-blue-600 hover:text-blue-900 font-medium">Review</a>
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="6" class="px-6 py-12 text-center text-sm text-gray-500">No subscription requests.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        @if($subscriptions->hasPages())
            <div class="px-6 py-4 border-t border-gray-200">{{ $subscriptions->links() }}</div>
        @endif
    </div>
</div>
@endsection
