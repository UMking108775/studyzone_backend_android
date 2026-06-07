@csrf
@if($errors->any())
    <div class="mb-4 bg-red-100 border border-red-300 text-red-700 px-4 py-3 rounded-lg">
        <ul class="list-disc list-inside text-sm">
            @foreach($errors->all() as $error)<li>{{ $error }}</li>@endforeach
        </ul>
    </div>
@endif

@php
    $p = $plan ?? null;
    $featuresText = old('features', isset($plan) ? implode("\n", $plan->features ?? []) : '');
@endphp

<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
    <div class="md:col-span-2">
        <label class="block text-sm font-medium text-gray-700 mb-1">Plan Name *</label>
        <input type="text" name="name" value="{{ old('name', $p->name ?? '') }}" required placeholder="e.g. Monthly, 3 Months, Yearly"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg">
    </div>
    <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Duration (days) *</label>
        <input type="number" name="duration_days" min="1" value="{{ old('duration_days', $p->duration_days ?? 30) }}" required
            class="w-full px-3 py-2 border border-gray-300 rounded-lg">
        <p class="mt-1 text-xs text-gray-500">e.g. 30 = monthly, 90 = 3 months, 365 = yearly.</p>
    </div>
    <div class="grid grid-cols-3 gap-2">
        <div class="col-span-2">
            <label class="block text-sm font-medium text-gray-700 mb-1">Price *</label>
            <input type="number" step="0.01" min="0" name="price" value="{{ old('price', $p->price ?? '') }}" required
                class="w-full px-3 py-2 border border-gray-300 rounded-lg">
        </div>
        <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Currency</label>
            <input type="text" name="currency" value="{{ old('currency', $p->currency ?? 'PKR') }}" maxlength="8"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg">
        </div>
    </div>
    <div class="md:col-span-2">
        <label class="block text-sm font-medium text-gray-700 mb-1">Short Description</label>
        <textarea name="description" rows="2" placeholder="One line about this plan"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg">{{ old('description', $p->description ?? '') }}</textarea>
    </div>
    <div class="md:col-span-2">
        <label class="block text-sm font-medium text-gray-700 mb-1">Features — what the user gets</label>
        <textarea name="features" rows="5" placeholder="One feature per line, e.g.&#10;Full access to all locked content&#10;Download PDFs &amp; audio&#10;All quizzes"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg">{{ $featuresText }}</textarea>
        <p class="mt-1 text-xs text-gray-500">One feature per line. Shown to the user on the plan card.</p>
    </div>
    <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Display Order</label>
        <input type="number" name="sort_order" min="0" value="{{ old('sort_order', $p->sort_order ?? 0) }}"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg">
    </div>
    <div class="flex items-end">
        <label class="flex items-center">
            <input type="checkbox" name="is_active" value="1" {{ old('is_active', $p->is_active ?? true) ? 'checked' : '' }}
                class="w-4 h-4 text-blue-600 border-gray-300 rounded">
            <span class="ml-2 text-sm text-gray-700">Active (offered to users)</span>
        </label>
    </div>
</div>

<div class="flex gap-3 mt-6">
    <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg font-medium">{{ isset($plan) ? 'Save Plan' : 'Create Plan' }}</button>
    <a href="{{ route('admin.subscription-plans.index') }}" class="bg-gray-500 hover:bg-gray-600 text-white px-6 py-2 rounded-lg font-medium">Cancel</a>
</div>
