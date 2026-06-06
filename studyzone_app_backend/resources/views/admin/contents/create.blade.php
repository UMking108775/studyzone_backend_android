@extends('admin.layouts.app')

@section('title', 'Add Content')
@section('page-title', 'Add Content')

@section('content')
<link href="https://cdn.jsdelivr.net/npm/quill@2.0.3/dist/quill.snow.css" rel="stylesheet">
<div class="max-w-3xl">
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h2 class="text-2xl font-bold text-gray-900 mb-6">Add New Content</h2>

        <form action="{{ route('admin.contents.store') }}" method="POST" class="space-y-6" id="content-form">
            @csrf

            <!-- Category Selection (any level) -->
            <div>
                <label for="category_id" class="block text-sm font-medium text-gray-700 mb-2">
                    Select Category <span class="text-red-500">*</span>
                </label>
                <select id="category_id" name="category_id" required
                    class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent @error('category_id') border-red-500 @enderror">
                    <option value="">Choose a category...</option>
                    @foreach($categories as $category)
                        <option value="{{ $category['id'] }}" {{ (string)old('category_id', $selectedCategoryId ?? '') === (string)$category['id'] ? 'selected' : '' }}>
                            {{ $category['title'] }}
                        </option>
                    @endforeach
                </select>
                <p class="mt-1 text-xs text-gray-500">You can attach content to a category at any level.</p>
                @error('category_id')<p class="mt-1 text-sm text-red-600">{{ $message }}</p>@enderror
            </div>

            <!-- Content Type -->
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">
                    Content Type <span class="text-red-500">*</span>
                </label>
                <div class="grid grid-cols-2 gap-3" id="content-type-container">
                    @php
                        $types = [
                            ['v' => 'pdf', 'label' => 'PDF', 'desc' => 'Document file', 'bg' => 'bg-red-100', 'fg' => 'text-red-600'],
                            ['v' => 'audio', 'label' => 'Audio', 'desc' => 'Audio file', 'bg' => 'bg-purple-100', 'fg' => 'text-purple-600'],
                            ['v' => 'video', 'label' => 'Video', 'desc' => 'Video URL / file', 'bg' => 'bg-blue-100', 'fg' => 'text-blue-600'],
                            ['v' => 'rich_text', 'label' => 'Rich Text', 'desc' => 'Article (e.g. fee structure)', 'bg' => 'bg-green-100', 'fg' => 'text-green-600'],
                        ];
                        $current = old('content_type', 'pdf');
                    @endphp
                    @foreach($types as $t)
                        <label class="content-type-option relative flex items-center p-4 border-2 rounded-lg cursor-pointer transition-colors {{ $current == $t['v'] ? 'border-blue-500 bg-blue-50' : 'border-gray-200 hover:border-blue-300' }}">
                            <input type="radio" name="content_type" value="{{ $t['v'] }}" {{ $current == $t['v'] ? 'checked' : '' }} class="sr-only content-type-radio" required>
                            <div class="flex items-center">
                                <div class="{{ $t['bg'] }} rounded-lg p-3 mr-3">
                                    <svg class="w-6 h-6 {{ $t['fg'] }}" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M4 4a2 2 0 012-2h8a2 2 0 012 2v12a2 2 0 01-2 2H6a2 2 0 01-2-2V4zm3 1h6v2H7V5zm0 4h6v2H7V9zm0 4h4v2H7v-2z" clip-rule="evenodd"></path></svg>
                                </div>
                                <div>
                                    <div class="font-medium text-gray-900">{{ $t['label'] }}</div>
                                    <div class="text-sm text-gray-500">{{ $t['desc'] }}</div>
                                </div>
                            </div>
                        </label>
                    @endforeach
                </div>
                @error('content_type')<p class="mt-1 text-sm text-red-600">{{ $message }}</p>@enderror
            </div>

            <!-- Media URL (pdf / audio / video) -->
            <div id="media-url-section">
                <label for="backblaze_url" class="block text-sm font-medium text-gray-700 mb-2">
                    Media URL <span class="text-red-500">*</span>
                </label>
                <input type="url" id="backblaze_url" name="backblaze_url" value="{{ old('backblaze_url') }}"
                    placeholder="https://..."
                    class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent @error('backblaze_url') border-red-500 @enderror">
                <p class="mt-1 text-xs text-gray-500">Full URL of the PDF / audio / video file (e.g. Backblaze, YouTube, etc.).</p>
                @error('backblaze_url')<p class="mt-1 text-sm text-red-600">{{ $message }}</p>@enderror
            </div>

            <!-- Rich Text (rich_text) -->
            <div id="richtext-section" class="hidden">
                <label class="block text-sm font-medium text-gray-700 mb-2">
                    Content <span class="text-red-500">*</span>
                </label>
                <div id="editor" class="bg-white" style="min-height: 220px;"></div>
                <input type="hidden" name="body" id="body-input" value="{{ old('body') }}">
                <p class="mt-1 text-xs text-gray-500">Write the article (used for pages like admission / fee structure).</p>
                @error('body')<p class="mt-1 text-sm text-red-600">{{ $message }}</p>@enderror
            </div>

            <!-- Title -->
            <div>
                <label for="title" class="block text-sm font-medium text-gray-700 mb-2">
                    Content Title <span class="text-red-500">*</span>
                </label>
                <input type="text" id="title" name="title" value="{{ old('title') }}" required
                    placeholder="Enter content title"
                    class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent @error('title') border-red-500 @enderror">
                @error('title')<p class="mt-1 text-sm text-red-600">{{ $message }}</p>@enderror
            </div>

            <!-- Active Status -->
            <div class="flex items-center">
                <input type="checkbox" id="is_active" name="is_active" value="1" {{ old('is_active', true) ? 'checked' : '' }}
                    class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded">
                <label for="is_active" class="ml-2 block text-sm text-gray-700">Active (Content will be visible in the app)</label>
            </div>

            <div class="flex items-center justify-end space-x-4 pt-4 border-t border-gray-200">
                <a href="{{ route('admin.contents.index') }}" class="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors">Cancel</a>
                <button type="submit" class="px-6 py-2 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 transition-colors">Add Content</button>
            </div>
        </form>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/quill@2.0.3/dist/quill.js"></script>
