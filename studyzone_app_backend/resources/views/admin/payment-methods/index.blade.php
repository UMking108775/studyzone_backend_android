@extends('admin.layouts.app')

@section('title', 'Payment Methods')
@section('page-title', 'Payment Methods')

@section('content')
<div class="space-y-6">
    <div class="flex justify-between items-center">
        <div>
            <h2 class="text-2xl font-bold text-gray-900">Payment Methods</h2>
            <p class="text-sm text-gray-500 mt-1">Accounts users send subscription payments to (bank, EasyPaisa, JazzCash …).</p>
        </div>
        <a href="{{ route('admin.payment-methods.create') }}" class="inline-flex items-center px-4 py-2 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700">
            <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
            Add Method
        </a>
    </div>

    @if(session('success'))
        <div class="bg-green-100 border border-green-300 text-green-800 px-4 py-3 rounded-lg">{{ session('success') }}</div>
    @endif

    <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
                <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Account</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                    <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th>
                </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
                @forelse($methods as $m)
                    <tr class="hover:bg-gray-50">
                        <td class="px-6 py-4 text-sm font-medium text-gray-900">{{ $m->name }}</td>
                        <td class="px-6 py-4"><span class="px-2.5 py-0.5 rounded-full text-xs bg-gray-100 text-gray-700">{{ ucfirst($m->type) }}</span></td>
                        <td class="px-6 py-4 text-sm text-gray-700">
                            <div>{{ $m->account_title }}</div>
                            <div class="text-xs text-gray-500">{{ $m->account_number }}</div>
                        </td>
                        <td class="px-6 py-4">
                            @if($m->is_active)
                                <span class="px-2.5 py-0.5 rounded-full text-xs bg-green-100 text-green-800">Active</span>
                            @else
                                <span class="px-2.5 py-0.5 rounded-full text-xs bg-gray-100 text-gray-600">Hidden</span>
                            @endif
                        </td>
                        <td class="px-6 py-4 text-right text-sm">
                            <div class="flex items-center justify-end gap-3">
                                <a href="{{ route('admin.payment-methods.edit', $m->id) }}" class="text-blue-600 hover:text-blue-900">Edit</a>
                                <form action="{{ route('admin.payment-methods.destroy', $m->id) }}" method="POST" onsubmit="return confirm('Delete this payment method?');">
                                    @csrf @method('DELETE')
                                    <button type="submit" class="text-red-600 hover:text-red-900">Delete</button>
                                </form>
                            </div>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="5" class="px-6 py-10 text-center text-sm text-gray-500">No payment methods yet.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection
