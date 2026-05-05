import { useState, useEffect } from 'react';
import { ClipboardList, Plane, Crosshair } from 'lucide-react';
import Card from '../../components/ui/Card';
import Table from '../../components/ui/Table';
import Badge from '../../components/ui/Badge';
import Spinner from '../../components/ui/Spinner';
import { getMissions } from '../../api/missions.api';
import { getDrones } from '../../api/drones.api';
import { getDetections } from '../../api/detections.api';
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

export default function OperatorDashboard() {
  const [missions, setMissions] = useState([]);
  const [drones, setDrones] = useState([]);
  const [detections, setDetections] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([getMissions(), getDrones(), getDetections()])
      .then(([m, d, det]) => {
        setMissions(m.data.data);
        setDrones(d.data.data);
        setDetections(det.data.data);
      })
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <Spinner />;

  const activeMissions = missions.filter((m) => ['Scheduled', 'In Progress'].includes(m.mission_status));
  const activeDrones = drones.filter((d) => d.status === 'Active');
  const recentDetections = detections.slice(0, 8);

  return (
    <div className="space-y-6">
      <h1 className="text-lg font-semibold text-white">Operator Dashboard</h1>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <StatCard icon={ClipboardList} label="Assigned Missions" value={activeMissions.length} color="bg-[#4a90d9]/10 text-[#4a90d9]" />
        <StatCard icon={Plane} label="Active Drones" value={activeDrones.length} color="bg-emerald-400/10 text-emerald-400" />
        <StatCard icon={Crosshair} label="Total Detections" value={detections.length} color="bg-amber-400/10 text-amber-400" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card>
          <h2 className="text-sm font-medium text-[#a0a0a0] mb-3">Active Missions</h2>
          <Table
            headers={['Drone', 'Zone', 'Status', 'Time']}
            rows={activeMissions.slice(0, 5)}
            renderRow={(m) => (
              <>
                <td className="px-4 py-3 text-sm text-white">{m.drone_name}</td>
                <td className="px-4 py-3 text-sm text-[#a0a0a0]">{m.zone_name}</td>
                <td className="px-4 py-3"><Badge>{m.mission_status}</Badge></td>
                <td className="px-4 py-3 text-sm text-[#a0a0a0]">{formatDateTime(m.scheduled_time)}</td>
              </>
            )}
          />
        </Card>

        <Card>
          <h2 className="text-sm font-medium text-[#a0a0a0] mb-3">Recent Detections</h2>
          <Table
            headers={['Type', 'Threat', 'Zone', 'Time']}
            rows={recentDetections}
            renderRow={(d) => (
              <>
                <td className="px-4 py-3 text-sm text-white">{d.object_type}</td>
                <td className="px-4 py-3"><Badge>{d.threat_level}</Badge></td>
                <td className="px-4 py-3 text-sm text-[#a0a0a0]">{d.zone_name || '—'}</td>
                <td className="px-4 py-3 text-sm text-[#a0a0a0]">{formatDateTime(d.detected_at)}</td>
              </>
            )}
          />
        </Card>
      </div>
    </div>
  );
}
