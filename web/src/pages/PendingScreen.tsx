import React from 'react';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import './Auth.css';

const PendingScreen: React.FC = () => {
  const { logout, user } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div className="auth-container">
      <div className="auth-card" style={{ textAlign: 'center' }}>
        <h2 className="auth-title">Registration Pending</h2>
        <p className="auth-subtitle" style={{ marginBottom: '30px' }}>
          Hello, {user?.email}! Your Operator account is currently awaiting Admin approval. You will gain access to the dashboard once verified.
        </p>
        
        <button onClick={handleLogout} className="btn-secondary" style={{ width: '100%', padding: '15px' }}>
          Logout
        </button>
      </div>
    </div>
  );
};

export default PendingScreen;
