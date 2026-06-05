@extends('admin.layouts.app')

@section('title', 'Home Banners')

@section('content')
<div class="max-w-5xl mx-auto">
    <div class="flex items-center justify-between mb-6">
        <div>
            <h1 class="text-2xl font-bold text-gray-800">Home Banners / Slider</h1>
            <p class="text-sm text-gray-500">Promotional banners shown at the top of the app home screen.</p>
        </div>
        <a href="{{ route('admin.banners.create') }}" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-medium">
            + Add Banner
        </a>
    </div>

    @if(session('success'))
        <div class="mb-4 bg-green-100 border border-green-300 text-green-800 px-4 py-3 rounded-lg">
            {{ session('success') }}
        </div>
    @endif

    <div class="bg-white rounded-lg shadow-md overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
                <tr>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Preview</th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Title</th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Order</th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Status</th>
                    <th class="px-4 py-3 text-right text-xs font-semibold text-gray-500 uppercase">Actions</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
                @forelse($banners as $banner)
                    <tr>
                        <td class="px-4 py-3">
                            <img src="{{ $banner->image_url }}" alt="" class="w-28 h-14 object-cover rounded-md border border-gray-200">
                        </td>
                        <td class="px-4 py-3">
                            <div class="text-sm font-medium text-gray-800">{{ $banner->title ?: '—' }}</div>
                            <div class="text-xs text-gray-500">{{ $banner->subtitle }}</div>
                        </td>
                        <td class="px-4 py-3 text-sm text-gray-600">{{ $banner->sort_order }}</td>
                        <td class="px-4 py-3">
                            @if($banner->is_active)
                                <span class="px-2 py-1 text-xs rounded-full bg-green-100 text-green-700">Active</span>
                            @else
                                <span class="px-2 py-1 text-xs rounded-full bg-gray-100 text-gray-600">Hidden</span>
                            @endif
                        </td>
                        <td class="px-4 py-3 text-right">
                            <a href="{{ route('admin.banners.edit', $banner->id) }}" class="text-blue-600 hover:text-blue-800 text-sm mr-3">Edit</a>
                            <form action="{{ route('admin.banners.destroy', $banner->id) }}" method="POST" class="inline" onsubmit="return confirm('Delete this banner?');">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="text-red-600 hover:text-red-800 text-sm">Delete</button>
                            </form>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="5" class="px-4 py-8 text-center text-gray-500">No banners yet. Add one to show a slider on the app home screen.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">
        {{ $banners->links() }}
    </div>
</div>
@endsection
