@extends('admin.layouts.app')

@section('title', 'App Settings')

@section('content')
<div class="max-w-2xl mx-auto">
    <div class="mb-6">
        <h1 class="text-2xl font-bold text-gray-800">App Settings</h1>
        <p class="text-sm text-gray-500">Control behaviour of the mobile app and the AI quiz maker.</p>
    </div>

    @if(session('success'))
        <div class="mb-4 bg-green-100 border border-green-300 text-green-800 px-4 py-3 rounded-lg">{{ session('success') }}</div>
    @endif

    <form method="POST" action="{{ route('admin.settings.update') }}">
        @csrf
        @method('PUT')

        {{-- Downloads --}}
        <div class="bg-white rounded-lg shadow-md p-6 mb-6">
            <h2 class="text-lg font-semibold text-gray-800 mb-1">Downloads</h2>
            <p class="text-sm text-gray-500 mb-4">When off, users can still stream, but the "Download" option is hidden in the app.</p>

            <label class="flex items-center justify-between py-3 border-b border-gray-100">
                <span>
                    <span class="block text-sm font-medium text-gray-800">Allow audio downloads</span>
                    <span class="block text-xs text-gray-500">Users can save audio for offline listening</span>
                </span>
                <input type="checkbox" name="allow_audio_download" value="1" {{ $allowAudio ? 'checked' : '' }}
                    class="w-5 h-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500">
            </label>

            <label class="flex items-center justify-between py-3">
                <span>
                    <span class="block text-sm font-medium text-gray-800">Allow video downloads</span>
                    <span class="block text-xs text-gray-500">Users can save video for offline viewing</span>
                </span>
                <input type="checkbox" name="allow_video_download" value="1" {{ $allowVideo ? 'checked' : '' }}
                    class="w-5 h-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500">
            </label>
        </div>

        {{-- AI quiz maker --}}
        <div class="bg-white rounded-lg shadow-md p-6 mb-6">
            <h2 class="text-lg font-semibold text-gray-800 mb-1">AI Quiz Maker</h2>
            <p class="text-sm text-gray-500 mb-4">Add an API key for any one provider. Keys are stored encrypted. The quiz maker uses the selected provider (or the first one that has a key).</p>

            <div class="mb-5">
                <label class="block text-sm font-medium text-gray-700 mb-1">Provider</label>
                <select name="ai_provider" class="w-full px-3 py-2 border border-gray-300 rounded-lg bg-white">
                    @foreach(['auto' => 'Auto (first available)', 'anthropic' => 'Anthropic (Claude)', 'openai' => 'OpenAI', 'gemini' => 'Google Gemini'] as $val => $lbl)
                        <option value="{{ $val }}" {{ $aiProvider === $val ? 'selected' : '' }}>{{ $lbl }}</option>
                    @endforeach
                </select>
            </div>

            @php
                $providers = [
                    ['key' => 'anthropic', 'name' => 'Anthropic (Claude)', 'has' => $hasAnthropic, 'model' => $anthropicModel, 'ph' => 'claude-haiku-4-5-20251001'],
                    ['key' => 'openai', 'name' => 'OpenAI', 'has' => $hasOpenai, 'model' => $openaiModel, 'ph' => 'gpt-4o-mini'],
                    ['key' => 'gemini', 'name' => 'Google Gemini', 'has' => $hasGemini, 'model' => $geminiModel, 'ph' => 'gemini-2.0-flash'],
                ];
            @endphp

            @foreach($providers as $p)
                <div class="border border-gray-200 rounded-lg p-4 mb-3">
                    <div class="flex items-center justify-between mb-2">
                        <span class="text-sm font-semibold text-gray-800">{{ $p['name'] }}</span>
                        @if($p['has'])
                            <span class="px-2 py-0.5 text-xs rounded-full bg-green-100 text-green-700">Key saved</span>
                        @else
                            <span class="px-2 py-0.5 text-xs rounded-full bg-gray-100 text-gray-500">No key</span>
                        @endif
                    </div>
                    <input type="password" name="ai_{{ $p['key'] }}_key" autocomplete="new-password"
                        placeholder="{{ $p['has'] ? '•••••••• (leave blank to keep)' : 'Paste API key' }}"
                        class="w-full px-3 py-2 border border-gray-300 rounded-lg mb-2">
                    <input type="text" name="ai_{{ $p['key'] }}_model" value="{{ $p['model'] }}"
                        placeholder="Model (optional) — e.g. {{ $p['ph'] }}"
                        class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm">
                    @if($p['has'])
                        <label class="flex items-center mt-2 text-xs text-gray-600">
                            <input type="checkbox" name="clear_{{ $p['key'] }}_key" value="1" class="w-4 h-4 text-red-600 border-gray-300 rounded mr-2">
                            Remove saved key
                        </label>
                    @endif
                </div>
            @endforeach
        </div>

        <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg font-medium">Save Settings</button>
    </form>
</div>
@endsection
