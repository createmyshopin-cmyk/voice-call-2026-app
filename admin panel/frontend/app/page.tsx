// app/page.tsx
'use client';

import React, { useState, useEffect, useRef, Suspense, lazy, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { 
  LayoutDashboard, Users, PhoneCall, Wallet, Coins, CreditCard, 
  Bell, ShieldAlert, BarChart3, Settings, UserCheck, Search, Command, X, ArrowUpRight,
  Sun, Moon, LogOut, TrendingUp, Gift, MessageSquare, Crown, Target, Flame, Heart,
  Award, Video, Scale, Activity, Radio, Banknote
} from 'lucide-react';

// Core views (eager — frequently accessed)
import DashboardView from '../components/DashboardView';
import UsersView from '../components/UsersView';
import ListenersView from '../components/ListenersView';
import FinanceDashboard from '../components/FinanceDashboard';

// Lazy-loaded modules (avoid rebuild storms)
const WithdrawalsView = lazy(() => import('../components/modules/WithdrawalsView'));
const CreatorAnalyticsView = lazy(() => import('../components/modules/CreatorAnalyticsView'));
const GiftsAdminView = lazy(() => import('../components/modules/GiftsAdminView'));
const MessagesAnalyticsView = lazy(() => import('../components/modules/MessagesAnalyticsView'));
const VipAdminView = lazy(() => import('../components/modules/VipAdminView'));
const MissionsView = lazy(() => import('../components/modules/MissionsView'));
const StreaksView = lazy(() => import('../components/modules/StreaksView'));
const FollowFavoriteView = lazy(() => import('../components/modules/FollowFavoriteView'));
const CreatorLevelsView = lazy(() => import('../components/modules/CreatorLevelsView'));
const TrainingVideosView = lazy(() => import('../components/modules/TrainingVideosView'));
const ReconciliationView = lazy(() => import('../components/modules/ReconciliationView'));
const SystemHealthView = lazy(() => import('../components/modules/SystemHealthView'));
const OperationsCenterView = lazy(() => import('../components/modules/OperationsCenterView'));
const WalletView = lazy(() => import('../components/WalletView'));
const CoinsView = lazy(() => import('../components/CoinsView'));
const PaymentsView = lazy(() => import('../components/PaymentsView'));
const CallsView = lazy(() => import('../components/CallsView'));
const NotificationsView = lazy(() => import('../components/NotificationsView'));
const SafetyView = lazy(() => import('../components/SafetyView'));
const SettingsView = lazy(() => import('../components/SettingsView'));
const AdminsView = lazy(() => import('../components/AdminsView'));

import { MockDatabase } from '../lib/mockDb';
import { API_BASE, getHeaders } from '../lib/api';
import { normalizeWithdrawalList } from '../lib/api/withdrawals';
import { clearSession, getAdminUser, isAuthenticated, type AdminUser } from '../lib/auth';
import { canAccessModule, type AdminModule } from '../lib/rbac';

export default function Home() {
  const router = useRouter();
  const [authReady, setAuthReady] = useState(false);
  const [adminUser, setAdminUser] = useState<AdminUser | null>(null);
  const [activeTab, setActiveTab] = useState('dashboard');
  const [subTab, setSubTab] = useState<any>(undefined);
  
  // Theme State (Dark Mode default)
  const [theme, setTheme] = useState<'dark' | 'light'>('dark');

  useEffect(() => {
    const legacyAppToken = localStorage.getItem('token');
    if (legacyAppToken && !localStorage.getItem('coincall_admin_token')) {
      localStorage.removeItem('token');
    }
    if (!isAuthenticated()) {
      router.replace('/login');
      return;
    }
    setAdminUser(getAdminUser());
    setAuthReady(true);
  }, [router]);

  useEffect(() => {
    const savedTheme = localStorage.getItem('coincall_theme') as 'dark' | 'light' | null;
    if (savedTheme) {
      setTheme(savedTheme);
    }
  }, []);

  const handleLogout = () => {
    clearSession();
    router.replace('/login');
  };

  const toggleTheme = () => {
    const nextTheme = theme === 'dark' ? 'light' : 'dark';
    setTheme(nextTheme);
    localStorage.setItem('coincall_theme', nextTheme);
  };
  
  // States for stats badges
  const [pendingListenersCount, setPendingListenersCount] = useState(0);
  const [pendingWithdrawsCount, setPendingWithdrawsCount] = useState(0);
  const [pendingReportsCount, setPendingReportsCount] = useState(0);

  // Command Palette State
  const [isPaletteOpen, setIsPaletteOpen] = useState(false);
  const [paletteQuery, setPaletteQuery] = useState('');
  const [paletteResults, setPaletteResults] = useState<{ id: string; title: string; category: string; action: () => void }[]>([]);
  const paletteInputRef = useRef<HTMLInputElement>(null);

  // Global user search jump target
  const [selectedUserId, setSelectedUserId] = useState<string | undefined>(undefined);

  const refreshBadges = async () => {
    try {
      const [pendingRes, withdrawsRes] = await Promise.all([
        fetch(`${API_BASE}/creators/pending`, { headers: getHeaders() }),
        fetch(`${API_BASE}/admin/withdrawals`, { headers: getHeaders() })
      ]);

      let pendingCount = 0;
      let withdrawsCount = 0;

      if (pendingRes.ok) {
        const pendingData = await pendingRes.json();
        pendingCount = pendingData.length;
      }

      if (withdrawsRes.ok) {
        const withdrawsData = normalizeWithdrawalList(await withdrawsRes.json());
        withdrawsCount = withdrawsData.items.filter((w) => w.status === 'pending').length;
      }

      setPendingListenersCount(pendingCount);
      setPendingWithdrawsCount(withdrawsCount);
    } catch (e) {
      console.warn('refreshBadges failed to load live data:', e);
    }

    setPendingReportsCount(0);
  };

  useEffect(() => {
    refreshBadges();

    // Hotkey handler for Cmd/Ctrl + K command palette
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        setIsPaletteOpen(prev => !prev);
      }
      if (e.key === 'Escape') {
        setIsPaletteOpen(false);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  // Update badge stats on active tab switches
  useEffect(() => {
    refreshBadges();
  }, [activeTab]);

  // Focus palette input when opened
  useEffect(() => {
    if (isPaletteOpen && paletteInputRef.current) {
      paletteInputRef.current.focus();
      setPaletteQuery('');
      setPaletteResults([]);
    }
  }, [isPaletteOpen]);

  // Perform Palette Search
  useEffect(() => {
    if (!paletteQuery.trim()) {
      setPaletteResults([]);
      return;
    }

    const query = paletteQuery.toLowerCase().trim();
    const results: typeof paletteResults = [];

    // Search Navigation Pages
    const pages = [
      { title: 'Dashboard Analytics', tab: 'dashboard' },
      { title: 'Users Directory', tab: 'users' },
      { title: 'Listeners Directory', tab: 'listeners' },
      { title: 'Onboarding Applications', tab: 'listeners', sub: 'pending' },
      { title: 'Withdraw Payout Requests', tab: 'listeners', sub: 'withdrawals' },
      { title: 'Transactions Registry', tab: 'wallet' },
      { title: 'Coin Purchasing Packages', tab: 'coins' },
      { title: 'Recharges Payment Audits', tab: 'payments' },
      { title: 'Ongoing Live Call Streams', tab: 'calls', sub: 'active' },
      { title: 'Sent Broadcast Notifications', tab: 'notifications' },
      { title: 'Moderation Abuse Reports', tab: 'safety' },
      { title: 'Platform Settings Configs', tab: 'settings' },
      { title: 'Admin Accounts permissions', tab: 'admins' }
    ];

    pages.forEach(p => {
      if (p.title.toLowerCase().includes(query)) {
        results.push({
          id: `page_${p.tab}_${p.sub || ''}`,
          title: `Navigate: ${p.title}`,
          category: 'Pages',
          action: () => {
            setActiveTab(p.tab);
            if (p.sub) setSubTab(p.sub);
            setIsPaletteOpen(false);
          }
        });
      }
    });

    // Search Users Database
    const usersList = MockDatabase.getUsers();
    usersList.forEach(u => {
      if (u.name.toLowerCase().includes(query) || u.phone.includes(query) || u.id.toLowerCase().includes(query)) {
        results.push({
          id: `user_${u.id}`,
          title: `${u.name} (Coins: ${u.coins})`,
          category: 'Users',
          action: () => {
            setSelectedUserId(u.id);
            setActiveTab('users');
            setIsPaletteOpen(false);
          }
        });
      }
    });

    // Search Listeners Database
    const hostList = MockDatabase.getListeners();
    hostList.forEach(l => {
      if (l.name.toLowerCase().includes(query) || l.id.toLowerCase().includes(query) || l.bio.toLowerCase().includes(query)) {
        results.push({
          id: `listener_${l.id}`,
          title: `${l.name} (${l.status.toUpperCase()})`,
          category: 'Listeners/Hosts',
          action: () => {
            setActiveTab('listeners');
            setSubTab(l.status === 'pending' ? 'pending' : 'active');
            setIsPaletteOpen(false);
          }
        });
      }
    });

    setPaletteResults(results.slice(0, 7)); // cap at 7 results
  }, [paletteQuery]);

  const handleGlobalNavigate = (tab: string, arg?: string) => {
    setActiveTab(tab);
    if (arg === 'withdraw') {
      setSubTab('withdrawals');
    } else {
      setSubTab(undefined);
    }
  };

  const tabToModule = (id: string): AdminModule => id as AdminModule;

  const allNavItems = [
    { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard, section: 'Overview' },
    { id: 'operations', label: 'Operations Center', icon: Radio, section: 'Overview' },
    { id: 'finance', label: 'Finance', icon: BarChart3, section: 'Finance' },
    { id: 'reconciliation', label: 'Reconciliation', icon: Scale, section: 'Finance' },
    { id: 'withdrawals', label: 'Withdrawals', icon: Banknote, badge: pendingWithdrawsCount, section: 'Finance' },
    { id: 'creator_analytics', label: 'Creator Analytics', icon: TrendingUp, section: 'Creators' },
    { id: 'listeners', label: 'Creator Management', icon: UserCheck, badge: pendingListenersCount, section: 'Creators' },
    { id: 'gifts', label: 'Gifts', icon: Gift, section: 'Engagement' },
    { id: 'messages', label: 'Paid Messages', icon: MessageSquare, section: 'Engagement' },
    { id: 'vip', label: 'VIP Membership', icon: Crown, section: 'Engagement' },
    { id: 'missions', label: 'Missions', icon: Target, section: 'Engagement' },
    { id: 'streaks', label: 'Streaks', icon: Flame, section: 'Engagement' },
    { id: 'follows', label: 'Follow / Favorite', icon: Heart, section: 'Engagement' },
    { id: 'levels', label: 'Creator Levels', icon: Award, section: 'Engagement' },
    { id: 'training', label: 'Training Videos', icon: Video, section: 'Content' },
    { id: 'users', label: 'User Management', icon: Users, section: 'People' },
    { id: 'calls', label: 'Live Calls', icon: PhoneCall, section: 'Operations' },
    { id: 'wallet', label: 'Wallet Logs', icon: Wallet, section: 'Finance' },
    { id: 'coins', label: 'Coin Packages', icon: Coins, section: 'Finance' },
    { id: 'payments', label: 'Recharge History', icon: CreditCard, section: 'Finance' },
    { id: 'health', label: 'System Health', icon: Activity, section: 'Operations' },
    { id: 'notifications', label: 'Notifications', icon: Bell, section: 'Operations' },
    { id: 'safety', label: 'Safety', icon: ShieldAlert, badge: pendingReportsCount, section: 'Operations' },
    { id: 'settings', label: 'Settings', icon: Settings, section: 'System' },
    { id: 'admins', label: 'Admin Access', icon: Users, section: 'System' },
  ];

  const navItems = useMemo(
    () => allNavItems.filter((item) => canAccessModule(adminUser, tabToModule(item.id))),
    [adminUser, pendingListenersCount, pendingWithdrawsCount, pendingReportsCount],
  );

  const navSections = useMemo(() => {
    const sections: { title: string; items: typeof navItems }[] = [];
    for (const item of navItems) {
      const section = (item as { section?: string }).section ?? 'Other';
      let group = sections.find((s) => s.title === section);
      if (!group) {
        group = { title: section, items: [] };
        sections.push(group);
      }
      group.items.push(item);
    }
    return sections;
  }, [navItems]);

  if (!authReady) {
    return (
      <div className="flex h-screen items-center justify-center bg-zinc-950 text-sm text-zinc-400">
        Loading console…
      </div>
    );
  }

  const displayName = adminUser?.name || 'Admin';
  const displayRole = adminUser?.role?.replace(/_/g, ' ') || 'Administrator';
  const initials = displayName.split(' ').map((p) => p[0]).join('').slice(0, 2).toUpperCase();

  return (
    <div className={theme}>
      <div className="flex h-screen bg-background font-sans antialiased text-foreground transition-colors duration-200">
        
        {/* 1. STICKY SIDEBAR NAVIGATION */}
        <aside className="w-64 border-r border-border bg-card flex flex-col justify-between flex-shrink-0 transition-colors duration-200">
          <div>
            {/* Logo Header */}
            <div className="h-16 px-6 flex items-center gap-2 border-b border-border">
              <span className="p-1.5 bg-indigo-600 rounded text-white flex items-center justify-center font-bold">
                CC
              </span>
              <div className="flex flex-col">
                <span className="text-sm font-black text-foreground tracking-tight">CoinCalling</span>
                <span className="text-[10px] text-zinc-500 font-semibold tracking-wider uppercase leading-none">Console</span>
              </div>
            </div>

            {/* Navigation Links */}
            <nav className="p-4 space-y-4 overflow-y-auto max-h-[calc(100vh-8rem)]">
              {navSections.map((section) => (
                <div key={section.title}>
                  <span className="px-3 text-[9px] font-bold uppercase tracking-widest text-zinc-600">{section.title}</span>
                  <div className="mt-1 space-y-0.5">
                    {section.items.map((item) => {
                      const Icon = item.icon;
                      const isActive = activeTab === item.id;
                      return (
                        <button
                          key={item.id}
                          onClick={() => { setActiveTab(item.id); setSubTab(undefined); }}
                          className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-semibold transition-colors ${
                            isActive
                              ? 'bg-secondary text-foreground shadow-sm font-bold'
                              : 'text-muted-foreground hover:text-foreground hover:bg-secondary/40'
                          }`}
                        >
                          <div className="flex items-center gap-2.5">
                            <Icon size={16} className={isActive ? 'text-indigo-400' : 'text-zinc-500'} />
                            <span>{item.label}</span>
                          </div>
                          {'badge' in item && item.badge && item.badge > 0 ? (
                            <span className={`px-1.5 py-0.5 rounded-full text-[9px] font-bold ${
                              isActive ? 'bg-indigo-600 text-white' : 'bg-secondary text-muted-foreground'
                            }`}>
                              {item.badge}
                            </span>
                          ) : null}
                        </button>
                      );
                    })}
                  </div>
                </div>
              ))}
            </nav>
          </div>

          {/* Footer Admin info */}
          <div className="p-4 border-t border-border flex items-center justify-between gap-2">
            <div className="flex items-center gap-2.5 min-w-0">
              <div className="w-8 h-8 rounded-full bg-indigo-600 flex items-center justify-center font-bold text-white text-xs shrink-0">
                {initials}
              </div>
              <div className="min-w-0">
                <span className="text-xs font-semibold text-foreground block truncate">{displayName}</span>
                <span className="text-[10px] text-zinc-500 block capitalize truncate">{displayRole}</span>
              </div>
            </div>
            <button
              type="button"
              onClick={handleLogout}
              className="p-1.5 text-zinc-500 hover:text-foreground rounded-lg hover:bg-secondary/60"
              title="Sign out"
            >
              <LogOut size={14} />
            </button>
          </div>
        </aside>

        {/* Main Panel Wrapper */}
        <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        
        {/* 2. STICKY HEADER */}
        <header className="h-16 border-b border-border bg-card/85 backdrop-blur px-6 flex items-center justify-between flex-shrink-0 z-10 transition-colors duration-200">
          
          {/* Breadcrumb / Search bar trigger */}
          <div className="flex items-center gap-6">
            <span className="text-xs font-semibold text-muted-foreground capitalize">
              Dashboard / <span className="text-foreground font-bold">{activeTab.replace('_', ' ')}</span>
            </span>
            
            {/* Quick search input */}
            <div 
              onClick={() => setIsPaletteOpen(true)}
              className="hidden sm:flex items-center gap-2.5 pl-3 pr-2 py-1.5 bg-secondary/50 border border-border rounded-lg text-muted-foreground hover:text-foreground hover:border-muted-foreground/30 transition-all cursor-pointer text-xs select-none w-64"
            >
              <Search size={14} />
              <span>Search everywhere...</span>
              <span className="ml-auto flex items-center gap-0.5 bg-background border border-border px-1.5 py-0.5 rounded text-[10px] font-mono leading-none text-muted-foreground">
                <Command size={10} />K
              </span>
            </div>
          </div>

          {/* Quick buttons */}
          <div className="flex items-center gap-3">
            <button 
              onClick={toggleTheme}
              className="p-2 text-muted-foreground hover:text-foreground rounded-lg hover:bg-secondary/60 transition-colors"
              title={theme === 'dark' ? 'Switch to Light Mode' : 'Switch to Dark Mode'}
            >
              {theme === 'dark' ? <Sun size={15} /> : <Moon size={15} />}
            </button>
            <button 
              onClick={() => setIsPaletteOpen(true)}
              className="sm:hidden p-2 text-muted-foreground hover:text-foreground rounded-lg hover:bg-secondary"
            >
              <Search size={16} />
            </button>
            <div className="h-4 w-[1px] bg-border hidden sm:block"></div>
            <div className="text-xs text-muted-foreground hidden sm:block">
              Today: <span className="font-semibold text-foreground">{new Date().toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' })}</span>
            </div>
          </div>

        </header>

        {/* 3. MAIN CONTENTS VIEWPORT */}
        <main className="flex-1 overflow-y-auto p-6 bg-background glow-indigo transition-colors duration-200">
          <Suspense fallback={<div className="text-sm text-muted-foreground p-8">Loading module…</div>}>
            {activeTab === 'dashboard' && <DashboardView onNavigate={handleGlobalNavigate} />}
            {activeTab === 'finance' && <FinanceDashboard />}
            {activeTab === 'operations' && <OperationsCenterView />}
            {activeTab === 'creator_analytics' && <CreatorAnalyticsView />}
            {activeTab === 'withdrawals' && <WithdrawalsView />}
            {activeTab === 'gifts' && <GiftsAdminView />}
            {activeTab === 'messages' && <MessagesAnalyticsView />}
            {activeTab === 'vip' && <VipAdminView />}
            {activeTab === 'missions' && <MissionsView />}
            {activeTab === 'streaks' && <StreaksView />}
            {activeTab === 'follows' && <FollowFavoriteView />}
            {activeTab === 'levels' && <CreatorLevelsView />}
            {activeTab === 'training' && <TrainingVideosView />}
            {activeTab === 'reconciliation' && <ReconciliationView />}
            {activeTab === 'health' && <SystemHealthView />}
            {activeTab === 'users' && <UsersView embedded selectedUserId={selectedUserId} onClearSelectedUser={() => setSelectedUserId(undefined)} />}
            {activeTab === 'listeners' && <ListenersView onRefreshStats={refreshBadges} subTab={subTab} />}
            {activeTab === 'wallet' && <WalletView />}
            {activeTab === 'coins' && <CoinsView />}
            {activeTab === 'payments' && <PaymentsView />}
            {activeTab === 'calls' && <CallsView />}
            {activeTab === 'notifications' && <NotificationsView />}
            {activeTab === 'safety' && <SafetyView />}
            {activeTab === 'settings' && <SettingsView />}
            {activeTab === 'admins' && <AdminsView />}
          </Suspense>
        </main>
      </div>

      {/* 4. COMMAND PALETTE MODAL PANEL */}
      {isPaletteOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-start justify-center pt-24 px-4">
          <div className="w-full max-w-lg bg-card border border-border rounded-xl shadow-2xl overflow-hidden text-xs text-foreground">
            
            {/* Search Input bar */}
            <div className="p-3 border-b border-border flex items-center gap-2.5">
              <Search size={16} className="text-zinc-500" />
              <input
                ref={paletteInputRef}
                type="text"
                placeholder="Search matching users, hosts, pages, transactions..."
                value={paletteQuery}
                onChange={(e) => setPaletteQuery(e.target.value)}
                className="w-full bg-transparent border-none outline-none text-foreground text-xs placeholder-muted-foreground"
              />
              <button 
                onClick={() => setIsPaletteOpen(false)}
                className="p-1 hover:bg-secondary rounded text-zinc-500 hover:text-white"
              >
                <X size={14} />
              </button>
            </div>

            {/* Results body */}
            <div className="p-2 max-h-72 overflow-y-auto space-y-1.5">
              {paletteResults.length > 0 ? (
                paletteResults.map((res) => (
                  <button
                    key={res.id}
                    onClick={res.action}
                    className="w-full text-left p-2.5 rounded-lg bg-secondary/30 hover:bg-secondary border border-transparent hover:border-border text-foreground flex items-center justify-between group"
                  >
                    <div>
                      <span className="block font-semibold text-foreground group-hover:text-indigo-400">{res.title}</span>
                      <span className="text-[10px] text-muted-foreground block mt-0.5 font-medium uppercase tracking-wider">{res.category}</span>
                    </div>
                    <ArrowUpRight size={14} className="text-muted-foreground group-hover:text-indigo-400 transition-colors" />
                  </button>
                ))
              ) : paletteQuery.trim() ? (
                <div className="p-6 text-center text-zinc-500 font-medium">
                  No records matching query.
                </div>
              ) : (
                <div className="p-6 text-center text-zinc-500 leading-relaxed font-semibold">
                  Type a query to search, or try <span className="text-zinc-400">"users"</span>, <span className="text-zinc-400">"settings"</span>, or names like <span className="text-zinc-400">"Ishita"</span>.
                </div>
              )}
            </div>

            {/* Footer tips */}
            <div className="p-2 border-t border-border text-[9px] text-muted-foreground flex justify-between bg-card">
              <span>Press <kbd className="font-mono">ESC</kbd> to dismiss palette</span>
              <span>Use mouse or trackpad to select</span>
            </div>

          </div>
        </div>
      )}

      </div>
    </div>
  );
}
