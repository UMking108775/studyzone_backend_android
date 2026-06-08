@extends('admin.layouts.app')

@section('title', 'Generate Quiz with AI')

@section('content')
<div class="max-w-7xl mx-auto">
    <div class="mb-6">
        <a href="{{ route('admin.quizzes.index') }}" class="text-blue-600 hover:text-blue-800 flex items-center">
            <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path></svg>
            Back to Quizzes
        </a>
    </div>

    <div class="bg-white rounded-xl shadow-md overflow-hidden">
        <div class="bg-gradient-to-r from-purple-600 to-indigo-600 px-6 py-5 text-white">
            <h1 class="text-2xl font-bold">✨ Generate a Quiz with AI</h1>
            <p class="text-sm text-purple-100 mt-1">Upload lecture notes (PDF) or pick a program, and AI drafts the questions. Saved as a <strong>draft</strong> for you to review before activating.</p>
        </div>

        <div class="p-6">
        @if(!$configured)
            <div class="mb-4 bg-yellow-50 border border-yellow-300 text-yellow-800 px-4 py-3 rounded-lg text-sm">
                AI is not configured yet. Add an API key in
                <a href="{{ route('admin.settings.index') }}" class="font-semibold underline">Admin → App Settings</a>
                (Anthropic, OpenAI, or Gemini), then reload this page.
            </div>
        @else
            <div class="mb-4 bg-blue-50 border border-blue-200 text-blue-800 px-4 py-2 rounded-lg text-sm flex items-center gap-2">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/></svg>
                Using <strong>{{ $provider }}</strong>
            </div>
        @endif

        @if($errors->any())
            <div class="mb-4 bg-red-100 border border-red-300 text-red-700 px-4 py-3 rounded-lg">
                <ul class="list-disc list-inside text-sm">
                    @foreach($errors->all() as $error)<li>{{ $error }}</li>@endforeach
                </ul>
            </div>
        @endif

        <form method="POST" action="{{ route('admin.quizzes.generate') }}" enctype="multipart/form-data"
              onsubmit="if(this.dataset.sent){return false;} this.dataset.sent='1'; var b=document.getElementById('genBtn'); if(b){b.disabled=true; b.innerText='Generating… (this can take 15–40s)';}">
            @csrf

            {{-- Source PDF --}}
            <div class="mb-5">
                <label class="block text-sm font-medium text-gray-700 mb-1">Lecture notes / handout (PDF) <span class="text-gray-400 font-normal">— optional but recommended</span></label>
                <label for="pdf" class="flex flex-col items-center justify-center w-full border-2 border-dashed border-gray-300 rounded-lg p-6 cursor-pointer hover:border-purple-400 hover:bg-purple-50 transition">
                    <svg class="w-8 h-8 text-gray-400 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.9A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"/></svg>
                    <span id="pdfLabel" class="text-sm text-gray-600">Click to choose a PDF (max 12 MB)</span>
                    <span class="text-xs text-gray-400 mt-1">The whole PDF is sent to the AI — it reads it and writes questions from its content.</span>
                    <input id="pdf" name="pdf" type="file" accept="application/pdf" class="hidden"
                        onchange="document.getElementById('pdfLabel').innerText = this.files.length ? this.files[0].name : 'Click to choose a PDF (max 12 MB)';">
                </label>
                <p class="mt-1 text-xs text-gray-500">Scanned pages, tables and diagrams are fine — the model reads the document directly. Without a PDF, questions are based on the topic/program below.</p>
            </div>

            {{-- Custom prompt --}}
            <div class="mb-5">
                <label class="block text-sm font-medium text-gray-700 mb-1">Extra instructions for the AI <span class="text-gray-400 font-normal">— optional</span></label>
                <textarea name="prompt" rows="2" maxlength="2000" placeholder="e.g. Focus on chapters 3–4, include numerical problems, keep wording simple for first-year students."
                    class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500">{{ old('prompt') }}</textarea>
            </div>

            <hr class="my-5">

            {{-- Placement --}}
            <div class="mb-4">
                <label class="block text-sm font-medium text-gray-700 mb-1">Placement *</label>
                <select name="scope" class="w-full px-3 py-2 border border-gray-300 rounded-lg bg-white">
                    @foreach(['program' => 'Entire program — in “Test your knowledge”', 'lesson' => 'Lesson-specific — inside the category'] as $val => $lbl)
                        <option value="{{ $val }}" {{ old('scope', 'program') === $val ? 'selected' : '' }}>{{ $lbl }}</option>
                    @endforeach
                </select>
                <p class="mt-1 text-xs text-gray-500">Lesson-specific quizzes appear inside their category like other content (a category is required). Program quizzes appear in “Test your knowledge”. Scores count toward achievements either way.</p>
            </div>

            {{-- Category --}}
            <div class="mb-4">
                <label class="block text-sm font-medium text-gray-700 mb-1">Program / Category</label>
                <select name="category_id" class="w-full px-3 py-2 border border-gray-300 rounded-lg bg-white">
                    <option value="">— General knowledge —</option>
                    @foreach($categoryOptions as $id => $label)
                        <option value="{{ $id }}" {{ (string)old('category_id') === (string)$id ? 'selected' : '' }}>{{ $label }}</option>
                    @endforeach
                </select>
                <p class="mt-1 text-xs text-gray-500">Required for lesson-specific quizzes. The quiz is gated to users with access to this category.</p>
            </div>

            {{-- Topic --}}
            <div class="mb-4">
                <label class="block text-sm font-medium text-gray-700 mb-1">Topic <span class="text-gray-400 font-normal">— optional</span></label>
                <input type="text" name="topic" value="{{ old('topic') }}" placeholder="e.g. Data Structures, Tajweed basics"
                    class="w-full px-3 py-2 border border-gray-300 rounded-lg">
                <p class="mt-1 text-xs text-gray-500">Narrow the focus. Leave blank to use the PDF / category name.</p>
            </div>

            {{-- Count + difficulty --}}
            <div class="grid grid-cols-2 gap-4 mb-6">
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Number of questions</label>
                    <input type="number" name="count" min="1" max="30" value="{{ old('count', 5) }}"
                        class="w-full px-3 py-2 border border-gray-300 rounded-lg">
                    <p class="mt-1 text-xs text-gray-500">1–30.</p>
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

            <button id="genBtn" type="submit" {{ $configured ? '' : 'disabled' }}
                class="w-full bg-purple-600 hover:bg-purple-700 disabled:bg-gray-300 text-white px-6 py-3 rounded-lg font-medium">
                Generate draft quiz
            </button>
        </form>
        </div>
    </div>
</div>
@endsection
