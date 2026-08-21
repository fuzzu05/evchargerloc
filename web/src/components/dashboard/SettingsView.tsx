import { useState, useEffect } from 'react';
import axios from 'axios';
import { 
  Building2, 
  MapPin, 
  Zap, 
  Coffee, 
  Wifi, 
  Droplet, 
  ShieldCheck, 
  ShoppingCart, 
  Clock, 
  Coins, 
  Users, 
  ShieldAlert, 
  Check, 
  UserPlus, 
  Power, 
  AlertTriangle, 
  Smartphone,
  CreditCard,
  Wallet,
  Loader2
} from 'lucide-react';

const API_BASE = 'https://evchargerloc.onrender.com/api';

interface Station {
  id: string;
  name: string;
  address: string;
  pricePerKwh: number;
  gridPower: string;
  
  hasCafe: boolean;
  hasWifi: boolean;
  hasRestroom: boolean;
  hasSecurity: boolean;
  hasStore: boolean;

  is247: boolean;
  openTime: string;
  closeTime: string;
  
  defaultSlot: string;
  bufferGrace: string;
  autoCancel: string;
  
  idlePenalty: number;
  peakPricing: boolean;
  payCash: boolean;
  payWallet: boolean;
  payCorporate: boolean;
  
  emergencyStop: boolean;
  outageMode: boolean;
  manualOtp: boolean;
}

