// components/FinanceDashboard.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { 
  TrendingUp, DollarSign, Coins, Users, UserCheck, 
  Clock, CheckCircle2, Award, Download, Calendar, BarChart3, AlertCircle 
} from 'lucide-react';
import { MockDatabase } from '../lib/mockDb';

const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api';

interface OverviewMetrics {
  todayRevenue: number;
  monthlyRevenue: number;
  totalRevenue: number;
  coinsSold: number;
  activeUsers: number;
  activeCreators: number;
  pendingWithdrawals: number;
  paidWithdrawals: number;
  creatorPayouts: number;
  platformProfit: number;
}

interface ChartDataPoint {
  date: string;
  revenue: number;
  coinsSold: number;
  creatorEarnings: number;
  callVolume: number;
  withdrawals: number;
}

interface TopCreator {
  creatorId: string;
  creatorName: string;
  totalEarnings: number;
  totalCalls: number;
  totalMinutes: number;
}

interface CallAnalytics {
  totalCalls: number;
  completedCalls: number;
  totalCallMinutes: number;
  averageCallDuration: number;
  coinsUsed: number;
  outstandingCoins: number;
}

interface WithdrawalAnalytics {
  pendingWithdrawals: number;
  pendingAmount: number;
  paidWithdrawals: number;
  totalPayouts: number;
}

