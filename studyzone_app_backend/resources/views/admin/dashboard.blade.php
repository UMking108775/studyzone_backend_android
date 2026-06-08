@extends('admin.layouts.app')

@section('title', 'Dashboard')

@section('content')
<div class="space-y-5">
    <!-- Welcome Header -->
    <div class="flex items-center justify-between rounded-xl bg-gradient-to-r from-blue-600 to-blue-700 p-5 text-white shadow-md">
        <div>
            <h1 class="text-xl font-bold">Welcome back, {{ Auth::user()->name }}! 👋</h1>
            <p class="mt-0.5 text-sm text-blue-100">Here's what's happening with your app today</p>
        </div>
        <div class="hidden text-right md:block">
            <p class="text-xs text-blue-200">{{ now()->format('l') }}</p>
            <p class="text-base font-semibold">{{ now()->format('M d, Y') }}</p>
        </div>
    </div>

    <!-- Stats Grid -->
    <div class="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <!-- Total Categories -->
        <div class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm transition-shadow hover:shadow-md">
            <div class="flex items-start justify-between">
                <div class="min-w-0">
                    <p class="text-xs font-medium text-gray-500">Total Categories</p>
                    <p class="mt-1 text-2xl font-bold text-gray-900">{{ $stats['totalCategories'] }}</p>
                </div>
                <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-blue-100">
                    <svg class="h-5 w-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"></path></svg>
                </span>
            </div>
            <div class="mt-2 flex items-center gap-2 text-[11px]">
                <span class="font-medium text-green-600">{{ $stats['activeCategories'] }} Active</span>
                <span class="text-gray-300">•</span>
                <span class="font-medium text-red-600">{{ $stats['inactiveCategories'] }} Inactive</span>
            </div>
        </div>

        <!-- Total Users -->
        <div class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm transition-shadow hover:shadow-md">
            <div class="flex items-start justify-between">
                <div class="min-w-0">
                    <p class="text-xs font-medium text-gray-500">Total Users</p>
                    <p class="mt-1 text-2xl font-bold text-gray-900">{{ $stats['totalUsers'] }}</p>
                </div>
                <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-green-100">
                    <svg class="h-5 w-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"></path></svg>
                </span>
            </div>
            <a href="{{ route('admin.users.index') }}" class="mt-2 inline-block text-[11px] font-medium text-blue-600 hover:text-blue-800">Manage Users →</a>
        </div>

        <!-- Total Contents -->
        <div class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm transition-shadow hover:shadow-md">
            <div class="flex items-start justify-between">
                <div class="min-w-0">
                    <p class="text-xs font-medium text-gray-500">Total Materials</p>
                    <p class="mt-1 text-2xl font-bold text-gray-900">{{ $stats['totalContents'] }}</p>
                </div>
                <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-purple-100">
                    <svg class="h-5 w-5 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>
                </span>
            </div>
            <a href="{{ route('admin.contents.index') }}" class="mt-2 inline-block text-[11px] font-medium text-blue-600 hover:text-blue-800">View Materials →</a>
        </div>

        <!-- API Status -->
        <div class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm transition-shadow hover:shadow-md">
            <div class="flex items-start justify-between">
                <div class="min-w-0">
                    <p class="text-xs font-medium text-gray-500">API Status</p>
                    <p class="mt-1 text-2xl font-bold text-green-600">Active</p>
                </div>
                <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-amber-100">
                    <svg class="h-5 w-5 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"></path></svg>
                </span>
            </div>
            <a href="{{ route('admin.api.index') }}" class="mt-2 inline-block text-[11px] font-medium text-blue-600 hover:text-blue-800">View Docs →</a>
        </div>
    </div>

    <!-- Category Breakdown -->
    <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <a href="{{ route('admin.categories.index', ['level' => 1]) }}" class="flex items-center justify-between rounded-xl border-l-4 border-blue-500 bg-white p-4 shadow-sm transition-shadow hover:shadow-md">
            <div>
                <p class="text-[11px] font-semibold uppercase tracking-wide text-gray-500">Main Categories</p>
                <p class="mt-1 text-xl font-bold text-gray-900">{{ $stats['mainCategories'] }}</p>
            </div>
            <span class="rounded-full bg-blue-100 px-2.5 py-1 text-[11px] font-medium text-blue-700">Level 1</span>
        </a>
        <a href="{{ route('admin.categories.index', ['level' => 2]) }}" class="flex items-center justify-between rounded-xl border-l-4 border-green-500 bg-white p-4 shadow-sm transition-shadow hover:shadow-md">
            <div>
                <p class="text-[11px] font-semibold uppercase tracking-wide text-gray-500">Sub Categories</p>
                <p class="mt-1 text-xl font-bold text-gray-900">{{ $stats['subCategories'] }}</p>
            </div>
            <span class="rounded-full bg-green-100 px-2.5 py-1 text-[11px] font-medium text-green-700">Level 2</span>
        </a>
        <a href="{{ route('admin.categories.index', ['level' => 3]) }}" class="flex items-center justify-between rounded-xl border-l-4 border-purple-500 bg-white p-4 shadow-sm transition-shadow hover:shadow-md">
            <div>
                <p class="text-[11px] font-semibold uppercase tracking-wide text-gray-500">3rd Level Categories</p>
                <p class="mt-1 text-xl font-bold text-gray-900">{{ $stats['thirdLevelCategories'] }}</p>
            </div>
            <span class="rounded-full bg-purple-100 px-2.5 py-1 text-[11px] font-medium text-purple-700">Level 3</span>
        </a>
    </div>

    <!-- Recent Activity -->
    <div class="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <!-- Recent Categories -->
        <div class="rounded-xl border border-gray-200 bg-white shadow-sm">
            <div class="flex items-center justify-between border-b border-gray-100 px-5 py-3">
                <h3 class="text-sm font-semibold text-gray-900">Recent Categories</h3>
                <a href="{{ route('admin.categories.index') }}" class="text-xs font-medium text-blue-600 hover:text-blue-800">View all</a>
            </div>
            <div class="px-5 py-2">
                @forelse($recentCategories as $category)
                <div class="flex items-center justify-between py-2.5 {{ !$loop->last ? 'border-b border-gray-50' : '' }}">
                    <div class="flex min-w-0 items-center gap-3">
                        @if($category->image)
                        <img src="{{ asset('storage/' . $category->image) }}" alt="{{ $category->title }}" class="h-9 w-9 rounded-lg object-cover">
                        @else
                        <div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br from-blue-500 to-purple-600 text-sm font-bold text-white">{{ substr($category->title, 0, 1) }}</div>
                        @endif
                        <div class="min-w-0">
                            <p class="truncate text-sm font-medium text-gray-900">{{ $category->title }}</p>
                            <p class="truncate text-xs text-gray-500">{{ $category->parent ? $category->parent->title . ' → ' : '' }}Level {{ $category->level }}</p>
                        </div>
                    </div>
                    <span class="shrink-0 text-xs font-medium {{ $category->is_active ? 'text-green-600' : 'text-gray-400' }}">{{ $category->is_active ? 'Active' : 'Inactive' }}</span>
                </div>
                @empty
                <div class="py-8 text-center text-sm text-gray-500">No categories yet</div>
                @endforelse
            </div>
        </div>

        <!-- Recent Users -->
        <div class="rounded-xl border border-gray-200 bg-white shadow-sm">
            <div class="flex items-center justify-between border-b border-gray-100 px-5 py-3">
                <h3 class="text-sm font-semibold text-gray-900">Recent Users</h3>
                <a href="{{ route('admin.users.index') }}" class="text-xs font-medium text-blue-600 hover:text-blue-800">View all</a>
            </div>
            <div class="px-5 py-2">
                @forelse($recentUsers as $user)
                <div class="flex items-center justify-between py-2.5 {{ !$loop->last ? 'border-b border-gray-50' : '' }}">
                    <div class="flex min-w-0 items-center gap-3">
                        <div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-green-500 to-blue-600 text-sm font-bold text-white">{{ substr($user->name, 0, 1) }}</div>
                        <div class="min-w-0">
                            <p class="truncate text-sm font-medium text-gray-900">{{ $user->name }}</p>
                            <p class="truncate text-xs text-gray-500">{{ $user->email }}</p>
                        </div>
                    </div>
                    <a href="{{ route('admin.users.category-access', $user->id) }}" class="shrink-0 text-xs font-medium text-blue-600 hover:text-blue-800">Manage →</a>
                </div>
                @empty
                <div class="py-8 text-center text-sm text-gray-500">No users yet</div>
                @endforelse
            </div>
        </div>
    </div>

    <!-- Quick Actions -->
    <div class="rounded-xl border border-gray-200 bg-white p-5 shadow-sm">
        <h3 class="mb-3 text-sm font-semibold text-gray-900">Quick Actions</h3>
        <div class="grid grid-cols-2 gap-3 md:grid-cols-4">
            <a href="{{ route('admin.categories.create', ['level' => 1]) }}" class="flex flex-col items-center justify-center rounded-lg border border-gray-200 p-3 transition-all hover:border-blue-500 hover:bg-blue-50">
                <svg class="mb-1.5 h-6 w-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path></svg>
                <span class="text-xs font-medium text-gray-700">Add Category</span>
            </a>
            <a href="{{ route('admin.contents.create') }}" class="flex flex-col items-center justify-center rounded-lg border border-gray-200 p-3 transition-all hover:border-green-500 hover:bg-green-50">
                <svg class="mb-1.5 h-6 w-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 13h6m-3-3v6m5 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>
                <span class="text-xs font-medium text-gray-700">Add Material</span>
            </a>
            <a href="{{ route('admin.users.create') }}" class="flex flex-col items-center justify-center rounded-lg border border-gray-200 p-3 transition-all hover:border-purple-500 hover:bg-purple-50">
                <svg class="mb-1.5 h-6 w-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z"></path></svg>
                <span class="text-xs font-medium text-gray-700">Add User</span>
            </a>
            <a href="{{ route('admin.subscriptions.create') }}" class="flex flex-col items-center justify-center rounded-lg border border-gray-200 p-3 transition-all hover:border-amber-500 hover:bg-amber-50">
                <svg class="mb-1.5 h-6 w-6 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                <span class="text-xs font-medium text-gray-700">Assign Plan</span>
            </a>
        </div>
    </div>
</div>
@endsection
