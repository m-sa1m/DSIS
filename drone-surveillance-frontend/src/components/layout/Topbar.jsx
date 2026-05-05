import { LogOut, Radar } from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';
import Badge from '../ui/Badge';

export default function Topbar() {
  const { user, role, logout } = useAuth();

  return (
    <header className="h-14 border-b border-[#2a2a2a] bg-[#0a0a0a] flex items-center justify-between px-5 shrink-0">
      <div className="flex items-center gap-2">
        <Radar size={20} className="text-[#4a90d9]" />
        <span className="text-sm font-semibold text-white tracking-tight">Drone Surveillance</span>
      </div>
      <div className="flex items-center gap-3">
        <span className="text-sm text-[#a0a0a0]">{user?.full_name}</span>
        <Badge>{role}</Badge>
        <button
          onClick={logout}
          className="text-[#a0a0a0] hover:text-white transition-colors cursor-pointer"
          title="Logout"
        >
          <LogOut size={16} />
        </button>
      </div>
    </header>
  );
}
