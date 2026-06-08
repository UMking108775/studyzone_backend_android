@extends('admin.layouts.app')

@section('title', 'Home Banners')

@section('content')
<div class="max-w-7xl mx-auto">
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
                            <form action="{{ route('admin.banners.toggle', $banner->id) }}" method="POST">
                                @csrf
                                <button type="submit"
                                    title="{{ $banner->is_active ? 'Visible in app — click to hide' : 'Hidden — click to show in app' }}"
                                    class="relative inline-flex h-6 w-11 items-center rounded-full transition-colors {{ $banner->is_active ? 'bg-green-500' : 'bg-gray-300' }}">
                                    <span class="inline-block h-5 w-5 transform rounded-full bg-white shadow transition-transform {{ $banner->is_active ? 'translate-x-5' : 'translate-x-1' }}"></span>
                                </button>
                            </form>
                            <div class="mt-1 text-[11px] font-medium {{ $banner->is_active ? 'text-green-600' : 'text-gray-500' }}">
                                {{ $banner->is_active ? 'Visible' : 'Hidden' }}
                            </div>
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
