import { Routes, Route, Navigate } from 'react-router-dom';
import LandingPage from './pages/LandingPage';
import Dashboard from './pages/Dashboard';
import Login from './pages/Login';
import Register from './pages/Register';
import PendingScreen from './pages/PendingScreen';
import AdminDashboard from './pages/AdminDashboard';
import { useAuth } from './context/AuthContext';
import './App.css';

const ProtectedRoute = ({ children, allowedRoles }: { children: React.ReactNode, allowedRoles: string[] }) => {
  const { user, isAuthenticated } = useAuth();

  if (!isAuthenticated || !user) {
    return <Navigate to="/login" replace />;
  }

  if (user.status === 'PENDING') {
    return <Navigate to="/pending" replace />;
  }

  if (!allowedRoles.includes(user.role)) {
    return <Navigate to="/" replace />;
  }

  return <>{children}</>;
};

function App() {
  return (
    <div className="app">
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route path="/pending" element={<PendingScreen />} />
        
        <Route 
          path="/dashboard" 
          element={
            <ProtectedRoute allowedRoles={['OPERATOR']}>
              <Dashboard />
            </ProtectedRoute>
          } 
        />
        
        <Route 
          path="/admin-dashboard" 
          element={
            <ProtectedRoute allowedRoles={['ADMIN']}>
              <AdminDashboard />
            </ProtectedRoute>
          } 
        />
      </Routes>
    </div>
  );
}

export default App;
