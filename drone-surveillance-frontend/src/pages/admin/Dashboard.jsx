import { useState, useEffect } from 'react';
import { Plane, ClipboardList, FileText, Bell } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import Card from '../../components/ui/Card';
import Spinner from '../../components/ui/Spinner';
import { getDrones } from '../../api/drones.api';
import { getMissions } from '../../api/missions.api';
import { getIncidents } from '../../api/incidents.api';
import { getAlerts } from '../../api/alerts.api';
import { getAlertTrends, getDroneUtilization } from '../../api/reports.api';

function StatCard({ icon: Icon, label, value, color }) {
  return (
    <Card>
      <div className="flex items-center gap-3">
        <div className={`p-2 rounded-md ${color}`}>
          <Icon size={18} />
        </div>
        <div>
          <p className="text-xs text-[#a0a0a0]">{label}</p>
          <p className="text-xl font-semibold text-white">{value}</p>
        </div>
      </div>
    </Card>
  );
}

export default function AdminDashboard() {
  const [stats, setStats] = useState({ drones: 0, missions: 0, incidents: 0, alerts: 0 });
  const [alertData, setAlertData] = useState([]);
  const [droneData, setDroneData] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      getDrones(),
      getMissions(),
      getIncidents(),
      getAlerts(),
      getAlertTrends(),
      getDroneUtilization(),
    ])
      .then(([dronesRes, missionsRes, incidentsRes, alertsRes, trendsRes, utilRes]) => {
        const drones = dronesRes.data.data;
        const missions = missionsRes.data.data;
        const incidents = incidentsRes.data.data;
        const alerts = alertsRes.data.data;

        setStats({
          drones: drones.filter((d) => d.status === 'Active').length,
          missions: missions.filter((m) => m.mission_status === 'In Progress').length,
          incidents: incidents.filter((i) => i.incident_status === 'Open').length,
          alerts: alerts.filter((a) => a.alert_status === 'New').length,
        });

        const trendRows = trendsRes.data.data;
        const months = [...new Set(trendRows.map((r) => r.month))].sort();
        const chartData = months.map((m) => {
          const row = { month: m };
          trendRows.filter((r) => r.month === m).forEach((r) => {
            row[r.severity] = r.alert_count;
          });
          return row;
        });
        setAlertData(chartData);
        setDroneData(utilRes.data.data);
      })
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <Spinner />;

  return (
    <div className="space-y-6">
      <h1 className="text-lg font-semibold text-white">Admin Dashboard</h1>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard icon={Plane} label="Active Drones" value={stats.drones} color="bg-[#4a90d9]/10 text-[#4a90d9]" />
        <StatCard icon={ClipboardList} label="Active Missions" value={stats.missions} color="bg-amber-400/10 text-amber-400" />
        <StatCard icon={FileText} label="Open Incidents" value={stats.incidents} color="bg-red-400/10 text-red-400" />
        <StatCard icon={Bell} label="New Alerts" value={stats.alerts} color="bg-emerald-400/10 text-emerald-400" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card>
          <h2 className="text-sm font-medium text-[#a0a0a0] mb-4">Alert Trends by Severity</h2>
          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={alertData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#2a2a2a" />
              <XAxis dataKey="month" tick={{ fill: '#a0a0a0', fontSize: 12 }} />
              <YAxis tick={{ fill: '#a0a0a0', fontSize: 12 }} />
              <Tooltip contentStyle={{ background: '#1a1a1a', border: '1px solid #2a2a2a', borderRadius: 6, color: '#fff' }} />
              <Legend wrapperStyle={{ fontSize: 12, color: '#a0a0a0' }} />
              <Bar dataKey="Critical" fill="#ef4444" radius={[2, 2, 0, 0]} />
              <Bar dataKey="High" fill="#f97316" radius={[2, 2, 0, 0]} />
              <Bar dataKey="Medium" fill="#4a90d9" radius={[2, 2, 0, 0]} />
              <Bar dataKey="Low" fill="#64748b" radius={[2, 2, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </Card>

        <Card>
          <h2 className="text-sm font-medium text-[#a0a0a0] mb-4">Drone Utilization (Flight Minutes)</h2>
          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={droneData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#2a2a2a" />
              <XAxis dataKey="drone_name" tick={{ fill: '#a0a0a0', fontSize: 10 }} angle={-20} textAnchor="end" height={60} />
              <YAxis tick={{ fill: '#a0a0a0', fontSize: 12 }} />
              <Tooltip contentStyle={{ background: '#1a1a1a', border: '1px solid #2a2a2a', borderRadius: 6, color: '#fff' }} />
              <Bar dataKey="total_flight_minutes" name="Flight Minutes" fill="#4a90d9" radius={[2, 2, 0, 0]} />
              <Bar dataKey="total_missions" name="Missions" fill="#64748b" radius={[2, 2, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </Card>
      </div>
    </div>
  );
}
