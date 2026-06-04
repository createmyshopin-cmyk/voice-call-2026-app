// components/UsersView.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { 
  Search, Shield, ShieldAlert, Plus, Minus, UserMinus, 
  Trash2, Mail, Phone, Calendar, Landmark, MapPin, X, ExternalLink, Smartphone
} from 'lucide-react';
import { MockDatabase, User, Transaction } from '../lib/mockDb';

interface UsersViewProps {
  onRefreshStats?: () => void;
  selectedUserId?: string;
  onClearSelectedUser?: () => void;
}

export default function UsersView({ onRefreshStats, selectedUserId, onClearSelectedUser }: UsersViewProps) {
  const [users, setUsers] = useState<User[]>([]);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState<'all' | 'active' | 'blocked' | 'new' | 'premium'>('all');
  const [sortField, setSortField] = useState<'id' | 'coins' | 'totalCalls' | 'registeredAt'>('id');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('asc');
  
  // Pagination
  const [page, setPage] = useState(1);
  const itemsPerPage = 5;

  // Selected User for details modal
  const [activeUser, setActiveUser] = useState<User | null>(null);
  
  // Coin Adjustment Form
  const [adjustCoinsMode, setAdjustCoinsMode] = useState<'add' | 'deduct' | null>(null);
  const [coinAmount, setCoinAmount] = useState<number>(100);
  const [adjustmentReason, setAdjustmentReason] = useState('Admin Bonus');
  
  // Notification Toast State
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'info' | 'error' } | null>(null);

  const triggerToast = (message: string, type: 'success' | 'info' | 'error' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const loadData = () => {
    const allUsers = MockDatabase.getUsers();
    setUsers(allUsers);
    
    // Check if a specific user was selected via global prop (e.g. from search palette)
    if (selectedUserId) {
      const matched = allUsers.find(u => u.id === selectedUserId);
      if (matched) {
        setActiveUser(matched);
      }
      if (onClearSelectedUser) onClearSelectedUser();
    }
  };

  useEffect(() => {
    loadData();
  }, [selectedUserId]);

  // Handle global page changes when data updates
  const handleUpdate = () => {
    loadData();
    if (onRefreshStats) onRefreshStats();
  };

  // Block/Unblock Action
  const toggleBlockStatus = (user: User) => {
    const updatedUsers: User[] = users.map(u => {
      if (u.id === user.id) {
        const nextStatus: 'active' | 'blocked' = u.status === 'active' ? 'blocked' : 'active';
        triggerToast(`${user.name} is now ${nextStatus}`, nextStatus === 'active' ? 'success' : 'error');
        return { ...u, status: nextStatus };
      }
      return u;
    });
    MockDatabase.saveUsers(updatedUsers);
    
    // Update current active profile modal if open
    if (activeUser?.id === user.id) {
      setActiveUser({ ...activeUser, status: activeUser.status === 'active' ? 'blocked' : 'active' });
    }
    
    setUsers(updatedUsers);
    handleUpdate();
  };

  // Delete User Action
  const deleteUser = (userId: string, name: string) => {
    if (!window.confirm(`Are you sure you want to permanently delete user ${name}?`)) return;
    
    const updatedUsers = users.filter(u => u.id !== userId);
    MockDatabase.saveUsers(updatedUsers);
    
    if (activeUser?.id === userId) {
      setActiveUser(null);
    }
    
    triggerToast(`Deleted user ${name}`, 'error');
    setUsers(updatedUsers);
    handleUpdate();
  };

  // Add or Deduct Coins Action
  const adjustCoins = (e: React.FormEvent) => {
    e.preventDefault();
    if (!activeUser) return;
    if (coinAmount <= 0) {
      triggerToast('Amount must be positive', 'error');
      return;
    }

    const multiplier = adjustCoinsMode === 'add' ? 1 : -1;
    const finalAmount = coinAmount * multiplier;
    
    if (adjustCoinsMode === 'deduct' && activeUser.coins < coinAmount) {
      triggerToast('Insufficient coins balance', 'error');
      return;
    }

    // Save Updated user
    const updatedUsers: User[] = users.map(u => {
      if (u.id === activeUser.id) {
        const newBal = u.coins + finalAmount;
        return { 
          ...u, 
          coins: newBal,
          totalSpent: adjustCoinsMode === 'deduct' ? u.totalSpent + coinAmount : u.totalSpent
        };
      }
      return u;
    });
    MockDatabase.saveUsers(updatedUsers);

    // Save Transaction
    const allTxns = MockDatabase.getTransactions();
    const newTxn: Transaction = {
      id: `TXN${Date.now().toString().slice(-4)}`,
      userId: activeUser.id,
      userName: activeUser.name,
      type: 'admin_adjustment',
      amount: finalAmount,
      balanceAfter: activeUser.coins + finalAmount,
      date: new Date().toISOString()
    };
    MockDatabase.saveTransactions([newTxn, ...allTxns]);

    // Update state
    const match = updatedUsers.find(u => u.id === activeUser.id);
    if (match) setActiveUser(match);
    
    setUsers(updatedUsers);
    setAdjustCoinsMode(null);
    triggerToast(`Adjusted ${coinAmount} coins for ${activeUser.name}`, 'success');
    handleUpdate();
  };

  // Sorting logic
  const handleSort = (field: typeof sortField) => {
    if (sortField === field) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortOrder('asc');
    }
  };

  // Filters & Search
  const filteredUsers = users
    .filter(u => {
      const matchSearch = 
        u.name.toLowerCase().includes(search.toLowerCase()) ||
        u.email.toLowerCase().includes(search.toLowerCase()) ||
        u.phone.includes(search) ||
        u.id.toLowerCase().includes(search.toLowerCase());
      
      if (filter === 'active') return matchSearch && u.status === 'active';
      if (filter === 'blocked') return matchSearch && u.status === 'blocked';
      if (filter === 'new') {
        const joinDate = new Date(u.registeredAt);
        const threshold = new Date();
        threshold.setDate(threshold.getDate() - 14); // registered in last 14 days
        return matchSearch && joinDate >= threshold;
      }
      if (filter === 'premium') return matchSearch && u.coins >= 1000;
      
      return matchSearch;
    })
    .sort((a, b) => {
      let valA = a[sortField];
      let valB = b[sortField];

      if (typeof valA === 'string') {
        return sortOrder === 'asc' 
          ? (valA as string).localeCompare(valB as string) 
          : (valB as string).localeCompare(valA as string);
      }
      return sortOrder === 'asc'
        ? (valA as number) - (valB as number)
        : (valB as number) - (valA as number);
    });

  // Paginated chunk
  const totalPages = Math.ceil(filteredUsers.length / itemsPerPage);
  const displayedUsers = filteredUsers.slice((page - 1) * itemsPerPage, page * itemsPerPage);

  return (
    <div className="space-y-6 relative">
      {/* Toast Notification */}
      {toast && (
        <div className={`fixed top-4 right-4 z-50 flex items-center gap-2 px-4 py-3 rounded-lg border shadow-lg transition-all duration-300 ${
          toast.type === 'success' ? 'bg-emerald-950/90 border-emerald-500/50 text-emerald-300' :
          toast.type === 'error' ? 'bg-red-950/90 border-red-500/50 text-red-300' :
          'bg-zinc-900 border-zinc-800 text-zinc-300'
        }`}>
          <span>{toast.message}</span>
        </div>
      )}

      {/* Title */}
      <div className="flex flex-col sm:flex-row justify-between sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-white sm:text-3xl">Users Directory</h1>
          <p className="text-sm text-zinc-400">View profiles, adjust coin balances, and manage access rights.</p>
        </div>
      </div>

      {/* Filters toolbar */}
      <div className="glass-panel p-4 rounded-xl flex flex-col md:flex-row md:items-center justify-between gap-4">
        
        {/* Search */}
        <div className="relative flex-1 max-w-sm">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-500" />
          <input
            type="text"
            placeholder="Search by ID, Name, Phone, Email..."
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1); }}
            className="w-full pl-9 pr-4 py-2 text-xs bg-zinc-900 border border-zinc-800 rounded-lg text-white focus:outline-none focus:border-indigo-500"
          />
        </div>

        {/* Tab filters */}
        <div className="flex flex-wrap items-center gap-2">
          {(['all', 'active', 'blocked', 'new', 'premium'] as const).map((t) => (
            <button
              key={t}
              onClick={() => { setFilter(t); setPage(1); }}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold capitalize transition-colors ${
                filter === t 
                  ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/10' 
                  : 'bg-zinc-900 text-zinc-400 hover:text-zinc-200 border border-zinc-800/80'
              }`}
            >
              {t} Users
            </button>
          ))}
        </div>

      </div>

      {/* Users Data Table */}
      <div className="glass-panel rounded-2xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="border-b border-zinc-800 text-zinc-400 bg-zinc-900/30">
                <th className="p-4 font-semibold">User Details</th>
                <th className="p-4 font-semibold cursor-pointer select-none" onClick={() => handleSort('id')}>
                  User ID {sortField === 'id' && (sortOrder === 'asc' ? '▲' : '▼')}
                </th>
                <th className="p-4 font-semibold">Phone / Email</th>
                <th className="p-4 font-semibold cursor-pointer select-none text-right" onClick={() => handleSort('coins')}>
                  Coin Balance {sortField === 'coins' && (sortOrder === 'asc' ? '▲' : '▼')}
                </th>
                <th className="p-4 font-semibold cursor-pointer select-none text-right" onClick={() => handleSort('totalCalls')}>
                  Total Calls {sortField === 'totalCalls' && (sortOrder === 'asc' ? '▲' : '▼')}
                </th>
                <th className="p-4 font-semibold">Status</th>
                <th className="p-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-900">
              {displayedUsers.length > 0 ? (
                displayedUsers.map((user) => (
                  <tr key={user.id} className="hover:bg-zinc-900/30 text-zinc-300 transition-colors">
                    <td className="p-4">
                      <div className="flex items-center gap-3">
                        <img 
                          src={user.image} 
                          alt={user.name} 
                          className="w-8 h-8 rounded-full object-cover border border-zinc-800"
                        />
                        <div>
                          <span className="font-semibold text-white hover:text-indigo-400 cursor-pointer" onClick={() => setActiveUser(user)}>
                            {user.name}
                          </span>
                          <span className="block text-[10px] text-zinc-500 mt-0.5">Joined {new Date(user.registeredAt).toLocaleDateString()}</span>
                        </div>
                      </div>
                    </td>
                    <td className="p-4 font-mono font-medium text-zinc-400">{user.id}</td>
                    <td className="p-4">
                      <span className="block font-medium">{user.phone}</span>
                      <span className="block text-[10px] text-zinc-500 mt-0.5">{user.email}</span>
                    </td>
                    <td className="p-4 text-right font-semibold text-amber-400">
                      {user.coins.toLocaleString()}
                    </td>
                    <td className="p-4 text-right font-medium text-zinc-400">{user.totalCalls}</td>
                    <td className="p-4">
                      <span className={`inline-flex items-center px-2 py-0.5 rounded text-[10px] font-bold ${
                        user.status === 'active' 
                          ? 'bg-emerald-500/10 text-emerald-400' 
                          : 'bg-red-500/10 text-red-400'
                      }`}>
                        {user.status === 'active' ? 'Active' : 'Blocked'}
                      </span>
                    </td>
                    <td className="p-4 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => setActiveUser(user)}
                          className="px-2 py-1 bg-zinc-900 border border-zinc-800 text-zinc-400 rounded-md hover:bg-zinc-800 hover:text-white transition-colors"
                        >
                          View
                        </button>
                        <button
                          onClick={() => toggleBlockStatus(user)}
                          title={user.status === 'active' ? 'Block User' : 'Unblock User'}
                          className={`p-1.5 rounded-md border transition-colors ${
                            user.status === 'active'
                              ? 'bg-red-950/20 border-red-900/30 text-red-400 hover:bg-red-900/30'
                              : 'bg-emerald-950/20 border-emerald-900/30 text-emerald-400 hover:bg-emerald-900/30'
                          }`}
                        >
                          {user.status === 'active' ? <ShieldAlert size={14} /> : <Shield size={14} />}
                        </button>
                        <button
                          onClick={() => deleteUser(user.id, user.name)}
                          title="Delete User"
                          className="p-1.5 bg-zinc-900 border border-zinc-800 text-zinc-500 rounded-md hover:bg-red-900/20 hover:text-red-400 hover:border-red-900/30 transition-colors"
                        >
                          <Trash2 size={14} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={7} className="p-8 text-center text-zinc-500">
                    No users matching criteria.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination controls */}
        {totalPages > 1 && (
          <div className="border-t border-zinc-800 p-4 flex items-center justify-between">
            <span className="text-zinc-500">
              Showing {(page - 1) * itemsPerPage + 1} to {Math.min(page * itemsPerPage, filteredUsers.length)} of {filteredUsers.length}
            </span>
            <div className="flex items-center gap-1">
              <button
                disabled={page === 1}
                onClick={() => setPage(p => Math.max(1, p - 1))}
                className="px-3 py-1 bg-zinc-900 border border-zinc-800 rounded text-zinc-400 hover:bg-zinc-800 hover:text-white transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
              >
                Previous
              </button>
              {Array.from({ length: totalPages }, (_, i) => i + 1).map((p) => (
                <button
                  key={p}
                  onClick={() => setPage(p)}
                  className={`px-3 py-1 rounded text-xs font-semibold ${
                    page === p 
                      ? 'bg-indigo-600 text-white' 
                      : 'bg-zinc-900 text-zinc-400 hover:text-zinc-200 border border-zinc-800'
                  }`}
                >
                  {p}
                </button>
              ))}
              <button
                disabled={page === totalPages}
                onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                className="px-3 py-1 bg-zinc-900 border border-zinc-800 rounded text-zinc-400 hover:bg-zinc-800 hover:text-white transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
              >
                Next
              </button>
            </div>
          </div>
        )}
      </div>

      {/* User Profile Modal Drawer */}
      {activeUser && (
        <div className="fixed inset-0 z-40 bg-black/60 backdrop-blur-sm flex items-center justify-end">
          <div className="w-full max-w-lg h-full bg-zinc-950 border-l border-zinc-800 p-6 overflow-y-auto flex flex-col justify-between">
            
            {/* Header info */}
            <div>
              <div className="flex items-center justify-between pb-4 border-b border-zinc-900">
                <div className="flex items-center gap-3">
                  <span className="text-zinc-500 font-mono text-[10px] tracking-widest">{activeUser.id}</span>
                  <span className={`px-1.5 py-0.5 rounded text-[8px] font-extrabold capitalize ${
                    activeUser.status === 'active' ? 'bg-emerald-500/10 text-emerald-400' : 'bg-red-500/10 text-red-400'
                  }`}>
                    {activeUser.status}
                  </span>
                </div>
                <button 
                  onClick={() => { setActiveUser(null); setAdjustCoinsMode(null); }}
                  className="p-1 text-zinc-500 hover:text-white rounded hover:bg-zinc-900 transition-colors"
                >
                  <X size={16} />
                </button>
              </div>

              {/* Avatar & Hero */}
              <div className="mt-6 flex flex-col items-center text-center">
                <img 
                  src={activeUser.image} 
                  alt={activeUser.name} 
                  className="w-20 h-20 rounded-full object-cover border-2 border-indigo-500/30"
                />
                <h2 className="mt-3 text-lg font-bold text-white tracking-tight">{activeUser.name}</h2>
                <span className="text-xs text-zinc-500 flex items-center gap-1 mt-1">
                  <MapPin size={12} /> {activeUser.country}
                </span>
              </div>

              {/* Interactive Wallet Balance & Actions */}
              <div className="mt-6 p-4 rounded-xl bg-zinc-900/40 border border-zinc-900 flex items-center justify-between">
                <div>
                  <span className="text-[10px] text-zinc-500 font-medium">Coin Balance</span>
                  <div className="text-xl font-bold text-amber-400 mt-0.5">{activeUser.coins} <span className="text-xs text-zinc-400 font-normal">coins</span></div>
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => setAdjustCoinsMode('add')}
                    className="flex items-center gap-1 px-2.5 py-1 bg-indigo-500/10 hover:bg-indigo-500/20 border border-indigo-500/20 text-indigo-400 rounded-lg text-xs font-semibold transition-colors"
                  >
                    <Plus size={12} /> Add Coins
                  </button>
                  <button
                    onClick={() => setAdjustCoinsMode('deduct')}
                    className="flex items-center gap-1 px-2.5 py-1 bg-amber-500/10 hover:bg-amber-500/20 border border-amber-500/20 text-amber-400 rounded-lg text-xs font-semibold transition-colors"
                  >
                    <Minus size={12} /> Deduct
                  </button>
                </div>
              </div>

              {/* Coin Adjustment form */}
              {adjustCoinsMode && (
                <form onSubmit={adjustCoins} className="mt-4 p-4 rounded-xl bg-zinc-900 border border-zinc-800 space-y-3">
                  <div className="text-xs font-bold text-white capitalize flex items-center justify-between">
                    <span>{adjustCoinsMode} Coins</span>
                    <button type="button" onClick={() => setAdjustCoinsMode(null)} className="text-zinc-500 hover:text-white">✕</button>
                  </div>
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="block text-[10px] text-zinc-500 mb-1">Amount</label>
                      <input 
                        type="number"
                        min="1"
                        value={coinAmount}
                        onChange={(e) => setCoinAmount(parseInt(e.target.value) || 0)}
                        className="w-full bg-zinc-950 border border-zinc-800 rounded px-2.5 py-1.5 text-xs text-white"
                        required
                      />
                    </div>
                    <div>
                      <label className="block text-[10px] text-zinc-500 mb-1">Reason</label>
                      <input 
                        type="text"
                        value={adjustmentReason}
                        onChange={(e) => setAdjustmentReason(e.target.value)}
                        className="w-full bg-zinc-950 border border-zinc-800 rounded px-2.5 py-1.5 text-xs text-white"
                        required
                      />
                    </div>
                  </div>
                  <button
                    type="submit"
                    className="w-full py-1.5 bg-indigo-600 hover:bg-indigo-500 text-white rounded text-xs font-semibold capitalize transition-colors"
                  >
                    Confirm {adjustCoinsMode}
                  </button>
                </form>
              )}

              {/* Personal Details */}
              <div className="mt-6 space-y-4">
                <h3 className="text-xs font-bold text-white border-b border-zinc-900 pb-2">Information Metrics</h3>
                
                <div className="grid grid-cols-2 gap-4">
                  <div className="flex items-start gap-2">
                    <Mail size={14} className="text-zinc-500 mt-0.5" />
                    <div>
                      <span className="block text-[10px] text-zinc-500 leading-none">Email</span>
                      <span className="text-xs text-zinc-300 font-medium block mt-1">{activeUser.email}</span>
                    </div>
                  </div>
                  <div className="flex items-start gap-2">
                    <Phone size={14} className="text-zinc-500 mt-0.5" />
                    <div>
                      <span className="block text-[10px] text-zinc-500 leading-none">Phone</span>
                      <span className="text-xs text-zinc-300 font-medium block mt-1">{activeUser.phone}</span>
                    </div>
                  </div>
                  <div className="flex items-start gap-2">
                    <Smartphone size={14} className="text-zinc-500 mt-0.5" />
                    <div>
                      <span className="block text-[10px] text-zinc-500 leading-none">Device</span>
                      <span className="text-xs text-zinc-300 font-medium block mt-1">{activeUser.device}</span>
                    </div>
                  </div>
                  <div className="flex items-start gap-2">
                    <Calendar size={14} className="text-zinc-500 mt-0.5" />
                    <div>
                      <span className="block text-[10px] text-zinc-500 leading-none">Registered</span>
                      <span className="text-xs text-zinc-300 font-medium block mt-1">{new Date(activeUser.registeredAt).toLocaleDateString()}</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Stats Metrics Grid */}
              <div className="mt-6 space-y-4">
                <h3 className="text-xs font-bold text-white border-b border-zinc-900 pb-2">Platform Metrics</h3>
                <div className="grid grid-cols-3 gap-2 text-center">
                  <div className="bg-zinc-900/30 border border-zinc-900 p-2.5 rounded-lg">
                    <span className="block text-[9px] text-zinc-500">Recharge</span>
                    <span className="text-sm font-bold text-emerald-400 block mt-1">₹{activeUser.totalRecharge}</span>
                  </div>
                  <div className="bg-zinc-900/30 border border-zinc-900 p-2.5 rounded-lg">
                    <span className="block text-[9px] text-zinc-500">Spent Coins</span>
                    <span className="text-sm font-bold text-zinc-300 block mt-1">{activeUser.totalSpent}</span>
                  </div>
                  <div className="bg-zinc-900/30 border border-zinc-900 p-2.5 rounded-lg">
                    <span className="block text-[9px] text-zinc-500">Call Minutes</span>
                    <span className="text-sm font-bold text-indigo-400 block mt-1">{activeUser.totalDuration}m</span>
                  </div>
                </div>
              </div>

              {/* Safety section */}
              <div className="mt-6 space-y-4">
                <h3 className="text-xs font-bold text-white border-b border-zinc-900 pb-2">Safety Profile</h3>
                <div className="grid grid-cols-2 gap-2">
                  <div className="bg-zinc-900/30 border border-zinc-900 p-2.5 rounded-lg flex items-center justify-between">
                    <div>
                      <span className="block text-[9px] text-zinc-500">Safety Score</span>
                      <span className={`text-sm font-bold block mt-1 ${
                        activeUser.safetyScore >= 80 ? 'text-emerald-400' :
                        activeUser.safetyScore >= 50 ? 'text-amber-400' : 'text-red-400'
                      }`}>{activeUser.safetyScore}%</span>
                    </div>
                  </div>
                  <div className="bg-zinc-900/30 border border-zinc-900 p-2.5 rounded-lg">
                    <span className="block text-[9px] text-zinc-500">Reports Received</span>
                    <span className="text-sm font-bold text-rose-400 block mt-1">{activeUser.reportsCount}</span>
                  </div>
                </div>
              </div>

            </div>

            {/* Block / Delete Actions in footer */}
            <div className="mt-8 border-t border-zinc-900 pt-4 flex gap-2">
              <button
                type="button"
                onClick={() => toggleBlockStatus(activeUser)}
                className={`flex-1 py-2 rounded-lg text-xs font-semibold transition-colors border ${
                  activeUser.status === 'active'
                    ? 'bg-red-950/20 border-red-500/20 text-red-400 hover:bg-red-900/20'
                    : 'bg-emerald-950/20 border-emerald-500/20 text-emerald-400 hover:bg-emerald-500/20'
                }`}
              >
                {activeUser.status === 'active' ? 'Block Access' : 'Unblock Account'}
              </button>
              <button
                type="button"
                onClick={() => deleteUser(activeUser.id, activeUser.name)}
                className="px-3 bg-zinc-900 hover:bg-red-950/20 hover:text-red-400 border border-zinc-800 hover:border-red-950/40 text-zinc-500 rounded-lg transition-colors"
                title="Delete Account"
              >
                <Trash2 size={16} />
              </button>
            </div>

          </div>
        </div>
      )}

    </div>
  );
}
