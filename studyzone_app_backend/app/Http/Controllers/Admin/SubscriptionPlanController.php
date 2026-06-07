<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\SubscriptionPlan;
use Illuminate\Http\Request;

class SubscriptionPlanController extends Controller
{
    public function index()
    {
        $plans = SubscriptionPlan::withCount('subscriptions')
            ->orderBy('sort_order')->orderBy('id')->get();
        return view('admin.subscription-plans.index', compact('plans'));
    }

    public function create()
    {
        return view('admin.subscription-plans.create');
    }

    public function store(Request $request)
    {
        $plan = SubscriptionPlan::create($this->payload($request));

        return redirect()->route('admin.subscription-plans.index')
            ->with('success', 'Plan created.');
    }

    public function edit(string $id)
    {
        $plan = SubscriptionPlan::findOrFail($id);
        return view('admin.subscription-plans.edit', compact('plan'));
    }

    public function update(Request $request, string $id)
    {
        $plan = SubscriptionPlan::findOrFail($id);
        $plan->update($this->payload($request));

        return redirect()->route('admin.subscription-plans.index')
            ->with('success', 'Plan updated.');
    }

    public function destroy(string $id)
    {
        SubscriptionPlan::findOrFail($id)->delete();
        return redirect()->route('admin.subscription-plans.index')
            ->with('success', 'Plan deleted.');
    }

    /** Validate + shape the data, turning the features textarea into an array. */
    private function payload(Request $request): array
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'duration_days' => 'required|integer|min:1|max:3650',
            'price' => 'required|numeric|min:0',
            'currency' => 'nullable|string|max:8',
            'features' => 'nullable|string',
            'sort_order' => 'nullable|integer|min:0',
            'is_active' => 'boolean',
        ]);

        // Features: one per line → clean array.
        $features = collect(preg_split('/\r\n|\r|\n/', (string) ($data['features'] ?? '')))
            ->map(fn ($f) => trim($f))
            ->filter()
            ->values()
            ->all();

        return [
            'name' => $data['name'],
            'description' => $data['description'] ?? null,
            'duration_days' => $data['duration_days'],
            'price' => $data['price'],
            'currency' => strtoupper(trim($data['currency'] ?? 'PKR')) ?: 'PKR',
            'features' => $features,
            'sort_order' => $data['sort_order'] ?? 0,
            'is_active' => $request->has('is_active'),
        ];
    }
}
