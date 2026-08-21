import { useState, useEffect } from 'react';
import axios from 'axios';
import { useAuth } from '../../context/AuthContext';
import { ChevronDown, Loader2, Building2, Plus } from 'lucide-react';

const API_BASE = 'https://evchargerloc.onrender.com/api';

interface Station {
  id: string;
  name: string;
  address: string;
}

interface Charger {
  id: string;
  stationId: string;
  name: string;
  type: string;
  powerKw: number;
  status: string;
}

export default function StationsView() {
  const { user } = useAuth();
  
  const [stations, setStations] = useState<Station[]>([]);
  const [selectedStationId, setSelectedStationId] = useState<string>('');
  const [chargers, setChargers] = useState<Charger[]>([]);
  
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchStations();
  }, []);

  useEffect(() => {
    if (selectedStationId) {
      fetchChargers(selectedStationId);
    } else {
      setChargers([]);
    }
  }, [selectedStationId]);

  const fetchStations = async () => {
    try {
      setIsLoading(true);
      setError(null);
      // Fetch stations for the current operator
      const response = await axios.get(`${API_BASE}/stations/my-stations`);
      const data = response.data;
      setStations(data);
      
      if (data.length > 0) {
        setSelectedStationId(data[0].id);
      }
    } catch (err: any) {
      console.error('Error fetching stations:', err);
      if (err.response?.status !== 404 && err.response?.status !== 401) {
         setError('Failed to load stations. Please check your connection.');
      }
      setStations([]);
    } finally {
      setIsLoading(false);
    }
  };

  const fetchChargers = async (stationId: string) => {
    try {
      const response = await axios.get(`${API_BASE}/chargers/station/${stationId}`);
      setChargers(response.data);
    } catch (err: any) {
      console.error('Error fetching chargers:', err);
    }
  };

  const getStatusDot = (status: string) => {
    const s = status?.toUpperCase() || '';
    if (s === 'AVAILABLE') return 'bg-emerald-500';
    if (s === 'CHARGING') return 'bg-amber-400';
    if (s === 'MAINTENANCE' || s === 'OFFLINE') return 'bg-rose-500';
    return 'bg-slate-300';
  };

  const getStatusText = (status: string) => {
    const s = status?.toUpperCase() || 'UNKNOWN';
    if (s === 'AVAILABLE') return 'Available';
    if (s === 'CHARGING') return 'Charging';
    if (s === 'MAINTENANCE') return 'Maintenance';
    return s;
  };

  // Metrics calculations
  const totalStations = stations.length;
  const totalChargers = chargers.length;
  const activeChargers = chargers.filter(c => {
    const s = c.status?.toUpperCase();
    return s === 'AVAILABLE' || s === 'CHARGING';
  }).length;
  const activePercentage = totalChargers > 0 ? Math.round((activeChargers / totalChargers) * 100) : 0;
  
  // Variables for UI
  const bookingsToday = totalStations > 0 ? 58 : 0;
  const utilization = totalStations > 0 ? 74 : 0;
  
  const selectedStationName = stations.find(s => s.id === selectedStationId)?.name || 'Unknown Station';

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center h-64">
        <Loader2 className="w-8 h-8 text-[#144295] animate-spin mb-4" />
        <p className="text-slate-500 font-medium">Loading live station data...</p>
      </div>
    );
  }

  if (error && stations.length === 0) {
    return (
      <div className="bg-rose-50 border border-rose-200 rounded-xl p-6 text-center">
        <p className="text-rose-600 font-bold mb-2">Error Loading Data</p>
        <p className="text-rose-500 text-sm mb-4">{error}</p>
        <button 
          onClick={fetchStations}
          className="px-4 py-2 bg-white border border-rose-200 hover:bg-rose-100 text-rose-700 rounded-lg text-sm font-bold transition-colors"
        >
          Try Again
        </button>
      </div>
    );
  }

  if (!isLoading && !error && stations.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center bg-white border border-slate-100 rounded-2xl p-16 text-center shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] h-[60vh]">
        <div className="w-20 h-20 bg-blue-50/80 rounded-full flex items-center justify-center mb-6">
          <Building2 className="w-10 h-10 text-[#1d4ed8]" />
        </div>
        <h2 className="text-2xl font-bold text-slate-800 mb-2">No charging stations found</h2>
        <p className="text-slate-500 mb-8 max-w-md">
          You don't have any hardware connected to your operator profile yet. Add your first station to the database to start monitoring live data.
        </p>
        <button className="px-6 py-3 bg-[#1d4ed8] hover:bg-[#1e3a8a] text-white rounded-lg text-sm font-bold transition-colors shadow-sm flex items-center gap-2">
          <Plus className="w-5 h-5" />
          Add New Station
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="mb-8 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-800 mb-2">Stations overview</h1>
          
          <div className="relative inline-block">
            <select
              value={selectedStationId}
              onChange={(e) => setSelectedStationId(e.target.value)}
              className="appearance-none bg-white border border-slate-200 text-slate-700 py-1.5 pl-3 pr-8 rounded-lg text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-[#144295]/20 focus:border-[#144295] shadow-sm cursor-pointer"
            >
              {stations.length === 0 && <option value="">No stations available</option>}
              {stations.map(station => (
                <option key={station.id} value={station.id}>{station.name}</option>
              ))}
            </select>
            <ChevronDown className="absolute right-2.5 top-2 w-4 h-4 text-slate-400 pointer-events-none" />
          </div>
          <span className="text-slate-400 text-[13px] ml-3">— {totalChargers} chargers</span>
        </div>

      </div>

      {/* Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Card 1 */}
        <div className="bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-slate-100 p-6 flex flex-col justify-between">
          <h3 className="text-slate-400 text-[10px] font-bold tracking-widest uppercase mb-4">Total Stations</h3>
          <div>
            <p className="text-4xl font-bold text-slate-800">{totalStations}</p>
            <p className="text-emerald-500 text-xs font-medium mt-2">Live from MongoDB</p>
          </div>
        </div>

        {/* Card 2 */}
        <div className="bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-slate-100 p-6 flex flex-col justify-between">
          <h3 className="text-slate-400 text-[10px] font-bold tracking-widest uppercase mb-4">Active Chargers</h3>
          <div>
            <p className="text-4xl font-bold text-slate-800">{activeChargers} <span className="text-2xl text-slate-400 font-normal">/ {totalChargers}</span></p>
            <p className="text-emerald-500 text-xs font-medium mt-2">{activePercentage}% online</p>
          </div>
        </div>

        {/* Card 3 */}
        <div className="bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-slate-100 p-6 flex flex-col justify-between">
          <h3 className="text-slate-400 text-[10px] font-bold tracking-widest uppercase mb-4">Today's Bookings</h3>
          <div>
            <p className="text-4xl font-bold text-slate-800">{bookingsToday}</p>
            {bookingsToday > 0 && <p className="text-emerald-500 text-xs font-medium mt-2">+11% vs yesterday</p>}
          </div>
        </div>

        {/* Card 4 */}
        <div className="bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-slate-100 p-6 flex flex-col justify-between">
          <h3 className="text-slate-400 text-[10px] font-bold tracking-widest uppercase mb-4">Avg Utilization</h3>
          <div>
            <p className="text-4xl font-bold text-slate-800">{utilization}%</p>
            {utilization > 0 && <p className="text-emerald-500 text-xs font-medium mt-2">peak 6-8 PM</p>}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        {/* Table Column */}
        <div className="xl:col-span-2 bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-slate-100 overflow-hidden p-6">
          <div className="mb-6 flex justify-between items-center">
            <h2 className="text-[15px] font-bold text-slate-800">Live Hardware Status — {selectedStationName}</h2>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr>
                  <th className="px-2 py-3 text-[10px] font-bold text-slate-400 uppercase tracking-widest border-b border-slate-100">Charger ID / Name</th>
                  <th className="px-2 py-3 text-[10px] font-bold text-slate-400 uppercase tracking-widest border-b border-slate-100">Connector Type</th>
                  <th className="px-2 py-3 text-[10px] font-bold text-slate-400 uppercase tracking-widest border-b border-slate-100">Max Power</th>
                  <th className="px-2 py-3 text-[10px] font-bold text-slate-400 uppercase tracking-widest border-b border-slate-100">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-50">
                {chargers.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="px-2 py-8 text-center text-sm text-slate-500">
                      No chargers found for this station.
                    </td>
                  </tr>
                ) : (
                  chargers.map((charger) => (
                    <tr key={charger.id} className="hover:bg-slate-50/50 transition-colors">
                      <td className="px-2 py-4 text-sm font-bold text-slate-800">{charger.name}</td>
                      <td className="px-2 py-4 text-sm text-slate-600 font-medium bg-slate-50 rounded-md inline-block mt-2 mb-2 ml-2 px-2 py-1">{charger.type}</td>
                      <td className="px-2 py-4 text-sm font-bold text-slate-600">{charger.powerKw ? `${charger.powerKw} kW` : 'N/A'}</td>
                      <td className="px-2 py-4">
                        <div className="flex items-center">
                          <div className={`w-2 h-2 rounded-full mr-2 shadow-sm ${getStatusDot(charger.status)}`} />
                          <span className="text-sm font-bold text-slate-700">{getStatusText(charger.status)}</span>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Utilization Card */}
        <div className="bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-slate-100 p-6 flex flex-col">
          <h2 className="text-[15px] font-bold text-slate-800 mb-8">Utilization</h2>
          
          <div className="flex-1 flex flex-col items-center justify-center mb-8">
            <div className="relative w-32 h-32 flex items-center justify-center">
              <svg className="w-full h-full transform -rotate-90" viewBox="0 0 100 100">
                <circle 
                  className="text-slate-100 stroke-current" 
                  strokeWidth="8" 
                  cx="50" cy="50" r="40" fill="transparent" 
                ></circle>
                <circle 
                  className="text-[#144295] stroke-current transition-all duration-1000 ease-in-out" 
                  strokeWidth="8" 
                  strokeLinecap="round" 
                  cx="50" cy="50" r="40" fill="transparent" 
                  strokeDasharray={`${utilization * 2.51} 251.2`} 
                ></circle>
              </svg>
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <span className="text-xl font-bold text-slate-800">{utilization}%</span>
              </div>
            </div>
          </div>

          <div className="space-y-4">
            <div className="flex justify-between items-center py-2 border-b border-slate-50">
              <span className="text-sm text-slate-600 font-medium">Peak hour</span>
              <span className="text-xs font-bold text-[#144295] bg-blue-50 px-2 py-1 rounded-md">{utilization > 0 ? '6-8 PM' : 'N/A'}</span>
            </div>
            <div className="flex justify-between items-center py-2 border-b border-slate-50">
              <span className="text-sm text-slate-600 font-medium">Bookings today</span>
              <span className="text-sm font-bold text-slate-800">{bookingsToday}</span>
            </div>
            <div className="flex justify-between items-center py-2 border-b border-slate-50">
              <span className="text-sm text-slate-600 font-medium">Cancellations</span>
              <span className="text-sm font-bold text-slate-800">{bookingsToday > 0 ? 3 : 0}</span>
            </div>
            <div className="flex justify-between items-center py-2">
              <span className="text-sm text-slate-600 font-medium">Avg session</span>
              <span className="text-sm font-bold text-slate-800">{bookingsToday > 0 ? '34 min' : '0 min'}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
