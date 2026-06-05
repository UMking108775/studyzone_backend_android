@csrf

@if($errors->any())
    <div class="mb-4 bg-red-100 border border-red-300 text-red-700 px-4 py-3 rounded-lg">
        <ul class="list-disc list-inside text-sm">
            @foreach($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif

<div class="mb-4">
    <label class="block text-sm font-medium text-gray-700 mb-2">Title</label>
    <input type="text" name="title" value="{{ old('title', $banner->title ?? '') }}"
        class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
        placeholder="e.g. Welcome to Study Zone">
</div>

<div class="mb-4">
    <label class="block text-sm font-medium text-gray-700 mb-2">Subtitle</label>
    <input type="text" name="subtitle" value="{{ old('subtitle', $banner->subtitle ?? '') }}"
        class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
        placeholder="e.g. New past papers available">
</div>

@if(isset($banner) && $banner->image_url)
    <div class="mb-2">
        <span class="block text-sm font-medium text-gray-700 mb-2">Current image</span>
        <img src="{{ $banner->image_url }}" alt="" class="w-full max-w-md h-32 object-cover rounded-lg border border-gray-200">
    </div>
@endif

<div class="mb-4">
    <label class="block text-sm font-medium text-gray-700 mb-2">
        Image {{ isset($banner) ? '(upload to replace)' : '*' }}
    </label>
    <input type="file" name="image" accept="image/*"
        class="w-full px-4 py-2 border border-gray-300 rounded-lg bg-white">
    <p class="mt-1 text-xs text-gray-500">JPG/PNG/WebP, up to 4&nbsp;MB. Recommended ~1000×420.</p>
</div>

<div class="mb-4">
    <label class="block text-sm font-medium text-gray-700 mb-2">…or Image URL</label>
    <input type="url" name="image_url" value="{{ old('image_url') }}"
        class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
        placeholder="https://…/banner.jpg">
    <p class="mt-1 text-xs text-gray-500">Use this instead of uploading a file.</p>
</div>

<div class="mb-4">
    <label class="block text-sm font-medium text-gray-700 mb-2">Link URL (optional)</label>
    <input type="url" name="link_url" value="{{ old('link_url', $banner->link_url ?? '') }}"
        class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
        placeholder="https://… (opens when the banner is tapped)">
</div>

<div class="mb-4">
    <label class="block text-sm font-medium text-gray-700 mb-2">Display Order</label>
    <input type="number" name="sort_order" min="0" value="{{ old('sort_order', $banner->sort_order ?? 0) }}"
        class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500">
    <p class="mt-1 text-xs text-gray-500">Lower numbers appear first.</p>
</div>

<div class="mb-6">
    <label class="flex items-center">
        <input type="checkbox" name="is_active" value="1"
            {{ old('is_active', $banner->is_active ?? true) ? 'checked' : '' }}
            class="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500">
        <span class="ml-2 text-sm text-gray-700">Active (visible in the app)</span>
    </label>
</div>

<div class="flex gap-3">
    <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg font-medium">
        {{ isset($banner) ? 'Save Changes' : 'Create Banner' }}
    </button>
    <a href="{{ route('admin.banners.index') }}" class="bg-gray-500 hover:bg-gray-600 text-white px-6 py-2 rounded-lg font-medium">
        Cancel
    </a>
</div>
