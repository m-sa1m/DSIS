import { useState, useEffect } from 'react';
import Card from '../../components/ui/Card';
import Table from '../../components/ui/Table';
import Input from '../../components/ui/Input';
import Button from '../../components/ui/Button';
import Spinner from '../../components/ui/Spinner';
import { getAuditLogs } from '../../api/audit.api';
import { formatDateTime } from '../../utils/formatDate';

export default function Audit() {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [userId, setUserId] = useState('');

  const load = (uid) => {
    setLoading(true);
    getAuditLogs(uid || undefined)
      .then((r) => setLogs(r.data.data))
      .finally(() => setLoading(false));
  };

  useEffect(() => load(), []);

  const handleFilter = () => load(userId);

  return (
    <div className="space-y-4">
      <h1 className="text-lg font-semibold text-white">Audit Log</h1>

      <div className="flex items-end gap-3">
        <div className="w-48">
          <Input label="Filter by User ID" type="number" value={userId} onChange={(e) => setUserId(e.target.value)} placeholder="e.g. 1" />
        </div>
        <Button onClick={handleFilter} className="mb-3">Filter</Button>
        <Button variant="secondary" onClick={() => { setUserId(''); load(); }} className="mb-3">Reset</Button>
      </div>

      {loading ? <Spinner /> : (
        <Card className="p-0 overflow-hidden">
          <Table
            headers={['ID', 'User', 'Action', 'Table', 'Record ID', 'Description', 'Time']}
            rows={logs}
            renderRow={(l) => (
              <>
                <td className="px-4 py-3 text-sm text-[#a0a0a0]">{l.audit_id}</td>
                <td className="px-4 py-3 text-sm text-white">{l.full_name || '—'}</td>
                <td className="px-4 py-3 text-sm text-[#a0a0a0]">{l.action}</td>
                <td className="px-4 py-3 text-sm text-[#a0a0a0]">{l.table_name}</td>
                <td className="px-4 py-3 text-sm text-[#a0a0a0]">{l.record_id || '—'}</td>
                <td className="px-4 py-3 text-sm text-[#a0a0a0] max-w-xs truncate">{l.description || '—'}</td>
                <td className="px-4 py-3 text-sm text-[#a0a0a0]">{formatDateTime(l.performed_at)}</td>
              </>
            )}
          />
        </Card>
      )}
    </div>
  );
}
