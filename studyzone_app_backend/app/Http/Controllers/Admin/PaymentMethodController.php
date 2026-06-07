<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\PaymentMethod;
use Illuminate\Http\Request;

class PaymentMethodController extends Controller
{
    public function index()
    {
        $methods = PaymentMethod::orderBy('sort_order')->orderBy('id')->get();
        return view('admin.payment-methods.index', compact('methods'));
    }

    public function create()
    {
        return view('admin.payment-methods.create');
    }

    public function store(Request $request)
    {
        $data = $this->validateData($request);
        $data['is_active'] = $request->has('is_active');
        PaymentMethod::create($data);

        return redirect()->route('admin.payment-methods.index')
            ->with('success', 'Payment method added.');
    }

    public function edit(string $id)
    {
        $method = PaymentMethod::findOrFail($id);
        return view('admin.payment-methods.edit', compact('method'));
    }

    public function update(Request $request, string $id)
    {
        $method = PaymentMethod::findOrFail($id);
        $data = $this->validateData($request);
        $data['is_active'] = $request->has('is_active');
        $method->update($data);

        return redirect()->route('admin.payment-methods.index')
            ->with('success', 'Payment method updated.');
    }

    public function destroy(string $id)
    {
        PaymentMethod::findOrFail($id)->delete();
        return redirect()->route('admin.payment-methods.index')
            ->with('success', 'Payment method deleted.');
    }

    private function validateData(Request $request): array
    {
        return $request->validate([
            'name' => 'required|string|max:255',
            'type' => 'required|in:bank,easypaisa,jazzcash,other',
            'account_title' => 'nullable|string|max:255',
            'account_number' => 'nullable|string|max:255',
            'instructions' => 'nullable|string',
            'sort_order' => 'nullable|integer|min:0',
            'is_active' => 'boolean',
        ]);
    }
}