<script>
    document.addEventListener('DOMContentLoaded', function () {
        const radios = document.querySelectorAll('.content-type-radio');
        const options = document.querySelectorAll('.content-type-option');
        const mediaSection = document.getElementById('media-url-section');
        const richSection = document.getElementById('richtext-section');
        const urlInput = document.getElementById('backblaze_url');

        // Rich text editor
        const quill = new Quill('#editor', {
            theme: 'snow',
            modules: {
                toolbar: [
                    [{ header: [1, 2, 3, false] }],
                    ['bold', 'italic', 'underline'],
                    [{ list: 'ordered' }, { list: 'bullet' }],
                    ['link', 'blockquote'],
                    ['clean'],
                ],
            },
        });
        const bodyInput = document.getElementById('body-input');
        if (bodyInput.value) quill.root.innerHTML = bodyInput.value;

        function applyType(type) {
            const isRich = type === 'rich_text';
            richSection.classList.toggle('hidden', !isRich);
            mediaSection.classList.toggle('hidden', isRich);
            urlInput.required = !isRich;
        }

        radios.forEach(function (radio) {
            radio.addEventListener('change', function () {
                options.forEach(function (o) {
                    o.classList.remove('border-blue-500', 'bg-blue-50');
                    o.classList.add('border-gray-200');
                });
                const sel = this.closest('.content-type-option');
                if (sel) { sel.classList.add('border-blue-500', 'bg-blue-50'); sel.classList.remove('border-gray-200'); }
                applyType(this.value);
            });
        });

        const checked = document.querySelector('.content-type-radio:checked');
        if (checked) applyType(checked.value);

        document.getElementById('content-form').addEventListener('submit', function () {
            bodyInput.value = quill.root.innerHTML;
        });
    });
</script>
@endsection
