// components/PaymentsView.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { Search, ShieldCheck, CheckCircle2, RotateCcw, AlertTriangle } from 'lucide-react';
import { MockDatabase, Payment, User, Transaction } from '../lib/mockDb';
import { API_BASE, getHeaders } from '../lib/api';

export default function PaymentsView() {
  const [payments, setPayments] = useState<Payment[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');

  // Toast
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const triggerToast = (message: string, type: 'success' | 'error' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const [isLive, setIsLive] = useState(false);

  const loadData = async () => {
    try {
      const res = await fetch(`${API_BASE}/payments/history`, { headers: getHeaders() });
      if (res.ok) {
        const data = await res.json();
        setPayments(data.map((p: any) => ({
          id: p.id,
          userId: p.userId,
          userName: p.userName || 'User',
          amount: Number(p.amount),
          coins: Number(p.coins),
          gateway: p.gateway,
          transactionId: p.transactionId,
          status: p.status,
          date: p.date
        })));
        setIsLive(true);
        return;
      }
    } catch (e) {
      console.warn('PaymentsView failed to load payments history from API:', e);
    }
    setPayments([]);
    setUsers([]);
    setIsLive(false);
  };

  useEffect(() => {
    loadData();
  }, []);

  // 1. Verify Pending Payment
  const verifyPayment = async (payment: Payment) => {
    try {
      const res = await fetch(`${API_BASE}/payments/verify`, {
        method: 'POST',
        headers: getHeaders(),
        body: JSON.stringify({
          paymentId: payment.id,
          transactionId: `pay_${Date.now().toString().slice(-6)}`
        })
      });
      if (res.ok) {
        triggerToast(`Payment transaction verified successfully!`, 'success');
        loadData();
        return;
      }
    } catch (e) {
      console.warn('Failed to verify payment on API:', e);
    }

    const updated = payments.map(p => {
      if (p.id === payment.id) {
        triggerToast(`Payment transaction verified successfully! (Sandbox)`, 'success');
        
        const allUsers = MockDatabase.getUsers();
        const updatedUsers = allUsers.map(u => {
          if (u.id === payment.userId) {
            return {
              ...u,
              coins: u.coins + payment.coins,
              totalRecharge: u.totalRecharge + payment.amount
            };
          }
          return u;
        });
        MockDatabase.saveUsers(updatedUsers);

        const allTxns = MockDatabase.getTransactions();
        const newTxn: Transaction = {
          id: `TXN${Date.now().toString().slice(-4)}`,
          userId: payment.userId,
          userName: payment.userName,
          type: 'recharge',
          amount: payment.coins,
          balanceAfter: (updatedUsers.find(u => u.id === payment.userId)?.coins || 0),
          date: new Date().toISOString()
        };
        MockDatabase.saveTransactions([newTxn, ...allTxns]);

        return { ...p, status: 'success' as const };
      }
      return p;
    });
    MockDatabase.savePayments(updated);
    setPayments(updated);
    loadData();
  };

  // 2. Refund Coins
  const refundCoins = async (payment: Payment) => {
    if (payment.status !== 'success') {
      triggerToast('Can only refund successful recharges', 'error');
      return;
    }
    if (!window.confirm(`Refund ${payment.coins} coins to ${payment.userName}?`)) return;

    try {
      const res = await fetch(`${API_BASE}/payments/${payment.id}/refund`, {
        method: 'POST',
        headers: getHeaders(),
        body: JSON.stringify({
          reason: `Admin refund for package recharge ${payment.id}`
        })
      });
      if (res.ok) {
        triggerToast(`Refunded ${payment.coins} coins to ${payment.userName}`, 'success');
        loadData();
        return;
      }
    } catch (e) {
      console.warn('Failed to refund payment on API:', e);
    }

    const allUsers = MockDatabase.getUsers();
    const targetUser = allUsers.find(u => u.id === payment.userId);
    if (!targetUser) return;

    if (targetUser.coins < payment.coins) {
      if (!window.confirm('User balance is less than refund amount. Force negative balance?')) return;
    }

    const updatedUsers = allUsers.map(u => {
      if (u.id === payment.userId) {
        return {
          ...u,
          coins: Math.max(0, u.coins - payment.coins),
          totalRecharge: Math.max(0, u.totalRecharge - payment.amount)
        };
      }
      return u;
    });
    MockDatabase.saveUsers(updatedUsers);

    const allTxns = MockDatabase.getTransactions();
    const newTxn: Transaction = {
      id: `TXN${Date.now().toString().slice(-4)}`,
      userId: payment.userId,
      userName: payment.userName,
      type: 'refund',
      amount: -payment.coins,
      balanceAfter: (updatedUsers.find(u => u.id === payment.userId)?.coins || 0),
      date: new Date().toISOString()
    };
    MockDatabase.saveTransactions([newTxn, ...allTxns]);

    const updatedPayments = payments.map(p => {
      if (p.id === payment.id) {
        return { ...p, status: 'failed' as const };
      }
      return p;
    });
    MockDatabase.savePayments(updatedPayments);
    setPayments(updatedPayments);

    triggerToast(`Refunded ${payment.coins} coins to ${payment.userName} (Sandbox)`, 'success');
    loadData();
  };

  const filteredPayments = payments.filter(p => {
    const matchesSearch = p.userName.toLowerCase().includes(search.toLowerCase()) || 
                          p.userId.toLowerCase().includes(search.toLowerCase()) || 
                          p.transactionId.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || p.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-6 relative">
      {/* Toast */}
      {toast && (
        <div className={`fixed top-4 right-4 z-50 flex items-center gap-2 px-4 py-3 rounded-lg border shadow-lg transition-all duration-300 ${
          toast.type === 'success' ? 'bg-emerald-950/90 border-emerald-500/50 text-emerald-300' :
          'bg-red-950/90 border-red-500/50 text-red-300'
        }`}>
          <span>{toast.message}</span>
        </div>
      )}

      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-white sm:text-3xl">Recharge History</h1>
        <p className="text-sm text-zinc-400">Audit user purchase payments, track API gateways, and manage refunds.</p>
      </div>

      {/* Toolbar */}
      <div className="glass-panel p-4 rounded-xl flex flex-col md:flex-row md:items-center justify-between gap-4">
        
        {/* Search */}
        <div className="relative flex-1 max-w-sm">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-500" />
          <input
            type="text"
            placeholder="Search by User, Transaction Reference..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 text-xs bg-zinc-900 border border-zinc-800 rounded-lg text-white focus:outline-none focus:border-indigo-500"
          />
        </div>

        {/* Status Filter */}
        <div className="flex items-center gap-2">
          <span className="text-xs text-zinc-500 font-medium">Status:</span>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none focus:border-indigo-500"
          >
            <option value="all">All statuses</option>
            <option value="success">Success</option>
            <option value="pending">Pending</option>
            <option value="failed">Failed</option>
          </select>
        </div>

      </div>

      {/* Payments Table */}
      <div className="glass-panel rounded-2xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="border-b border-zinc-800 text-zinc-400 bg-zinc-900/30">
                <th className="p-4 font-semibold">User</th>
                <th className="p-4 font-semibold">Gateway / Txn ID</th>
                <th className="p-4 font-semibold text-right">Amount (₹)</th>
                <th className="p-4 font-semibold text-right">Coins Credit</th>
                <th className="p-4 font-semibold">Status</th>
                <th className="p-4 font-semibold text-right">Date</th>
                <th className="p-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-900">
              {filteredPayments.length > 0 ? (
                filteredPayments.map((p) => (
                  <tr key={p.id} className="hover:bg-zinc-900/30 text-zinc-300">
                    <td className="p-4">
                      <span className="font-semibold text-white">{p.userName}</span>
                      <span className="block text-[10px] text-zinc-500 mt-0.5">{p.userId}</span>
                    </td>
                    <td className="p-4 font-mono">
                      <span className="block font-semibold">{p.gateway}</span>
                      <span className="block text-[10px] text-zinc-500 mt-0.5">{p.transactionId}</span>
                    </td>
                    <td className="p-4 text-right font-bold text-white">₹{p.amount}</td>
                    <td className="p-4 text-right font-bold text-amber-400">+{p.coins}</td>
                    <td className="p-4">
                      <span className={`inline-flex px-1.5 py-0.5 rounded text-[9px] font-bold capitalize ${
                        p.status === 'success' ? 'bg-emerald-500/10 text-emerald-400' :
                        p.status === 'pending' ? 'bg-amber-500/10 text-amber-400' : 'bg-red-500/10 text-red-400'
                      }`}>
                        {p.status}
                      </span>
                    </td>
                    <td className="p-4 text-right text-zinc-500">{new Date(p.date).toLocaleString()}</td>
                    <td className="p-4 text-right">
                      <div className="flex justify-end gap-2">
                        {p.status === 'pending' && (
                          <button
                            onClick={() => verifyPayment(p)}
                            className="flex items-center gap-1 px-2 py-1 bg-emerald-600 hover:bg-emerald-500 text-white rounded text-[10px] font-semibold transition-colors"
                          >
                            <ShieldCheck size={12} /> Verify
                          </button>
                        )}
                        {p.status === 'success' && (
                          <button
                            onClick={() => refundCoins(p)}
                            className="flex items-center gap-1 px-2 py-1 bg-zinc-900 border border-zinc-800 hover:bg-red-950/20 hover:text-red-400 text-zinc-400 hover:border-red-950/30 rounded text-[10px] font-semibold transition-colors"
                            title="Refund coins & deduct package"
                          >
                            <RotateCcw size={12} /> Refund
                          </button>
                        )}
                        {p.status === 'failed' && (
                          <span className="text-[10px] text-zinc-500 font-semibold">Cancelled</span>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={7} className="p-8 text-center text-zinc-500">
                    No recharge payments matching filter.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
