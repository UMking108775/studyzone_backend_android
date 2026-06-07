@extends('admin.layouts.app')

@section('title', 'Add Payment Method')
@section('page-title', 'Add Payment Method')

@section('content')
<div class="max-w-3xl">
    <div class="mb-4">
        <a href="{{ route('admin.payment-methods.index') }}" class="text-blue-600 hover:text-blue-800 text-sm">← Back to Payment Methods</a>
    </div>
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h2 class="text-xl font-bold text-gray-900 mb-5">Add Payment Method</h2>
        <form method="POST" action="{{ route('admin.payment-methods.store') }}">
            @include('admin.payment-methods._form')
        </form>
    </div>
</div>
@endsection
