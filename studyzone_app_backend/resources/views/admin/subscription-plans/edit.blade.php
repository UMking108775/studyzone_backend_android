@extends('admin.layouts.app')

@section('title', 'Edit Plan')
@section('page-title', 'Edit Subscription Plan')

@section('content')
<div class="max-w-3xl mx-auto">
    <div class="mb-4">
        <a href="{{ route('admin.subscription-plans.index') }}" class="text-blue-600 hover:text-blue-800 text-sm">← Back to Plans</a>
    </div>
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h2 class="text-xl font-bold text-gray-900 mb-5">Edit Subscription Plan</h2>
        <form method="POST" action="{{ route('admin.subscription-plans.update', $plan->id) }}">
            @method('PUT')
            @include('admin.subscription-plans._form')
        </form>
    </div>
</div>
@endsection
