import { useState, useEffect } from 'react';
import axios from 'axios';
import { 
  Search, 
  Filter, 
  Plus, 
  Zap, 
  Activity, 
  Wrench, 
  Power,
  X,
  ChevronDown,
  Loader2,
  Building2
} from 'lucide-react';

const API_BASE = 'https://evchargerloc.onrender.com/api';

interface Station {
  id: string;
  name: string;
}

interface Charger {
  id: string;
  stationId: string;
  name: string;
  type: string;
  powerKw: number;
  status: string;
}

export default function ChargersView() {
  const [stations, setStations] = useState<Station[]>([]);
  const [selectedStationId, setSelectedStationId] = useState<string>('');
  const [chargers, setChargers] = useState<Charger[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('All');
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  
  const [newCharger, setNewCharger] = useState<Partial<Charger>>({
    name: '', type: 'CCS2', powerKw: 60, status: 'AVAILABLE'
  });

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
      const response = await axios.get(`${API_BASE}/stations/my-stations`);
      setStations(response.data);
      if (response.data.length > 0) {
        setSelectedStationId(response.data[0].id);
      }
    } catch (err: any) {
      console.error('Error fetching stations:', err);
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

  const getStatusColor = (status: string) => {
    const s = status?.toUpperCase() || '';
    switch (s) {
      case 'AVAILABLE': return 'bg-emerald-100 text-emerald-700 border-emerald-200';
      case 'CHARGING': return 'bg-amber-100 text-amber-700 border-amber-200';
      case 'MAINTENANCE': return 'bg-rose-100 text-rose-700 border-rose-200';
      case 'OFFLINE': return 'bg-slate-100 text-slate-700 border-slate-200';
      default: return 'bg-slate-100 text-slate-700 border-slate-200';
    }
  };

  const filteredChargers = chargers.filter(c => {
    const nameMatch = c.name?.toLowerCase().includes(searchQuery.toLowerCase());
    const typeMatch = c.type?.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesSearch = nameMatch || typeMatch;
    
    const matchesStatus = statusFilter === 'All' || c.status?.toUpperCase() === statusFilter.toUpperCase();
    
    return matchesSearch && matchesStatus;
  });

  const handleAddCharger = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedStationId) return;

    try {
      const chargerToAdd = {
        stationId: selectedStationId,
        name: newCharger.name || `Gun #${chargers.length + 1}`,
        type: newCharger.type || 'CCS2',
        powerKw: newCharger.powerKw || 60,
        status: newCharger.status || 'AVAILABLE'
      };
      const response = await axios.post(`${API_BASE}/chargers`, chargerToAdd);
      setChargers([...chargers, response.data]);
      setIsAddModalOpen(false);
      setNewCharger({ name: '', type: 'CCS2', powerKw: 60, status: 'AVAILABLE' });
    } catch (err) {
      console.error('Error adding charger:', err);
      alert('Failed to add charger');
    }
  };

  const toggleStatus = async (charger: Charger) => {
    const newStatus = charger.status === 'AVAILABLE' ? 'MAINTENANCE' : 'AVAILABLE';
    try {
      const response = await axios.put(`${API_BASE}/chargers/${charger.id}/status?status=${newStatus}`);
      setChargers(chargers.map(c => c.id === charger.id ? response.data : c));
    } catch (err) {
      console.error('Error updating status', err);
      alert('Failed to update status');
    }
  };

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center h-64">
        <Loader2 className="w-8 h-8 text-[#144295] animate-spin mb-4" />
        <p className="text-slate-500 font-medium">Loading chargers...</p>
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
          You need to add a station from the Stations tab before you can manage chargers.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header & Action Bar */}
      <div className="flex flex-col lg:flex-row lg:items-start justify-between gap-4 mb-8">
        <div>
          <div className="flex items-center gap-4 mb-1">
            <h1 className="text-2xl font-bold text-slate-800">Chargers Management</h1>
            <div className="relative inline-block">
              <select
                value={selectedStationId}
                onChange={(e) => setSelectedStationId(e.target.value)}
                className="appearance-none bg-white border border-slate-200 text-slate-700 py-1 pl-3 pr-8 rounded-md text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-[#144295]/20 focus:border-[#144295] shadow-sm cursor-pointer"
              >
                {stations.map(station => (
                  <option key={station.id} value={station.id}>{station.name}</option>
                ))}
              </select>
              <ChevronDown className="absolute right-2.5 top-1.5 w-4 h-4 text-slate-400 pointer-events-none" />
            </div>
          </div>
          <p className="text-slate-400 text-[13px] max-w-lg">
            Manage physical charging guns, connector configurations, real-time power outputs, and hardware status.
          </p>
        </div>
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input 
              type="text" 
              placeholder="Search chargers..." 
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-9 pr-4 py-2 w-full sm:w-64 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#144295]/20 focus:border-[#144295] text-slate-900 bg-white"
            />
          </div>
          <div className="relative">
            <Filter className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <select 
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="pl-9 pr-8 py-2 w-full sm:w-40 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#144295]/20 focus:border-[#144295] appearance-none bg-white text-slate-900"
            >
              <option value="All">All Status</option>
              <option value="AVAILABLE">Available</option>
              <option value="CHARGING">Charging</option>
              <option value="MAINTENANCE">Maintenance</option>
              <option value="OFFLINE">Offline</option>
            </select>
          </div>
          <button 
            onClick={() => setIsAddModalOpen(true)}
            className="flex items-center justify-center px-4 py-2 bg-[#1d4ed8] hover:bg-[#1e3a8a] text-white rounded-lg text-sm font-medium transition-colors shadow-sm"
          >
            <Plus className="w-4 h-4 mr-2" />
            Add New Charger
          </button>
        </div>
      </div>

      {/* Quick Metrics Banner */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-slate-100 p-6 flex items-center">
          <div className="w-12 h-12 bg-blue-50 rounded-full flex items-center justify-center mr-4">
            <Zap className="w-6 h-6 text-[#1d4ed8]" />
          </div>
          <div>
            <h3 className="text-slate-400 text-[10px] font-bold tracking-widest uppercase mb-1">Total Guns / Ports</h3>
            <p className="text-xl font-bold text-slate-800">{chargers.length} Installed</p>
          </div>
        </div>

        <div className="bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-slate-100 p-6 flex items-center">
          <div className="w-12 h-12 bg-amber-50 rounded-full flex items-center justify-center mr-4">
            <Activity className="w-6 h-6 text-amber-500" />
          </div>
          <div>
            <h3 className="text-slate-400 text-[10px] font-bold tracking-widest uppercase mb-1">Max Power Output</h3>
            <p className="text-xl font-bold text-slate-800">{chargers.reduce((acc, curr) => acc + (curr.powerKw || 0), 0)} kW</p>
          </div>
        </div>

        <div className="bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-slate-100 p-6 flex items-center">
          <div className="w-12 h-12 bg-emerald-50 rounded-full flex items-center justify-center mr-4">
            <Wrench className="w-6 h-6 text-emerald-500" />
          </div>
          <div>
            <h3 className="text-slate-400 text-[10px] font-bold tracking-widest uppercase mb-1">Hardware Health</h3>
            <p className="text-xl font-bold text-slate-800">
              {chargers.length > 0 ? Math.round((chargers.filter(c => c.status !== 'MAINTENANCE' && c.status !== 'OFFLINE').length / chargers.length) * 100) : 0}% Operational
            </p>
          </div>
        </div>
      </div>

      {/* Interactive Charger Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6 pt-4">
        {filteredChargers.map((charger) => (
          <div key={charger.id} className="bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-slate-100 overflow-hidden flex flex-col">
            <div className="p-5 border-b border-slate-50">
              <div className="flex justify-between items-start mb-4">
                <div>
                  <h3 className="text-lg font-bold text-slate-800">{charger.name}</h3>
                  <p className="text-xs font-medium text-slate-500">{charger.id.slice(-6)} • {charger.type}</p>
                </div>
                <div className={`px-2.5 py-1 rounded-full text-xs font-semibold border ${getStatusColor(charger.status)}`}>
                  {charger.status || 'AVAILABLE'}
                </div>
              </div>
              
              <div className="flex items-center gap-4 mt-4">
                <div className="flex items-center text-sm">
                  <Zap className="w-4 h-4 text-slate-400 mr-1.5" />
                  <span className="font-medium text-slate-700">{charger.powerKw} kW</span>
                </div>
              </div>
            </div>

            <div className="px-5 py-4 bg-slate-50/50 flex-1">
              <p className="text-[10px] font-bold tracking-widest uppercase text-slate-400 mb-2">Active Session</p>
              {charger.status?.toUpperCase() === 'CHARGING' ? (
                <div>
                  <p className="text-sm font-medium text-slate-800">Vehicle Connected</p>
                  <p className="text-xs text-amber-600 font-medium mt-1">Charging in progress...</p>
                </div>
              ) : (
                <p className="text-sm text-slate-500">—</p>
              )}
            </div>

            <div className="p-4 border-t border-slate-50 flex items-center justify-between gap-2">
              <button 
                onClick={() => toggleStatus(charger)}
                className="flex-1 flex items-center justify-center py-2 px-3 rounded-lg border border-slate-200 text-xs font-semibold text-slate-600 hover:bg-slate-50 hover:text-slate-800 transition-colors"
              >
                <Power className="w-3.5 h-3.5 mr-1.5" />
                Toggle Mode
              </button>
            </div>
          </div>
        ))}

        {filteredChargers.length === 0 && (
          <div className="col-span-full py-12 text-center bg-white rounded-2xl border border-dashed border-slate-200">
            <p className="text-slate-500 font-medium">No chargers found matching your filters.</p>
            <button 
              onClick={() => { setSearchQuery(''); setStatusFilter('All'); }}
              className="mt-3 text-sm text-[#1d4ed8] font-medium hover:underline"
            >
              Clear filters
            </button>
          </div>
        )}
      </div>

      {/* Add Charger Modal */}
      {isAddModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 backdrop-blur-sm p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            <div className="px-6 py-4 border-b border-slate-100 flex justify-between items-center bg-slate-50/50">
              <h2 className="text-lg font-bold text-slate-800">Add New Charger</h2>
              <button onClick={() => setIsAddModalOpen(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>
            
            <form onSubmit={handleAddCharger} className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Charger Name / ID</label>
                <input 
                  required
                  type="text" 
                  placeholder="e.g. Gun #5"
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#144295]/20 focus:border-[#144295] text-slate-900 bg-white"
                  value={newCharger.name}
                  onChange={e => setNewCharger({...newCharger, name: e.target.value})}
                />
              </div>
              
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Connector Type</label>
                  <select 
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#144295]/20 focus:border-[#144295] bg-white text-slate-900"
                    value={newCharger.type}
                    onChange={e => setNewCharger({...newCharger, type: e.target.value})}
                  >
                    <option value="CCS2">CCS2</option>
                    <option value="Type 2">Type 2</option>
                    <option value="CHAdeMO">CHAdeMO</option>
                    <option value="GB/T">GB/T</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Max Power (kW)</label>
                  <input 
                    required
                    type="number" 
                    min="1"
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#144295]/20 focus:border-[#144295] text-slate-900 bg-white"
                    value={newCharger.powerKw}
                    onChange={e => setNewCharger({...newCharger, powerKw: parseInt(e.target.value) || 0})}
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Initial Status</label>
                <select 
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#144295]/20 focus:border-[#144295] bg-white text-slate-900"
                  value={newCharger.status}
                  onChange={e => setNewCharger({...newCharger, status: e.target.value})}
                >
                  <option value="AVAILABLE">Available</option>
                  <option value="MAINTENANCE">Maintenance</option>
                  <option value="OFFLINE">Offline</option>
                </select>
              </div>

              <div className="pt-4 mt-6 border-t border-slate-100 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsAddModalOpen(false)}
                  className="px-4 py-2 text-sm font-semibold text-slate-600 hover:text-slate-800 hover:bg-slate-50 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-4 py-2 text-sm font-semibold text-white bg-[#1d4ed8] hover:bg-[#1e3a8a] rounded-lg transition-colors shadow-sm"
                >
                  Save Charger
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
