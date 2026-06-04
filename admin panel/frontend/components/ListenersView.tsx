// components/ListenersView.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { 
  Search, Check, X, ShieldAlert, Sparkles, PhoneCall, Star, 
  TrendingUp, Award, DollarSign, Wallet, ArrowUpRight, Ban, UserCheck, Play
} from 'lucide-react';
import { MockDatabase, Listener, WithdrawRequest } from '../lib/mockDb';
import { API_BASE, getHeaders } from '../lib/api';

interface ListenersViewProps {
  onRefreshStats?: () => void;
  subTab?: 'active' | 'pending' | 'suspended' | 'withdrawals' | 'performance';
}

export default function ListenersView({ onRefreshStats, subTab = 'active' }: ListenersViewProps) {
  const [listeners, setListeners] = useState<Listener[]>([]);
  const [withdraws, setWithdraws] = useState<WithdrawRequest[]>([]);
  const [activeSubTab, setActiveSubTab] = useState<string>(subTab);
  const [search, setSearch] = useState('');
  
  // Selected Listener Modal
  const [selectedListener, setSelectedListener] = useState<Listener | null>(null);

  // Toast notification
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' | 'info' } | null>(null);

  const triggerToast = (message: string, type: 'success' | 'error' | 'info' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  useEffect(() => {
    setActiveSubTab(subTab);
  }, [subTab]);

  const [isLive, setIsLive] = useState(false);

  const loadData = async () => {
    try {
      const activeRes = await fetch(`${API_BASE}/creators/active`, { headers: getHeaders() });
      const pendingRes = await fetch(`${API_BASE}/creators/pending`, { headers: getHeaders() });
      const suspendedRes = await fetch(`${API_BASE}/creators/suspended`, { headers: getHeaders() });
      const withdrawsRes = await fetch(`${API_BASE}/admin/withdrawals`, { headers: getHeaders() });

      if (activeRes.ok && pendingRes.ok && suspendedRes.ok && withdrawsRes.ok) {
        const activeData = await activeRes.json();
        const pendingData = await pendingRes.json();
        const suspendedData = await suspendedRes.json();
        const withdrawsData = await withdrawsRes.json();

        const combinedCreators = [
          ...activeData.map((c: any) => ({ ...c, status: 'active' })),
          ...pendingData.map((c: any) => ({ ...c, status: 'pending' })),
          ...suspendedData.map((c: any) => ({ ...c, status: 'suspended' }))
        ].map((c: any) => ({
          id: c.id,
          name: c.name || c.user?.name || 'Unknown Host',
          image: c.profile_image || c.user?.profile_image || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
          phone: c.phone || c.user?.phone || 'N/A',
          email: c.email || c.user?.email || 'N/A',
          bio: c.bio || '',
          languages: Array.isArray(c.languages)
            ? c.languages
            : typeof c.languages === 'string' && c.languages
              ? c.languages.split(',').map((l: string) => l.trim())
              : ['English'],
          gender: c.gender || c.user?.gender || 'Female',
          experience: c.experience || '1 Year',
          status: c.status,
          rating: Number(c.rating || 0),
          completedCalls: Number(c.total_calls || 0),
          revenueGenerated: Number(c.total_earnings || 0),
          commissionRate: 60,
          joinDate: c.created_at?.split('T')[0] || new Date().toISOString().split('T')[0],
          acceptanceRate: 100,
          missedCallRate: 0,
          earningsToday: 0,
          earningsWeek: 0,
          earningsMonth: 0,
          earningsLifetime: Number(c.total_earnings || 0)
        }));

        setListeners(combinedCreators);
        setWithdraws(withdrawsData.map((w: any) => ({
          id: w.id,
          listenerId: w.creator_id,
          listenerName: w.creator_name || 'Host',
          amount: w.amount,
          upiId: w.upi_id || 'N/A',
          bankDetails: {
            bankName: w.bank_name || 'N/A',
            accountNo: w.account_number || 'N/A',
            ifsc: w.ifsc_code || 'N/A',
            holderName: w.account_name || 'N/A'
          },
          requestDate: w.created_at || new Date().toISOString(),
          status: w.status || 'pending',
          adminNote: w.admin_note
        })));
        setIsLive(true);
        return;
      }
    } catch (e) {
      console.warn('ListenersView failed to load live API data, falling back to mockDb:', e);
    }

    setListeners([]);
    setWithdraws([]);
    setIsLive(false);
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleUpdate = () => {
    loadData();
    if (onRefreshStats) onRefreshStats();
  };

  // 1. Approve Listener Action
  const approveListener = async (listener: Listener) => {
    try {
      const res = await fetch(`${API_BASE}/creators/${listener.id}/approve`, {
        method: 'POST',
        headers: getHeaders()
      });
      if (res.ok) {
        triggerToast(`${listener.name} approved successfully!`, 'success');
        loadData();
        if (onRefreshStats) onRefreshStats();
        return;
      }
    } catch (e) {
      console.warn('Failed to approve listener on API:', e);
    }

    const updated = listeners.map(l => {
      if (l.id === listener.id) {
        triggerToast(`${listener.name} approved successfully! (Sandbox)`, 'success');
        return { ...l, status: 'active' as const, joinDate: new Date().toISOString().split('T')[0] };
      }
      return l;
    });
    MockDatabase.saveListeners(updated);
    setListeners(updated);
    handleUpdate();
  };

  // 2. Reject/Request Changes Action
  const rejectListener = async (listener: Listener) => {
    if (!window.confirm(`Reject application for ${listener.name}?`)) return;
    try {
      const res = await fetch(`${API_BASE}/creators/${listener.id}/reject`, {
        method: 'POST',
        headers: getHeaders()
      });
      if (res.ok) {
        triggerToast(`Application rejected for ${listener.name}`, 'error');
        loadData();
        if (onRefreshStats) onRefreshStats();
        return;
      }
    } catch (e) {
      console.warn('Failed to reject listener on API:', e);
    }

    const updated = listeners.filter(l => l.id !== listener.id);
    MockDatabase.saveListeners(updated);
    setListeners(updated);
    triggerToast(`Application rejected for ${listener.name} (Sandbox)`, 'error');
    handleUpdate();
  };

  // 3. Suspend Listener Action
  const suspendListener = async (listener: Listener) => {
    const nextStatus = listener.status === 'suspended' ? 'active' : 'suspended';
    try {
      const res = await fetch(`${API_BASE}/creators/${listener.id}/suspend`, {
        method: 'POST',
        headers: getHeaders()
      });
      if (res.ok) {
        triggerToast(`${listener.name} is now ${nextStatus}`, nextStatus === 'active' ? 'success' : 'error');
        if (selectedListener?.id === listener.id) {
          setSelectedListener({ ...selectedListener, status: nextStatus as any });
        }
        loadData();
        if (onRefreshStats) onRefreshStats();
        return;
      }
    } catch (e) {
      console.warn('Failed to suspend listener on API:', e);
    }

    const updated = listeners.map(l => {
      if (l.id === listener.id) {
        triggerToast(`${listener.name} is now ${nextStatus} (Sandbox)`, nextStatus === 'active' ? 'success' : 'error');
        return { ...l, status: nextStatus as any };
      }
      return l;
    });
    MockDatabase.saveListeners(updated);
    setListeners(updated);
    
    if (selectedListener?.id === listener.id) {
      setSelectedListener({ ...selectedListener, status: nextStatus as any });
    }
    
    handleUpdate();
  };

  // 4. Verification Toggle (Badge)
  const toggleVerification = (listener: Listener) => {
    triggerToast(`Toggled verification badge for ${listener.name}`, 'info');
  };

  // 5. Withdrawal status updater
  const handleWithdrawal = async (reqId: string, action: 'approve' | 'pay' | 'reject') => {
    let reason = '';
    let refNum = '';
    let notes = '';

    if (action === 'reject') {
      const promptReason = window.prompt('Enter rejection reason:');
      if (promptReason === null) return;
      reason = promptReason || 'Rejected by admin';
    } else if (action === 'pay') {
      const promptRef = window.prompt('Enter payment reference/transaction number:');
      if (promptRef === null) return;
      refNum = promptRef || `TXN${Date.now().toString().slice(-6)}`;
      notes = window.prompt('Enter admin notes (optional):') || 'Processed by admin';
    }

    try {
      let endpoint = `${API_BASE}/admin/withdrawals/${reqId}/approve`;
      let body: any = undefined;
      
      if (action === 'reject') {
        endpoint = `${API_BASE}/admin/withdrawals/${reqId}/reject`;
        body = JSON.stringify({ reason });
      } else if (action === 'pay') {
        endpoint = `${API_BASE}/admin/withdrawals/${reqId}/mark-paid`;
        body = JSON.stringify({ referenceNumber: refNum, notes });
      }

      const res = await fetch(endpoint, {
        method: 'POST',
        headers: getHeaders(),
        body
      });

      if (res.ok) {
        triggerToast(`Payout request marked successfully`, 'success');
        loadData();
        if (onRefreshStats) onRefreshStats();
        return;
      }
    } catch (e) {
      console.warn('Failed to update withdrawal status on API:', e);
    }

    const updatedReqs = withdraws.map(w => {
      if (w.id === reqId) {
        let nextStatus: WithdrawRequest['status'] = 'pending';
        let updatedW = { ...w };

        if (action === 'approve') {
          nextStatus = 'approved';
          updatedW.status = nextStatus;
        } else if (action === 'pay') {
          nextStatus = 'paid';
          updatedW.status = nextStatus;
          updatedW.adminNote = notes;
          const allListeners = MockDatabase.getListeners();
          const targetListener = allListeners.find(l => l.name === w.listenerName);
          if (targetListener) {
            targetListener.revenueGenerated = Math.max(0, targetListener.revenueGenerated - w.amount);
            targetListener.earningsLifetime = Math.max(0, targetListener.earningsLifetime - w.amount);
            MockDatabase.saveListeners(allListeners);
            setListeners(allListeners);
          }
        } else if (action === 'reject') {
          nextStatus = 'rejected';
          updatedW.status = nextStatus;
          updatedW.adminNote = reason;
        }
        
        triggerToast(`Payout request ${reqId} marked as ${nextStatus} (Sandbox)`, action === 'reject' ? 'error' : 'success');
        return updatedW;
      }
      return w;
    });
    MockDatabase.saveWithdrawRequests(updatedReqs);
    setWithdraws(updatedReqs);
    handleUpdate();
  };

  // Search filter
  const filteredListeners = listeners.filter(l => {
    const matchesSearch = l.name.toLowerCase().includes(search.toLowerCase()) || 
                          l.phone.includes(search) || 
                          l.id.toLowerCase().includes(search.toLowerCase());
    
    if (activeSubTab === 'active') return matchesSearch && l.status === 'active';
    if (activeSubTab === 'pending') return matchesSearch && l.status === 'pending';
    if (activeSubTab === 'suspended') return matchesSearch && l.status === 'suspended';
    return matchesSearch; // for performance/earnings sub-tabs, show all
  });

  return (
    <div className="space-y-6">
      {/* Toast */}
      {toast && (
        <div className={`fixed top-4 right-4 z-50 flex items-center gap-2 px-4 py-3 rounded-lg border shadow-lg transition-all duration-300 ${
          toast.type === 'success' ? 'bg-emerald-950/90 border-emerald-500/50 text-emerald-300' :
          toast.type === 'error' ? 'bg-red-950/90 border-red-500/50 text-red-300' :
          'bg-zinc-900 border-zinc-800 text-zinc-300'
        }`}>
          <span>{toast.message}</span>
        </div>
      )}

      {/* Header & Internal Nav */}
      <div className="flex flex-col gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-white sm:text-3xl">Listeners Management</h1>
          <p className="text-sm text-zinc-400">Review onboarding profiles, audit ratings, and process payouts.</p>
        </div>

        {/* Sub-tabs bar */}
        <div className="flex flex-wrap border-b border-zinc-800 gap-1 text-xs">
          {[
            { id: 'active', label: 'Active Listeners' },
            { id: 'pending', label: 'Pending Approval' },
            { id: 'suspended', label: 'Suspended' },
            { id: 'withdrawals', label: 'Withdrawal Requests' },
            { id: 'performance', label: 'Performance Analytics' }
          ].map(tab => (
            <button
              key={tab.id}
              onClick={() => { setActiveSubTab(tab.id); setSearch(''); }}
              className={`px-4 py-2 font-semibold border-b-2 transition-all ${
                activeSubTab === tab.id 
                  ? 'border-indigo-500 text-white bg-indigo-500/5' 
                  : 'border-transparent text-zinc-400 hover:text-zinc-200'
              }`}
            >
              {tab.label}
              {tab.id === 'pending' && listeners.filter(l => l.status === 'pending').length > 0 && (
                <span className="ml-2 px-1.5 py-0.5 bg-indigo-500 text-white rounded-full text-[9px]">
                  {listeners.filter(l => l.status === 'pending').length}
                </span>
              )}
              {tab.id === 'withdrawals' && withdraws.filter(w => w.status === 'pending').length > 0 && (
                <span className="ml-2 px-1.5 py-0.5 bg-amber-500 text-black rounded-full text-[9px] font-bold">
                  {withdraws.filter(w => w.status === 'pending').length}
                </span>
              )}
            </button>
          ))}
        </div>
      </div>

      {/* Sub-tab view contents */}
      
      {/* 1. Active Listeners */}
      {activeSubTab === 'active' && (
        <div className="space-y-6">
          <div className="flex justify-between items-center max-w-sm">
            <div className="relative w-full">
              <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-500" />
              <input
                type="text"
                placeholder="Search hosts..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full pl-9 pr-4 py-2 text-xs bg-zinc-900 border border-zinc-800 rounded-lg text-white focus:outline-none focus:border-indigo-500"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredListeners.map(host => (
              <div key={host.id} className="glass-card rounded-xl p-5 border border-zinc-900 hover:border-zinc-800 flex flex-col justify-between">
                <div>
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-3">
                      <img src={host.image} alt={host.name} className="w-12 h-12 rounded-full object-cover border border-zinc-800" />
                      <div>
                        <h3 className="text-sm font-semibold text-white hover:text-indigo-400 cursor-pointer" onClick={() => setSelectedListener(host)}>
                          {host.name}
                        </h3>
                        <p className="text-[10px] text-zinc-500 mt-0.5 font-mono">{host.id}</p>
                      </div>
                    </div>
                    <span className="inline-flex items-center px-1.5 py-0.5 bg-emerald-500/10 text-emerald-400 rounded text-[8px] font-extrabold">
                      Online
                    </span>
                  </div>
                  
                  <p className="mt-3 text-xs text-zinc-400 line-clamp-2 italic">"{host.bio}"</p>
                  
                  <div className="mt-3 flex flex-wrap gap-1">
                    {host.languages.map(lang => (
                      <span key={lang} className="px-1.5 py-0.5 bg-zinc-900 border border-zinc-800 rounded text-[9px] text-zinc-400">
                        {lang}
                      </span>
                    ))}
                  </div>

                  <div className="mt-4 grid grid-cols-3 gap-2 border-t border-zinc-900 pt-3 text-center text-[10px]">
                    <div>
                      <span className="block text-zinc-500">Rating</span>
                      <span className="text-white font-semibold flex items-center justify-center gap-0.5 mt-0.5">
                        ★ {host.rating.toFixed(1)}
                      </span>
                    </div>
                    <div>
                      <span className="block text-zinc-500">Calls Done</span>
                      <span className="text-white font-semibold mt-0.5 block">{host.completedCalls}</span>
                    </div>
                    <div>
                      <span className="block text-zinc-500">Earnings</span>
                      <span className="text-emerald-400 font-semibold mt-0.5 block">₹{host.earningsLifetime}</span>
                    </div>
                  </div>
                </div>

                <div className="mt-4 flex gap-2 border-t border-zinc-900 pt-3">
                  <button
                    onClick={() => setSelectedListener(host)}
                    className="flex-1 py-1 bg-zinc-900 border border-zinc-800 hover:bg-zinc-800 text-zinc-300 rounded text-[11px] font-semibold transition-colors"
                  >
                    View details
                  </button>
                  <button
                    onClick={() => suspendListener(host)}
                    className="px-2 py-1 bg-red-950/20 hover:bg-red-900/20 text-red-400 border border-red-900/30 rounded text-[11px] font-semibold transition-colors"
                    title="Suspend Host"
                  >
                    <Ban size={12} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* 2. Pending Approval */}
      {activeSubTab === 'pending' && (
        <div className="space-y-4">
          {filteredListeners.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {filteredListeners.map(host => (
                <div key={host.id} className="glass-panel p-5 rounded-2xl border border-zinc-900 space-y-4 flex flex-col justify-between">
                  <div className="space-y-3">
                    <div className="flex items-start gap-4">
                      <img src={host.image} alt={host.name} className="w-16 h-16 rounded-xl object-cover border border-zinc-800" />
                      <div className="space-y-1">
                        <span className="text-[10px] font-mono text-zinc-500">{host.id} • Registered {host.joinDate}</span>
                        <h3 className="text-base font-bold text-white leading-none">{host.name}</h3>
                        <p className="text-xs text-zinc-400 font-medium">{host.phone} • {host.gender}</p>
                      </div>
                    </div>

                    <div className="space-y-1 text-xs">
                      <span className="block font-semibold text-zinc-500">Bio Description:</span>
                      <p className="text-zinc-300 bg-zinc-900/40 p-2.5 rounded-lg border border-zinc-900 leading-relaxed italic">"{host.bio}"</p>
                    </div>

                    <div className="grid grid-cols-2 gap-4 text-xs">
                      <div>
                        <span className="block font-semibold text-zinc-500">Languages:</span>
                        <span className="text-zinc-300 block mt-1">{host.languages.join(', ')}</span>
                      </div>
                      <div>
                        <span className="block font-semibold text-zinc-500">Declared Experience:</span>
                        <span className="text-zinc-300 block mt-1">{host.experience}</span>
                      </div>
                    </div>
                  </div>

                  <div className="flex gap-2 border-t border-zinc-900 pt-4 mt-2">
                    <button
                      onClick={() => approveListener(host)}
                      className="flex-1 flex items-center justify-center gap-1 py-1.5 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg text-xs font-semibold transition-colors"
                    >
                      <Check size={14} /> Approve Host
                    </button>
                    <button
                      onClick={() => rejectListener(host)}
                      className="flex-1 flex items-center justify-center gap-1 py-1.5 bg-zinc-900 hover:bg-red-900/20 hover:text-red-400 border border-zinc-800 rounded-lg text-xs font-semibold transition-colors"
                    >
                      <X size={14} /> Reject Application
                    </button>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="glass-panel p-8 text-center text-zinc-500 rounded-2xl">
              No pending host applications requiring approval.
            </div>
          )}
        </div>
      )}

      {/* 3. Suspended Hosts */}
      {activeSubTab === 'suspended' && (
        <div className="glass-panel rounded-2xl overflow-hidden">
          {filteredListeners.length > 0 ? (
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse text-xs">
                <thead>
                  <tr className="border-b border-zinc-800 text-zinc-400 bg-zinc-900/30">
                    <th className="p-4 font-semibold">Listener</th>
                    <th className="p-4 font-semibold">Contact</th>
                    <th className="p-4 font-semibold text-right">Lifetime Earnings</th>
                    <th className="p-4 font-semibold">Join Date</th>
                    <th className="p-4 font-semibold text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-zinc-900">
                  {filteredListeners.map(host => (
                    <tr key={host.id} className="hover:bg-zinc-900/30 text-zinc-300">
                      <td className="p-4">
                        <div className="flex items-center gap-3">
                          <img src={host.image} alt={host.name} className="w-8 h-8 rounded-full object-cover border border-zinc-800" />
                          <div>
                            <span className="font-semibold text-white">{host.name}</span>
                            <span className="block text-[10px] text-zinc-500 mt-0.5">{host.id}</span>
                          </div>
                        </div>
                      </td>
                      <td className="p-4">
                        <span className="block">{host.phone}</span>
                        <span className="block text-[10px] text-zinc-500 mt-0.5">{host.email}</span>
                      </td>
                      <td className="p-4 text-right font-semibold text-zinc-400">₹{host.revenueGenerated}</td>
                      <td className="p-4 text-zinc-500">{host.joinDate}</td>
                      <td className="p-4 text-right">
                        <button
                          onClick={() => suspendListener(host)}
                          className="px-2 py-1 bg-emerald-950/20 border border-emerald-900/30 text-emerald-400 rounded hover:bg-emerald-900/30 transition-colors"
                        >
                          Lift Suspension
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="p-8 text-center text-zinc-500">
              No suspended listeners.
            </div>
          )}
        </div>
      )}

      {/* 4. Withdrawal Requests */}
      {activeSubTab === 'withdrawals' && (
        <div className="space-y-6">
          {/* Withdrawal KPI Cards Grid */}
          <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
            {/* Card 1: Pending */}
            <div className="glass-card p-4 rounded-xl border border-zinc-900">
              <div className="flex items-center justify-between">
                <span className="text-xs font-medium text-zinc-400">Pending Requests</span>
                <span className="p-1 bg-amber-500/10 rounded text-amber-400 text-[9px] font-bold">
                  ⌛ Pending
                </span>
              </div>
              <div className="mt-2 flex items-baseline gap-2">
                <span className="text-2xl font-bold text-white tracking-tight">
                  {withdraws.filter(w => w.status === 'pending').length}
                </span>
                <span className="text-[10px] text-zinc-500">
                  (₹{withdraws.filter(w => w.status === 'pending').reduce((sum, w) => sum + w.amount, 0)})
                </span>
              </div>
            </div>

            {/* Card 2: Approved */}
            <div className="glass-card p-4 rounded-xl border border-zinc-900">
              <div className="flex items-center justify-between">
                <span className="text-xs font-medium text-zinc-400">Approved Requests</span>
                <span className="p-1 bg-blue-500/10 rounded text-blue-400 text-[9px] font-bold">
                  ✓ Approved
                </span>
              </div>
              <div className="mt-2 flex items-baseline gap-2">
                <span className="text-2xl font-bold text-white tracking-tight">
                  {withdraws.filter(w => w.status === 'approved').length}
                </span>
                <span className="text-[10px] text-zinc-500">
                  (₹{withdraws.filter(w => w.status === 'approved').reduce((sum, w) => sum + w.amount, 0)})
                </span>
              </div>
            </div>

            {/* Card 3: Paid */}
            <div className="glass-card p-4 rounded-xl border border-zinc-900">
              <div className="flex items-center justify-between">
                <span className="text-xs font-medium text-zinc-400">Paid Requests</span>
                <span className="p-1 bg-emerald-500/10 rounded text-emerald-400 text-[9px] font-bold">
                  $ Paid
                </span>
              </div>
              <div className="mt-2 flex items-baseline gap-2">
                <span className="text-2xl font-bold text-white tracking-tight">
                  {withdraws.filter(w => w.status === 'paid').length}
                </span>
                <span className="text-[10px] text-zinc-500">
                  (₹{withdraws.filter(w => w.status === 'paid').reduce((sum, w) => sum + w.amount, 0)})
                </span>
              </div>
            </div>

            {/* Card 4: Total Payouts */}
            <div className="glass-card p-4 rounded-xl border border-zinc-900">
              <div className="flex items-center justify-between">
                <span className="text-xs font-medium text-zinc-400">Total Paid Payouts</span>
                <span className="p-1 bg-pink-500/10 rounded text-pink-400 text-[9px] font-bold">
                  Total
                </span>
              </div>
              <div className="mt-2 flex items-baseline gap-2">
                <span className="text-2xl font-bold text-emerald-400 tracking-tight">
                  ₹{withdraws.filter(w => w.status === 'paid').reduce((sum, w) => sum + w.amount, 0)}
                </span>
              </div>
            </div>
          </div>

          <div className="glass-panel rounded-2xl overflow-hidden border border-zinc-900">
            <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="border-b border-zinc-800 text-zinc-400 bg-zinc-900/30">
                  <th className="p-4 font-semibold">Listener</th>
                  <th className="p-4 font-semibold text-right">Payout Amount</th>
                  <th className="p-4 font-semibold">Payment Targets (UPI / Bank)</th>
                  <th className="p-4 font-semibold">Request Date</th>
                  <th className="p-4 font-semibold">Status</th>
                  <th className="p-4 font-semibold text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-zinc-900">
                {withdraws.map(w => (
                  <tr key={w.id} className="hover:bg-zinc-900/30 text-zinc-300">
                    <td className="p-4 font-semibold text-white">{w.listenerName}</td>
                    <td className="p-4 text-right font-bold text-emerald-400">₹{w.amount}</td>
                    <td className="p-4">
                      {w.upiId ? (
                        <span className="block font-medium">UPI: {w.upiId}</span>
                      ) : (
                        <div className="text-[10px] space-y-0.5 text-zinc-400">
                          <span className="block">Holder: {w.bankDetails.holderName}</span>
                          <span className="block">Bank: {w.bankDetails.bankName}</span>
                          <span className="block">A/C: {w.bankDetails.accountNo} ({w.bankDetails.ifsc})</span>
                        </div>
                      )}
                    </td>
                    <td className="p-4 text-zinc-500">{new Date(w.requestDate).toLocaleDateString()}</td>
                    <td className="p-4">
                      <span className={`inline-flex px-1.5 py-0.5 rounded text-[9px] font-bold capitalize ${
                        w.status === 'pending' ? 'bg-amber-500/10 text-amber-400' :
                        w.status === 'approved' ? 'bg-blue-500/10 text-blue-400' :
                        w.status === 'paid' ? 'bg-emerald-500/10 text-emerald-400' : 'bg-red-500/10 text-red-400'
                      }`}>
                        {w.status}
                      </span>
                    </td>
                    <td className="p-4 text-right">
                      <div className="flex justify-end gap-1.5">
                        {w.status === 'pending' && (
                          <>
                            <button
                              onClick={() => handleWithdrawal(w.id, 'approve')}
                              className="px-2 py-1 bg-blue-900/30 border border-blue-900/30 hover:bg-blue-900/60 text-blue-300 rounded text-[10px] font-semibold transition-colors"
                            >
                              Approve
                            </button>
                            <button
                              onClick={() => handleWithdrawal(w.id, 'reject')}
                              className="px-2 py-1 bg-zinc-900 border border-zinc-800 hover:bg-red-900/20 hover:text-red-400 text-zinc-400 rounded text-[10px] font-semibold transition-colors"
                            >
                              Reject
                            </button>
                          </>
                        )}
                        {w.status === 'approved' && (
                          <button
                            onClick={() => handleWithdrawal(w.id, 'pay')}
                            className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-500 text-white rounded text-[10px] font-semibold transition-colors"
                          >
                            Mark Paid
                          </button>
                        )}
                        {w.status === 'paid' && <span className="text-[10px] text-zinc-500 font-medium">Processed</span>}
                        {w.status === 'rejected' && <span className="text-[10px] text-zinc-500 font-medium">Cancelled</span>}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
      )}

      {/* 5. Performance Analytics */}
      {activeSubTab === 'performance' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Top Performance Ratings */}
          <div className="glass-panel p-5 rounded-2xl">
            <h2 className="text-base font-semibold text-white mb-4">Acceptance Rates</h2>
            <div className="space-y-4">
              {listeners.map(l => (
                <div key={l.id} className="space-y-1">
                  <div className="flex justify-between text-xs font-semibold text-zinc-300">
                    <span>{l.name}</span>
                    <span>{l.acceptanceRate}% Acceptance</span>
                  </div>
                  <div className="w-full bg-zinc-900 h-2 rounded-full overflow-hidden">
                    <div 
                      className={`h-full rounded-full ${
                        l.acceptanceRate >= 90 ? 'bg-emerald-500' :
                        l.acceptanceRate >= 75 ? 'bg-indigo-500' : 'bg-amber-500'
                      }`}
                      style={{ width: `${l.acceptanceRate}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Missed Call Rates */}
          <div className="glass-panel p-5 rounded-2xl">
            <h2 className="text-base font-semibold text-white mb-4">Missed Call Rates (Alert)</h2>
            <div className="space-y-4">
              {listeners.map(l => (
                <div key={l.id} className="space-y-1">
                  <div className="flex justify-between text-xs font-semibold text-zinc-300">
                    <span>{l.name}</span>
                    <span>{l.missedCallRate}% Missed</span>
                  </div>
                  <div className="w-full bg-zinc-900 h-2 rounded-full overflow-hidden">
                    <div 
                      className={`h-full rounded-full ${
                        l.missedCallRate >= 15 ? 'bg-red-500' :
                        l.missedCallRate >= 5 ? 'bg-amber-500' : 'bg-emerald-500'
                      }`}
                      style={{ width: `${l.missedCallRate}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Listener Profile Details Modal */}
      {selectedListener && (
        <div className="fixed inset-0 z-40 bg-black/60 backdrop-blur-sm flex items-center justify-end">
          <div className="w-full max-w-lg h-full bg-zinc-950 border-l border-zinc-800 p-6 overflow-y-auto flex flex-col justify-between text-xs text-zinc-300">
            <div>
              
              {/* Header */}
              <div className="flex items-center justify-between pb-4 border-b border-zinc-900">
                <div className="flex items-center gap-3">
                  <span className="text-zinc-500 font-mono text-[10px] tracking-widest">{selectedListener.id}</span>
                  <span className={`px-1.5 py-0.5 rounded text-[8px] font-extrabold capitalize ${
                    selectedListener.status === 'active' ? 'bg-emerald-500/10 text-emerald-400' : 
                    selectedListener.status === 'pending' ? 'bg-amber-500/10 text-amber-400' : 'bg-red-500/10 text-red-400'
                  }`}>
                    {selectedListener.status}
                  </span>
                </div>
                <button 
                  onClick={() => setSelectedListener(null)}
                  className="p-1 text-zinc-500 hover:text-white rounded hover:bg-zinc-900 transition-colors"
                >
                  <X size={16} />
                </button>
              </div>

              {/* Profile Details Hero */}
              <div className="mt-6 flex flex-col items-center text-center">
                <img 
                  src={selectedListener.image} 
                  alt={selectedListener.name} 
                  className="w-20 h-20 rounded-full object-cover border-2 border-indigo-500/30"
                />
                <h2 className="mt-3 text-lg font-bold text-white tracking-tight">{selectedListener.name}</h2>
                <span className="text-zinc-500 block mt-1">{selectedListener.gender} • Joined {selectedListener.joinDate}</span>
              </div>

              {/* Bio details */}
              <div className="mt-6 p-4 rounded-xl bg-zinc-900/40 border border-zinc-900 leading-relaxed italic">
                "{selectedListener.bio}"
              </div>

              {/* Technical performance details */}
              <div className="mt-6 space-y-4">
                <h3 className="font-bold text-white border-b border-zinc-900 pb-2">Engagement Metrics</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <span className="text-zinc-500">Contact Number</span>
                    <span className="block font-semibold text-white mt-1">{selectedListener.phone}</span>
                  </div>
                  <div>
                    <span className="text-zinc-500">Email Address</span>
                    <span className="block font-semibold text-white mt-1">{selectedListener.email}</span>
                  </div>
                  <div>
                    <span className="text-zinc-500">Experience Profile</span>
                    <span className="block font-semibold text-white mt-1">{selectedListener.experience}</span>
                  </div>
                  <div>
                    <span className="text-zinc-500">Spoken Languages</span>
                    <span className="block font-semibold text-white mt-1">{selectedListener.languages.join(', ')}</span>
                  </div>
                </div>
              </div>

              {/* Payout & Earnings Details */}
              <div className="mt-6 space-y-4">
                <h3 className="font-bold text-white border-b border-zinc-900 pb-2">Financial Accounting</h3>
                <div className="grid grid-cols-4 gap-2 text-center">
                  <div className="bg-zinc-900/30 p-2.5 rounded-lg border border-zinc-900">
                    <span className="text-[9px] text-zinc-500 block">Today</span>
                    <span className="text-xs font-bold text-emerald-400 mt-1 block">₹{selectedListener.earningsToday}</span>
                  </div>
                  <div className="bg-zinc-900/30 p-2.5 rounded-lg border border-zinc-900">
                    <span className="text-[9px] text-zinc-500 block">Week</span>
                    <span className="text-xs font-bold text-emerald-400 mt-1 block">₹{selectedListener.earningsWeek}</span>
                  </div>
                  <div className="bg-zinc-900/30 p-2.5 rounded-lg border border-zinc-900">
                    <span className="text-[9px] text-zinc-500 block">Month</span>
                    <span className="text-xs font-bold text-emerald-400 mt-1 block">₹{selectedListener.earningsMonth}</span>
                  </div>
                  <div className="bg-zinc-900/30 p-2.5 rounded-lg border border-zinc-900">
                    <span className="text-[9px] text-zinc-500 block">Lifetime</span>
                    <span className="text-xs font-bold text-white mt-1 block">₹{selectedListener.earningsLifetime}</span>
                  </div>
                </div>
              </div>

            </div>

            {/* Suspends toggle in footer */}
            {selectedListener.status !== 'pending' && (
              <div className="mt-8 border-t border-zinc-900 pt-4 flex gap-2">
                <button
                  type="button"
                  onClick={() => suspendListener(selectedListener)}
                  className={`w-full py-2 rounded-lg text-xs font-semibold transition-colors border ${
                    selectedListener.status === 'suspended'
                      ? 'bg-emerald-950/20 border-emerald-500/20 text-emerald-400 hover:bg-emerald-950/40'
                      : 'bg-red-950/20 border-red-500/20 text-red-400 hover:bg-red-950/40'
                  }`}
                >
                  {selectedListener.status === 'suspended' ? 'Activate Account' : 'Suspend Access'}
                </button>
              </div>
            )}

          </div>
        </div>
      )}

    </div>
  );
}
