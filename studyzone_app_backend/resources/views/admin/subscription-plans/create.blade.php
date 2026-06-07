@extends('admin.layouts.app')

@section('title', 'New Plan')
@section('page-title', 'New Subscription Plan')

@section('content')
<div class="max-w-3xl">
    <div class="mb-4">
        <a href="{{ route('admin.subscription-plans.index') }}" class="text-blue-600 hover:text-blue-800 text-sm">← Back to Plans</a>
    </div>
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h2 class="text-xl font-bold text-gray-900 mb-5">New Subscription Plan</h2>
        <form method="POST" action="{{ route('admin.subscription-plans.store') }}">
            @include('admin.subscription-plans._form')
        </form>
    </div>
</div>
@endsection
