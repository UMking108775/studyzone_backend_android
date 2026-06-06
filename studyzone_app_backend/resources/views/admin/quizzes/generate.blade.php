@extends('admin.layouts.app')

@section('title', 'Generate Quiz with AI')

@section('content')
<div class="max-w-2xl mx-auto">
    <div class="mb-6">
        <a href="{{ route('admin.quizzes.index') }}" class="text-blue-600 hover:text-blue-800 flex items-center">
            <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path></svg>
            Back to Quizzes
        </a>
    </div>

    <div class="bg-white rounded-lg shadow-md p-6">
        <h1 class="text-2xl font-bold text-gray-800 mb-1">✨ Generate a Quiz with AI</h1>
        <p class="text-sm text-gray-500 mb-6">AI writes a draft quiz based on a program/category (and its study material). It's saved as a <strong>draft</strong> so you can review and edit before activating.</p>

        @if(!$configured)
            <div class="mb-4 bg-yellow-50 border border-yellow-300 text-yellow-800 px-4 py-3 rounded-lg text-sm">
                AI is not configured yet. Add <strong>one</strong> of these to your <code>.env</code>, then reload:
                <code>ANTHROPIC_API_KEY</code>, <code>OPENAI_API_KEY</code>, or <code>GEMINI_API_KEY</code>.
                Optionally set <code>AI_PROVIDER</code> to force one, and the matching <code>*_MODEL</code>.
            </div>
        @else
            <div class="mb-4 bg-blue-50 border border-blue-200 text-blue-800 px-4 py-2 rounded-lg text-sm">
                Using <strong>{{ $provider }}</strong>.
            </div>
        @endif

        @if($errors->any())
            <div class="mb-4 bg-red-100 border border-red-300 text-red-700 px-4 py-3 rounded-lg">
                <ul class="list-disc list-inside text-sm">
                    @foreach($errors->all() as $error)<li>{{ $error }}</li>@endforeach
                </ul>
            </div>
        @endif

        <form method="POST" action="{{ route('admin.quizzes.generate') }}"
              onsubmit="if(this.dataset.sent){return false;} this.dataset.sent='1';">
            @csrf
            <div class="mb-4">
                <label class="block text-sm font-medium text-gray-700 mb-1">Program / Category</label>
                <select name="category_id" class="w-full px-3 py-2 border border-gray-300 rounded-lg bg-white">
                    <option value="">— General knowledge —</option>
                    @foreach($categoryOptions as $id => $label)
                        <option value="{{ $id }}" {{ (string)old('category_id') === (string)$id ? 'selected' : '' }}>{{ $label }}</option>
                    @endforeach
                </select>
                <p class="mt-1 text-xs text-gray-500">Questions are grounded on this program's material. The quiz is gated to users with access to this category.</p>
            </div>
            <div class="mb-4">
                <label class="block text-sm font-medium text-gray-700 mb-1">Topic (optional)</label>
                <input type="text" name="topic" value="{{ old('topic') }}" placeholder="e.g. Data Structures, Tajweed basics"
                    class="w-full px-3 py-2 border border-gray-300 rounded-lg">
                <p class="mt-1 text-xs text-gray-500">Narrow the focus. Leave blank to use the category name.</p>
            </div>
            <div class="grid grid-cols-2 gap-4 mb-6">
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Number of questions</label>
                    <input type="number" name="count" min="1" max="20" value="{{ old('count', 5) }}"
                        class="w-full px-3 py-2 border border-gray-300 rounded-lg">
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Difficulty</label>
                    <select name="difficulty" class="w-full px-3 py-2 border border-gray-300 rounded-lg bg-white">
                        @foreach(['easy' => 'Easy', 'medium' => 'Medium', 'hard' => 'Hard'] as $val => $lbl)
                            <option value="{{ $val }}" {{ old('difficulty', 'medium') === $val ? 'selected' : '' }}>{{ $lbl }}</option>
                        @endforeach
                    </select>
                </div>
            </div>
            <button type="submit" {{ $configured ? '' : 'disabled' }}
                class="bg-purple-600 hover:bg-purple-700 disabled:bg-gray-300 text-white px-6 py-2.5 rounded-lg font-medium"
                onclick="this.innerText='Generating… (this can take ~15s)';">
                Generate draft quiz
            </button>
        </form>
    </div>
</div>
@endsection
