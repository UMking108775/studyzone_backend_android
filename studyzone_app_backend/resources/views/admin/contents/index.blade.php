@extends('admin.layouts.app')

@section('title', 'Contents')
@section('page-title', 'Content Management')

@section('content')
@php
    // type => [label, badge classes]
    $typeMeta = [
        'pdf'       => ['PDF',   'bg-red-100 text-red-800'],
        'video'     => ['Video', 'bg-purple-100 text-purple-800'],
        'audio'     => ['Audio', 'bg-cyan-100 text-cyan-800'],
        'rich_text' => ['Notes', 'bg-indigo-100 text-indigo-800'],
    ];
    $anyFilter = request('search') || request('category_id') || request('content_type') || (request('is_active') !== null && request('is_active') !== '') || request('sort');
@endphp
<div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
            <h2 class="text-2xl font-bold text-gray-900">All Content</h2>
            <p class="text-sm text-gray-600 mt-1">Search and manage study material across all categories.</p>
        </div>
        <a href="{{ route('admin.contents.create') }}" class="inline-flex items-center px-4 py-2 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 transition-colors">
            <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
            </svg>
            Add Content
        </a>
    </div>

    <!-- Filters -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
        <form method="GET" action="{{ route('admin.contents.index') }}" class="space-y-3">
            <!-- Search (full width) -->
            <div class="relative">
                <span class="absolute inset-y-0 left-0 flex items-center pl-3 text-gray-400">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
                </span>
                <input type="text" name="search" value="{{ request('search') }}" placeholder="Search by title…"
                    class="w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-3">
                <!-- Category (hierarchical) -->
                <div class="lg:col-span-2">
                    <label for="category_id" class="block text-xs font-medium text-gray-500 mb-1">Category</label>
                    <select id="category_id" name="category_id" class="w-full px-3 py-2 border border-gray-300 rounded-lg bg-white focus:ring-2 focus:ring-blue-500">
                        <option value="">All categories</option>
                        @foreach($categoryOptions as $id => $label)
                            <option value="{{ $id }}" {{ (string)request('category_id') === (string)$id ? 'selected' : '' }}>{{ $label }}</option>
                        @endforeach
                    </select>
                </div>

                <!-- Type -->
                <div>
                    <label for="content_type" class="block text-xs font-medium text-gray-500 mb-1">Type</label>
                    <select id="content_type" name="content_type" class="w-full px-3 py-2 border border-gray-300 rounded-lg bg-white focus:ring-2 focus:ring-blue-500">
                        <option value="">All types</option>
                        @foreach(['pdf' => 'PDF', 'video' => 'Video', 'audio' => 'Audio', 'rich_text' => 'Notes'] as $val => $lbl)
                            <option value="{{ $val }}" {{ request('content_type') === $val ? 'selected' : '' }}>{{ $lbl }}</option>
                        @endforeach
                    </select>
                </div>

                <!-- Status -->
                <div>
                    <label for="is_active" class="block text-xs font-medium text-gray-500 mb-1">Status</label>
                    <select id="is_active" name="is_active" class="w-full px-3 py-2 border border-gray-300 rounded-lg bg-white focus:ring-2 focus:ring-blue-500">
                        <option value="">All status</option>
                        <option value="1" {{ request('is_active') === '1' ? 'selected' : '' }}>Active</option>
                        <option value="0" {{ request('is_active') === '0' ? 'selected' : '' }}>Inactive</option>
                    </select>
                </div>

                <!-- Sort -->
                <div>
                    <label for="sort" class="block text-xs font-medium text-gray-500 mb-1">Sort</label>
                    <select id="sort" name="sort" class="w-full px-3 py-2 border border-gray-300 rounded-lg bg-white focus:ring-2 focus:ring-blue-500">
                        @foreach(['newest' => 'Newest first', 'oldest' => 'Oldest first', 'title' => 'Title A–Z'] as $val => $lbl)
                            <option value="{{ $val }}" {{ request('sort', 'newest') === $val ? 'selected' : '' }}>{{ $lbl }}</option>
                        @endforeach
                    </select>
                </div>
            </div>

            <div class="flex items-center gap-2">
                <button type="submit" class="px-5 py-2 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 transition-colors">
                    Apply
                </button>
                @if($anyFilter)
                    <a href="{{ route('admin.contents.index') }}" class="px-4 py-2 text-gray-600 font-medium rounded-lg hover:bg-gray-100 transition-colors">
                        Clear
                    </a>
                @endif
            </div>
        </form>
    </div>

    <!-- Result count -->
    <div class="flex items-center justify-between text-sm text-gray-600">
        <span>
            @if($contents->total() > 0)
                Showing <strong>{{ $contents->firstItem() }}</strong>–<strong>{{ $contents->lastItem() }}</strong> of <strong>{{ $contents->total() }}</strong>
            @else
                No results
            @endif
        </span>
    </div>

    <!-- Contents Table -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Title</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Category</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Source</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created</th>
                        <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    @forelse($contents as $content)
                        @php $tm = $typeMeta[$content->content_type] ?? [ucfirst(str_replace('_',' ',$content->content_type)), 'bg-gray-100 text-gray-800']; @endphp
                        <tr class="hover:bg-gray-50 transition-colors">
                            <td class="px-6 py-4">
                                <div class="text-sm font-medium text-gray-900">{{ $content->title }}</div>
                            </td>
                            <td class="px-6 py-4">
                                <div class="text-sm text-gray-700">
                                    @if($content->category)
                                        {{ $categoryOptions[$content->category_id] ?? $content->category->title }}
                                    @else
                                        <span class="text-gray-400">Uncategorized</span>
                                    @endif
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {{ $tm[1] }}">
                                    {{ $tm[0] }}
                                </span>
                            </td>
                            <td class="px-6 py-4">
                                @if($content->content_type === 'rich_text')
                                    <span class="text-xs text-gray-400">Inline text</span>
                                @elseif($content->backblaze_url)
                                    <a href="{{ $content->backblaze_url }}" target="_blank" rel="noopener" class="text-sm text-blue-600 hover:text-blue-800 truncate max-w-xs block" title="{{ $content->backblaze_url }}">
                                        {{ \Illuminate\Support\Str::limit($content->backblaze_url, 40) }}
                                    </a>
                                @else
                                    <span class="text-gray-400">—</span>
                                @endif
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                @if($content->is_active)
                                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">Active</span>
                                @else
                                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-600">Inactive</span>
                                @endif
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                {{ $content->created_at?->format('M d, Y') }}
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                <div class="flex items-center justify-end space-x-2">
                                    <a href="{{ route('admin.contents.edit', $content->id) }}" class="text-blue-600 hover:text-blue-900" title="Edit">
                                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                                        </svg>
                                    </a>
                                    <form action="{{ route('admin.contents.destroy', $content->id) }}" method="POST" class="inline" onsubmit="return confirm('Delete this content? This cannot be undone.');">
                                        @csrf
                                        @method('DELETE')
                                        <button type="submit" class="text-red-600 hover:text-red-900" title="Delete">
                                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                                            </svg>
                                        </button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="px-6 py-12 text-center">
                                <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                                </svg>
                                <h3 class="mt-2 text-sm font-medium text-gray-900">{{ $anyFilter ? 'No content matches your filters' : 'No content yet' }}</h3>
                                <p class="mt-1 text-sm text-gray-500">{{ $anyFilter ? 'Try a different search or clear the filters.' : 'Get started by adding new content.' }}</p>
                                <div class="mt-6">
                                    @if($anyFilter)
                                        <a href="{{ route('admin.contents.index') }}" class="inline-flex items-center px-4 py-2 bg-gray-600 text-white text-sm font-medium rounded-lg hover:bg-gray-700">Clear filters</a>
                                    @else
                                        <a href="{{ route('admin.contents.create') }}" class="inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700">
                                            <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
                                            </svg>
                                            Add Content
                                        </a>
                                    @endif
                                </div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <!-- Pagination -->
        @if($contents->hasPages())
            <div class="px-6 py-4 border-t border-gray-200">
                {{ $contents->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
