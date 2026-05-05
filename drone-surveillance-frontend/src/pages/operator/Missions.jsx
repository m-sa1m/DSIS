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
import { getMissions, createMission, updateMission, deleteMission } from '../../api/missions.api';
import { getDrones } from '../../api/drones.api';
import { getZones } from '../../api/zones.api';
import { getUsers } from '../../api/users.api';
import { useAuth } from '../../hooks/useAuth';
import { formatDateTime } from '../../utils/formatDate';

const statusOptions = [
  { value: 'Scheduled', label: 'Scheduled' },
  { value: 'In Progress', label: 'In Progress' },
  { value: 'Completed', label: 'Completed' },
  { value: 'Aborted', label: 'Aborted' },
];

export default function Missions() {
  const { user } = useAuth();
  const [missions, setMissions] = useState([]);
  const [drones, setDrones] = useState([]);
  const [zones, setZones] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({ drone_id: '', zone_id: '', scheduled_time: '', mission_status: 'Scheduled', notes: '' });
  const [errors, setErrors] = useState({});
  const [apiError, setApiError] = useState('');

  const load = () => {
    setLoading(true);
    Promise.all([getMissions(), getDrones(), getZones()])
      .then(([m, d, z]) => {
        setMissions(m.data.data);
        setDrones(d.data.data);
        setZones(z.data.data);
      })
      .finally(() => setLoading(false));
  };

  useEffect(load, []);

  const droneOptions = drones.map((d) => ({ value: String(d.drone_id), label: d.drone_name }));
  const zoneOptions = zones.map((z) => ({ value: String(z.zone_id), label: z.zone_name }));

  const validate = () => {
    const e = {};
    if (!form.drone_id) e.drone_id = 'Required';
    if (!form.zone_id) e.zone_id = 'Required';
    if (!form.scheduled_time) e.scheduled_time = 'Required';
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const handleSubmit = async () => {
    if (!validate()) return;
    setApiError('');
    try {
      const data = {
        drone_id: parseInt(form.drone_id, 10),
        zone_id: parseInt(form.zone_id, 10),
        operator_id: user.user_id,
        scheduled_time: form.scheduled_time,
        mission_status: form.mission_status,
        notes: form.notes || undefined,
      };
      if (editing) {
        await updateMission(editing.mission_id, data);
      } else {
        await createMission(data);
      }
      setModal(false);
      setEditing(null);
      load();
    } catch (err) {
      setApiError(err.response?.data?.message || 'Operation failed');
    }
  };

  const handleEdit = (m) => {
    setEditing(m);
    setForm({
      drone_id: String(m.drone_id),
      zone_id: String(m.zone_id),
      scheduled_time: m.scheduled_time ? m.scheduled_time.slice(0, 16) : '',
      mission_status: m.mission_status,
      notes: m.notes || '',
    });
    setErrors({});
    setApiError('');
    setModal(true);
  };

  const handleDelete = async (m) => {
    await deleteMission(m.mission_id);
    load();
  };

  if (loading) return <Spinner />;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-lg font-semibold text-white">Missions</h1>
        <Button onClick={() => { setEditing(null); setForm({ drone_id: '', zone_id: '', scheduled_time: '', mission_status: 'Scheduled', notes: '' }); setErrors({}); setApiError(''); setModal(true); }}>
          <span className="flex items-center gap-1.5"><Plus size={14} /> New Mission</span>
        </Button>
      </div>

      <Card className="p-0 overflow-hidden">
        <Table
          headers={['Drone', 'Zone', 'Operator', 'Scheduled', 'Status', 'Actions']}
          rows={missions}
          renderRow={(m) => (
            <>
              <td className="px-4 py-3 text-sm text-white">{m.drone_name}</td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{m.zone_name}</td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{m.operator_name || '—'}</td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{formatDateTime(m.scheduled_time)}</td>
              <td className="px-4 py-3"><Badge>{m.mission_status}</Badge></td>
              <td className="px-4 py-3">
                <div className="flex gap-2">
                  <Button variant="secondary" onClick={() => handleEdit(m)}>Edit</Button>
                  <Button variant="danger" onClick={() => handleDelete(m)}>Delete</Button>
                </div>
              </td>
            </>
          )}
        />
      </Card>

      <Modal open={modal} onClose={() => setModal(false)} title={editing ? 'Edit Mission' : 'New Mission'}>
        {apiError && <div className="mb-3 px-3 py-2 bg-red-400/10 border border-red-400/20 rounded text-sm text-red-400">{apiError}</div>}
        <Select label="Drone" value={form.drone_id} onChange={(e) => setForm({ ...form, drone_id: e.target.value })} options={droneOptions} error={errors.drone_id} />
        <Select label="Zone" value={form.zone_id} onChange={(e) => setForm({ ...form, zone_id: e.target.value })} options={zoneOptions} error={errors.zone_id} />
        <Input label="Scheduled Time" type="datetime-local" value={form.scheduled_time} onChange={(e) => setForm({ ...form, scheduled_time: e.target.value })} error={errors.scheduled_time} />
        <Select label="Status" value={form.mission_status} onChange={(e) => setForm({ ...form, mission_status: e.target.value })} options={statusOptions} />
        <Input label="Notes" value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} />
        <div className="flex justify-end gap-2 mt-4">
          <Button variant="secondary" onClick={() => setModal(false)}>Cancel</Button>
          <Button onClick={handleSubmit}>{editing ? 'Update' : 'Create'}</Button>
        </div>
      </Modal>
    </div>
  );
}
