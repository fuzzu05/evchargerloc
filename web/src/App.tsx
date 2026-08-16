import { useState, useEffect } from 'react';
import axios from 'axios';
import { Zap, BatteryCharging, Wrench, CheckCircle, Activity, Plus } from 'lucide-react';
import { Client } from '@stomp/stompjs';
import SockJS from 'sockjs-client';
import './App.css';

const API_BASE = 'http://localhost:8081/api';

interface Station {
  id: string;
  name: string;
  address: string;
  operatorId: string;
}

interface Charger {
  id: string;
  stationId: string;
  name: string;
  type: string;
  powerKw: number;
  status: string;
}

function App() {
  const [stations, setStations] = useState<Station[]>([]);
  const [selectedStation, setSelectedStation] = useState<Station | null>(null);
  const [chargers, setChargers] = useState<Charger[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchStations();

    // Setup STOMP WebSocket for real-time updates
    const socket = new SockJS('http://localhost:8081/ws');
    const client = new Client({
      webSocketFactory: () => socket,
      debug: (str) => console.log(str),
      onConnect: () => {
        console.log('Connected to WebSocket!');
        client.subscribe('/topic/chargers', (message) => {
          if (message.body) {
            const updatedCharger = JSON.parse(message.body) as Charger;
            console.log("Real-time update received:", updatedCharger);
            
            // Update the state instantly
            setChargers((prev) => 
              prev.map(c => c.id === updatedCharger.id ? updatedCharger : c)
            );
          }
        });
      },
      onStompError: (frame) => {
        console.error('WebSocket Error:', frame.headers['message']);
      },
    });

    client.activate();

    return () => {
      client.deactivate();
    };
  }, []);

  const fetchStations = async () => {
    try {
      const res = await axios.get(`${API_BASE}/stations`);
      setStations(res.data);
    } catch (e) {
      console.error("Failed to fetch stations", e);
    }
  };

  const fetchChargers = async (stationId: string) => {
    setLoading(true);
    try {
      const res = await axios.get(`${API_BASE}/chargers/station/${stationId}`);
      setChargers(res.data);
    } catch (e) {
      console.error("Failed to fetch chargers", e);
    } finally {
      setLoading(false);
    }
  };

  const updateChargerStatus = async (chargerId: string, status: string) => {
    try {
      await axios.put(`${API_BASE}/chargers/${chargerId}/status?status=${status}`);
      // Removed fetchChargers call because WebSocket will automatically update the UI instantly!
    } catch (e) {
      console.error("Failed to update status", e);
    }
  };

  const handleStationClick = (station: Station) => {
    setSelectedStation(station);
    fetchChargers(station.id);
  };

  const seedDemoData = async () => {
    try {
      // 1. Create Station
      const stationRes = await axios.post(`${API_BASE}/stations`, {
        name: "Bandra West Smart Hub",
        address: "Linking Road, Bandra West, Mumbai",
        operatorId: "OP-002",
        pricePerKwh: 18.0
      });
      const newStation = stationRes.data;

      // 2. Create Chargers
      await axios.post(`${API_BASE}/chargers`, { stationId: newStation.id, name: "Charger 1 (Fast)", type: "CCS2", powerKw: 150, status: "AVAILABLE" });
      await axios.post(`${API_BASE}/chargers`, { stationId: newStation.id, name: "Charger 2", type: "CCS2", powerKw: 50, status: "CHARGING" });
      await axios.post(`${API_BASE}/chargers`, { stationId: newStation.id, name: "Charger 3", type: "Type 2", powerKw: 22, status: "MAINTENANCE" });

      fetchStations();
    } catch (e) {
      console.error("Failed to seed data", e);
      alert("Make sure the Spring Boot backend is running on port 8081!");
    }
  };

  return (
    <div className="app-container">
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="sidebar-header">
          <Zap size={32} className="logo-icon" />
          <h2>EvWay Operator</h2>
        </div>

        <div className="station-list">
          <h3>Your Stations</h3>
          {stations.length === 0 ? (
            <div className="empty-state">
              <p>No stations found.</p>
            </div>
          ) : (
            stations.map(station => (
              <div
                key={station.id}
                className={`station-item ${selectedStation?.id === station.id ? 'active' : ''}`}
                onClick={() => handleStationClick(station)}
              >
                <div className="station-name">{station.name}</div>
                <div className="station-address">{station.address}</div>
              </div>
            ))
          )}

          <button onClick={seedDemoData} className="btn-primary" style={{ marginTop: '20px' }}>
            <Plus size={16} /> Seed Another Station
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="main-content">
        <header className="topbar">
          <h1>Dashboard Overview</h1>
          <div className="user-profile">Operator ID: OP-001</div>
        </header>

        {selectedStation ? (
          <div className="dashboard-content">
            <div className="station-header">
              <h2>{selectedStation.name}</h2>
              <span className="badge">Active</span>
            </div>

            <div className="chargers-grid">
              {loading ? (
                <p>Loading chargers...</p>
              ) : chargers.length === 0 ? (
                <p>No chargers installed at this station.</p>
              ) : (
                chargers.map(charger => (
                  <div key={charger.id} className="charger-card">
                    <div className="charger-header">
                      <h3>{charger.name}</h3>
                      <span className={`status-badge ${charger.status.toLowerCase()}`}>
                        {charger.status}
                      </span>
                    </div>

                    <div className="charger-details">
                      <p><strong>Type:</strong> {charger.type}</p>
                      <p><strong>Power:</strong> {charger.powerKw} kW</p>
                    </div>

                    <div className="action-buttons">
                      <button onClick={() => updateChargerStatus(charger.id, 'AVAILABLE')} className="action-btn btn-available">
                        <CheckCircle size={14} /> Set Available
                      </button>
                      <button onClick={() => updateChargerStatus(charger.id, 'CHARGING')} className="action-btn btn-charging">
                        <BatteryCharging size={14} /> Set Charging
                      </button>
                      <button onClick={() => updateChargerStatus(charger.id, 'MAINTENANCE')} className="action-btn btn-maintenance">
                        <Wrench size={14} /> Set Maintenance
                      </button>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        ) : (
          <div className="welcome-state">
            <Activity size={64} className="welcome-icon" />
            <h2>Select a station to manage chargers</h2>
            <p>Real-time updates will automatically sync with the mobile app.</p>
          </div>
        )}
      </main>
    </div>
  );
}

export default App;
