import { useState, useEffect } from 'react';
import Card from '../../components/ui/Card';
import Table from '../../components/ui/Table';
import Badge from '../../components/ui/Badge';
import Button from '../../components/ui/Button';
import Modal from '../../components/ui/Modal';
import Select from '../../components/ui/Select';
import Spinner from '../../components/ui/Spinner';
import { getIncidents, updateIncidentStatus } from '../../api/incidents.api';
import { formatDateTime } from '../../utils/formatDate';

const statusOptions = [
  { value: 'Open', label: 'Open' },
  { value: 'Under Review', label: 'Under Review' },
  { value: 'Resolved', label: 'Resolved' },
  { value: 'Archived', label: 'Archived' },
];

export default function Incidents() {
  const [incidents, setIncidents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [selected, setSelected] = useState(null);
  const [status, setStatus] = useState('');

  const load = () => {
    setLoading(true);
    getIncidents().then((r) => setIncidents(r.data.data)).finally(() => setLoading(false));
  };

  useEffect(load, []);

  const handleStatusUpdate = async () => {
    if (!selected || !status) return;
    await updateIncidentStatus(selected.incident_id, { incident_status: status });
    setModal(false);
    load();
  };

  if (loading) return <Spinner />;

  return (
    <div className="space-y-4">
      <h1 className="text-lg font-semibold text-white">Incidents</h1>

      <Card className="p-0 overflow-hidden">
        <Table
          headers={['Title', 'Status', 'Severity', 'Zone', 'Reporter', 'Created', 'Actions']}
          rows={incidents}
          renderRow={(i) => (
            <>
              <td className="px-4 py-3 text-sm text-white max-w-xs truncate">{i.title}</td>
              <td className="px-4 py-3"><Badge>{i.incident_status}</Badge></td>
              <td className="px-4 py-3"><Badge>{i.severity}</Badge></td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{i.zone_name || '—'}</td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{i.reporter_name || '—'}</td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{formatDateTime(i.created_at)}</td>
              <td className="px-4 py-3">
                <Button variant="secondary" onClick={() => { setSelected(i); setStatus(i.incident_status); setModal(true); }}>
                  Update Status
                </Button>
              </td>
            </>
          )}
        />
      </Card>

      <Modal open={modal} onClose={() => setModal(false)} title="Update Incident Status">
        <p className="text-sm text-[#a0a0a0] mb-3">{selected?.title}</p>
        <Select label="Status" value={status} onChange={(e) => setStatus(e.target.value)} options={statusOptions} />
        <div className="flex justify-end gap-2 mt-4">
          <Button variant="secondary" onClick={() => setModal(false)}>Cancel</Button>
          <Button onClick={handleStatusUpdate}>Update</Button>
        </div>
      </Modal>
    </div>
  );
}
