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
import { getUsers, createUser, updateUser, deleteUser } from '../../api/users.api';
import { formatDate } from '../../utils/formatDate';

const roleOptions = [
  { value: '1', label: 'Admin' },
  { value: '2', label: 'Operator' },
  { value: '3', label: 'Analyst' },
];

export default function Users() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({ full_name: '', email: '', password: '', role_id: '' });
  const [errors, setErrors] = useState({});
  const [apiError, setApiError] = useState('');

  const load = () => {
    setLoading(true);
    getUsers().then((r) => setUsers(r.data.data)).finally(() => setLoading(false));
  };

  useEffect(load, []);

  const validate = () => {
    const e = {};
    if (!form.full_name) e.full_name = 'Required';
    if (!form.email) e.email = 'Required';
    if (!editing && !form.password) e.password = 'Required';
    if (!form.role_id) e.role_id = 'Required';
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const handleSubmit = async () => {
    if (!validate()) return;
    setApiError('');
    try {
      const data = {
        full_name: form.full_name,
        email: form.email,
        role_id: parseInt(form.role_id, 10),
      };
      if (form.password) data.password = form.password;

      if (editing) {
        await updateUser(editing.user_id, data);
      } else {
        data.password = form.password;
        await createUser(data);
      }
      setModal(false);
      setEditing(null);
      setForm({ full_name: '', email: '', password: '', role_id: '' });
      load();
    } catch (err) {
      setApiError(err.response?.data?.message || 'Operation failed');
    }
  };

  const handleEdit = (user) => {
    setEditing(user);
    setForm({ full_name: user.full_name, email: user.email, password: '', role_id: String(user.role_id) });
    setErrors({});
    setApiError('');
    setModal(true);
  };

  const handleDeactivate = async (user) => {
    await deleteUser(user.user_id);
    load();
  };

  if (loading) return <Spinner />;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-lg font-semibold text-white">Users</h1>
        <Button onClick={() => { setEditing(null); setForm({ full_name: '', email: '', password: '', role_id: '' }); setErrors({}); setApiError(''); setModal(true); }}>
          <span className="flex items-center gap-1.5"><Plus size={14} /> Add User</span>
        </Button>
      </div>

      <Card className="p-0 overflow-hidden">
        <Table
          headers={['Name', 'Email', 'Role', 'Status', 'Created', 'Actions']}
          rows={users}
          renderRow={(u) => (
            <>
              <td className="px-4 py-3 text-sm text-white">{u.full_name}</td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{u.email}</td>
              <td className="px-4 py-3"><Badge>{u.role_name}</Badge></td>
              <td className="px-4 py-3"><Badge>{u.is_active ? 'Active' : 'Inactive'}</Badge></td>
              <td className="px-4 py-3 text-sm text-[#a0a0a0]">{formatDate(u.created_at)}</td>
              <td className="px-4 py-3">
                <div className="flex gap-2">
                  <Button variant="secondary" onClick={() => handleEdit(u)}>Edit</Button>
                  {u.is_active && <Button variant="danger" onClick={() => handleDeactivate(u)}>Deactivate</Button>}
                </div>
              </td>
            </>
          )}
        />
      </Card>

      <Modal open={modal} onClose={() => setModal(false)} title={editing ? 'Edit User' : 'Create User'}>
        {apiError && <div className="mb-3 px-3 py-2 bg-red-400/10 border border-red-400/20 rounded text-sm text-red-400">{apiError}</div>}
        <Input label="Full Name" value={form.full_name} onChange={(e) => setForm({ ...form, full_name: e.target.value })} error={errors.full_name} />
        <Input label="Email" type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} error={errors.email} />
        <Input label="Password" type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} error={errors.password} placeholder={editing ? 'Leave blank to keep current' : ''} />
        <Select label="Role" value={form.role_id} onChange={(e) => setForm({ ...form, role_id: e.target.value })} options={roleOptions} error={errors.role_id} />
        <div className="flex justify-end gap-2 mt-4">
          <Button variant="secondary" onClick={() => setModal(false)}>Cancel</Button>
          <Button onClick={handleSubmit}>{editing ? 'Update' : 'Create'}</Button>
        </div>
      </Modal>
    </div>
  );
}
