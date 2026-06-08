@extends('admin.layouts.app')

@section('title', 'Quizzes')

@section('content')
<div class="max-w-7xl mx-auto">
    <div class="flex items-center justify-between mb-6">
        <div>
            <h1 class="text-2xl font-bold text-gray-800">Quizzes & Flashcards</h1>
            <p class="text-sm text-gray-500">Practice quizzes shown to users by program access.</p>
        </div>
        <div class="flex gap-2">
            <a href="{{ route('admin.quizzes.generate.form') }}" class="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-lg font-medium">✨ Generate with AI</a>
            <a href="{{ route('admin.quizzes.create') }}" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-medium">+ Add Quiz</a>
        </div>
    </div>

    @if(session('success'))
        <div class="mb-4 bg-green-100 border border-green-300 text-green-800 px-4 py-3 rounded-lg">{{ session('success') }}</div>
    @endif

    <div class="bg-white rounded-lg shadow-md overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
                <tr>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Title</th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Program</th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Difficulty</th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Qs</th>
                    <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Status</th>
                    <th class="px-4 py-3 text-right text-xs font-semibold text-gray-500 uppercase">Actions</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
                @forelse($quizzes as $quiz)
                    <tr>
                        <td class="px-4 py-3 text-sm font-medium text-gray-800">{{ $quiz->title }}</td>
                        <td class="px-4 py-3 text-sm text-gray-600">{{ $quiz->category->title ?? 'General' }}</td>
                        <td class="px-4 py-3 text-sm capitalize text-gray-600">{{ $quiz->difficulty }}</td>
                        <td class="px-4 py-3 text-sm text-gray-600">{{ $quiz->questions_count }}</td>
                        <td class="px-4 py-3">
                            @if($quiz->is_active)
                                <span class="px-2 py-1 text-xs rounded-full bg-green-100 text-green-700">Active</span>
                            @else
                                <span class="px-2 py-1 text-xs rounded-full bg-yellow-100 text-yellow-700">Draft</span>
                            @endif
                        </td>
                        <td class="px-4 py-3 text-right">
                            <a href="{{ route('admin.quizzes.edit', $quiz->id) }}" class="text-blue-600 hover:text-blue-800 text-sm mr-3">Edit</a>
                            <form action="{{ route('admin.quizzes.destroy', $quiz->id) }}" method="POST" class="inline" onsubmit="return confirm('Delete this quiz?');">
                                @csrf @method('DELETE')
                                <button type="submit" class="text-red-600 hover:text-red-800 text-sm">Delete</button>
                            </form>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="6" class="px-4 py-8 text-center text-gray-500">No quizzes yet. Add one or generate with AI.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">{{ $quizzes->links() }}</div>
</div>
@endsection
