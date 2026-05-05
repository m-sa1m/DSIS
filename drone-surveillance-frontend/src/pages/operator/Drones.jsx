import { useState, useEffect } from 'react';
import Card from '../../components/ui/Card';
import Table from '../../components/ui/Table';
import Badge from '../../components/ui/Badge';
import Button from '../../components/ui/Button';
import Modal from '../../components/ui/Modal';
import Select from '../../components/ui/Select';
import Spinner from '../../components/ui/Spinner';
import { getDrones, updateDrone } from '../../api/drones.api';
import { formatDate } from '../../utils/formatDate';

const statusOptions = [
  { value: 'Active', label: 'Active' },
  { value: 'Inactive', label: 'Inactive' },
  { value: 'Under Maintenance', label: 'Under Maintenance' },
];

export default function OperatorDrones() {
  const [drones, setDrones] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [selected, setSelected] = useState(null);
  const [status, setStatus] = useState('');

  const load = () => {
    setLoading(true);
    getDrones().then((r) => setDrones(r.data.data)).finally(() => setLoading(false));
  };

  useEffect(load, []);

  const handleStatusUpdate = async () => {
    if (!selected || !status) return;
    await updateDrone(selected.drone_id, { status });
    setModal(false);
    load();
  };

  if (loading) return <Spinner />;

  return (
    <div className="space-y-4">
      <h1 className="text-lg font-semibold text-white">Drones</h1>

      <Card className="p-0 overflow-hidden">
        <Table
          headers={['Name', 'Model', 'Status', 'Zone', 'Registered', 'Actions']}
          rows={drones}
          renderRow={(d) => (
            <>
              <td className="px-4 py-3 text-sm text-white font-medium">{d.drone_name}</td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{d.model}</td>
              <td className="px-4 py-3"><Badge>{d.status}</Badge></td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{d.zone_name || '—'}</td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{formatDate(d.registered_at)}</td>
              <td className="px-4 py-3">
                <Button variant="secondary" onClick={() => { setSelected(d); setStatus(d.status); setModal(true); }}>
                  Update Status
                </Button>
              </td>
            </>
          )}
        />
      </Card>

      <Modal open={modal} onClose={() => setModal(false)} title="Update Drone Status">
        <p className="text-sm text-[#a0a0a0] mb-3">Updating status for <span className="text-white">{selected?.drone_name}</span></p>
        <Select label="Status" value={status} onChange={(e) => setStatus(e.target.value)} options={statusOptions} />
        <div className="flex justify-end gap-2 mt-4">
          <Button variant="secondary" onClick={() => setModal(false)}>Cancel</Button>
          <Button onClick={handleStatusUpdate}>Update</Button>
        </div>
      </Modal>
    </div>
  );
}
