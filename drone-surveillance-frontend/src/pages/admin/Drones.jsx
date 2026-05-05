import { useState, useEffect } from 'react';
import { Plus } from 'lucide-react';
import Card from '../../components/ui/Card';
import Table from '../../components/ui/Table';
import Badge from '../../components/ui/Badge';
import Button from '../../components/ui/Button';
import Modal from '../../components/ui/Modal';
import Input from '../../components/ui/Input';
import Select from '../../components/ui/Select';
import Spinner from '../../components/ui/Spinner';
import { getDrones, createDrone, updateDrone, deleteDrone } from '../../api/drones.api';
import { getZones } from '../../api/zones.api';
import { formatDate } from '../../utils/formatDate';

const statusOptions = [
  { value: 'Active', label: 'Active' },
  { value: 'Inactive', label: 'Inactive' },
  { value: 'Under Maintenance', label: 'Under Maintenance' },
];

export default function Drones() {
  const [drones, setDrones] = useState([]);
  const [zones, setZones] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({ drone_name: '', model: '', status: 'Active', zone_id: '' });
  const [errors, setErrors] = useState({});
  const [apiError, setApiError] = useState('');

  const load = () => {
    setLoading(true);
    Promise.all([getDrones(), getZones()])
      .then(([d, z]) => {
        setDrones(d.data.data);
        setZones(z.data.data);
      })
      .finally(() => setLoading(false));
  };

  useEffect(load, []);

  const zoneOptions = zones.map((z) => ({ value: String(z.zone_id), label: z.zone_name }));

  const validate = () => {
    const e = {};
    if (!form.drone_name) e.drone_name = 'Required';
    if (!form.model) e.model = 'Required';
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const handleSubmit = async () => {
    if (!validate()) return;
    setApiError('');
    try {
      const data = {
        drone_name: form.drone_name,
        model: form.model,
        status: form.status,
        zone_id: form.zone_id ? parseInt(form.zone_id, 10) : null,
      };
      if (editing) {
        await updateDrone(editing.drone_id, data);
      } else {
        await createDrone(data);
      }
      setModal(false);
      setEditing(null);
      load();
    } catch (err) {
      setApiError(err.response?.data?.message || 'Operation failed');
    }
  };

  const handleEdit = (drone) => {
    setEditing(drone);
    setForm({ drone_name: drone.drone_name, model: drone.model, status: drone.status, zone_id: drone.zone_id ? String(drone.zone_id) : '' });
    setErrors({});
    setApiError('');
    setModal(true);
  };

  const handleDelete = async (drone) => {
    await deleteDrone(drone.drone_id);
    load();
  };

  if (loading) return <Spinner />;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-lg font-semibold text-white">Drones</h1>
        <Button onClick={() => { setEditing(null); setForm({ drone_name: '', model: '', status: 'Active', zone_id: '' }); setErrors({}); setApiError(''); setModal(true); }}>
          <span className="flex items-center gap-1.5"><Plus size={14} /> Add Drone</span>
        </Button>
      </div>

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
                <div className="flex gap-2">
                  <Button variant="secondary" onClick={() => handleEdit(d)}>Edit</Button>
                  <Button variant="danger" onClick={() => handleDelete(d)}>Delete</Button>
                </div>
              </td>
            </>
          )}
        />
      </Card>

      <Modal open={modal} onClose={() => setModal(false)} title={editing ? 'Edit Drone' : 'Add Drone'}>
        {apiError && <div className="mb-3 px-3 py-2 bg-red-400/10 border border-red-400/20 rounded text-sm text-red-400">{apiError}</div>}
        <Input label="Drone Name" value={form.drone_name} onChange={(e) => setForm({ ...form, drone_name: e.target.value })} error={errors.drone_name} />
        <Input label="Model" value={form.model} onChange={(e) => setForm({ ...form, model: e.target.value })} error={errors.model} />
        <Select label="Status" value={form.status} onChange={(e) => setForm({ ...form, status: e.target.value })} options={statusOptions} />
        <Select label="Assigned Zone" value={form.zone_id} onChange={(e) => setForm({ ...form, zone_id: e.target.value })} options={zoneOptions} />
        <div className="flex justify-end gap-2 mt-4">
          <Button variant="secondary" onClick={() => setModal(false)}>Cancel</Button>
          <Button onClick={handleSubmit}>{editing ? 'Update' : 'Create'}</Button>
        </div>
      </Modal>
    </div>
  );
}
