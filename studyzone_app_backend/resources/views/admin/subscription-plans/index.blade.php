@extends('admin.layouts.app')

@section('title', 'Subscription Plans')
@section('page-title', 'Subscription Plans')

@section('content')
<div class="space-y-6">
    <div class="flex justify-between items-center">
        <div>
            <h2 class="text-2xl font-bold text-gray-900">Subscription Plans</h2>
            <p class="text-sm text-gray-500 mt-1">Plans users can buy to unlock all locked content.</p>
        </div>
        <a href="{{ route('admin.subscription-plans.create') }}" class="inline-flex items-center px-4 py-2 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700">
            <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
            New Plan
        </a>
    </div>

    @if(session('success'))
        <div class="bg-green-100 border border-green-300 text-green-800 px-4 py-3 rounded-lg">{{ session('success') }}</div>
    @endif

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        @forelse($plans as $plan)
            <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-5 flex flex-col">
                <div class="flex items-start justify-between">
                    <h3 class="text-lg font-bold text-gray-900">{{ $plan->name }}</h3>
                    @if($plan->is_active)
                        <span class="px-2 py-0.5 rounded-full text-xs bg-green-100 text-green-800">Active</span>
                    @else
                        <span class="px-2 py-0.5 rounded-full text-xs bg-gray-100 text-gray-600">Hidden</span>
                    @endif
                </div>
                <div class="mt-2 text-2xl font-extrabold text-blue-600">{{ $plan->currency }} {{ number_format($plan->price, 0) }}</div>
                <div class="text-xs text-gray-500">{{ $plan->duration_days }} days</div>
                @if($plan->description)<p class="mt-2 text-sm text-gray-600">{{ $plan->description }}</p>@endif
                @if(!empty($plan->features))
                    <ul class="mt-3 space-y-1 flex-1">
                        @foreach(array_slice($plan->features, 0, 5) as $f)
                            <li class="flex items-start text-sm text-gray-700">
                                <svg class="w-4 h-4 text-green-500 mr-2 mt-0.5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
                                <span>{{ $f }}</span>
                            </li>
                        @endforeach
                    </ul>
                @else
                    <div class="flex-1"></div>
                @endif
                <div class="mt-4 pt-3 border-t border-gray-100 flex items-center justify-between">
                    <span class="text-xs text-gray-400">{{ $plan->subscriptions_count }} purchase(s)</span>
                    <div class="flex items-center gap-3 text-sm">
                        <a href="{{ route('admin.subscription-plans.edit', $plan->id) }}" class="text-blue-600 hover:text-blue-900">Edit</a>
                        <form action="{{ route('admin.subscription-plans.destroy', $plan->id) }}" method="POST" onsubmit="return confirm('Delete this plan?');">
                            @csrf @method('DELETE')
                            <button type="submit" class="text-red-600 hover:text-red-900">Delete</button>
                        </form>
                    </div>
                </div>
            </div>
        @empty
            <div class="col-span-full bg-white rounded-lg border border-gray-200 px-6 py-12 text-center text-sm text-gray-500">
                No plans yet. Create your first subscription plan.
            </div>
        @endforelse
    </div>
</div>
@endsection
