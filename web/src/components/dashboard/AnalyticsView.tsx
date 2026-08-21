import { useState, useEffect } from 'react';
import axios from 'axios';
import { 
  TrendingUp, 
  Zap, 
  IndianRupee, 
  Clock, 
  Sparkles, 
  Download, 
  AlertCircle,
  BarChart3,
  BatteryCharging,
  ArrowRight,
  Loader2,
  Building2
} from 'lucide-react';

const API_BASE = 'https://evchargerloc.onrender.com/api';

interface Station {
  id: string;
  name: string;
  pricePerKwh: number;
}

interface AnalyticsData {
  totalEnergy: number;
  totalRevenue: number;
  completedSessions: number;
  successRate: number;
  hourlyEnergy: number[];
  peakDemand: number[];
}

export default function AnalyticsView() {
  const [stations, setStations] = useState<Station[]>([]);
  const [selectedStationId, setSelectedStationId] = useState<string>('');
  const [selectedStation, setSelectedStation] = useState<Station | null>(null);
  
  const [analytics, setAnalytics] = useState<AnalyticsData | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const [timeRange, setTimeRange] = useState('Today');

  useEffect(() => {
    fetchStations();
  }, []);

  useEffect(() => {
    if (selectedStationId) {
      const station = stations.find(s => s.id === selectedStationId);
      if (station) setSelectedStation(station);
      fetchAnalytics(selectedStationId);
    }
  }, [selectedStationId, stations]);

  const fetchStations = async () => {
    try {
      setIsLoading(true);
      const response = await axios.get(`${API_BASE}/stations/my-stations`);
      setStations(response.data);
      if (response.data.length > 0) {
        setSelectedStationId(response.data[0].id);
      }
    } catch (err) {
      console.error('Error fetching stations:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const fetchAnalytics = async (stationId: string) => {
    try {
      const response = await axios.get(`${API_BASE}/analytics/station/${stationId}`);
      setAnalytics(response.data);
    } catch (err) {
      console.error('Error fetching analytics:', err);
    }
  };

  if (isLoading || !analytics) {
    return (
      <div className="flex flex-col items-center justify-center h-64">
        <Loader2 className="w-8 h-8 text-[#144295] animate-spin mb-4" />
        <p className="text-slate-500 font-medium">Loading analytics...</p>
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
          You need to add a station from the Stations tab before viewing analytics.
        </p>
      </div>
    );
  }

  const maxKwh = Math.max(10, ...analytics.hourlyEnergy); // at least 10 for scale
  const totalPeakDemand = Math.max(...analytics.peakDemand);

  // Generate hourly labels
  const hourlyData = analytics.hourlyEnergy.map((kwh, i) => {
    let hour = i;
    let period = 'AM';
    if (hour === 0) hour = 12;
    else if (hour === 12) period = 'PM';
    else if (hour > 12) {
      hour -= 12;
      period = 'PM';
    }
    const timeLabel = `${hour.toString().padStart(2, '0')} ${period}`;
    return {
      time: timeLabel,
      kwh,
      vehicles: Math.round(kwh / 20), // rough estimate
      isPeak: i >= 18 && i <= 21 // 6 PM to 9 PM is peak
    };
  }).filter((_, i) => i % 2 === 0); // show every 2 hours for clarity

  return (
    <div className="space-y-6 pb-12">
      {/* Section Header & Filters Toolbar */}
      <div className="flex flex-col lg:flex-row lg:items-start justify-between gap-4 mb-2">
        <div>
          <div className="flex items-center gap-4 mb-1">
            <h1 className="text-2xl font-bold text-slate-800">Station Analytics & Management Insights</h1>
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
            Track daily energy throughput, revenue generation, utilization patterns, and AI-driven operator recommendations.
          </p>
        </div>
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="flex bg-slate-100 p-1 rounded-lg border border-slate-200">
            {['Today', 'Last 7 Days', 'This Month'].map((range) => (
              <button
                key={range}
                onClick={() => setTimeRange(range)}
                className={`px-4 py-1.5 text-xs font-bold rounded-md transition-colors ${
                  timeRange === range 
                    ? 'bg-white text-slate-800 shadow-sm' 
                    : 'text-slate-500 hover:text-slate-700'
                }`}
              >
                {range}
              </button>
            ))}
          </div>
          <button 
            className="flex items-center justify-center px-4 py-2 bg-white border border-slate-200 hover:bg-slate-50 text-slate-700 rounded-lg text-sm font-bold transition-colors shadow-sm"
          >
            <Download className="w-4 h-4 mr-2" />
            Export CSV / PDF
          </button>
        </div>
      </div>

      {/* Primary KPI Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Total Energy */}
        <div className="bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-slate-100 p-6 flex flex-col justify-between">
          <div className="flex items-start justify-between mb-4">
            <div className="w-10 h-10 bg-blue-50 rounded-full flex items-center justify-center">
              <Zap className="w-5 h-5 text-[#1d4ed8]" />
            </div>
            {analytics.totalEnergy > 0 && (
              <span className="text-[10px] font-bold px-2 py-1 rounded-md bg-emerald-100 text-emerald-700 flex items-center gap-1">
                <TrendingUp className="w-3 h-3" />
                Live Data
              </span>
            )}
          </div>
          <div>
            <h3 className="text-slate-400 text-[10px] font-bold tracking-widest uppercase mb-1">Total Energy Delivered</h3>
            <p className="text-2xl font-bold text-slate-800">{analytics.totalEnergy.toFixed(1)} kWh</p>
          </div>
        </div>

        {/* Total Revenue */}
        <div className="bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-slate-100 p-6 flex flex-col justify-between">
          <div className="flex items-start justify-between mb-4">
            <div className="w-10 h-10 bg-emerald-50 rounded-full flex items-center justify-center">
              <IndianRupee className="w-5 h-5 text-emerald-600" />
            </div>
            <span className="text-[10px] font-bold px-2 py-1 rounded-md bg-slate-100 text-slate-600">
              Avg ₹{selectedStation?.pricePerKwh || 18}/kWh
            </span>
          </div>
          <div>
            <h3 className="text-slate-400 text-[10px] font-bold tracking-widest uppercase mb-1">Total Revenue</h3>
            <p className="text-2xl font-bold text-slate-800">₹{analytics.totalRevenue.toFixed(0)}</p>
          </div>
        </div>

        {/* Completed Sessions */}
        <div className="bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-slate-100 p-6 flex flex-col justify-between">
          <div className="flex items-start justify-between mb-4">
            <div className="w-10 h-10 bg-indigo-50 rounded-full flex items-center justify-center">
              <BatteryCharging className="w-5 h-5 text-indigo-600" />
            </div>
            <span className="text-[10px] font-bold px-2 py-1 rounded-md bg-indigo-100 text-indigo-700">
              {analytics.successRate}% success rate
            </span>
          </div>
          <div>
            <h3 className="text-slate-400 text-[10px] font-bold tracking-widest uppercase mb-1">Completed Sessions</h3>
            <p className="text-2xl font-bold text-slate-800">{analytics.completedSessions} Sessions</p>
          </div>
        </div>

        {/* Peak Grid Demand */}
        <div className="bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-slate-100 p-6 flex flex-col justify-between">
          <div className="flex items-start justify-between mb-4">
            <div className="w-10 h-10 bg-amber-50 rounded-full flex items-center justify-center">
              <BarChart3 className="w-5 h-5 text-amber-500" />
            </div>
            {totalPeakDemand > 0 && (
              <span className="text-[10px] font-bold px-2 py-1 rounded-md bg-amber-100 text-amber-800">
                Peak Load Tracker
              </span>
            )}
          </div>
          <div>
            <h3 className="text-slate-400 text-[10px] font-bold tracking-widest uppercase mb-1">Peak Grid Demand</h3>
            <p className="text-2xl font-bold text-slate-800">{totalPeakDemand} kW <span className="text-sm font-medium text-slate-400">/ 200 kW</span></p>
          </div>
        </div>
      </div>

      {/* Analytics Visualizations */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column: Hourly Energy & Demand Chart */}
        <div className="lg:col-span-2 bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-slate-100 p-6">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-lg font-bold text-slate-800">Hourly Energy Profile (Live)</h2>
            <div className="flex items-center gap-3 text-xs font-bold text-slate-500">
              <div className="flex items-center gap-1.5"><span className="w-3 h-3 rounded bg-blue-100"></span> Off-Peak</div>
              <div className="flex items-center gap-1.5"><span className="w-3 h-3 rounded bg-[#1d4ed8]"></span> Peak Hours</div>
            </div>
          </div>
          
          <div className="h-64 flex items-end justify-between gap-2 pt-4 group">
            {hourlyData.map((data, i) => (
              <div key={i} className="relative flex flex-col items-center w-full h-full justify-end group/bar">
                {/* Tooltip */}
                <div className="absolute -top-14 opacity-0 group-hover/bar:opacity-100 transition-opacity bg-slate-800 text-white text-[10px] py-1 px-2 rounded pointer-events-none whitespace-nowrap z-10 flex flex-col items-center">
                  <span className="font-bold">{data.kwh} kWh</span>
                  <span className="text-slate-300">{data.vehicles} vehicles</span>
                  <div className="absolute -bottom-1 w-2 h-2 bg-slate-800 rotate-45"></div>
                </div>
                
                {/* Bar */}
                <div 
                  className={`w-full max-w-[40px] rounded-t-md transition-all duration-500 ${data.isPeak ? 'bg-[#1d4ed8] hover:bg-[#1e3a8a]' : 'bg-blue-100 hover:bg-blue-200'} ${data.kwh === 0 ? 'min-h-[4px] bg-slate-100' : ''}`}
                  style={{ height: data.kwh === 0 ? '4px' : `${(data.kwh / maxKwh) * 100}%` }}
                ></div>
                <span className="text-[10px] font-bold text-slate-400 mt-3">{data.time}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Right Column: Charger Utilization Breakdown */}
        <div className="bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-slate-100 p-6">
          <h2 className="text-lg font-bold text-slate-800 mb-6">Connector Breakdown</h2>
          
          <div className="space-y-5">
            <div>
              <div className="flex justify-between text-sm font-bold text-slate-700 mb-1.5">
                <span>CCS2 (Fast DC)</span>
                <span>62%</span>
              </div>
              <div className="w-full bg-slate-100 rounded-full h-2">
                <div className="bg-[#1d4ed8] h-2 rounded-full" style={{ width: '62%' }}></div>
              </div>
            </div>
            
            <div>
              <div className="flex justify-between text-sm font-bold text-slate-700 mb-1.5">
                <span>Type 2 (AC)</span>
                <span>26%</span>
              </div>
              <div className="w-full bg-slate-100 rounded-full h-2">
                <div className="bg-emerald-500 h-2 rounded-full" style={{ width: '26%' }}></div>
              </div>
            </div>
            
            <div>
              <div className="flex justify-between text-sm font-bold text-slate-700 mb-1.5">
                <span>CHAdeMO</span>
                <span>12%</span>
              </div>
              <div className="w-full bg-slate-100 rounded-full h-2">
                <div className="bg-amber-500 h-2 rounded-full" style={{ width: '12%' }}></div>
              </div>
            </div>
          </div>

          <h2 className="text-lg font-bold text-slate-800 mb-4 mt-8">Session Duration</h2>
          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-2 h-2 rounded-full bg-emerald-500"></div>
              <div className="flex-1 text-sm font-bold text-slate-600">&lt; 30 mins <span className="font-medium text-slate-400 text-xs">(Top-up)</span></div>
              <div className="text-sm font-bold text-slate-800">45%</div>
            </div>
            <div className="flex items-center gap-3">
              <div className="w-2 h-2 rounded-full bg-[#1d4ed8]"></div>
              <div className="flex-1 text-sm font-bold text-slate-600">30–60 mins <span className="font-medium text-slate-400 text-xs">(Full Charge)</span></div>
              <div className="text-sm font-bold text-slate-800">40%</div>
            </div>
            <div className="flex items-center gap-3">
              <div className="w-2 h-2 rounded-full bg-amber-500"></div>
              <div className="flex-1 text-sm font-bold text-slate-600">&gt; 60 mins</div>
              <div className="text-sm font-bold text-slate-800">15%</div>
            </div>
          </div>
        </div>
      </div>

      {/* AI & Smart Recommendations Section */}
      <div className="bg-white rounded-2xl shadow-[0_2px_10px_-3px_rgba(6,81,237,0.05)] border border-slate-100 p-1">
        <div className="bg-gradient-to-r from-indigo-50/50 to-blue-50/50 rounded-xl p-6">
          <div className="flex items-center gap-2 mb-6">
            <Sparkles className="w-5 h-5 text-indigo-600" />
            <h2 className="text-lg font-bold text-slate-800">EvWay Smart Operator Recommendations</h2>
          </div>
          
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
            {/* Recommendation 1 */}
            <div className="bg-white rounded-xl p-5 border border-indigo-100/50 shadow-sm flex flex-col justify-between">
              <div>
                <div className="flex items-center gap-2 mb-3">
                  <div className="w-8 h-8 rounded-full bg-emerald-50 flex items-center justify-center shrink-0">
                    <IndianRupee className="w-4 h-4 text-emerald-600" />
                  </div>
                  <h3 className="font-bold text-slate-800 text-sm">Dynamic Pricing Optimization</h3>
                </div>
                <p className="text-[13px] text-slate-600 leading-relaxed mb-4">
                  High demand detected between <strong className="text-slate-800">6:00 PM - 8:30 PM</strong> (92% occupancy). Recommended: Increase tariff by ₹2/kWh during peak hours to balance grid load and maximize revenue.
                </p>
              </div>
              <button className="w-full flex items-center justify-center gap-2 py-2 bg-white border border-slate-200 hover:bg-slate-50 hover:text-[#1d4ed8] hover:border-blue-200 text-slate-700 rounded-lg text-xs font-bold transition-all">
                Apply Peak Tariff
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
            </div>

            {/* Recommendation 2 */}
            <div className="bg-white rounded-xl p-5 border border-indigo-100/50 shadow-sm flex flex-col justify-between">
              <div>
                <div className="flex items-center gap-2 mb-3">
                  <div className="w-8 h-8 rounded-full bg-rose-50 flex items-center justify-center shrink-0">
                    <AlertCircle className="w-4 h-4 text-rose-500" />
                  </div>
                  <h3 className="font-bold text-slate-800 text-sm">Predictive Maintenance Alert</h3>
                </div>
                <p className="text-[13px] text-slate-600 leading-relaxed mb-4">
                  <strong className="text-slate-800">Gun #4 (CHAdeMO)</strong> has shown repeated session drop-offs during high temperature spikes. Recommended: Schedule thermal inspection.
                </p>
              </div>
              <button className="w-full flex items-center justify-center gap-2 py-2 bg-white border border-slate-200 hover:bg-slate-50 hover:text-rose-600 hover:border-rose-200 text-slate-700 rounded-lg text-xs font-bold transition-all">
                Flag for Maintenance
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
            </div>

            {/* Recommendation 3 */}
            <div className="bg-white rounded-xl p-5 border border-indigo-100/50 shadow-sm flex flex-col justify-between">
              <div>
                <div className="flex items-center gap-2 mb-3">
                  <div className="w-8 h-8 rounded-full bg-amber-50 flex items-center justify-center shrink-0">
                    <Clock className="w-4 h-4 text-amber-500" />
                  </div>
                  <h3 className="font-bold text-slate-800 text-sm">Queue & Overlap Management</h3>
                </div>
                <p className="text-[13px] text-slate-600 leading-relaxed mb-4">
                  Walk-in queue frequency increases near lunch hours <strong className="text-slate-800">(12:30 PM – 2:00 PM)</strong>. Recommended: Reserve Gun #3 exclusively for app-booked express slots.
                </p>
              </div>
              <button className="w-full flex items-center justify-center gap-2 py-2 bg-white border border-slate-200 hover:bg-slate-50 hover:text-amber-600 hover:border-amber-200 text-slate-700 rounded-lg text-xs font-bold transition-all">
                Auto-Reserve Express Gun
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