export default function FinanceDashboard() {
  const [loading, setLoading] = useState(true);
  const [isLive, setIsLive] = useState(false);
  const [chartDays, setChartDays] = useState<7 | 30>(7);

  // CSV Date Filters
  const [exportRange, setExportRange] = useState<'today' | '7days' | '30days' | 'custom'>('7days');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  // Data States
  const [overview, setOverview] = useState<OverviewMetrics>({
    todayRevenue: 0,
    monthlyRevenue: 0,
    totalRevenue: 0,
    coinsSold: 0,
    activeUsers: 0,
    activeCreators: 0,
    pendingWithdrawals: 0,
    paidWithdrawals: 0,
    creatorPayouts: 0,
    platformProfit: 0
  });
  const [chartData, setChartData] = useState<ChartDataPoint[]>([]);
  const [topCreators, setTopCreators] = useState<TopCreator[]>([]);
  const [callAnalytics, setCallAnalytics] = useState<CallAnalytics>({
    totalCalls: 0,
    completedCalls: 0,
    totalCallMinutes: 0,
    averageCallDuration: 0,
    coinsUsed: 0,
    outstandingCoins: 0
  });
  const [withdrawalAnalytics, setWithdrawalAnalytics] = useState<WithdrawalAnalytics>({
    pendingWithdrawals: 0,
    pendingAmount: 0,
    paidWithdrawals: 0,
    totalPayouts: 0
  });

  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const triggerToast = (message: string, type: 'success' | 'error' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const getHeaders = () => {
    const token = localStorage.getItem('token') || localStorage.getItem('coincall_admin_token') || '';
    return {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    };
  };

  const loadData = async () => {
    setLoading(true);
    let success = false;

    try {
      const headers = getHeaders();
      
      const [ovRes, chartRes, topRes, callRes, wRes] = await Promise.all([
        fetch(`${API_BASE}/admin/finance/overview`, { headers }),
        fetch(`${API_BASE}/admin/finance/revenue-chart?days=${chartDays}`, { headers }),
        fetch(`${API_BASE}/admin/finance/top-creators`, { headers }),
        fetch(`${API_BASE}/admin/finance/call-analytics`, { headers }),
        fetch(`${API_BASE}/admin/finance/withdrawal-analytics`, { headers })
      ]);

      if (ovRes.ok && chartRes.ok && topRes.ok && callRes.ok && wRes.ok) {
        const ovData = await ovRes.json();
        const cData = await chartRes.json();
        const tData = await topRes.json();
        const caData = await callRes.json();
        const waData = await wRes.json();

        setOverview(ovData);
        setChartData(cData);
        setTopCreators(tData);
        setCallAnalytics(caData);
        setWithdrawalAnalytics(waData);
        setIsLive(true);
        success = true;
      }
    } catch (e) {
      console.warn('Failed to fetch from NestJS finance API, falling back to mock data:', e);
    }

    if (!success) {
      setIsLive(false);
      loadMockData();
    }
    setLoading(false);
  };

  const loadMockData = () => {
    // Generate fallback datasets from MockDatabase
    const payments = MockDatabase.getPayments();
    const calls = MockDatabase.getCalls();
    const users = MockDatabase.getUsers();
    const withdraws = MockDatabase.getWithdrawRequests();
    const listeners = MockDatabase.getListeners();

    const totalRevenue = payments.filter(p => p.status === 'success').reduce((sum, p) => sum + p.amount, 0);
    const todayRevenue = payments
      .filter(p => p.status === 'success' && (p.date.startsWith('2026-06-03') || p.date.startsWith('2026-06-04')))
      .reduce((sum, p) => sum + p.amount, 0);
    const monthlyRevenue = payments
      .filter(p => p.status === 'success' && p.date.startsWith('2026-06'))
      .reduce((sum, p) => sum + p.amount, 0);
    
    const coinsSold = payments.filter(p => p.status === 'success').reduce((sum, p) => sum + p.coins, 0);

    const pendingWithdrawals = withdraws.filter(w => w.status === 'pending').length;
    const paidWithdrawals = withdraws.filter(w => w.status === 'paid').length;
    const creatorPayouts = withdraws.filter(w => w.status === 'paid').reduce((sum, w) => sum + w.amount, 0);
    const platformProfit = totalRevenue - creatorPayouts;

    setOverview({
      todayRevenue,
      monthlyRevenue,
      totalRevenue,
      coinsSold,
      activeUsers: users.filter(u => u.status === 'active').length,
      activeCreators: listeners.filter(l => l.status === 'active').length,
      pendingWithdrawals,
      paidWithdrawals,
      creatorPayouts,
      platformProfit
    });

    // Mock chart trends
    const mockChart: ChartDataPoint[] = [];
    for (let i = chartDays - 1; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const ds = d.toISOString().split('T')[0];
      
      mockChart.push({
        date: ds,
        revenue: Math.floor(Math.random() * 800) + 200,
        coinsSold: Math.floor(Math.random() * 1000) + 400,
        creatorEarnings: Math.floor(Math.random() * 500) + 200,
        callVolume: Math.floor(Math.random() * 15) + 5,
        withdrawals: i === 2 ? 3000 : 0
      });
    }
    setChartData(mockChart);

    // Mock top creators
    const top: TopCreator[] = listeners
      .sort((a, b) => b.earningsLifetime - a.earningsLifetime)
      .slice(0, 10)
      .map(l => ({
        creatorId: l.id,
        creatorName: l.name,
        totalEarnings: l.earningsLifetime,
        totalCalls: l.completedCalls,
        totalMinutes: Math.round(l.completedCalls * 8.4)
      }));
    setTopCreators(top);

    // Mock call analytics
    const totalDuration = calls.reduce((sum, c) => sum + c.duration, 0);
    const coinsUsed = calls.reduce((sum, c) => sum + c.coinsConsumed, 0);
    setCallAnalytics({
      totalCalls: calls.length,
      completedCalls: calls.filter(c => c.status === 'completed' || c.status === 'active').length,
      totalCallMinutes: Math.round(totalDuration / 60),
      averageCallDuration: calls.length > 0 ? Math.round(totalDuration / calls.length) : 0,
      coinsUsed,
      outstandingCoins: coinsSold - coinsUsed
    });

    // Mock withdrawal analytics
    const pendingAmount = withdraws.filter(w => w.status === 'pending').reduce((sum, w) => sum + w.amount, 0);
    setWithdrawalAnalytics({
      pendingWithdrawals,
      pendingAmount,
      paidWithdrawals,
      totalPayouts: creatorPayouts
    });
  };

  useEffect(() => {
    loadData();
  }, [chartDays]);

  // Export CSV triggers
  const handleExport = async (type: 'revenue' | 'earnings' | 'withdrawals') => {
    let url = `${API_BASE}/admin/finance/export/${type}?range=${exportRange}`;
    if (exportRange === 'custom') {
      if (!startDate) {
        triggerToast('Please select a start date for custom range', 'error');
        return;
      }
      url += `&startDate=${startDate}&endDate=${endDate}`;
    }

    try {
      const headers = getHeaders();
      const res = await fetch(url, { headers });
      if (!res.ok) {
        throw new Error(`Server returned ${res.status}`);
      }
      const blob = await res.blob();
      const downloadUrl = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = downloadUrl;
      a.download = `${type}-report-${exportRange}-${Date.now()}.csv`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      triggerToast(`Exported ${type} report successfully`, 'success');
    } catch (e) {
      console.warn(`API export failed, generating client-side CSV fallback:`, e);
      generateClientCsvFallback(type);
    }
  };

  const generateClientCsvFallback = (type: 'revenue' | 'earnings' | 'withdrawals') => {
    let headers = '';
    let rows = '';

    if (type === 'revenue') {
      headers = 'ID,User ID,Amount (₹),Coins Added,Gateway,Order ID,Date\n';
      const payments = MockDatabase.getPayments().filter(p => p.status === 'success');
      rows = payments.map(p => 
        `"${p.id}","${p.userId}",${p.amount},${p.coins},"${p.gateway}","${p.transactionId}","${p.date}"`
      ).join('\n');
    } else if (type === 'earnings') {
      headers = 'ID,Call ID,Creator ID,Gross Amount (Coins),Creator Share (Coins),Platform Share (Coins),Date\n';
      const earners = MockDatabase.getListeners();
      rows = earners.map(l => 
        `"ERN-${l.id}","CAL-MOCK","${l.id}",${l.revenueGenerated * 1.5},${l.revenueGenerated},${l.revenueGenerated * 0.5},"${l.joinDate}"`
      ).join('\n');
    } else {
      headers = 'ID,Creator ID,Amount (₹),Status,Method,Requested At\n';
      const withdraws = MockDatabase.getWithdrawRequests();
      rows = withdraws.map(w => 
        `"${w.id}","${w.listenerId}",${w.amount},"${w.status}","UPI","${w.requestDate}"`
      ).join('\n');
    }

    const blob = new Blob([headers + rows], { type: 'text/csv' });
    const downloadUrl = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = downloadUrl;
    a.download = `${type}-report-mock-${Date.now()}.csv`;
    document.body.appendChild(a);
    a.click();
    a.remove();
    triggerToast(`Exported ${type} mock report successfully`, 'success');
  };

  // SVG Chart Helper
  const generateSvgPath = (data: number[], width = 500, height = 150) => {
    if (data.length === 0) return { path: '', fillPath: '', coordinates: [] };
    const padding = 20;
    const maxVal = Math.max(...data) * 1.1 || 10;
    const minVal = Math.min(...data) * 0.9 || 0;

    const points = data.map((val, idx) => {
      const x = padding + (idx * (width - padding * 2)) / (data.length - 1);
      const y = height - padding - ((val - minVal) * (height - padding * 2)) / (maxVal - minVal || 1);
      return `${x},${y}`;
    });

    const path = `M ${points.join(' L ')}`;
    const firstPoint = points[0].split(',');
    const lastPoint = points[points.length - 1].split(',');
    const fillPath = `${path} L ${lastPoint[0]},${height - padding} L ${firstPoint[0]},${height - padding} Z`;

    const coordinates = points.map(p => {
      const [x, y] = p.split(',');
      return { x: parseFloat(x), y: parseFloat(y) };
    });

    return { path, fillPath, coordinates };
  };

  const revenuePoints = chartData.map(c => c.revenue);
  const coinPoints = chartData.map(c => c.coinsSold);
  const callPoints = chartData.map(c => c.callVolume);

  const revenueChart = generateSvgPath(revenuePoints);
  const coinChart = generateSvgPath(coinPoints);
  const callChart = generateSvgPath(callPoints);

  return (
    <div className="space-y-6 relative">
      {/* Toast Notification */}
      {toast && (
        <div className={`fixed top-4 right-4 z-50 flex items-center gap-2 px-4 py-3 rounded-lg border shadow-lg transition-all duration-300 ${
          toast.type === 'success' ? 'bg-emerald-950/90 border-emerald-500/50 text-emerald-300' :
          'bg-red-950/90 border-red-500/50 text-red-300'
        }`}>
          <span>{toast.message}</span>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-white sm:text-3xl flex items-center gap-2">
            <BarChart3 className="text-indigo-500" />
            Revenue & Finance Console
          </h1>
          <p className="text-sm text-zinc-400">
            Monitor recharges, coin ledger balances, creator payouts, and platform health.
          </p>
        </div>
        
        <div className="flex items-center gap-3">
          <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold tracking-wide uppercase border flex items-center gap-1.5 ${
            isLive 
              ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30' 
              : 'bg-amber-500/10 text-amber-400 border-amber-500/30'
          }`}>
            <span className={`w-1.5 h-1.5 rounded-full ${isLive ? 'bg-emerald-400 animate-pulse' : 'bg-amber-400'}`}></span>
            {isLive ? 'Live Sync Active' : 'Fallback Sandbox'}
          </span>

          <button 
            onClick={loadData}
            className="px-3 py-1.5 bg-secondary text-foreground text-xs font-semibold rounded-lg hover:bg-secondary/80 border border-border"
          >
            Refresh
          </button>
        </div>
      </div>

      {/* KPI Cards Grid */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-5">
        
        {/* Today's Revenue */}
        <div className="glass-card glow-indigo p-4 rounded-xl">
          <div className="flex items-center justify-between">
            <span className="text-[10px] uppercase tracking-wider font-semibold text-zinc-500">Today's Revenue</span>
            <div className="p-1.5 bg-indigo-500/10 rounded text-indigo-400">
              <DollarSign size={14} />
            </div>
          </div>
          <div className="mt-2">
            <span className="text-2xl font-bold text-white tracking-tight">₹{overview.todayRevenue.toLocaleString()}</span>
          </div>
        </div>

        {/* Monthly Revenue */}
        <div className="glass-card p-4 rounded-xl">
          <div className="flex items-center justify-between">
            <span className="text-[10px] uppercase tracking-wider font-semibold text-zinc-500">This Month</span>
            <div className="p-1.5 bg-indigo-500/10 rounded text-indigo-400">
              <DollarSign size={14} />
            </div>
          </div>
          <div className="mt-2">
            <span className="text-2xl font-bold text-white tracking-tight">₹{overview.monthlyRevenue.toLocaleString()}</span>
          </div>
        </div>

        {/* Total Revenue */}
        <div className="glass-card p-4 rounded-xl">
          <div className="flex items-center justify-between">
            <span className="text-[10px] uppercase tracking-wider font-semibold text-zinc-500">Total Revenue</span>
            <div className="p-1.5 bg-indigo-500/10 rounded text-indigo-400">
              <DollarSign size={14} />
            </div>
          </div>
          <div className="mt-2">
            <span className="text-2xl font-bold text-white tracking-tight">₹{overview.totalRevenue.toLocaleString()}</span>
          </div>
        </div>

        {/* Coins Sold */}
        <div className="glass-card p-4 rounded-xl">
          <div className="flex items-center justify-between">
            <span className="text-[10px] uppercase tracking-wider font-semibold text-zinc-500">Coins Sold</span>
            <div className="p-1.5 bg-amber-500/10 rounded text-amber-400">
              <Coins size={14} />
            </div>
          </div>
          <div className="mt-2">
            <span className="text-2xl font-bold text-white tracking-tight">{overview.coinsSold.toLocaleString()}</span>
          </div>
        </div>

        {/* Platform Profit */}
        <div className="glass-card glow-indigo p-4 rounded-xl border-l-2 border-l-emerald-500/50">
          <div className="flex items-center justify-between">
            <span className="text-[10px] uppercase tracking-wider font-semibold text-zinc-500">Platform Profit</span>
            <div className="p-1.5 bg-emerald-500/10 rounded text-emerald-400">
              <TrendingUp size={14} />
            </div>
          </div>
          <div className="mt-2">
            <span className="text-2xl font-bold text-white tracking-tight">₹{overview.platformProfit.toLocaleString()}</span>
          </div>
        </div>

        {/* Active Users */}
        <div className="glass-card p-4 rounded-xl">
          <div className="flex items-center justify-between">
            <span className="text-[10px] uppercase tracking-wider font-semibold text-zinc-500">Active Users 24h</span>
            <div className="p-1.5 bg-indigo-500/10 rounded text-indigo-400">
              <Users size={14} />
            </div>
          </div>
          <div className="mt-2">
            <span className="text-2xl font-bold text-white tracking-tight">{overview.activeUsers}</span>
          </div>
        </div>

        {/* Active Creators */}
        <div className="glass-card p-4 rounded-xl">
          <div className="flex items-center justify-between">
            <span className="text-[10px] uppercase tracking-wider font-semibold text-zinc-500">Active Creators 24h</span>
            <div className="p-1.5 bg-indigo-500/10 rounded text-indigo-400">
              <UserCheck size={14} />
            </div>
          </div>
          <div className="mt-2">
            <span className="text-2xl font-bold text-white tracking-tight">{overview.activeCreators}</span>
          </div>
        </div>

        {/* Pending Withdrawals */}
        <div className="glass-card p-4 rounded-xl">
          <div className="flex items-center justify-between">
            <span className="text-[10px] uppercase tracking-wider font-semibold text-zinc-500">Pending Payouts</span>
            <div className="p-1.5 bg-rose-500/10 rounded text-rose-400">
              <Clock size={14} />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-2">
            <span className="text-2xl font-bold text-white tracking-tight">{overview.pendingWithdrawals}</span>
            {overview.pendingWithdrawals > 0 && (
              <span className="text-[9px] bg-amber-500/20 text-amber-300 font-bold px-1 py-0.5 rounded animate-pulse">Action</span>
            )}
          </div>
        </div>

        {/* Paid Withdrawals */}
        <div className="glass-card p-4 rounded-xl">
          <div className="flex items-center justify-between">
            <span className="text-[10px] uppercase tracking-wider font-semibold text-zinc-500">Paid Payouts</span>
            <div className="p-1.5 bg-emerald-500/10 rounded text-emerald-400">
              <CheckCircle2 size={14} />
            </div>
          </div>
          <div className="mt-2">
            <span className="text-2xl font-bold text-white tracking-tight">{overview.paidWithdrawals}</span>
          </div>
        </div>

        {/* Creator Payouts */}
        <div className="glass-card p-4 rounded-xl">
          <div className="flex items-center justify-between">
            <span className="text-[10px] uppercase tracking-wider font-semibold text-zinc-500">Total Payouts</span>
            <div className="p-1.5 bg-emerald-500/10 rounded text-emerald-400">
              <Award size={14} />
            </div>
          </div>
          <div className="mt-2">
            <span className="text-2xl font-bold text-white tracking-tight">₹{overview.creatorPayouts.toLocaleString()}</span>
          </div>
        </div>

      </div>

      {/* Analytics Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Revenue Chart Card */}
        <div className="glass-panel p-5 rounded-2xl flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-sm font-bold text-white">Revenue Trend</h2>
              <p className="text-[10px] text-zinc-400">Daily successful cash charges</p>
            </div>
            
            <div className="flex bg-zinc-900 border border-zinc-800 p-0.5 rounded text-[10px] font-semibold">
              <button 
                onClick={() => setChartDays(7)}
                className={`px-2 py-0.5 rounded ${chartDays === 7 ? 'bg-zinc-800 text-white' : 'text-zinc-500'}`}
              >
                7D
              </button>
              <button 
                onClick={() => setChartDays(30)}
                className={`px-2 py-0.5 rounded ${chartDays === 30 ? 'bg-zinc-800 text-white' : 'text-zinc-500'}`}
              >
                30D
              </button>
            </div>
          </div>

          <div className="h-32 mt-4 flex items-end relative">
            {revenuePoints.length > 0 ? (
              <svg className="w-full h-full" viewBox="0 0 500 150" preserveAspectRatio="none">
                <defs>
                  <linearGradient id="chartGradIndigo" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#6366f1" stopOpacity="0.4" />
                    <stop offset="100%" stopColor="#6366f1" stopOpacity="0" />
                  </linearGradient>
                </defs>
                <path d={revenueChart.fillPath} fill="url(#chartGradIndigo)" />
                <path d={revenueChart.path} fill="none" stroke="#6366f1" strokeWidth="2.5" strokeLinecap="round" />
                {revenueChart.coordinates.map((c, idx) => (
                  <circle key={idx} cx={c.x} cy={c.y} r="3" fill="#6366f1" stroke="#09090b" strokeWidth="1" />
                ))}
              </svg>
            ) : (
              <div className="text-zinc-500 text-center w-full pb-8">No data found</div>
            )}
          </div>
          
          <div className="flex justify-between text-[8px] font-bold tracking-wider text-zinc-500 mt-2 px-1 uppercase">
            <span>{chartData[0]?.date || ''}</span>
            <span>{chartData[chartData.length - 1]?.date || ''}</span>
          </div>
        </div>

        {/* Coin Sales Chart Card */}
        <div className="glass-panel p-5 rounded-2xl flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-sm font-bold text-white">Coin Purchase Volume</h2>
              <p className="text-[10px] text-zinc-400">Total coins sold day-over-day</p>
            </div>
            
            <div className="text-[10px] font-bold text-amber-400 bg-amber-500/10 border border-amber-500/20 px-2 py-0.5 rounded">
              Coins Sold
            </div>
          </div>

          <div className="h-32 mt-4 flex items-end relative">
            {coinPoints.length > 0 ? (
              <svg className="w-full h-full" viewBox="0 0 500 150" preserveAspectRatio="none">
                <defs>
                  <linearGradient id="chartGradAmber" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#f59e0b" stopOpacity="0.4" />
                    <stop offset="100%" stopColor="#f59e0b" stopOpacity="0" />
                  </linearGradient>
                </defs>
                <path d={coinChart.fillPath} fill="url(#chartGradAmber)" />
                <path d={coinChart.path} fill="none" stroke="#f59e0b" strokeWidth="2.5" strokeLinecap="round" />
                {coinChart.coordinates.map((c, idx) => (
                  <circle key={idx} cx={c.x} cy={c.y} r="3" fill="#f59e0b" stroke="#09090b" strokeWidth="1" />
                ))}
              </svg>
            ) : (
              <div className="text-zinc-500 text-center w-full pb-8">No data found</div>
            )}
          </div>
          
          <div className="flex justify-between text-[8px] font-bold tracking-wider text-zinc-500 mt-2 px-1 uppercase">
            <span>{chartData[0]?.date || ''}</span>
            <span>{chartData[chartData.length - 1]?.date || ''}</span>
          </div>
        </div>

        {/* Call Analytics Chart Card */}
        <div className="glass-panel p-5 rounded-2xl flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-sm font-bold text-white">Call Traffic Volume</h2>
              <p className="text-[10px] text-zinc-400">Total phone calls connected</p>
            </div>
            
            <div className="text-[10px] font-bold text-rose-400 bg-rose-500/10 border border-rose-500/20 px-2 py-0.5 rounded">
              Call Traffic
            </div>
          </div>

          <div className="h-32 mt-4 flex items-end relative">
            {callPoints.length > 0 ? (
              <svg className="w-full h-full" viewBox="0 0 500 150" preserveAspectRatio="none">
                <defs>
                  <linearGradient id="chartGradRose" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#f43f5e" stopOpacity="0.4" />
                    <stop offset="100%" stopColor="#f43f5e" stopOpacity="0" />
                  </linearGradient>
                </defs>
                <path d={callChart.fillPath} fill="url(#chartGradRose)" />
                <path d={callChart.path} fill="none" stroke="#f43f5e" strokeWidth="2.5" strokeLinecap="round" />
                {callChart.coordinates.map((c, idx) => (
                  <circle key={idx} cx={c.x} cy={c.y} r="3" fill="#f43f5e" stroke="#09090b" strokeWidth="1" />
                ))}
              </svg>
            ) : (
              <div className="text-zinc-500 text-center w-full pb-8">No data found</div>
            )}
          </div>
          
          <div className="flex justify-between text-[8px] font-bold tracking-wider text-zinc-500 mt-2 px-1 uppercase">
            <span>{chartData[0]?.date || ''}</span>
            <span>{chartData[chartData.length - 1]?.date || ''}</span>
          </div>
        </div>

      </div>

      {/* CSV Export & Date Filter Toolbar */}
      <div className="glass-panel p-5 rounded-2xl">
        <h2 className="text-sm font-bold text-white flex items-center gap-2 mb-3">
          <Calendar size={16} className="text-indigo-400" />
          Financial Reports CSV Exporter
        </h2>

        <div className="flex flex-col lg:flex-row gap-4 items-end">
          
          {/* Range Select */}
          <div className="w-full lg:w-44 flex flex-col gap-1">
            <label className="text-[10px] text-zinc-400 font-bold uppercase tracking-wide">Date Filter Range</label>
            <select
              value={exportRange}
              onChange={(e: any) => setExportRange(e.target.value)}
              className="bg-secondary text-foreground text-xs font-semibold px-3 py-2 border border-border rounded-lg outline-none w-full"
            >
              <option value="today">Today</option>
              <option value="7days">Last 7 Days</option>
              <option value="30days">Last 30 Days</option>
              <option value="custom">Custom Range</option>
            </select>
          </div>

          {/* Custom Date Inputs */}
          {exportRange === 'custom' && (
            <>
              <div className="w-full lg:w-44 flex flex-col gap-1">
                <label className="text-[10px] text-zinc-400 font-bold uppercase tracking-wide">Start Date</label>
                <input
                  type="date"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                  className="bg-secondary text-foreground text-xs px-3 py-2 border border-border rounded-lg outline-none w-full"
                />
              </div>
              
              <div className="w-full lg:w-44 flex flex-col gap-1">
                <label className="text-[10px] text-zinc-400 font-bold uppercase tracking-wide">End Date</label>
                <input
                  type="date"
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                  className="bg-secondary text-foreground text-xs px-3 py-2 border border-border rounded-lg outline-none w-full"
                />
              </div>
            </>
          )}

          {/* Action Export Buttons */}
          <div className="flex flex-wrap gap-2 w-full lg:w-auto lg:ml-auto">
            <button
              onClick={() => handleExport('revenue')}
              className="flex items-center gap-1.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs px-3.5 py-2 rounded-lg transition-colors border border-indigo-500/20"
            >
              <Download size={14} /> Export Revenue
            </button>
            <button
              onClick={() => handleExport('earnings')}
              className="flex items-center gap-1.5 bg-amber-600 hover:bg-amber-700 text-white font-bold text-xs px-3.5 py-2 rounded-lg transition-colors border border-amber-500/20"
            >
              <Download size={14} /> Export Earnings
            </button>
            <button
              onClick={() => handleExport('withdrawals')}
              className="flex items-center gap-1.5 bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs px-3.5 py-2 rounded-lg transition-colors border border-rose-500/20"
            >
              <Download size={14} /> Export Withdrawals
            </button>
          </div>

        </div>
      </div>

      {/* Tables Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        
        {/* Top Creators Table */}
        <div className="glass-panel p-5 rounded-2xl flex flex-col justify-between">
          <div className="flex justify-between items-center mb-4">
            <div>
              <h2 className="text-sm font-bold text-white flex items-center gap-2">
                <Award size={16} className="text-emerald-400" />
                Top Performing Creators (Limit 10)
              </h2>
              <p className="text-[10px] text-zinc-400">Ranked by total coin earnings share</p>
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead>
                <tr className="border-b border-border text-zinc-500 font-bold uppercase tracking-wider text-[10px]">
                  <th className="py-2.5">Name</th>
                  <th className="py-2.5">Creator ID</th>
                  <th className="py-2.5 text-right">Total Earnings</th>
                  <th className="py-2.5 text-right">Total Calls</th>
                  <th className="py-2.5 text-right">Minutes</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/40">
                {topCreators.length > 0 ? (
                  topCreators.map((item, idx) => (
                    <tr key={item.creatorId} className="hover:bg-secondary/20">
                      <td className="py-2 flex items-center gap-2 font-semibold text-white">
                        <span className="w-4 text-zinc-500 text-[10px]">{idx + 1}.</span>
                        {item.creatorName}
                      </td>
                      <td className="py-2 text-zinc-500 font-mono text-[10px]">{item.creatorId.slice(0, 8)}...</td>
                      <td className="py-2 text-right font-semibold text-emerald-400">₹{(item.totalEarnings).toLocaleString()}</td>
                      <td className="py-2 text-right text-zinc-300">{item.totalCalls}</td>
                      <td className="py-2 text-right text-zinc-300">{Math.round(item.totalMinutes)}m</td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={5} className="py-6 text-center text-zinc-500 font-semibold">No creators found</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Payout/Withdrawal Summary Table */}
        <div className="glass-panel p-5 rounded-2xl flex flex-col justify-between">
          <div className="flex justify-between items-center mb-4">
            <div>
              <h2 className="text-sm font-bold text-white flex items-center gap-2">
                <Clock size={16} className="text-indigo-400" />
                Withdrawal Summary Status
              </h2>
              <p className="text-[10px] text-zinc-400">Overview of pending and paid withdrawal amounts</p>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4 mb-6">
            <div className="bg-secondary/40 border border-border p-4 rounded-xl">
              <span className="text-[10px] uppercase font-bold text-zinc-400 tracking-wider">Pending Payouts</span>
              <div className="mt-1 flex items-baseline justify-between">
                <span className="text-xl font-bold text-white">{withdrawalAnalytics.pendingWithdrawals} requests</span>
                <span className="text-sm font-semibold text-amber-400">₹{withdrawalAnalytics.pendingAmount.toLocaleString()}</span>
              </div>
            </div>
            
            <div className="bg-secondary/40 border border-border p-4 rounded-xl">
              <span className="text-[10px] uppercase font-bold text-zinc-400 tracking-wider">Disbursed Payouts</span>
              <div className="mt-1 flex items-baseline justify-between">
                <span className="text-xl font-bold text-white">{withdrawalAnalytics.paidWithdrawals} requests</span>
                <span className="text-sm font-semibold text-emerald-400">₹{withdrawalAnalytics.totalPayouts.toLocaleString()}</span>
              </div>
            </div>
          </div>

          <div className="border border-border/50 rounded-xl p-4 bg-secondary/15 flex items-start gap-3">
            <AlertCircle size={18} className="text-indigo-400 mt-0.5 flex-shrink-0" />
            <div className="space-y-1">
              <h3 className="text-xs font-bold text-white">Call Minute Statistics</h3>
              <p className="text-[10px] text-zinc-400 leading-normal">
                Platform connected <span className="text-white font-semibold">{callAnalytics.totalCalls} total calls</span> 
                {' '}averaging <span className="text-white font-semibold">{(callAnalytics.averageCallDuration / 60).toFixed(1)} minutes</span> per call. 
                Users spent <span className="text-amber-400 font-semibold">{callAnalytics.coinsUsed.toLocaleString()} coins</span>. 
                Remaining outstanding user wallet balance in circulation: <span className="text-amber-400 font-semibold">{callAnalytics.outstandingCoins.toLocaleString()} coins</span>.
              </p>
            </div>
          </div>

        </div>

      </div>

    </div>
  );
}