export default function SettingsView() {
  const [stations, setStations] = useState<Station[]>([]);
  const [selectedStationId, setSelectedStationId] = useState<string>('');
  const [isLoading, setIsLoading] = useState(true);
  
  const [showToast, setShowToast] = useState(false);
  const [isAddOperatorOpen, setIsAddOperatorOpen] = useState(false);

  // States for toggles & inputs
  const [station, setStation] = useState<Partial<Station>>({});

  useEffect(() => {
    fetchStations();
  }, []);

  useEffect(() => {
    if (selectedStationId) {
      const selected = stations.find(s => s.id === selectedStationId);
      if (selected) setStation(selected);
    }
  }, [selectedStationId, stations]);

  const fetchStations = async () => {
    try {
      setIsLoading(true);
      const response = await axios.get(`${API_BASE}/stations/my-stations`);
      setStations(response.data);
      if (response.data.length > 0) {
        setSelectedStationId(response.data[0].id);
        setStation(response.data[0]);
      }
    } catch (err) {
      console.error('Error fetching stations:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSave = async () => {
    if (!selectedStationId) return;
    try {
      await axios.put(`${API_BASE}/stations/${selectedStationId}`, station);
      setShowToast(true);
      setTimeout(() => setShowToast(false), 3000);
      
      // Update local state
      setStations(stations.map(s => s.id === selectedStationId ? { ...s, ...station } as Station : s));
    } catch (err) {
      console.error('Error saving station:', err);
      alert('Failed to save changes');
    }
  };

  const updateStation = (key: keyof Station, value: any) => {
    setStation(prev => ({ ...prev, [key]: value }));
  };

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center h-64">
        <Loader2 className="w-8 h-8 text-[#144295] animate-spin mb-4" />
        <p className="text-slate-500 font-medium">Loading settings...</p>
      </div>
    );
  }

  if (stations.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center bg-white border border-slate-100 rounded-2xl p-16 text-center shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] h-[60vh]">
        <div className="w-20 h-20 bg-blue-50/80 rounded-full flex items-center justify-center mb-6">
          <Building2 className="w-10 h-10 text-[#1d4ed8]" />
        </div>
        <h2 className="text-2xl font-bold text-slate-800 mb-2">No stations found</h2>
        <p className="text-slate-500 mb-8 max-w-md">
          You need to add a station from the Stations tab before managing settings.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6 pb-12 relative">
      {/* Toast Notification */}
      {showToast && (
        <div className="fixed top-6 right-6 z-50 bg-slate-800 text-white px-4 py-3 rounded-xl shadow-lg flex items-center gap-3 animate-in fade-in slide-in-from-top-5 duration-300">
          <div className="w-6 h-6 bg-emerald-500/20 rounded-full flex items-center justify-center shrink-0">
            <Check className="w-4 h-4 text-emerald-400" />
          </div>
          <p className="text-sm font-bold">Settings saved successfully!</p>
        </div>
      )}

      {/* Header & Controls */}
      <div className="flex flex-col lg:flex-row lg:items-start justify-between gap-4 mb-2">
        <div>
          <div className="flex items-center gap-4 mb-1">
            <h1 className="text-2xl font-bold text-slate-800">Station Configuration & Operator Settings</h1>
            <select
              value={selectedStationId}
              onChange={(e) => setSelectedStationId(e.target.value)}
              className="appearance-none bg-white border border-slate-200 text-slate-700 py-1 pl-3 pr-8 rounded-md text-sm font-semibold focus:outline-none shadow-sm cursor-pointer"
            >
              {stations.map(station => (
                <option key={station.id} value={station.id}>{station.name}</option>
              ))}
            </select>
          </div>
          <p className="text-slate-400 text-[13px] max-w-2xl mt-1">
            Manage station profile, operational timing, dynamic pricing rules, multiple station operators, and emergency protocols.
          </p>
        </div>
        <div className="flex flex-col sm:flex-row gap-3">
          <button 
            onClick={() => setStation(stations.find(s => s.id === selectedStationId) || {})}
            className="px-4 py-2 bg-white border border-slate-200 hover:bg-slate-50 text-slate-700 rounded-lg text-sm font-bold transition-colors shadow-sm"
          >
            Discard Changes
          </button>
          <button 
            onClick={handleSave}
            className="flex items-center justify-center px-4 py-2 bg-[#1d4ed8] hover:bg-[#1e3a8a] text-white rounded-lg text-sm font-bold transition-colors shadow-sm"
          >
            <Check className="w-4 h-4 mr-2" />
            Save Changes
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        {/* Column 1 */}
        <div className="space-y-6">
          {/* Card 1: Station Details & Geolocation */}
          <div className="bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-slate-100 p-6">
            <div className="flex items-center gap-2 mb-6">
              <Building2 className="w-5 h-5 text-[#1d4ed8]" />
              <h2 className="text-lg font-bold text-slate-800">Station Details & Geolocation</h2>
            </div>
            
            <div className="space-y-4">
              <div>
                <label className="block text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1.5">Station Name</label>
                <div className="flex gap-2">
                  <input 
                    type="text" 
                    value={station.name || ''} 
                    onChange={e => updateStation('name', e.target.value)}
                    className="flex-1 px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-[#144295]/20 focus:border-[#144295]" 
                  />
                  <div className="bg-slate-100 text-slate-500 px-3 py-2 rounded-lg text-sm font-bold font-mono border border-slate-200 shrink-0 flex items-center">
                    {station.id ? station.id.substring(0, 10).toUpperCase() : 'UNKNOWN'}
                  </div>
                </div>
              </div>

              <div>
                <label className="block text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1.5">Address / Location</label>
                <div className="relative">
                  <MapPin className="absolute left-3 top-2.5 w-4 h-4 text-slate-400" />
                  <input 
                    type="text" 
                    value={station.address || ''} 
                    onChange={e => updateStation('address', e.target.value)}
                    className="w-full pl-9 pr-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-[#144295]/20 focus:border-[#144295]" 
                  />
                </div>
              </div>

              <div>
                <label className="block text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1.5">Total Sanctioned Grid Power</label>
                <div className="relative">
                  <Zap className="absolute left-3 top-2.5 w-4 h-4 text-slate-400" />
                  <select 
                    value={station.gridPower || '200 kW (3-Phase HT Connection)'}
                    onChange={e => updateStation('gridPower', e.target.value)}
                    className="w-full pl-9 pr-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-[#144295]/20 focus:border-[#144295] appearance-none"
                  >
                    <option>200 kW (3-Phase HT Connection)</option>
                    <option>100 kW (3-Phase LT Connection)</option>
                    <option>50 kW (Standard Connection)</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-2">Station Amenities</label>
                <div className="flex flex-wrap gap-2">
                  <button onClick={() => updateStation('hasCafe', !station.hasCafe)} className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold border transition-colors ${station.hasCafe ? 'bg-blue-50 text-[#1d4ed8] border-blue-200' : 'bg-white text-slate-500 border-slate-200'}`}>
                    <Coffee className="w-3.5 h-3.5" /> Cafe / Lounge
                  </button>
                  <button onClick={() => updateStation('hasWifi', !station.hasWifi)} className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold border transition-colors ${station.hasWifi ? 'bg-blue-50 text-[#1d4ed8] border-blue-200' : 'bg-white text-slate-500 border-slate-200'}`}>
                    <Wifi className="w-3.5 h-3.5" /> Free WiFi
                  </button>
                  <button onClick={() => updateStation('hasRestroom', !station.hasRestroom)} className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold border transition-colors ${station.hasRestroom ? 'bg-blue-50 text-[#1d4ed8] border-blue-200' : 'bg-white text-slate-500 border-slate-200'}`}>
                    <Droplet className="w-3.5 h-3.5" /> Restrooms
                  </button>
                  <button onClick={() => updateStation('hasSecurity', !station.hasSecurity)} className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold border transition-colors ${station.hasSecurity ? 'bg-blue-50 text-[#1d4ed8] border-blue-200' : 'bg-white text-slate-500 border-slate-200'}`}>
                    <ShieldCheck className="w-3.5 h-3.5" /> 24/7 Security
                  </button>
                  <button onClick={() => updateStation('hasStore', !station.hasStore)} className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold border transition-colors ${station.hasStore ? 'bg-blue-50 text-[#1d4ed8] border-blue-200' : 'bg-white text-slate-500 border-slate-200'}`}>
                    <ShoppingCart className="w-3.5 h-3.5" /> Store
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Card 2: Operating Hours & Auto-Slot Generation */}
          <div className="bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-slate-100 p-6">
            <div className="flex items-center gap-2 mb-6">
              <Clock className="w-5 h-5 text-indigo-600" />
              <h2 className="text-lg font-bold text-slate-800">Operating Hours & Bookings</h2>
            </div>

            <div className="space-y-5">
              <div className="flex items-center justify-between p-3 rounded-lg border border-slate-200 bg-slate-50">
                <div>
                  <p className="text-sm font-bold text-slate-800">24/7 Continuous Operation</p>
                  <p className="text-xs text-slate-500">Disable to set custom shift hours</p>
                </div>
                <button 
                  onClick={() => updateStation('is247', !station.is247)}
                  className={`w-11 h-6 rounded-full transition-colors relative flex items-center ${station.is247 ? 'bg-indigo-600' : 'bg-slate-300'}`}
                >
                  <span className={`w-4 h-4 bg-white rounded-full shadow-sm absolute transition-transform ${station.is247 ? 'translate-x-6' : 'translate-x-1'}`}></span>
                </button>
              </div>

              {!station.is247 && (
                <div className="grid grid-cols-2 gap-4 animate-in slide-in-from-top-2 fade-in duration-200">
                  <div>
                    <label className="block text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1.5">Opening Time</label>
                    <input type="time" value={station.openTime || '06:00'} onChange={e => updateStation('openTime', e.target.value)} className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-[#144295]/20 focus:border-[#144295]" />
                  </div>
                  <div>
                    <label className="block text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1.5">Closing Time</label>
                    <input type="time" value={station.closeTime || '23:00'} onChange={e => updateStation('closeTime', e.target.value)} className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-[#144295]/20 focus:border-[#144295]" />
                  </div>
                </div>
              )}

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-4 border-t border-slate-100">
                <div>
                  <label className="block text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1.5">Default Slot</label>
                  <select 
                    value={station.defaultSlot || '30 mins [Default]'}
                    onChange={e => updateStation('defaultSlot', e.target.value)}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-900 bg-white focus:outline-none focus:ring-2 focus:ring-[#144295]/20 focus:border-[#144295]"
                  >
                    <option>15 mins</option>
                    <option>30 mins [Default]</option>
                    <option>45 mins</option>
                    <option>60 mins</option>
                  </select>
                </div>
                <div>
                  <label className="block text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1.5">Buffer Grace</label>
                  <select 
                    value={station.bufferGrace || '5 mins'}
                    onChange={e => updateStation('bufferGrace', e.target.value)}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-900 bg-white focus:outline-none focus:ring-2 focus:ring-[#144295]/20 focus:border-[#144295]"
                  >
                    <option>5 mins</option>
                    <option>10 mins</option>
                    <option>None</option>
                  </select>
                </div>
                <div>
                  <label className="block text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1.5">Auto-Cancel</label>
                  <select 
                    value={station.autoCancel || 'After 10 mins'}
                    onChange={e => updateStation('autoCancel', e.target.value)}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-900 bg-white focus:outline-none focus:ring-2 focus:ring-[#144295]/20 focus:border-[#144295]"
                  >
                    <option>After 10 mins</option>
                    <option>After 15 mins</option>
                    <option>Never</option>
                  </select>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Column 2 */}
        <div className="space-y-6">
          {/* Card 3: Tariff, Peak Pricing & Payment Rules */}
          <div className="bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-slate-100 p-6">
            <div className="flex items-center gap-2 mb-6">
              <Coins className="w-5 h-5 text-emerald-600" />
              <h2 className="text-lg font-bold text-slate-800">Tariff & Payments</h2>
            </div>
            
            <div className="space-y-5">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1.5">Base Tariff (per kWh)</label>
                  <div className="relative">
                    <span className="absolute left-3 top-2.5 text-slate-500 font-bold">₹</span>
                    <input 
                      type="number" 
                      value={station.pricePerKwh || 0} 
                      onChange={e => updateStation('pricePerKwh', parseFloat(e.target.value))}
                      step="0.50" 
                      className="w-full pl-8 pr-3 py-2 border border-slate-200 rounded-lg text-sm font-bold text-slate-900 focus:outline-none focus:ring-2 focus:ring-[#144295]/20 focus:border-[#144295]" 
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1.5">Idle Penalty (per min)</label>
                  <div className="relative">
                    <span className="absolute left-3 top-2.5 text-slate-500 font-bold">₹</span>
                    <input 
                      type="number" 
                      value={station.idlePenalty || 0} 
                      onChange={e => updateStation('idlePenalty', parseFloat(e.target.value))}
                      step="1.00" 
                      className="w-full pl-8 pr-3 py-2 border border-slate-200 rounded-lg text-sm font-bold text-slate-900 focus:outline-none focus:ring-2 focus:ring-[#144295]/20 focus:border-[#144295]" 
                    />
                  </div>
                  <p className="text-[10px] text-slate-400 mt-1">Applies 15m after full charge</p>
                </div>
              </div>

              <div className="flex items-start justify-between p-3 rounded-lg border border-emerald-100 bg-emerald-50/50">
                <div>
                  <p className="text-sm font-bold text-emerald-800">Dynamic Peak Surge</p>
                  <p className="text-xs text-emerald-600 mt-0.5 max-w-[200px] leading-snug">Adds ₹2.00/kWh during peak load hours (6:00 PM – 8:30 PM)</p>
                </div>
                <button 
                  onClick={() => updateStation('peakPricing', !station.peakPricing)}
                  className={`w-11 h-6 rounded-full transition-colors relative flex items-center shrink-0 ${station.peakPricing ? 'bg-emerald-500' : 'bg-slate-300'}`}
                >
                  <span className={`w-4 h-4 bg-white rounded-full shadow-sm absolute transition-transform ${station.peakPricing ? 'translate-x-6' : 'translate-x-1'}`}></span>
                </button>
              </div>

              <div className="pt-2">
                <label className="block text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-3">Accepted Payment Methods</label>
                <div className="space-y-3">
                  <label className="flex items-center gap-3 cursor-pointer">
                    <input type="checkbox" checked={station.payCash || false} onChange={() => updateStation('payCash', !station.payCash)} className="w-4 h-4 rounded text-[#1d4ed8] focus:ring-[#1d4ed8]" />
                    <Smartphone className="w-4 h-4 text-slate-400" />
                    <span className="text-sm font-bold text-slate-700">Pay at Station (Cash / UPI QR)</span>
                  </label>
                  <label className="flex items-center gap-3 cursor-pointer">
                    <input type="checkbox" checked={station.payWallet || false} onChange={() => updateStation('payWallet', !station.payWallet)} className="w-4 h-4 rounded text-[#1d4ed8] focus:ring-[#1d4ed8]" />
                    <Wallet className="w-4 h-4 text-slate-400" />
                    <span className="text-sm font-bold text-slate-700">EvWay In-App Wallet</span>
                  </label>
                  <label className="flex items-center gap-3 cursor-pointer">
                    <input type="checkbox" checked={station.payCorporate || false} onChange={() => updateStation('payCorporate', !station.payCorporate)} className="w-4 h-4 rounded text-[#1d4ed8] focus:ring-[#1d4ed8]" />
                    <CreditCard className="w-4 h-4 text-slate-400" />
                    <span className="text-sm font-bold text-slate-700">Corporate Fleet Card</span>
                  </label>
                </div>
              </div>
            </div>
          </div>

          {/* Card 5: Emergency Protocols & Fallback Triggers */}
          <div className="bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-rose-100 p-6 relative overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 bg-rose-50 rounded-bl-full -z-10 opacity-50"></div>
            <div className="flex items-center gap-2 mb-6">
              <ShieldAlert className="w-5 h-5 text-rose-600" />
              <h2 className="text-lg font-bold text-slate-800">Emergency Protocols</h2>
            </div>

            <div className="space-y-4">
              <div className="flex items-center justify-between p-3 rounded-lg border border-rose-200 bg-rose-50">
                <div>
                  <p className="text-sm font-bold text-rose-800 flex items-center gap-2">
                    <Power className="w-4 h-4" /> Manual Emergency Stop
                  </p>
                  <p className="text-[11px] text-rose-600 mt-0.5">Force all guns offline instantly</p>
                </div>
                <button 
                  onClick={() => updateStation('emergencyStop', !station.emergencyStop)}
                  className={`w-11 h-6 rounded-full transition-colors relative flex items-center ${station.emergencyStop ? 'bg-rose-600' : 'bg-rose-200'}`}
                >
                  <span className={`w-4 h-4 bg-white rounded-full shadow-sm absolute transition-transform ${station.emergencyStop ? 'translate-x-6' : 'translate-x-1'}`}></span>
                </button>
              </div>

              <div className="flex items-center justify-between p-3 rounded-lg border border-amber-200 bg-amber-50">
                <div>
                  <p className="text-sm font-bold text-amber-800 flex items-center gap-2">
                    <AlertTriangle className="w-4 h-4" /> Grid Outage Mode
                  </p>
                  <p className="text-[11px] text-amber-700 mt-0.5">Notify booked drivers of power cut</p>
                </div>
                <button 
                  onClick={() => updateStation('outageMode', !station.outageMode)}
                  className={`w-11 h-6 rounded-full transition-colors relative flex items-center ${station.outageMode ? 'bg-amber-500' : 'bg-amber-200'}`}
                >
                  <span className={`w-4 h-4 bg-white rounded-full shadow-sm absolute transition-transform ${station.outageMode ? 'translate-x-6' : 'translate-x-1'}`}></span>
                </button>
              </div>

              <div className="flex items-center justify-between p-3 rounded-lg border border-slate-200 bg-slate-50">
                <div>
                  <p className="text-sm font-bold text-slate-800">QR Hardware Fallback</p>
                  <p className="text-[11px] text-slate-500 mt-0.5">Enable manual OTP phone check-in</p>
                </div>
                <button 
                  onClick={() => updateStation('manualOtp', !station.manualOtp)}
                  className={`w-11 h-6 rounded-full transition-colors relative flex items-center ${station.manualOtp ? 'bg-slate-600' : 'bg-slate-300'}`}
                >
                  <span className={`w-4 h-4 bg-white rounded-full shadow-sm absolute transition-transform ${station.manualOtp ? 'translate-x-6' : 'translate-x-1'}`}></span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Card 4: Multi-Operator Access & Station Roles */}
      <div className="bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-slate-100 p-6 mt-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
          <div className="flex items-center gap-2">
            <Users className="w-5 h-5 text-blue-500" />
            <div>
              <h2 className="text-lg font-bold text-slate-800">Multi-Operator Access</h2>
              <p className="text-xs text-slate-500">Authorize staff members to manage this station</p>
            </div>
          </div>
          <button 
            onClick={() => setIsAddOperatorOpen(true)}
            className="flex items-center justify-center px-4 py-2 bg-white border border-slate-200 hover:border-[#1d4ed8] hover:text-[#1d4ed8] text-slate-700 rounded-lg text-sm font-bold transition-all shadow-sm shrink-0"
          >
            <UserPlus className="w-4 h-4 mr-2" />
            Add Operator Member
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-slate-100 bg-slate-50/50">
                <th className="py-3 px-4 text-[11px] font-bold text-slate-500 uppercase tracking-wider">Member Name</th>
                <th className="py-3 px-4 text-[11px] font-bold text-slate-500 uppercase tracking-wider">Role / Access Level</th>
                <th className="py-3 px-4 text-[11px] font-bold text-slate-500 uppercase tracking-wider text-right">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              <tr className="hover:bg-slate-50/50 transition-colors group">
                <td className="py-3 px-4">
                  <p className="text-sm font-bold text-slate-800">Primary Operator <span className="text-xs font-normal text-slate-500 ml-1">(Lead)</span></p>
                </td>
                <td className="py-3 px-4">
                  <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-bold bg-blue-50 text-blue-700 border border-blue-100">Admin / Full Access</span>
                </td>
                <td className="py-3 px-4 text-right">
                  <span className="inline-flex items-center gap-1.5 text-xs font-bold text-emerald-600">
                    <span className="w-2 h-2 rounded-full bg-emerald-500"></span> Active Now
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      {/* Add Operator Modal */}
      {isAddOperatorOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 backdrop-blur-sm p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            <div className="px-6 py-4 border-b border-slate-100 flex justify-between items-center bg-slate-50/50">
              <h2 className="text-lg font-bold text-slate-800 flex items-center gap-2">
                <UserPlus className="w-5 h-5 text-[#1d4ed8]" /> Add Operator Member
              </h2>
            </div>
            
            <div className="p-6 space-y-4">
              <div>
                <label className="block text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1.5">Full Name</label>
                <input type="text" placeholder="e.g. Suresh Patel" className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-900 bg-white focus:outline-none focus:ring-2 focus:ring-[#144295]/20 focus:border-[#144295]" />
              </div>
              
              <div>
                <label className="block text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1.5">Email Address</label>
                <input type="email" placeholder="suresh@evway.in" className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-900 bg-white focus:outline-none focus:ring-2 focus:ring-[#144295]/20 focus:border-[#144295]" />
              </div>

              <div>
                <label className="block text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1.5">Access Role</label>
                <select className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm text-slate-900 bg-white focus:outline-none focus:ring-2 focus:ring-[#144295]/20 focus:border-[#144295]">
                  <option>Station Attendant (Slot Controls)</option>
                  <option>Technician (Hardware Diagnostics)</option>
                  <option>Admin (Full Access)</option>
                </select>
              </div>

              <div className="bg-blue-50 p-3 rounded-lg border border-blue-100 mt-4">
                <p className="text-xs text-blue-800 font-medium">
                  An email invitation will be sent with a secure login link. They must verify their phone number on first login.
                </p>
              </div>

              <div className="pt-4 mt-2 flex justify-end gap-3">
                <button 
                  onClick={() => setIsAddOperatorOpen(false)}
                  className="px-4 py-2 text-sm font-bold text-slate-600 hover:text-slate-800 hover:bg-slate-50 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  onClick={() => setIsAddOperatorOpen(false)}
                  className="px-4 py-2 text-sm font-bold text-white bg-[#1d4ed8] hover:bg-[#1e3a8a] rounded-lg transition-colors shadow-sm"
                >
                  Send Invite
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
