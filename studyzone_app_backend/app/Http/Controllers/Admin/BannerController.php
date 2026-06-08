<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Banner;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class BannerController extends Controller
{
    public function index()
    {
        $banners = Banner::orderBy('sort_order')->orderByDesc('id')->paginate(15);
        return view('admin.banners.index', compact('banners'));
    }

    public function create()
    {
        return view('admin.banners.create');
    }

    public function store(Request $request)
    {
        $data = $this->validateBanner($request);

        if (!$request->hasFile('image') && !$request->filled('image_url')) {
            return back()
                ->withErrors(['image' => 'Upload an image or provide an image URL.'])
                ->withInput();
        }

        $data['image_url'] = $this->resolveImageUrl($request, null);
        $data['is_active'] = $request->has('is_active');
        $data['sort_order'] = $data['sort_order'] ?? 0;

        Banner::create($data);

        return redirect()->route('admin.banners.index')
            ->with('success', 'Banner created successfully!');
    }

    public function edit(string $id)
    {
        $banner = Banner::findOrFail($id);
        return view('admin.banners.edit', compact('banner'));
    }

    public function update(Request $request, string $id)
    {
        $banner = Banner::findOrFail($id);

        $data = $this->validateBanner($request);
        $data['image_url'] = $this->resolveImageUrl($request, $banner->image_url);
        $data['is_active'] = $request->has('is_active');
        $data['sort_order'] = $data['sort_order'] ?? $banner->sort_order;

        $banner->update($data);

        return redirect()->route('admin.banners.index')
            ->with('success', 'Banner updated successfully!');
    }

    public function destroy(string $id)
    {
        Banner::findOrFail($id)->delete();

        return redirect()->route('admin.banners.index')
            ->with('success', 'Banner deleted successfully!');
    }

    /**
     * Quick enable/disable from the list — show or hide this banner in the app
     * without opening the full edit form. The app's API only serves active
     * banners, so hiding one removes it from the home slider immediately.
     */
    public function toggle(string $id)
    {
        $banner = Banner::findOrFail($id);
        $banner->update(['is_active' => ! $banner->is_active]);

        return redirect()->route('admin.banners.index')
            ->with('success', $banner->is_active
                ? 'Banner is now visible in the app.'
                : 'Banner is now hidden from the app.');
    }

    private function validateBanner(Request $request): array
    {
        return $request->validate([
            'title' => 'nullable|string|max:255',
            'subtitle' => 'nullable|string|max:255',
            'image' => 'nullable|image|mimes:jpeg,jpg,png,webp|max:4096',
            'image_url' => 'nullable|url',
            'link_url' => 'nullable|url',
            'sort_order' => 'nullable|integer|min:0',
            'is_active' => 'boolean',
        ]);
    }

    /**
     * Use the uploaded file if present, otherwise the pasted URL, otherwise keep
     * the existing value.
     */
    private function resolveImageUrl(Request $request, ?string $existing): string
    {
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('banners', 'public');
            return Storage::disk('public')->url($path);
        }
        if ($request->filled('image_url')) {
            return $request->input('image_url');
        }
        return $existing ?? '';
    }
}
