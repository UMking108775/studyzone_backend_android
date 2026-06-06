@extends('admin.layouts.app')

@section('title', 'Categories')
@section('page-title', 'Categories Management')

@section('content')
<div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
            <h2 class="text-2xl font-bold text-gray-900">Categories</h2>
            <p class="text-sm text-gray-500 mt-1">
                One place for the whole hierarchy. Press
                <span class="font-medium text-green-700">+ Sub</span>
                on any item to nest a deeper level &mdash; unlimited depth.
            </p>
        </div>
        <a href="{{ route('admin.categories.create') }}" class="inline-flex items-center px-4 py-2 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 transition-colors shrink-0">
            <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
            </svg>
            Create Main Category
        </a>
    </div>

    <!-- Tree -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        @forelse($tree as $category)
            @include('admin.categories._node', ['category' => $category, 'depth' => 0, 'isFirst' => $loop->first, 'isLast' => $loop->last])
        @empty
            <div class="px-6 py-16 text-center">
                <svg class="mx-auto h-12 w-12 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z"></path>
                </svg>
                <h3 class="mt-3 text-sm font-medium text-gray-900">No categories yet</h3>
                <p class="mt-1 text-sm text-gray-500">Start by creating a main category, then add sub-categories under it.</p>
                <a href="{{ route('admin.categories.create') }}" class="mt-6 inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700">
                    <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
                    </svg>
                    Create Main Category
                </a>
            </div>
        @endforelse
    </div>
</div>
@endsection
