<nav class="sticky top-0 z-30 border-b border-gray-200 bg-white/95 backdrop-blur">
    <div class="flex h-16 items-center justify-between px-4 sm:px-6">
        <div class="flex min-w-0 items-center">
            <button onclick="toggleSidebar()" class="mr-3 shrink-0 text-gray-500 hover:text-gray-900 lg:hidden">
                <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>
                </svg>
            </button>
            <h2 class="truncate text-lg font-semibold text-gray-800 sm:text-xl">@yield('page-title', 'Dashboard')</h2>
        </div>

        <div class="flex items-center gap-2">
            <!-- Admin profile dropdown -->
            <div class="relative">
                <button type="button" id="profileMenuButton" onclick="toggleProfileMenu(event)"
                    class="flex items-center gap-2 rounded-full py-1 pl-1 pr-2 transition-colors hover:bg-gray-100">
                    <span class="flex h-9 w-9 items-center justify-center rounded-full bg-gradient-to-br from-blue-500 to-purple-600 text-sm font-bold text-white shadow">
                        {{ strtoupper(substr(Auth::user()->name, 0, 1)) }}
                    </span>
                    <span class="hidden text-left leading-tight sm:block">
                        <span class="block max-w-[10rem] truncate text-sm font-semibold text-gray-800">{{ Auth::user()->name }}</span>
                        <span class="block text-xs text-gray-500">Administrator</span>
                    </span>
                    <svg class="hidden h-4 w-4 text-gray-400 sm:block" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
                    </svg>
                </button>

                <div id="profileMenu" class="absolute right-0 z-50 mt-2 hidden w-60 origin-top-right overflow-hidden rounded-xl border border-gray-200 bg-white shadow-lg">
                    <div class="border-b border-gray-100 px-4 py-3">
                        <p class="truncate text-sm font-semibold text-gray-800">{{ Auth::user()->name }}</p>
                        <p class="truncate text-xs text-gray-500">{{ Auth::user()->email }}</p>
                    </div>
                    <a href="{{ route('admin.profile.edit') }}" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50">
                        <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path></svg>
                        My Profile
                    </a>
                    <a href="{{ route('admin.settings.index') }}" class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50">
                        <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                        App Settings
                    </a>
                    <div class="border-t border-gray-100">
                        <form method="POST" action="{{ route('admin.logout') }}">
                            @csrf
                            <button type="submit" class="flex w-full items-center gap-3 px-4 py-2.5 text-sm font-medium text-red-600 hover:bg-red-50">
                                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"></path></svg>
                                Logout
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</nav>

<script>
    function toggleProfileMenu(e) {
        e.stopPropagation();
        document.getElementById('profileMenu').classList.toggle('hidden');
    }
    document.addEventListener('click', function (e) {
        const menu = document.getElementById('profileMenu');
        const btn = document.getElementById('profileMenuButton');
        if (menu && !menu.classList.contains('hidden') && !menu.contains(e.target) && !btn.contains(e.target)) {
            menu.classList.add('hidden');
        }
    });
</script>
