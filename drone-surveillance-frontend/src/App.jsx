import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import { useAuth } from './hooks/useAuth';
import Layout from './components/layout/Layout';
import ProtectedRoute from './components/layout/ProtectedRoute';
import Login from './pages/Login';
import AdminDashboard from './pages/admin/Dashboard';
import Users from './pages/admin/Users';
import AdminDrones from './pages/admin/Drones';
import Zones from './pages/admin/Zones';
import Audit from './pages/admin/Audit';
import AdminReports from './pages/admin/Reports';
import OperatorDashboard from './pages/operator/Dashboard';
import Missions from './pages/operator/Missions';
import OperatorDrones from './pages/operator/Drones';
import Detections from './pages/operator/Detections';
import AnalystDashboard from './pages/analyst/Dashboard';
import Alerts from './pages/analyst/Alerts';
import Incidents from './pages/analyst/Incidents';
import AnalystReports from './pages/analyst/Reports';

function DashboardRouter() {
  const { role } = useAuth();
  if (role === 'Admin') return <AdminDashboard />;
  if (role === 'Operator') return <OperatorDashboard />;
  if (role === 'Analyst') return <AnalystDashboard />;
  return <Navigate to="/login" />;
}

function DronesRouter() {
  const { role } = useAuth();
  if (role === 'Admin') return <AdminDrones />;
  return <OperatorDrones />;
}

function ReportsRouter() {
  const { role } = useAuth();
  if (role === 'Admin') return <AdminReports />;
  return <AnalystReports />;
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<Login />} />

          <Route path="/" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
            <Route index element={<Navigate to="/dashboard" replace />} />
            <Route path="dashboard" element={<DashboardRouter />} />

            <Route path="users" element={<ProtectedRoute allowedRoles={['Admin']}><Users /></ProtectedRoute>} />
            <Route path="drones" element={<ProtectedRoute allowedRoles={['Admin', 'Operator']}><DronesRouter /></ProtectedRoute>} />
            <Route path="zones" element={<ProtectedRoute allowedRoles={['Admin', 'Operator']}><Zones /></ProtectedRoute>} />
            <Route path="audit" element={<ProtectedRoute allowedRoles={['Admin']}><Audit /></ProtectedRoute>} />

            <Route path="missions" element={<ProtectedRoute allowedRoles={['Admin', 'Operator']}><Missions /></ProtectedRoute>} />
            <Route path="detections" element={<ProtectedRoute allowedRoles={['Admin', 'Operator']}><Detections /></ProtectedRoute>} />

            <Route path="alerts" element={<ProtectedRoute allowedRoles={['Admin', 'Analyst']}><Alerts /></ProtectedRoute>} />
            <Route path="incidents" element={<ProtectedRoute allowedRoles={['Admin', 'Operator', 'Analyst']}><Incidents /></ProtectedRoute>} />

            <Route path="reports" element={<ProtectedRoute allowedRoles={['Admin', 'Analyst']}><ReportsRouter /></ProtectedRoute>} />
          </Route>

          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}
