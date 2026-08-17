import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import axios from 'axios';
import './Auth.css';

const Register: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [secretKey, setSecretKey] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    setIsLoading(true);

    try {
      const response = await axios.post('http://localhost:8081/api/auth/register', {
        email,
        password,
        secretKey,
        role: 'OPERATOR'
      });

      setSuccess(response.data);
      setTimeout(() => {
        navigate('/login');
      }, 2000);
    } catch (err: any) {
      setError(err.response?.data || 'Registration failed');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="auth-container">
      <div className="auth-card">
        <h2 className="auth-title">Partner with EVWay</h2>
        <p className="auth-subtitle">Register your Charging Station Operator Account</p>
        
        {error && <div className="auth-error">{error}</div>}
        {success && <div className="auth-success">{success} Redirecting...</div>}
        
        <form onSubmit={handleRegister} className="auth-form">
          <div className="form-group">
            <label>Business Email Address</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="operator@company.com"
              required
            />
          </div>
          
          <div className="form-group">
            <label>Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              required
            />
          </div>

          <div className="form-group">
            <label>Invite Key (Optional)</label>
            <input
              type="password"
              value={secretKey}
              onChange={(e) => setSecretKey(e.target.value)}
              placeholder="Enter to instantly approve account"
            />
          </div>
          
          <button type="submit" className="auth-button" disabled={isLoading}>
            {isLoading ? 'Registering...' : 'Register as Operator'}
          </button>
        </form>
        
        <div className="auth-footer">
          Already have an account? <Link to="/login">Login here</Link>
        </div>
      </div>
    </div>
  );
};

export default Register;
