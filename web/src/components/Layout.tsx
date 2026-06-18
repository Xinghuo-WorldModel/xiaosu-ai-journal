import { Outlet, NavLink } from 'react-router-dom'

export default function Layout() {
  return (
    <div className="min-h-screen bg-warm-50 flex flex-col max-w-md mx-auto relative">
      <header className="sticky top-0 z-10 bg-white/80 backdrop-blur-md border-b border-warm-100 px-4 py-3">
        <h1 className="text-center text-lg font-semibold text-warm-700">
          🍪 小酥
        </h1>
      </header>

      <main className="flex-1 overflow-y-auto pb-20">
        <Outlet />
      </main>

      <nav className="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-md bg-white/90 backdrop-blur-md border-t border-warm-100">
        <div className="flex justify-around py-2">
          <NavItem to="/chat" icon="💬" label="聊天" />
          <NavItem to="/diary" icon="📖" label="日记" />
          <NavItem to="/search" icon="🔍" label="搜索" />
        </div>
      </nav>
    </div>
  )
}

function NavItem({ to, icon, label }: { to: string; icon: string; label: string }) {
  return (
    <NavLink
      to={to}
      className={({ isActive }) =>
        `flex flex-col items-center gap-0.5 px-4 py-1 rounded-lg transition-colors ${
          isActive ? 'text-warm-500' : 'text-warm-700/50 hover:text-warm-700'
        }`
      }
    >
      <span className="text-xl">{icon}</span>
      <span className="text-xs">{label}</span>
    </NavLink>
  )
}
