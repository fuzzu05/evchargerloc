import { Link } from 'react-router-dom';
import { Zap, MapPin, BatteryCharging, ChevronRight, Activity, ShieldCheck } from 'lucide-react';
import './LandingPage.css';

function LandingPage() {
  return (
    <div className="landing-container">
      {/* Dynamic Background */}
      <div className="bg-glow bg-glow-blue"></div>
      <div className="bg-glow bg-glow-green"></div>

      {/* Navigation */}
      <nav className="landing-nav">
        <div className="nav-logo">
          <Zap size={28} className="logo-icon text-green" />
          <span className="logo-text">EvWay</span>
        </div>
        <div className="nav-links">
          <Link to="/dashboard" className="btn-operator-login">
            Operator Login
            <ChevronRight size={16} />
          </Link>
        </div>
      </nav>

      {/* Hero Section */}
      <header className="hero-section">
        <div className="hero-content">
          <div className="badge-pill">
            <span className="live-dot"></span>
            Smart EV Charging Network
          </div>
          <h1 className="hero-title">
            Charge Your Future with <span className="text-gradient">EvWay</span>
          </h1>
          <p className="hero-subtitle">
            Find the fastest chargers, book instantly, and track your route in real-time. Whether you drive an EV or operate a station, EvWay is your ultimate companion.
          </p>
          <div className="hero-actions">
            <a href="/EvWay.apk" download className="btn-download" style={{ textDecoration: 'none' }}>
              Download the App
            </a>
            <Link to="/dashboard" className="btn-secondary">
              Manage Your Station
            </Link>
          </div>
        </div>

        {/* Floating Glass Cards */}
        <div className="hero-visuals">
          <div className="glass-card card-top">
            <div className="card-icon"><MapPin size={24} /></div>
            <div>
              <h4>Real-Time Navigation</h4>
              <p>Turn-by-turn guidance to your charger.</p>
            </div>
          </div>
          <div className="glass-card card-bottom">
            <div className="card-icon"><BatteryCharging size={24} /></div>
            <div>
              <h4>Instant Booking</h4>
              <p>Reserve slots before you arrive.</p>
            </div>
          </div>
        </div>
      </header>

      {/* Features Section */}
      <section className="features-section">
        <div className="feature-grid">
          <div className="feature-card">
            <Activity size={32} className="feature-icon blue" />
            <h3>Live Availability</h3>
            <p>Know exactly which chargers are open right now.</p>
          </div>
          <div className="feature-card">
            <ShieldCheck size={32} className="feature-icon green" />
            <h3>Secure Payments</h3>
            <p>Wallet-based seamless auto-deduction system.</p>
          </div>
          <div className="feature-card">
            <Zap size={32} className="feature-icon blue" />
            <h3>Super Fast</h3>
            <p>Filter by kW power to find ultra-fast DC chargers.</p>
          </div>
        </div>
      </section>
    </div>
  );
}

export default LandingPage;
