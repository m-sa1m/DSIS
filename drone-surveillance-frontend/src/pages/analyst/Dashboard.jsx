import { useState, useEffect } from 'react';
import { Bell, FileText, AlertTriangle } from 'lucide-react';
import Card from '../../components/ui/Card';
import Table from '../../components/ui/Table';
import Badge from '../../components/ui/Badge';
import Spinner from '../../components/ui/Spinner';
import { getAlerts } from '../../api/alerts.api';
import { getIncidents } from '../../api/incidents.api';
import { formatDateTime } from '../../utils/formatDate';

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

export default function AnalystDashboard() {
  const [alerts, setAlerts] = useState([]);
  const [incidents, setIncidents] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([getAlerts(), getIncidents()])
      .then(([a, i]) => {
        setAlerts(a.data.data);
        setIncidents(i.data.data);
      })
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <Spinner />;

  const newAlerts = alerts.filter((a) => a.alert_status === 'New');
  const criticalAlerts = alerts.filter((a) => a.severity === 'Critical');
  const openIncidents = incidents.filter((i) => i.incident_status === 'Open');

  return (
    <div className="space-y-6">
      <h1 className="text-lg font-semibold text-white">Analyst Dashboard</h1>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <StatCard icon={Bell} label="New Alerts" value={newAlerts.length} color="bg-[#4a90d9]/10 text-[#4a90d9]" />
        <StatCard icon={AlertTriangle} label="Critical Alerts" value={criticalAlerts.length} color="bg-red-400/10 text-red-400" />
        <StatCard icon={FileText} label="Open Incidents" value={openIncidents.length} color="bg-amber-400/10 text-amber-400" />
      </div>

      <Card>
        <h2 className="text-sm font-medium text-[#a0a0a0] mb-3">Recent High Threat Alerts</h2>
        <Table
          headers={['Severity', 'Status', 'Object', 'Threat', 'Zone', 'Drone', 'Time']}
          rows={alerts.filter((a) => a.severity === 'Critical' || a.severity === 'High').slice(0, 8)}
          renderRow={(a) => (
            <>
              <td className="px-4 py-3"><Badge>{a.severity}</Badge></td>
              <td className="px-4 py-3"><Badge>{a.alert_status}</Badge></td>
              <td className="px-4 py-3 text-sm text-white">{a.object_type || '—'}</td>
              <td className="px-4 py-3"><Badge>{a.threat_level}</Badge></td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{a.zone_name || '—'}</td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{a.drone_name || '—'}</td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{formatDateTime(a.generated_at)}</td>
            </>
          )}
        />
      </Card>
    </div>
  );
}
