import { Link } from 'react-router-dom';
import { useEffect, useRef, useState } from 'react';
import { Sun, Moon } from 'lucide-react';
import { Zap, MapPin, BatteryCharging, ChevronRight, Activity, ShieldCheck } from 'lucide-react';
import './LandingPage.css';

function LandingPage() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  const cursorDotRef = useRef<HTMLDivElement>(null);
  const cursorOutlineRef = useRef<HTMLDivElement>(null);
  const [isScrolled, setIsScrolled] = useState(false);
  const [isDarkMode, setIsDarkMode] = useState(true);

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
    const handleScroll = () => setIsScrolled(window.scrollY > 50);
    window.addEventListener('scroll', handleScroll);
    return () => {
      window.removeEventListener('mousemove', moveCursor);
      window.removeEventListener('scroll', handleScroll);
    };
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
      <nav className={"landing-nav " + (isScrolled ? "scrolled" : "")}>
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

      
      {/* How It Works Section */}
      <section className="how-it-works-section">
        <h2 className="section-title">How It Works</h2>
        <div className="steps-container">
          <div className="step-card">
            <div className="step-icon"><MapPin size={32} /></div>
            <h3>1. Locate</h3>
            <p>Find nearby compatible EV chargers in real-time.</p>
          </div>
          <div className="step-connector"></div>
          <div className="step-card">
            <div className="step-icon"><Activity size={32} /></div>
            <h3>2. Book</h3>
            <p>Reserve your slot to avoid waiting queues.</p>
          </div>
          <div className="step-connector"></div>
          <div className="step-card">
            <div className="step-icon"><BatteryCharging size={32} /></div>
            <h3>3. Charge & Pay</h3>
            <p>Seamless auto-deduction and real-time charging status.</p>
          </div>
        </div>
      </section>

      
      {/* Slot Booking Showcase */}
      <section id="booking-showcase" className="booking-showcase-section">
        <div className="showcase-content">
          <h2>Smart Slot Booking</h2>
          <p>The core of our SIH problem statement. Never wait in line again. Book your precise charging slot in advance.</p>
        </div>
        <div className="showcase-visual">
          <div className="booking-ui-mockup">
            <h3>Select a Slot for Today</h3>
            <div className="slots-grid">
              <div className="time-slot available">10:00 AM</div>
              <div className="time-slot booked">11:00 AM</div>
              <div className="time-slot available selected">12:00 PM</div>
              <div className="time-slot available">01:00 PM</div>
            </div>
            <button className="btn-confirm-booking">Confirm Booking (₹50)</button>
          </div>
        </div>
      </section>

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
