import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';

interface PendingOperator {
  email: string;
  id: string;
  status: string;
}

const AdminDashboard: React.FC = () => {
  const [operators, setOperators] = useState<PendingOperator[]>([]);
  const { logout, user } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    fetchPendingOperators();
  }, []);

  const fetchPendingOperators = async () => {
    try {
      const response = await axios.get('http://localhost:8081/api/auth/pending-operators');
      setOperators(response.data);
    } catch (error) {
      console.error('Error fetching pending operators', error);
    }
  };

  const handleApprove = async (email: string) => {
    try {
      await axios.post(`http://localhost:8081/api/auth/approve/${email}`);
      setOperators(operators.filter(op => op.email !== email));
    } catch (error) {
      console.error('Error approving operator', error);
    }
  };

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div className="dashboard-layout" style={{ minHeight: '100vh', backgroundColor: '#030712', color: '#f8fafc', padding: '40px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '40px' }}>
        <h2>Admin Dashboard</h2>
        <div>
          <span style={{ marginRight: '20px' }}>{user?.email}</span>
          <button className="btn-secondary" onClick={handleLogout}>Logout</button>
        </div>
      </div>

      <div className="glass-card" style={{ background: 'rgba(17, 24, 39, 0.8)', padding: '30px', borderRadius: '20px', border: '1px solid rgba(255,255,255,0.1)' }}>
        <h3 style={{ marginBottom: '20px' }}>Pending Operator Approvals</h3>
        
        {operators.length === 0 ? (
          <p style={{ color: '#94a3b8' }}>No pending operators.</p>
        ) : (
          <table style={{ width: '100%', textAlign: 'left', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.1)' }}>
                <th style={{ padding: '15px' }}>ID</th>
                <th style={{ padding: '15px' }}>Email</th>
                <th style={{ padding: '15px' }}>Status</th>
                <th style={{ padding: '15px' }}>Action</th>
              </tr>
            </thead>
            <tbody>
              {operators.map(op => (
                <tr key={op.id} style={{ borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                  <td style={{ padding: '15px' }}>{op.id}</td>
                  <td style={{ padding: '15px' }}>{op.email}</td>
                  <td style={{ padding: '15px' }}>
                    <span style={{ background: 'rgba(234, 179, 8, 0.2)', color: '#eab308', padding: '5px 10px', borderRadius: '5px' }}>
                      {op.status}
                    </span>
                  </td>
                  <td style={{ padding: '15px' }}>
                    <button 
                      onClick={() => handleApprove(op.email)}
                      style={{ background: '#34d399', color: '#000', border: 'none', padding: '8px 15px', borderRadius: '5px', cursor: 'pointer', fontWeight: 'bold' }}
                    >
                      Approve
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};

export default AdminDashboard;
