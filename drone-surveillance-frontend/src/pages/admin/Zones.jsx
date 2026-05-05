import { useState, useEffect } from 'react';
import { Plus, ExternalLink } from 'lucide-react';
import Card from '../../components/ui/Card';
import Table from '../../components/ui/Table';
import Badge from '../../components/ui/Badge';
import Button from '../../components/ui/Button';
import Modal from '../../components/ui/Modal';
import Input from '../../components/ui/Input';
import Select from '../../components/ui/Select';
import Spinner from '../../components/ui/Spinner';
import { getZones, createZone, updateZone, deleteZone } from '../../api/zones.api';

const riskOptions = [
  { value: 'Low', label: 'Low' },
  { value: 'Medium', label: 'Medium' },
  { value: 'High', label: 'High' },
];

export default function Zones() {
  const [zones, setZones] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({ zone_name: '', location_description: '', risk_level: 'Low', coordinates_lat: '', coordinates_lng: '' });
  const [errors, setErrors] = useState({});
  const [apiError, setApiError] = useState('');

  const load = () => {
    setLoading(true);
    getZones().then((r) => setZones(r.data.data)).finally(() => setLoading(false));
  };

  useEffect(load, []);

  const validate = () => {
    const e = {};
    if (!form.zone_name) e.zone_name = 'Required';
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const handleSubmit = async () => {
    if (!validate()) return;
    setApiError('');
    try {
      const data = {
        zone_name: form.zone_name,
        location_description: form.location_description || undefined,
        risk_level: form.risk_level,
        coordinates_lat: form.coordinates_lat ? parseFloat(form.coordinates_lat) : undefined,
        coordinates_lng: form.coordinates_lng ? parseFloat(form.coordinates_lng) : undefined,
      };
      if (editing) {
        await updateZone(editing.zone_id, data);
      } else {
        await createZone(data);
      }
      setModal(false);
      setEditing(null);
      load();
    } catch (err) {
      setApiError(err.response?.data?.message || 'Operation failed');
    }
  };

  const handleEdit = (zone) => {
    setEditing(zone);
    setForm({
      zone_name: zone.zone_name,
      location_description: zone.location_description || '',
      risk_level: zone.risk_level,
      coordinates_lat: zone.coordinates_lat || '',
      coordinates_lng: zone.coordinates_lng || '',
    });
    setErrors({});
    setApiError('');
    setModal(true);
  };

  const handleDelete = async (zone) => {
    await deleteZone(zone.zone_id);
    load();
  };

  const CoordsCell = ({ lat, lng }) => {
    if (!lat || !lng) return <span className="text-[#555]">—</span>;
    return (
      <a
        href={`https://www.google.com/maps?q=${lat},${lng}`}
        target="_blank"
        rel="noopener noreferrer"
        className="inline-flex items-center gap-1 text-[#4a90d9] hover:underline"
      >
        {parseFloat(lat).toFixed(6)}, {parseFloat(lng).toFixed(6)}
        <ExternalLink size={12} />
      </a>
    );
  };

  if (loading) return <Spinner />;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-lg font-semibold text-white">Surveillance Zones</h1>
        <Button onClick={() => { setEditing(null); setForm({ zone_name: '', location_description: '', risk_level: 'Low', coordinates_lat: '', coordinates_lng: '' }); setErrors({}); setApiError(''); setModal(true); }}>
          <span className="flex items-center gap-1.5"><Plus size={14} /> Add Zone</span>
        </Button>
      </div>

      <Card className="p-0 overflow-hidden">
        <Table
          headers={['Zone Name', 'Description', 'Risk Level', 'Coordinates', 'Actions']}
          rows={zones}
          renderRow={(z) => (
            <>
              <td className="px-4 py-3 text-sm text-white font-medium">{z.zone_name}</td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0] max-w-xs truncate">{z.location_description || '—'}</td>
              <td className="px-4 py-3"><Badge>{z.risk_level}</Badge></td>
              <td className="px-4 py-3 text-sm"><CoordsCell lat={z.coordinates_lat} lng={z.coordinates_lng} /></td>
              <td className="px-4 py-3">
                <div className="flex gap-2">
                  <Button variant="secondary" onClick={() => handleEdit(z)}>Edit</Button>
                  <Button variant="danger" onClick={() => handleDelete(z)}>Delete</Button>
                </div>
              </td>
            </>
          )}
        />
      </Card>

      <Modal open={modal} onClose={() => setModal(false)} title={editing ? 'Edit Zone' : 'Add Zone'}>
        {apiError && <div className="mb-3 px-3 py-2 bg-red-400/10 border border-red-400/20 rounded text-sm text-red-400">{apiError}</div>}
        <Input label="Zone Name" value={form.zone_name} onChange={(e) => setForm({ ...form, zone_name: e.target.value })} error={errors.zone_name} />
        <Input label="Location Description" value={form.location_description} onChange={(e) => setForm({ ...form, location_description: e.target.value })} />
        <Select label="Risk Level" value={form.risk_level} onChange={(e) => setForm({ ...form, risk_level: e.target.value })} options={riskOptions} />
        <Input label="Latitude" type="number" step="any" value={form.coordinates_lat} onChange={(e) => setForm({ ...form, coordinates_lat: e.target.value })} />
        <Input label="Longitude" type="number" step="any" value={form.coordinates_lng} onChange={(e) => setForm({ ...form, coordinates_lng: e.target.value })} />
        <div className="flex justify-end gap-2 mt-4">
          <Button variant="secondary" onClick={() => setModal(false)}>Cancel</Button>
          <Button onClick={handleSubmit}>{editing ? 'Update' : 'Create'}</Button>
        </div>
      </Modal>
    </div>
  );
}
