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
import { getDetections, createDetection } from '../../api/detections.api';
import { formatDateTime } from '../../utils/formatDate';

const threatOptions = [
  { value: 'Low', label: 'Low' },
  { value: 'Medium', label: 'Medium' },
  { value: 'High', label: 'High' },
];

const objectTypes = [
  { value: 'Unauthorized Vehicle', label: 'Unauthorized Vehicle' },
  { value: 'Suspicious Person', label: 'Suspicious Person' },
  { value: 'Stray Animal', label: 'Stray Animal' },
  { value: 'Unknown Package', label: 'Unknown Package' },
  { value: 'Perimeter Breach', label: 'Perimeter Breach' },
];

export default function Detections() {
  const [detections, setDetections] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [form, setForm] = useState({ log_id: '', object_type: '', threat_level: '', coordinates_lat: '', coordinates_lng: '', description: '' });
  const [errors, setErrors] = useState({});
  const [apiError, setApiError] = useState('');

  const load = () => {
    setLoading(true);
    getDetections().then((r) => setDetections(r.data.data)).finally(() => setLoading(false));
  };

  useEffect(load, []);

  const validate = () => {
    const e = {};
    if (!form.log_id) e.log_id = 'Required';
    if (!form.object_type) e.object_type = 'Required';
    if (!form.threat_level) e.threat_level = 'Required';
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const handleSubmit = async () => {
    if (!validate()) return;
    setApiError('');
    try {
      await createDetection({
        log_id: parseInt(form.log_id, 10),
        object_type: form.object_type,
        threat_level: form.threat_level,
        coordinates_lat: form.coordinates_lat ? parseFloat(form.coordinates_lat) : undefined,
        coordinates_lng: form.coordinates_lng ? parseFloat(form.coordinates_lng) : undefined,
        description: form.description || undefined,
      });
      setModal(false);
      setForm({ log_id: '', object_type: '', threat_level: '', coordinates_lat: '', coordinates_lng: '', description: '' });
      load();
    } catch (err) {
      setApiError(err.response?.data?.message || 'Operation failed');
    }
  };

  if (loading) return <Spinner />;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-lg font-semibold text-white">Detections</h1>
        <Button onClick={() => { setErrors({}); setApiError(''); setModal(true); }}>
          <span className="flex items-center gap-1.5"><Plus size={14} /> Log Detection</span>
        </Button>
      </div>

      <Card className="p-0 overflow-hidden">
        <Table
          headers={['Type', 'Threat', 'Drone', 'Zone', 'Coordinates', 'Detected At']}
          rows={detections}
          renderRow={(d) => (
            <>
              <td className="px-4 py-3 text-sm text-white">{d.object_type}</td>
              <td className="px-4 py-3"><Badge>{d.threat_level}</Badge></td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{d.drone_name || '—'}</td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{d.zone_name || '—'}</td>
              <td className="px-4 py-3 text-sm">
                {d.coordinates_lat && d.coordinates_lng ? (
                  <a href={`https://www.google.com/maps?q=${d.coordinates_lat},${d.coordinates_lng}`} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-1 text-[#4a90d9] hover:underline">
                    {parseFloat(d.coordinates_lat).toFixed(6)}, {parseFloat(d.coordinates_lng).toFixed(6)}
                    <ExternalLink size={12} />
                  </a>
                ) : '—'}
              </td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{formatDateTime(d.detected_at)}</td>
            </>
          )}
        />
      </Card>

      <Modal open={modal} onClose={() => setModal(false)} title="Log Detection">
        {apiError && <div className="mb-3 px-3 py-2 bg-red-400/10 border border-red-400/20 rounded text-sm text-red-400">{apiError}</div>}
        <Input label="Flight Log ID" type="number" value={form.log_id} onChange={(e) => setForm({ ...form, log_id: e.target.value })} error={errors.log_id} />
        <Select label="Object Type" value={form.object_type} onChange={(e) => setForm({ ...form, object_type: e.target.value })} options={objectTypes} error={errors.object_type} />
        <Select label="Threat Level" value={form.threat_level} onChange={(e) => setForm({ ...form, threat_level: e.target.value })} options={threatOptions} error={errors.threat_level} />
        <Input label="Latitude" type="number" step="any" value={form.coordinates_lat} onChange={(e) => setForm({ ...form, coordinates_lat: e.target.value })} />
        <Input label="Longitude" type="number" step="any" value={form.coordinates_lng} onChange={(e) => setForm({ ...form, coordinates_lng: e.target.value })} />
        <Input label="Description" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
        <div className="flex justify-end gap-2 mt-4">
          <Button variant="secondary" onClick={() => setModal(false)}>Cancel</Button>
          <Button onClick={handleSubmit}>Submit</Button>
        </div>
      </Modal>
    </div>
  );
}
