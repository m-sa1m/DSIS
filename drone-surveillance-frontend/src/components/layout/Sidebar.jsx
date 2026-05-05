import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  Users,
  Plane,
  MapPin,
  ClipboardList,
  Crosshair,
  Bell,
  FileText,
  BarChart3,
  ScrollText,
} from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';

const navItems = {
  Admin: [
    { to: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { to: '/users', label: 'Users', icon: Users },
    { to: '/drones', label: 'Drones', icon: Plane },
    { to: '/zones', label: 'Zones', icon: MapPin },
    { to: '/reports', label: 'Reports', icon: BarChart3 },
    { to: '/audit', label: 'Audit Log', icon: ScrollText },
  ],
  Operator: [
    { to: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { to: '/missions', label: 'Missions', icon: ClipboardList },
    { to: '/drones', label: 'Drones', icon: Plane },
    { to: '/detections', label: 'Detections', icon: Crosshair },
  ],
  Analyst: [
    { to: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { to: '/alerts', label: 'Alerts', icon: Bell },
    { to: '/incidents', label: 'Incidents', icon: FileText },
    { to: '/reports', label: 'Reports', icon: BarChart3 },
  ],
};

export default function Sidebar() {
  const { role } = useAuth();
  const items = navItems[role] || [];

  return (
    <aside className="w-52 border-r border-[#2a2a2a] bg-[#0a0a0a] shrink-0 py-4">
      <nav className="flex flex-col gap-0.5 px-2">
        {items.map(({ to, label, icon: Icon }) => (
          <NavLink
            key={to}
            to={to}
            className={({ isActive }) =>
              `flex items-center gap-2.5 px-3 py-2 rounded-md text-sm transition-colors ${
                isActive
                  ? 'bg-[#4a90d9]/10 text-[#4a90d9]'
                  : 'text-[#a0a0a0] hover:text-white hover:bg-[#1a1a1a]'
              }`
            }
          >
            <Icon size={16} />
            {label}
          </NavLink>
        ))}
      </nav>
    </aside>
  );
}
