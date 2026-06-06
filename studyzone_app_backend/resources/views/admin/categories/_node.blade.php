{{-- Recursive category tree node. Expects: $category, $depth --}}
<div class="border-b border-gray-100">
    <div class="flex items-center gap-3 px-4 py-3 hover:bg-gray-50" style="padding-left: {{ 16 + $depth * 26 }}px;">
        @if($depth > 0)
            <span class="text-gray-300 select-none -ml-3">&#9492;&#9472;</span>
        @endif

        {{-- Thumbnail --}}
        @if($category->image)
            <img src="{{ asset('storage/' . $category->image) }}" alt="" class="w-10 h-10 rounded object-cover border border-gray-200 shrink-0">
        @else
            <div class="w-10 h-10 rounded bg-gray-100 flex items-center justify-center text-gray-400 shrink-0">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"></path>
                </svg>
            </div>
        @endif

        {{-- Title + meta --}}
        <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 flex-wrap">
                <span class="text-sm font-medium text-gray-900">{{ $category->title }}</span>
                <span class="text-[10px] font-semibold px-1.5 py-0.5 rounded bg-gray-100 text-gray-600">L{{ $category->level }}</span>
                @if(!$category->is_active)
                    <span class="text-[10px] font-semibold px-1.5 py-0.5 rounded bg-red-100 text-red-700">Inactive</span>
                @endif
            </div>
            <div class="text-xs text-gray-500 mt-0.5">
                {{ $category->children_count }} sub-categories &middot;
                <a href="{{ route('admin.contents.index', ['category_id' => $category->id]) }}" class="text-blue-600 hover:underline">{{ $category->contents_count }} materials</a>
            </div>
        </div>

        {{-- Actions --}}
        <div class="flex items-center gap-1 shrink-0">
            <a href="{{ route('admin.contents.index', ['category_id' => $category->id]) }}"
               class="p-1.5 text-gray-500 hover:bg-gray-100 rounded-lg" title="View content in this category">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"></path></svg>
            </a>
            <a href="{{ route('admin.contents.create', ['category_id' => $category->id]) }}"
               class="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs font-medium text-indigo-700 bg-indigo-50 hover:bg-indigo-100 rounded-lg" title="Add material to this category">
                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
                Material
            </a>
            <a href="{{ route('admin.categories.create', ['parent_id' => $category->id]) }}"
               class="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs font-medium text-green-700 bg-green-50 hover:bg-green-100 rounded-lg" title="Add sub-category">
                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
                Sub
            </a>
            <a href="{{ route('admin.categories.edit', $category->id) }}" class="p-1.5 text-blue-600 hover:bg-blue-50 rounded-lg" title="Edit">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path></svg>
            </a>
            <form action="{{ route('admin.categories.destroy', $category->id) }}" method="POST" class="inline" onsubmit="return confirm('Delete this category? You must remove its sub-categories first.');">
                @csrf
                @method('DELETE')
                <button type="submit" class="p-1.5 text-red-600 hover:bg-red-50 rounded-lg" title="Delete">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                </button>
            </form>
        </div>
    </div>

    {{-- Children (recursive, any depth) --}}
    @foreach($category->childrenRecursiveAdmin as $child)
        @include('admin.categories._node', ['category' => $child, 'depth' => $depth + 1])
    @endforeach
</div>
