// components/DashboardView.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { 
  Users, PhoneCall, DollarSign, Coins, AlertCircle, TrendingUp, 
  Clock, ArrowUpRight, CheckCircle2, UserCheck, Smartphone, UserMinus
} from 'lucide-react';
import { User, Listener, Call, Payment, SafetyReport, WithdrawRequest } from '../lib/mockDb';
import {
  API_BASE,
  getHeaders,
  classifyApiFailure,
  connectionErrorMessage,
  handleAuthFailure,
} from '../lib/api';
import { normalizeLanguages } from '../lib/format';
import LiveDataBanner from './LiveDataBanner';

interface DashboardViewProps {
  onNavigate: (tab: string, arg?: string) => void;
}

export default function DashboardView({ onNavigate }: DashboardViewProps) {
  const [users, setUsers] = useState<User[]>([]);
  const [listeners, setListeners] = useState<Listener[]>([]);
  const [calls, setCalls] = useState<Call[]>([]);
  const [payments, setPayments] = useState<Payment[]>([]);
  const [reports, setReports] = useState<SafetyReport[]>([]);
  const [withdrawRequests, setWithdrawRequests] = useState<WithdrawRequest[]>([]);
  const [revenueTab, setRevenueTab] = useState<'daily' | 'weekly' | 'monthly'>('daily');
  const [isLive, setIsLive] = useState(false);
  const [loadError, setLoadError] = useState<string | undefined>();

  const resolveHostName = (c: Record<string, unknown>) => {
    const user = c.user as { full_name?: string; fullName?: string; name?: string } | undefined;
    return String(
      c.fullName ||
        c.full_name ||
        c.name ||
        user?.full_name ||
        user?.fullName ||
        user?.name ||
        'Unknown Host',
    );
  };

  const mapCreator = (c: Record<string, unknown>, status: string): Listener => ({
    id: String(c.id),
    name: resolveHostName(c),
    image: String(
      c.profile_image ||
        c.profileImage ||
        (c.user as { profile_image?: string })?.profile_image ||
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    ),
    phone: String(c.phone || (c.user as { phone?: string })?.phone || 'N/A'),
    email: String(c.email || (c.user as { email?: string })?.email || 'N/A'),
    bio: String(c.bio || ''),
    languages: normalizeLanguages(c.languages),
    gender: (c.gender as Listener['gender']) || 'Female',
    experience: String(c.experience || '1 Year'),
    status: status as Listener['status'],
    rating: Number(c.rating || 0),
    completedCalls: Number(c.completedCalls ?? c.total_calls ?? 0),
    revenueGenerated: Number(c.revenueGenerated ?? c.total_earnings ?? 0),
    commissionRate: 60,
    joinDate: String(c.createdAt || c.created_at || new Date().toISOString()).split('T')[0],
    acceptanceRate: 100,
    missedCallRate: 0,
    earningsToday: 0,
    earningsWeek: 0,
    earningsMonth: 0,
    earningsLifetime: Number(c.revenueGenerated ?? c.total_earnings ?? 0),
  });

  const loadLiveDashboard = async () => {
    setLoadError(undefined);
    const headers = getHeaders();

    if (!headers.Authorization || headers.Authorization === 'Bearer ') {
      setLoadError('Not signed in. Use /login with your admin email and password.');
      setIsLive(false);
      return;
    }

    try {
      const endpoints = [
        { key: 'users', url: `${API_BASE}/users` },
        { key: 'creatorsActive', url: `${API_BASE}/creators/active` },
        { key: 'creatorsPending', url: `${API_BASE}/creators/pending` },
        { key: 'creatorsSuspended', url: `${API_BASE}/creators/suspended` },
        { key: 'callsActive', url: `${API_BASE}/calls/active` },
        { key: 'callsHistory', url: `${API_BASE}/calls` },
        { key: 'payments', url: `${API_BASE}/payments/history` },
        { key: 'withdrawals', url: `${API_BASE}/admin/withdrawals` },
      ] as const;

      const responses = await Promise.all(
        endpoints.map(async (ep) => {
          const res = await fetch(ep.url, { headers });
          return { ...ep, res };
        }),
      );

      const authRejected = responses.find((r) => r.res.status === 401 || r.res.status === 403);
      if (authRejected) {
        handleAuthFailure(authRejected.res.status);
        setLoadError(connectionErrorMessage(classifyApiFailure(authRejected.res.status)));
        setIsLive(false);
        return;
      }

      const usersRes = responses.find((r) => r.key === 'users')!;
      if (!usersRes.res.ok) {
        const failed = responses.filter((r) => !r.res.ok).map((r) => `${r.key} (${r.res.status})`);
        setLoadError(
          failed.length
            ? `API errors: ${failed.join(', ')}. Redeploy Vercel after setting NEXT_PUBLIC_API_URL.`
            : 'Could not load users from API.',
        );
        setIsLive(false);
        return;
      }

      const usersData = await usersRes.res.json();
      setUsers(
        usersData.map((u: Record<string, unknown>) => ({
          id: String(u.id),
          name: String(u.fullName || u.full_name || u.name || 'Unknown User'),
          image: String(
            u.profile_image || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
          ),
          phone: String(u.phone || 'N/A'),
          email: String(u.email || 'N/A'),
          coins: Number(u.coins ?? 0),
          totalCalls: Number(u.totalCalls ?? u.total_calls ?? 0),
          totalDuration: Number(u.total_duration ?? 0),
          totalRecharge: Number(u.total_recharge ?? 0),
          totalSpent: Number(u.total_spent ?? 0),
          country: String(u.country || 'India'),
          device: String(u.device || 'Android Device'),
          registeredAt: String(u.registeredAt || u.created_at || new Date().toISOString()),
          status: (u.status === 'blocked' ? 'blocked' : 'active') as User['status'],
          reportsCount: 0,
          safetyScore: 100,
        })),
      );

      const parseJson = async (r: (typeof responses)[number]) =>
        r.res.ok ? r.res.json() : [];

      const [activeCreatorsData, pendingCreatorsData, suspendedCreatorsData, activeCallsData, historyCallsData, paymentsData, withdrawData] =
        await Promise.all([
          parseJson(responses.find((r) => r.key === 'creatorsActive')!),
          parseJson(responses.find((r) => r.key === 'creatorsPending')!),
          parseJson(responses.find((r) => r.key === 'creatorsSuspended')!),
          parseJson(responses.find((r) => r.key === 'callsActive')!),
          parseJson(responses.find((r) => r.key === 'callsHistory')!),
          parseJson(responses.find((r) => r.key === 'payments')!),
          parseJson(responses.find((r) => r.key === 'withdrawals')!),
        ]);

      setListeners([
        ...activeCreatorsData.map((c: Record<string, unknown>) => mapCreator(c, 'active')),
        ...pendingCreatorsData.map((c: Record<string, unknown>) => mapCreator(c, 'pending')),
        ...suspendedCreatorsData.map((c: Record<string, unknown>) => mapCreator(c, 'suspended')),
      ]);

      const mapCall = (c: Record<string, unknown>, statusOverride?: Call['status']): Call => ({
        id: String(c.id),
        callerId: String(c.callerId),
        callerName: String(c.callerName || 'User'),
        listenerId: String(c.creatorId),
        listenerName: String(c.creatorName || 'Host'),
        type: (c.type as Call['type']) || 'voice',
        status: statusOverride || (c.status as Call['status']) || 'completed',
        duration: Number(c.durationSeconds ?? 0),
        coinsConsumed: Number(c.coinsSpent ?? 0),
        date: String(c.startedAt || new Date().toISOString()),
      });

      setCalls([
        ...activeCallsData.map((c: Record<string, unknown>) => mapCall(c, 'active')),
        ...historyCallsData.map((c: Record<string, unknown>) => mapCall(c)),
      ]);

      setPayments(
        paymentsData.map((p: Record<string, unknown>) => ({
          id: String(p.id),
          userId: String(p.userId),
          userName: String(p.userName || 'User'),
          amount: Number(p.amount),
          coins: Number(p.coins),
          gateway: String(p.gateway),
          transactionId: String(p.transactionId),
          status: p.status as Payment['status'],
          date: String(p.date),
        })),
      );

      setWithdrawRequests(
        withdrawData.map((w: Record<string, unknown>) => ({
          id: String(w.id),
          listenerId: String(w.creator_id ?? w.creatorId),
          listenerName: String(w.creator_name || 'Host'),
          amount: Number(w.amount),
          upiId: String(w.upi_id || 'N/A'),
          bankDetails: {
            bankName: String(w.bank_name || 'N/A'),
            accountNo: String(w.account_number || 'N/A'),
            ifsc: String(w.ifsc_code || 'N/A'),
            holderName: String(w.account_name || 'N/A'),
          },
          requestDate: String(w.created_at || new Date().toISOString()),
          status: (w.status as WithdrawRequest['status']) || 'pending',
          adminNote: w.admin_note ? String(w.admin_note) : undefined,
        })),
      );

      setReports([]);
      setIsLive(true);
    } catch (e) {
      console.warn('DashboardView failed to fetch live API data:', e);
      setLoadError('Network error reaching the API. Check CORS and Railway status.');
      setUsers([]);
      setListeners([]);
      setCalls([]);
      setPayments([]);
      setReports([]);
      setWithdrawRequests([]);
      setIsLive(false);
    }
  };

  useEffect(() => {
    loadLiveDashboard();
    const interval = setInterval(loadLiveDashboard, 30000);
    return () => clearInterval(interval);
  }, []);

  // Stats Calculations
  const totalUsers = users.length;
  const activeUsersToday = users.filter(u => u.status === 'active').length;
  const onlineUsers = users.filter(u => u.status === 'active').length;

  const totalListeners = listeners.length;
  const onlineListeners = listeners.filter(l => l.status === 'active').length;

  const todayPrefix = new Date().toISOString().split('T')[0];
  const callsToday = calls.filter(c => c.date.startsWith(todayPrefix)).length;
  const activeCalls = calls.filter(c => c.status === 'active').length;
  
  const totalRevenue = payments.filter(p => p.status === 'success').reduce((sum, p) => sum + p.amount, 0);
  const todayRevenue = payments
    .filter(p => p.status === 'success' && p.date.startsWith(todayPrefix))
    .reduce((sum, p) => sum + p.amount, 0);
    
  const totalCoinsSold = payments.filter(p => p.status === 'success').reduce((sum, p) => sum + p.coins, 0);
  const pendingWithdraws = withdrawRequests.filter(w => w.status === 'pending').length;
  const pendingReports = reports.filter(r => r.status === 'pending').length;

  // Custom SVG Chart Generators
  const generateRevenuePath = (period: 'daily' | 'weekly' | 'monthly') => {
    let data: number[] = [];
    if (period === 'daily') {
      const last7 = Array.from({ length: 7 }, (_, i) => {
        const d = new Date();
        d.setDate(d.getDate() - (6 - i));
        const prefix = d.toISOString().split('T')[0];
        return payments
          .filter(p => p.status === 'success' && p.date.startsWith(prefix))
          .reduce((sum, p) => sum + p.amount, 0);
      });
      data = last7;
    } else if (period === 'weekly') {
      data = [2500, 3200, 4100, 2800, 4500, 5800, 6200];
    } else {
      data = [12000, 18000, 15000, 22000, 28000, 32000, 35000];
    }
    
    const width = 500;
    const height = 150;
    const padding = 20;
    const maxVal = Math.max(...data) * 1.1;
    const minVal = Math.min(...data) * 0.9;
    
    const points = data.map((val, idx) => {
      const x = padding + (idx * (width - padding * 2)) / (data.length - 1);
      const y = height - padding - ((val - minVal) * (height - padding * 2)) / (maxVal - minVal || 1);
      return `${x},${y}`;
    });

    const path = `M ${points.join(' L ')}`;
    // Gradient fill path
    const firstPoint = points[0].split(',');
    const lastPoint = points[points.length - 1].split(',');
    const fillPath = `${path} L ${lastPoint[0]},${height - padding} L ${firstPoint[0]},${height - padding} Z`;
    
    return { path, fillPath, points: data, coordinates: points.map(p => {
      const [x, y] = p.split(',');
      return { x: parseFloat(x), y: parseFloat(y) };
    })};
  };

  const revenueChartData = generateRevenuePath(revenueTab);

  return (
    <div className="space-y-6">
      {/* Page Title */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div className="flex flex-col gap-1">
          <h1 className="text-2xl font-bold tracking-tight text-white sm:text-3xl">Dashboard Overview</h1>
          <p className="text-sm text-zinc-400">Real-time metrics, analytics, and platform health.</p>
        </div>
        <div className="flex items-center gap-3">
          <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold tracking-wide uppercase border flex items-center gap-1.5 ${
            isLive 
              ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30' 
              : 'bg-amber-500/10 text-amber-400 border-amber-500/30'
          }`}>
            <span className={`w-1.5 h-1.5 rounded-full ${isLive ? 'bg-emerald-400 animate-pulse' : 'bg-amber-400'}`}></span>
            {isLive ? 'Live data' : 'Not connected'}
          </span>
          <button 
            onClick={loadLiveDashboard}
            className="px-3 py-1.5 bg-secondary text-foreground text-xs font-semibold rounded-lg hover:bg-secondary/80 border border-border"
          >
            Refresh
          </button>
        </div>
      </div>

      <LiveDataBanner isLive={isLive} label="dashboard" errorMessage={loadError} apiBase={API_BASE} />

      {/* KPI Cards Grid */}
      <div className="grid grid-cols-2 gap-4 md:grid-cols-3 lg:grid-cols-4">
        
        {/* Card 1: Users */}
        <div 
          onClick={() => onNavigate('users')}
          className="group glass-card glow-indigo p-4 rounded-xl cursor-pointer hover:border-indigo-500/30"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-zinc-400">Total Users</span>
            <div className="p-2 bg-indigo-500/10 rounded-lg text-indigo-400 group-hover:bg-indigo-500/20 transition-colors">
              <Users size={16} />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-2">
            <span className="text-2xl font-bold text-white tracking-tight">{totalUsers}</span>
            <span className="text-[10px] font-semibold text-emerald-400 flex items-center bg-emerald-500/10 px-1.5 py-0.5 rounded">
              +12%
            </span>
          </div>
          <div className="mt-2 flex items-center gap-1.5 text-[10px] text-zinc-500">
            <span className="inline-block w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
            <span>{onlineUsers} Online now</span>
          </div>
        </div>

        {/* Card 2: Listeners */}
        <div 
          onClick={() => onNavigate('listeners')}
          className="group glass-card p-4 rounded-xl cursor-pointer hover:border-emerald-500/30"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-zinc-400">Total Listeners</span>
            <div className="p-2 bg-emerald-500/10 rounded-lg text-emerald-400 group-hover:bg-emerald-500/20 transition-colors">
              <UserCheck size={16} />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-2">
            <span className="text-2xl font-bold text-white tracking-tight">{totalListeners}</span>
            <span className="text-[10px] font-semibold text-emerald-400 flex items-center bg-emerald-500/10 px-1.5 py-0.5 rounded">
              +3 new
            </span>
          </div>
          <div className="mt-2 flex items-center gap-1.5 text-[10px] text-zinc-500">
            <span className="inline-block w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
            <span>{onlineListeners} Active/Online</span>
          </div>
        </div>

        {/* Card 3: Calls */}
        <div 
          onClick={() => onNavigate('calls')}
          className="group glass-card p-4 rounded-xl cursor-pointer hover:border-violet-500/30"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-zinc-400">Calls Today</span>
            <div className="p-2 bg-violet-500/10 rounded-lg text-violet-400 group-hover:bg-violet-500/20 transition-colors">
              <PhoneCall size={16} />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-2">
            <span className="text-2xl font-bold text-white tracking-tight">{callsToday}</span>
            {activeCalls > 0 && (
              <span className="text-[10px] font-semibold text-rose-400 flex items-center bg-rose-500/10 px-1.5 py-0.5 rounded animate-pulse">
                {activeCalls} Live
              </span>
            )}
          </div>
          <div className="mt-2 text-[10px] text-zinc-500 flex justify-between">
            <span>Avg: 8.4 mins</span>
            <span className="text-emerald-400 flex items-center gap-0.5">
              <TrendingUp size={10} /> +8%
            </span>
          </div>
        </div>

        {/* Card 4: Total Revenue */}
        <div 
          onClick={() => onNavigate('payments')}
          className="group glass-card glow-indigo p-4 rounded-xl cursor-pointer hover:border-indigo-500/30"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-zinc-400">Total Revenue</span>
            <div className="p-2 bg-pink-500/10 rounded-lg text-pink-400 group-hover:bg-pink-500/20 transition-colors">
              <DollarSign size={16} />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-2">
            <span className="text-2xl font-bold text-white tracking-tight">₹{totalRevenue}</span>
            <span className="text-[10px] font-semibold text-emerald-400 bg-emerald-500/10 px-1.5 py-0.5 rounded">
              +18%
            </span>
          </div>
          <div className="mt-2 text-[10px] text-zinc-500 flex justify-between">
            <span>Today: ₹{todayRevenue}</span>
            <span className="text-zinc-400">Gateway: Razorpay</span>
          </div>
        </div>

        {/* Card 5: Coins Sold */}
        <div 
          onClick={() => onNavigate('coins')}
          className="group glass-card p-4 rounded-xl cursor-pointer hover:border-amber-500/30"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-zinc-400">Total Coins Sold</span>
            <div className="p-2 bg-amber-500/10 rounded-lg text-amber-400 group-hover:bg-amber-500/20 transition-colors">
              <Coins size={16} />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-2">
            <span className="text-2xl font-bold text-white tracking-tight">{totalCoinsSold}</span>
          </div>
          <div className="mt-2 text-[10px] text-zinc-500">
            <span>Avg package price: ₹399</span>
          </div>
        </div>

        {/* Card 6: Pending Payouts */}
        <div 
          onClick={() => onNavigate('listeners', 'withdraw')}
          className="group glass-card p-4 rounded-xl cursor-pointer hover:border-blue-500/30"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-zinc-400">Pending Payouts</span>
            <div className="p-2 bg-blue-500/10 rounded-lg text-blue-400 group-hover:bg-blue-500/20 transition-colors">
              <Clock size={16} />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-2">
            <span className="text-2xl font-bold text-white tracking-tight">{pendingWithdraws}</span>
            {pendingWithdraws > 0 && (
              <span className="text-[10px] font-semibold text-amber-400 bg-amber-500/10 px-1.5 py-0.5 rounded animate-pulse">
                Requires action
              </span>
            )}
          </div>
          <div className="mt-2 text-[10px] text-zinc-500">
            <span>Minimum payout: ₹1000</span>
          </div>
        </div>

        {/* Card 7: Safety Reports */}
        <div 
          onClick={() => onNavigate('safety')}
          className="group glass-card p-4 rounded-xl cursor-pointer hover:border-red-500/30"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-zinc-400">Pending Reports</span>
            <div className="p-2 bg-red-500/10 rounded-lg text-red-400 group-hover:bg-red-500/20 transition-colors">
              <AlertCircle size={16} />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-2">
            <span className="text-2xl font-bold text-white tracking-tight">{pendingReports}</span>
            {pendingReports > 0 && (
              <span className="text-[10px] font-semibold text-red-400 bg-red-500/10 px-1.5 py-0.5 rounded animate-pulse">
                High Priority
              </span>
            )}
          </div>
          <div className="mt-2 text-[10px] text-zinc-500">
            <span>Safety Score Avg: 92%</span>
          </div>
        </div>

        {/* Card 8: Active Calls Live */}
        <div 
          onClick={() => onNavigate('calls')}
          className="group glass-card p-4 rounded-xl cursor-pointer hover:border-rose-500/30"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-zinc-400">Live Active Calls</span>
            <div className="p-2 bg-rose-500/10 rounded-lg text-rose-400 group-hover:bg-rose-500/20 transition-colors">
              <PhoneCall size={16} />
            </div>
          </div>
          <div className="mt-2 flex items-baseline gap-2">
            <span className="text-2xl font-bold text-white tracking-tight">{activeCalls}</span>
            <span className="flex h-2 w-2 relative">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-rose-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-rose-500"></span>
            </span>
          </div>
          <div className="mt-2 text-[10px] text-zinc-500">
            <span>Consuming ~{activeCalls * 10} coins/min</span>
          </div>
        </div>

      </div>

      {/* Analytics Charts & Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Main Chart Card */}
        <div className="lg:col-span-2 glass-panel p-5 rounded-2xl flex flex-col justify-between">
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div>
              <h2 className="text-base font-semibold text-white">Revenue Analytics</h2>
              <p className="text-xs text-zinc-400">Platform earnings via user coin recharges</p>
            </div>
            
            {/* Tabs */}
            <div className="flex bg-zinc-900 border border-zinc-800 p-0.5 rounded-lg text-xs">
              {(['daily', 'weekly', 'monthly'] as const).map((tab) => (
                <button
                  key={tab}
                  onClick={() => setRevenueTab(tab)}
                  className={`px-3 py-1 rounded-md capitalize font-medium transition-colors ${
                    revenueTab === tab 
                      ? 'bg-zinc-800 text-white' 
                      : 'text-zinc-400 hover:text-zinc-200'
                  }`}
                >
                  {tab}
                </button>
              ))}
            </div>
          </div>

          {/* Canvas SVG Graph */}
          <div className="mt-6 h-48 relative flex items-end">
            <svg className="w-full h-full" viewBox="0 0 500 150" preserveAspectRatio="none">
              <defs>
                <linearGradient id="chartGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#6366f1" stopOpacity="0.45" />
                  <stop offset="100%" stopColor="#6366f1" stopOpacity="0" />
                </linearGradient>
              </defs>
              {/* Grid Lines */}
              <line x1="20" y1="20" x2="480" y2="20" stroke="#27272a" strokeWidth="1" strokeDasharray="3 3" />
              <line x1="20" y1="65" x2="480" y2="65" stroke="#27272a" strokeWidth="1" strokeDasharray="3 3" />
              <line x1="20" y1="110" x2="480" y2="110" stroke="#27272a" strokeWidth="1" strokeDasharray="3 3" />
              <line x1="20" y1="130" x2="480" y2="130" stroke="#27272a" strokeWidth="1.5" />

              {/* Shaded Area */}
              <path d={revenueChartData.fillPath} fill="url(#chartGrad)" />
              {/* Line path */}
              <path 
                d={revenueChartData.path} 
                fill="none" 
                stroke="#6366f1" 
                strokeWidth="2.5" 
                strokeLinecap="round" 
                strokeLinejoin="round" 
              />

              {/* Data points */}
              {revenueChartData.coordinates.map((coord, idx) => (
                <g key={idx} className="group/dot cursor-pointer">
                  <circle 
                    cx={coord.x} 
                    cy={coord.y} 
                    r="4" 
                    fill="#6366f1" 
                    stroke="#09090b" 
                    strokeWidth="1.5" 
                    className="hover:r-6 transition-all duration-150"
                  />
                  <circle 
                    cx={coord.x} 
                    cy={coord.y} 
                    r="10" 
                    fill="#6366f1" 
                    fillOpacity="0" 
                    className="hover:fill-opacity-10 cursor-pointer"
                  />
                </g>
              ))}
            </svg>
            
            {/* Tooltip Overlay Mock */}
            <div className="absolute top-1 right-2 text-[10px] text-zinc-500 bg-zinc-950/80 px-2 py-1 rounded border border-zinc-800">
              Peak: ₹{Math.max(...revenueChartData.points)}
            </div>
          </div>

          {/* Graph labels */}
          <div className="mt-2 flex justify-between text-[10px] text-zinc-500 px-4">
            {revenueTab === 'daily' ? (
              <>
                <span>Mon</span><span>Tue</span><span>Wed</span><span>Thu</span><span>Fri</span><span>Sat</span><span>Today</span>
              </>
            ) : revenueTab === 'weekly' ? (
              <>
                <span>Week 1</span><span>Week 2</span><span>Week 3</span><span>Week 4</span><span>Week 5</span><span>Week 6</span><span>This Week</span>
              </>
            ) : (
              <>
                <span>Jan</span><span>Feb</span><span>Mar</span><span>Apr</span><span>May</span><span>Jun</span><span>Jul</span>
              </>
            )}
          </div>
        </div>

        {/* Top Listeners panel */}
        <div className="glass-panel p-5 rounded-2xl flex flex-col">
          <div className="flex justify-between items-center">
            <div>
              <h2 className="text-base font-semibold text-white">Top Hosts</h2>
              <p className="text-xs text-zinc-400">Top rating & high earners</p>
            </div>
            <button 
              onClick={() => onNavigate('listeners')}
              className="text-xs text-indigo-400 hover:text-indigo-300 font-medium flex items-center gap-0.5"
            >
              View all <ArrowUpRight size={14} />
            </button>
          </div>

          <div className="mt-4 flex-1 space-y-4">
            {listeners.slice(0, 3).map((listener, index) => (
              <div key={listener.id} className="flex items-center justify-between p-2 rounded-xl bg-zinc-900/40 hover:bg-zinc-900/80 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="relative">
                    <img 
                      src={listener.image} 
                      alt={listener.name} 
                      className="w-9 h-9 rounded-full object-cover border border-zinc-800"
                    />
                    <div className="absolute -bottom-1 -right-1 bg-indigo-500 text-[8px] font-bold text-white w-4 h-4 rounded-full flex items-center justify-center">
                      {index + 1}
                    </div>
                  </div>
                  <div>
                    <h3 className="text-xs font-semibold text-white leading-none">{listener.name}</h3>
                    <p className="text-[10px] text-zinc-500 mt-1">{listener.languages.slice(0, 2).join(', ')}</p>
                  </div>
                </div>
                <div className="text-right">
                  <span className="text-xs font-semibold text-emerald-400">₹{listener.earningsLifetime}</span>
                  <p className="text-[9px] text-zinc-500">⭐ {listener.rating.toFixed(1)} Rating</p>
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>

      {/* Recent Activities Section */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        
        {/* Latest Recharges & Registration Logs */}
        <div className="glass-panel p-5 rounded-2xl">
          <h2 className="text-base font-semibold text-white mb-4">Latest Recharges</h2>
          <div className="space-y-3">
            {payments.slice(0, 4).map((pay) => (
              <div key={pay.id} className="flex items-center justify-between p-3 rounded-xl bg-zinc-900/40 hover:bg-zinc-900/80 transition-all border border-transparent hover:border-zinc-800/50">
                <div className="flex items-center gap-3">
                  <div className={`p-2 rounded-lg text-xs font-semibold ${
                    pay.status === 'success' ? 'bg-emerald-500/10 text-emerald-400' :
                    pay.status === 'failed' ? 'bg-red-500/10 text-red-400' : 'bg-amber-500/10 text-amber-400'
                  }`}>
                    {pay.status === 'success' ? '✓' : pay.status === 'failed' ? '✗' : '⌛'}
                  </div>
                  <div>
                    <h3 className="text-xs font-semibold text-white leading-none">{pay.userName}</h3>
                    <p className="text-[9px] text-zinc-500 mt-1">{pay.gateway} • {new Date(pay.date).toLocaleTimeString()}</p>
                  </div>
                </div>
                <div className="text-right">
                  <span className="text-xs font-bold text-white">₹{pay.amount}</span>
                  <p className="text-[9px] text-indigo-400">+{pay.coins} coins</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Latest Activity Logs (Calls & Reports) */}
        <div className="glass-panel p-5 rounded-2xl">
          <h2 className="text-base font-semibold text-white mb-4">Recent Call Activity</h2>
          <div className="space-y-3">
            {calls.slice(0, 4).map((call) => (
              <div key={call.id} className="flex items-center justify-between p-3 rounded-xl bg-zinc-900/40 hover:bg-zinc-900/80 transition-all border border-transparent hover:border-zinc-800/50">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-zinc-800 rounded-lg text-zinc-400">
                    <PhoneCall size={14} className={call.status === 'active' ? 'text-rose-400 animate-pulse' : ''} />
                  </div>
                  <div>
                    <div className="flex items-center gap-1.5">
                      <span className="text-xs font-medium text-white">{call.callerName}</span>
                      <span className="text-[10px] text-zinc-500">→</span>
                      <span className="text-xs font-medium text-indigo-300">{call.listenerName}</span>
                    </div>
                    <p className="text-[9px] text-zinc-500 mt-1 capitalize">{call.type} • {call.status}</p>
                  </div>
                </div>
                <div className="text-right">
                  <span className="text-xs font-semibold text-zinc-300">
                    {call.duration === 0 ? 'Missed' : `${Math.floor(call.duration / 60)}m ${call.duration % 60}s`}
                  </span>
                  {call.coinsConsumed > 0 && (
                    <p className="text-[9px] text-amber-400">-{call.coinsConsumed} coins</p>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>

    </div>
  );
}
