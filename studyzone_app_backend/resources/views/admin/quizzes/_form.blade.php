@csrf

@if($errors->any())
    <div class="mb-4 bg-red-100 border border-red-300 text-red-700 px-4 py-3 rounded-lg">
        <ul class="list-disc list-inside text-sm">
            @foreach($errors->all() as $error)<li>{{ $error }}</li>@endforeach
        </ul>
    </div>
@endif

@php $q = $quiz ?? null; @endphp

<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
    <div class="md:col-span-2">
        <label class="block text-sm font-medium text-gray-700 mb-1">Title *</label>
        <input type="text" name="title" value="{{ old('title', $q->title ?? '') }}" required
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500">
    </div>
    <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Program / Category</label>
        <select name="category_id" class="w-full px-3 py-2 border border-gray-300 rounded-lg bg-white">
            <option value="">— General (all users) —</option>
            @foreach($categoryOptions as $id => $label)
                <option value="{{ $id }}" {{ (string)old('category_id', $q->category_id ?? '') === (string)$id ? 'selected' : '' }}>{{ $label }}</option>
            @endforeach
        </select>
        <p class="mt-1 text-xs text-gray-500">Only users with access to this category will see the quiz.</p>
    </div>
    <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Placement *</label>
        <select name="scope" class="w-full px-3 py-2 border border-gray-300 rounded-lg bg-white">
            @foreach(['program' => 'Entire program — in “Test your knowledge”', 'lesson' => 'Lesson-specific — inside the category'] as $val => $lbl)
                <option value="{{ $val }}" {{ old('scope', $q->scope ?? 'program') === $val ? 'selected' : '' }}>{{ $lbl }}</option>
            @endforeach
        </select>
        <p class="mt-1 text-xs text-gray-500">Lesson-specific quizzes appear inside their category like other content (a category is required). Program quizzes appear in “Test your knowledge”. Scores count toward achievements either way.</p>
    </div>
    <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Difficulty</label>
        <select name="difficulty" class="w-full px-3 py-2 border border-gray-300 rounded-lg bg-white">
            @foreach(['easy' => 'Easy', 'medium' => 'Medium', 'hard' => 'Hard'] as $val => $lbl)
                <option value="{{ $val }}" {{ old('difficulty', $q->difficulty ?? 'medium') === $val ? 'selected' : '' }}>{{ $lbl }}</option>
            @endforeach
        </select>
    </div>
    <div class="md:col-span-2">
        <label class="block text-sm font-medium text-gray-700 mb-1">Description</label>
        <textarea name="description" rows="2"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500">{{ old('description', $q->description ?? '') }}</textarea>
    </div>
    <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Display Order</label>
        <input type="number" name="sort_order" min="0" value="{{ old('sort_order', $q->sort_order ?? 0) }}"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg">
    </div>
    <div class="flex items-end">
        <label class="flex items-center">
            <input type="checkbox" name="is_active" value="1" {{ old('is_active', $q->is_active ?? false) ? 'checked' : '' }}
                class="w-4 h-4 text-blue-600 border-gray-300 rounded">
            <span class="ml-2 text-sm text-gray-700">Active (visible in app)</span>
        </label>
    </div>
</div>

<hr class="my-6">

<div class="flex items-center justify-between mb-3">
    <h2 class="text-lg font-semibold text-gray-800">Questions</h2>
    <button type="button" onclick="addQuestion()" class="bg-gray-800 hover:bg-gray-900 text-white text-sm px-3 py-1.5 rounded-lg">+ Add Question</button>
</div>

<div id="questions"></div>

<div class="flex gap-3 mt-6">
    <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg font-medium">
        {{ isset($quiz) ? 'Save Quiz' : 'Create Quiz' }}
    </button>
    <a href="{{ route('admin.quizzes.index') }}" class="bg-gray-500 hover:bg-gray-600 text-white px-6 py-2 rounded-lg font-medium">Cancel</a>
</div>

@php
    $existing = old('questions', isset($quiz)
        ? $quiz->questions->map(fn($qq) => [
            'question' => $qq->question,
            'options' => $qq->options,
            'correct_index' => $qq->correct_index,
            'explanation' => $qq->explanation,
          ])->toArray()
        : []);
@endphp

<script>
    const OPTION_COUNT = 4;
    let qIndex = 0;

    function questionHtml(i, data) {
        data = data || {};
        const opts = data.options || [];
        const correct = (data.correct_index != null) ? Number(data.correct_index) : 0;
        const count = Math.max(OPTION_COUNT, opts.length);
        let optionRows = '';
        for (let o = 0; o < count; o++) {
            const val = opts[o] != null ? String(opts[o]).replace(/"/g, '&quot;') : '';
            optionRows += `
                <div class="flex items-center gap-2 mb-2">
                    <input type="radio" name="questions[${i}][correct_index]" value="${o}" ${correct === o ? 'checked' : ''} title="Mark correct" class="text-green-600">
                    <input type="text" name="questions[${i}][options][]" value="${val}" placeholder="Option ${String.fromCharCode(65 + o)}"
                        class="flex-1 px-3 py-1.5 border border-gray-300 rounded-lg text-sm">
                </div>`;
        }
        const qText = data.question ? String(data.question).replace(/</g, '&lt;') : '';
        const expl = data.explanation ? String(data.explanation).replace(/"/g, '&quot;') : '';
        return `
        <div class="border border-gray-200 rounded-lg p-4 mb-3 bg-gray-50" data-q>
            <div class="flex items-center justify-between mb-2">
                <span class="text-sm font-semibold text-gray-600">Question</span>
                <button type="button" onclick="this.closest('[data-q]').remove()" class="text-red-600 text-sm hover:text-red-800">Remove</button>
            </div>
            <textarea name="questions[${i}][question]" rows="2" placeholder="Question text"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm mb-3">${qText}</textarea>
            <p class="text-xs text-gray-500 mb-1">Select the radio next to the correct option.</p>
            ${optionRows}
            <input type="text" name="questions[${i}][explanation]" value="${expl}" placeholder="Explanation (optional)"
                class="w-full px-3 py-1.5 border border-gray-300 rounded-lg text-sm mt-2">
        </div>`;
    }

    function addQuestion(data) {
        document.getElementById('questions').insertAdjacentHTML('beforeend', questionHtml(qIndex, data));
        qIndex++;
    }

    // Render existing questions (or a blank one for a new quiz).
    const existingRaw = @json($existing);
    const existing = Array.isArray(existingRaw) ? existingRaw : Object.values(existingRaw || {});
    if (existing.length) {
        existing.forEach(d => addQuestion(d));
    } else {
        addQuestion();
    }
</script>
