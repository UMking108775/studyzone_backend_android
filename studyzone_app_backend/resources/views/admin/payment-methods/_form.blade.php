@csrf
@if($errors->any())
    <div class="mb-4 bg-red-100 border border-red-300 text-red-700 px-4 py-3 rounded-lg">
        <ul class="list-disc list-inside text-sm">
            @foreach($errors->all() as $error)<li>{{ $error }}</li>@endforeach
        </ul>
    </div>
@endif

@php $m = $method ?? null; @endphp

<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
    <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Name *</label>
        <input type="text" name="name" value="{{ old('name', $m->name ?? '') }}" required placeholder="e.g. EasyPaisa, HBL Bank"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg">
    </div>
    <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Type *</label>
        <select name="type" class="w-full px-3 py-2 border border-gray-300 rounded-lg bg-white">
            @foreach(['bank' => 'Bank', 'easypaisa' => 'EasyPaisa', 'jazzcash' => 'JazzCash', 'other' => 'Other'] as $val => $lbl)
                <option value="{{ $val }}" {{ old('type', $m->type ?? 'bank') === $val ? 'selected' : '' }}>{{ $lbl }}</option>
            @endforeach
        </select>
    </div>
    <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Account Title</label>
        <input type="text" name="account_title" value="{{ old('account_title', $m->account_title ?? '') }}" placeholder="Account holder name"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg">
    </div>
    <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Account Number / IBAN / Mobile</label>
        <input type="text" name="account_number" value="{{ old('account_number', $m->account_number ?? '') }}" placeholder="e.g. 03XX-XXXXXXX or IBAN"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg">
    </div>
    <div class="md:col-span-2">
        <label class="block text-sm font-medium text-gray-700 mb-1">Instructions (optional)</label>
        <textarea name="instructions" rows="3" placeholder="Any notes for the user (e.g. send screenshot after transfer)"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg">{{ old('instructions', $m->instructions ?? '') }}</textarea>
    </div>
    <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Display Order</label>
        <input type="number" name="sort_order" min="0" value="{{ old('sort_order', $m->sort_order ?? 0) }}"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg">
    </div>
    <div class="flex items-end">
        <label class="flex items-center">
            <input type="checkbox" name="is_active" value="1" {{ old('is_active', $m->is_active ?? true) ? 'checked' : '' }}
                class="w-4 h-4 text-blue-600 border-gray-300 rounded">
            <span class="ml-2 text-sm text-gray-700">Active (shown to users)</span>
        </label>
    </div>
</div>

<div class="flex gap-3 mt-6">
    <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg font-medium">{{ isset($method) ? 'Save' : 'Add Method' }}</button>
    <a href="{{ route('admin.payment-methods.index') }}" class="bg-gray-500 hover:bg-gray-600 text-white px-6 py-2 rounded-lg font-medium">Cancel</a>
</div>
