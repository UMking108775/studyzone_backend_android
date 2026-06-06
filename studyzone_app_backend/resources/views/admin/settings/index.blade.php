@extends('admin.layouts.app')

@section('title', 'App Settings')

@section('content')
<div class="max-w-2xl mx-auto">
    <div class="mb-6">
        <h1 class="text-2xl font-bold text-gray-800">App Settings</h1>
        <p class="text-sm text-gray-500">Control behaviour of the mobile app.</p>
    </div>

    @if(session('success'))
        <div class="mb-4 bg-green-100 border border-green-300 text-green-800 px-4 py-3 rounded-lg">{{ session('success') }}</div>
    @endif

    <div class="bg-white rounded-lg shadow-md p-6">
        <h2 class="text-lg font-semibold text-gray-800 mb-1">Downloads</h2>
        <p class="text-sm text-gray-500 mb-4">When turned off, users can still stream, but the "Download" option is hidden in the app.</p>

        <form method="POST" action="{{ route('admin.settings.update') }}">
            @csrf
            @method('PUT')

            <label class="flex items-center justify-between py-3 border-b border-gray-100">
                <span>
                    <span class="block text-sm font-medium text-gray-800">Allow audio downloads</span>
                    <span class="block text-xs text-gray-500">Users can save audio for offline listening</span>
                </span>
                <input type="checkbox" name="allow_audio_download" value="1" {{ $allowAudio ? 'checked' : '' }}
                    class="w-5 h-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500">
            </label>

            <label class="flex items-center justify-between py-3 border-b border-gray-100">
                <span>
                    <span class="block text-sm font-medium text-gray-800">Allow video downloads</span>
                    <span class="block text-xs text-gray-500">Users can save video for offline viewing</span>
                </span>
                <input type="checkbox" name="allow_video_download" value="1" {{ $allowVideo ? 'checked' : '' }}
                    class="w-5 h-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500">
            </label>

            <div class="mt-6">
                <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg font-medium">Save Settings</button>
            </div>
        </form>
    </div>
</div>
@endsection
