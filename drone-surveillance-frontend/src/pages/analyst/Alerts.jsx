import { useState, useEffect } from 'react';
import Card from '../../components/ui/Card';
import Table from '../../components/ui/Table';
import Badge from '../../components/ui/Badge';
import Spinner from '../../components/ui/Spinner';
import { getAlerts } from '../../api/alerts.api';
import { formatDateTime } from '../../utils/formatDate';

const tabs = ['All', 'New', 'Acknowledged', 'Resolved'];

export default function Alerts() {
  const [alerts, setAlerts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('All');

  useEffect(() => {
    setLoading(true);
    getAlerts().then((r) => setAlerts(r.data.data)).finally(() => setLoading(false));
  }, []);

  const filtered = activeTab === 'All' ? alerts : alerts.filter((a) => a.alert_status === activeTab);

  if (loading) return <Spinner />;

  return (
    <div className="space-y-4">
      <h1 className="text-lg font-semibold text-white">Alerts</h1>

      <div className="flex gap-1">
        {tabs.map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-3 py-1.5 rounded-md text-sm transition-colors cursor-pointer ${
              activeTab === tab
                ? 'bg-[#4a90d9]/10 text-[#4a90d9]'
                : 'text-[#a0a0a0] hover:text-white hover:bg-[#1a1a1a]'
            }`}
          >
            {tab}
            <span className="ml-1.5 text-xs opacity-60">
              ({tab === 'All' ? alerts.length : alerts.filter((a) => a.alert_status === tab).length})
            </span>
          </button>
        ))}
      </div>

      <Card className="p-0 overflow-hidden">
        <Table
          headers={['ID', 'Severity', 'Status', 'Object Type', 'Threat', 'Zone', 'Drone', 'Generated']}
          rows={filtered}
          renderRow={(a) => (
            <>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{a.alert_id}</td>
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
