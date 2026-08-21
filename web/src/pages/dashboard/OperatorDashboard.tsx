import { useState } from 'react';
import {
  Building2,
  Zap,
  CalendarDays,
  BarChart3,
  Settings,
  LogOut
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import './dashboard.css';

import StationsView from '../../components/dashboard/StationsView';
import ChargersView from '../../components/dashboard/ChargersView';
import SlotsView from '../../components/dashboard/SlotsView';
import AnalyticsView from '../../components/dashboard/AnalyticsView';
import SettingsView from '../../components/dashboard/SettingsView';

type Tab = 'stations' | 'chargers' | 'slots' | 'analytics' | 'settings';

export default function OperatorDashboard() {
  const [activeTab, setActiveTab] = useState<Tab>('stations');
  const { user, logout } = useAuth();

  const renderView = () => {
    switch (activeTab) {
      case 'stations': return <StationsView />;
      case 'chargers': return <ChargersView />;
      case 'slots': return <SlotsView />;
      case 'analytics': return <AnalyticsView />;
      case 'settings': return <SettingsView />;
      default: return <StationsView />;
    }
  };

  const navItems: { id: Tab; label: string; icon: React.FC<{ className?: string }> }[] = [
    { id: 'stations', label: 'Stations', icon: Building2 },
    { id: 'chargers', label: 'Chargers', icon: Zap },
    { id: 'slots', label: 'Slots', icon: CalendarDays },
    { id: 'analytics', label: 'Analytics', icon: BarChart3 },
    { id: 'settings', label: 'Settings', icon: Settings },
  ];

  return (
    <div className="flex h-screen bg-[#f8f9fa] font-sans overflow-hidden">
      {/* Sidebar */}
      <aside className="w-64 bg-[#144295] text-white flex flex-col flex-shrink-0">
        <div className="h-24 flex items-center px-8">
          <div className="bg-white text-[#144295] p-1.5 rounded-lg mr-3">
            <Zap className="w-5 h-5 fill-current" />
          </div>
          <span className="text-xl font-bold tracking-tight">EvWay Operator</span>
        </div>

        <nav className="flex-1 py-2 px-4 space-y-1">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id)}
                className={`
                  w-full flex items-center px-4 py-3 rounded-xl text-sm font-medium transition-colors
                  ${isActive
                    ? 'bg-white/15 text-white'
                    : 'text-blue-100 hover:bg-white/5 hover:text-white'}
                `}
              >
                <Icon className={`w-5 h-5 mr-3 ${isActive ? 'text-white' : 'text-blue-200'}`} />
                {item.label}
              </button>
            );
          })}
        </nav>

        <div className="p-4 mt-auto">
          <div className="flex items-center px-4 py-3 bg-white/10 rounded-xl mb-2 text-white">
            <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center font-bold mr-3">
              {user?.email?.charAt(0).toUpperCase() || 'O'}
            </div>
            <div className="flex-1 overflow-hidden">
              <p className="text-xs font-bold truncate">{user?.email || 'Operator'}</p>
              <p className="text-[10px] text-blue-200 uppercase">{user?.role || 'OPERATOR'}</p>
            </div>
          </div>
          <button
            onClick={logout}
            className="w-full flex items-center px-4 py-3 rounded-xl text-sm font-medium text-blue-100 hover:bg-rose-500/20 hover:text-rose-100 transition-colors"
          >
            <LogOut className="w-5 h-5 mr-3" />
            Logout
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 overflow-auto p-8 lg:p-10">
        {renderView()}
      </main>
    </div>
  );
}
