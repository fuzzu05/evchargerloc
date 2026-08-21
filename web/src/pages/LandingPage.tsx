import { Link } from 'react-router-dom';
import { useEffect, useRef } from 'react';
import { Zap, MapPin, BatteryCharging, ChevronRight, Activity, ShieldCheck } from 'lucide-react';
import './LandingPage.css';

function LandingPage() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  const cursorDotRef = useRef<HTMLDivElement>(null);
  const cursorOutlineRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const moveCursor = (e) => {
      if (cursorDotRef.current && cursorOutlineRef.current) {
        cursorDotRef.current.style.left = e.clientX + 'px';
        cursorDotRef.current.style.top = e.clientY + 'px';
        
        cursorOutlineRef.current.animate({
          left: e.clientX + 'px',
          top: e.clientY + 'px'
        }, { duration: 500, fill: "forwards" });
      }
    };
    window.addEventListener('mousemove', moveCursor);
    return () => window.removeEventListener('mousemove', moveCursor);
  }, []);


  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;

    const particles = [];
    for (let i = 0; i < 50; i++) {
      particles.push({
        x: Math.random() * canvas.width,
        y: Math.random() * canvas.height,
        vx: (Math.random() - 0.5) * 1,
        vy: (Math.random() - 0.5) * 1
      });
    }

    let animationId;
    const animate = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.fillStyle = 'rgba(52, 211, 153, 0.5)';
      
      particles.forEach(p => {
        p.x += p.vx;
        p.y += p.vy;
        if (p.x < 0 || p.x > canvas.width) p.vx *= -1;
        if (p.y < 0 || p.y > canvas.height) p.vy *= -1;
        
        ctx.beginPath();
        ctx.arc(p.x, p.y, 2, 0, Math.PI * 2);
        ctx.fill();
      });

      // Draw edges
      ctx.lineWidth = 0.5;
      for (let i = 0; i < particles.length; i++) {
        for (let j = i + 1; j < particles.length; j++) {
          const dx = particles[i].x - particles[j].x;
          const dy = particles[i].y - particles[j].y;
          const dist = Math.sqrt(dx * dx + dy * dy);
          if (dist < 150) {
            ctx.strokeStyle = 'rgba(52, 211, 153, ' + (1 - dist/150) + ')';
            ctx.beginPath();
            ctx.moveTo(particles[i].x, particles[i].y);
            ctx.lineTo(particles[j].x, particles[j].y);
            ctx.stroke();
          }
        }
      }
      animationId = requestAnimationFrame(animate);
    };
    animate();

    return () => cancelAnimationFrame(animationId);
  }, []);

  return (
    <div className="landing-container">

      {/* Custom Cursor */}
      <div ref={cursorDotRef} className="custom-cursor-dot"></div>
      <div ref={cursorOutlineRef} className="custom-cursor-outline"></div>

      {/* Dynamic Background */}
      <canvas ref={canvasRef} className="particle-canvas"></canvas>
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

        
        {/* Rotating Rings */}
        <div className="hero-rings">
          <svg className="ring ring-1" viewBox="0 0 500 500">
            <circle cx="250" cy="250" r="220" fill="none" stroke="rgba(52, 211, 153, 0.4)" strokeWidth="2" strokeDasharray="12 18"></circle>
          </svg>
          <svg className="ring ring-2" viewBox="0 0 500 500">
            <circle cx="250" cy="250" r="160" fill="none" stroke="rgba(56, 189, 248, 0.35)" strokeWidth="1.5" strokeDasharray="6 14"></circle>
          </svg>
          <svg className="ring ring-3" viewBox="0 0 500 500">
            <circle cx="250" cy="250" r="100" fill="none" stroke="rgba(129, 140, 248, 0.2)" strokeWidth="1" strokeDasharray="4 8"></circle>
          </svg>
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
