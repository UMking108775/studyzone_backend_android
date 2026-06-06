<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class ProfileController extends Controller
{
    /** Show the admin's profile form. */
    public function edit(Request $request)
    {
        return view('admin.profile.edit', ['admin' => $request->user()]);
    }

    /** Update name / email, and optionally the password. */
    public function update(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => ['required', 'email', 'max:255', Rule::unique('users', 'email')->ignore($user->id)],
        ]);

        $user->name = $validated['name'];
        $user->email = $validated['email'];

        // Password change is optional; when requested, require the current one.
        if ($request->filled('password')) {
            $request->validate([
                'current_password' => 'required',
                'password' => 'required|string|min:8|confirmed',
            ], [
                'current_password.required' => 'Enter your current password to set a new one.',
            ]);

            if (!Hash::check($request->current_password, $user->password)) {
                return back()->withErrors(['current_password' => 'Your current password is incorrect.']);
            }

            $user->password = Hash::make($request->password);
        }

        $user->save();

        return redirect()->route('admin.profile.edit')->with('success', 'Profile updated successfully.');
    }
}
