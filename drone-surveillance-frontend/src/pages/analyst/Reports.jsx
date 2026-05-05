import { useState, useEffect } from 'react';
import Card from '../../components/ui/Card';
import Table from '../../components/ui/Table';
import Badge from '../../components/ui/Badge';
import Spinner from '../../components/ui/Spinner';
import { getDroneUtilization, getAlertTrends, getHighRiskZones, getOperatorPerformance } from '../../api/reports.api';

export default function AnalystReports() {
  const [utilization, setUtilization] = useState([]);
  const [trends, setTrends] = useState([]);
  const [riskZones, setRiskZones] = useState([]);
  const [operators, setOperators] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([getDroneUtilization(), getAlertTrends(), getHighRiskZones(), getOperatorPerformance()])
      .then(([u, t, r, o]) => {
        setUtilization(u.data.data);
        setTrends(t.data.data);
        setRiskZones(r.data.data);
        setOperators(o.data.data);
      })
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <Spinner />;

  return (
    <div className="space-y-6">
      <h1 className="text-lg font-semibold text-white">Reports</h1>

      <Card>
        <h2 className="text-sm font-medium text-[#a0a0a0] mb-3">Drone Utilization</h2>
        <Table
          headers={['Drone', 'Total Missions', 'Flight Minutes', 'Zones Covered']}
          rows={utilization}
          renderRow={(r) => (
            <>
              <td className="px-4 py-3 text-sm text-white">{r.drone_name}</td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{r.total_missions}</td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{r.total_flight_minutes}</td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{r.zones_covered}</td>
            </>
          )}
        />
      </Card>

      <Card>
        <h2 className="text-sm font-medium text-[#a0a0a0] mb-3">Alert Trends (Current Year)</h2>
        <Table
          headers={['Month', 'Severity', 'Count']}
          rows={trends}
          renderRow={(r) => (
            <>
              <td className="px-4 py-3 text-sm text-white">{r.month}</td>
              <td className="px-4 py-3"><Badge>{r.severity}</Badge></td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{r.alert_count}</td>
            </>
          )}
        />
      </Card>

      <Card>
        <h2 className="text-sm font-medium text-[#a0a0a0] mb-3">High Risk Zones</h2>
        <Table
          headers={['Zone', 'Risk Level', 'High Detections']}
          rows={riskZones}
          renderRow={(r) => (
            <>
              <td className="px-4 py-3 text-sm text-white">{r.zone_name}</td>
              <td className="px-4 py-3"><Badge>{r.risk_level}</Badge></td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{r.high_detection_count}</td>
            </>
          )}
        />
      </Card>

      <Card>
        <h2 className="text-sm font-medium text-[#a0a0a0] mb-3">Operator Performance</h2>
        <Table
          headers={['Operator', 'Completed Missions']}
          rows={operators}
          renderRow={(r) => (
            <>
              <td className="px-4 py-3 text-sm text-white">{r.full_name}</td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{r.completed_missions}</td>
            </>
          )}
        />
      </Card>
    </div>
  );
}
