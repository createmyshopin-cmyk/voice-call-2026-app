// components/WalletView.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { Search, Download, RefreshCw, Wallet, ArrowUpRight, ArrowDownLeft } from 'lucide-react';
import { MockDatabase, Transaction } from '../lib/mockDb';
import { API_BASE, getHeaders } from '../lib/api';

export default function WalletView() {
  const [txns, setTxns] = useState<Transaction[]>([]);
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState<string>('all');

  const [isLive, setIsLive] = useState(false);

  const loadData = async () => {
    try {
      const res = await fetch(`${API_BASE}/wallets/transactions`, { headers: getHeaders() });
      if (res.ok) {
        const data = await res.json();
        setTxns(data.map((t: any) => ({
          id: t.id,
          userId: t.userId,
          userName: t.userName || 'Unknown User',
          type: t.type || 'recharge',
          amount: t.amount,
          balanceAfter: t.balanceAfter || 0,
          date: t.date || new Date().toISOString()
        })));
        setIsLive(true);
        return;
      }
    } catch (e) {
      console.warn('WalletView failed to fetch transactions from API:', e);
    }
    setTxns([]);
    setIsLive(false);
  };

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 30000);
    return () => clearInterval(interval);
  }, []);

  const handleExportCSV = () => {
    const headers = 'Transaction ID,User,Type,Amount,Date\n';
    const rows = txns.map(t => `${t.id},${t.userName},${t.type},${t.amount},${t.date}`).join('\n');
    const blob = new Blob([headers + rows], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.setAttribute('href', url);
    a.setAttribute('download', `transactions_export_${Date.now()}.csv`);
    a.click();
  };

  const filteredTxns = txns.filter(t => {
    const matchesSearch = t.userName.toLowerCase().includes(search.toLowerCase()) || 
                          t.userId.toLowerCase().includes(search.toLowerCase()) || 
                          t.id.toLowerCase().includes(search.toLowerCase());
    const matchesType = typeFilter === 'all' || t.type === typeFilter;
    return matchesSearch && matchesType;
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-white sm:text-3xl">Wallet Transactions</h1>
          <p className="text-sm text-zinc-400">Track and review all credit, debit, and adjustment logs.</p>
        </div>
        <button
          onClick={handleExportCSV}
          className="flex items-center gap-1.5 px-4 py-2 bg-zinc-900 border border-zinc-800 hover:bg-zinc-800 hover:text-white rounded-lg text-xs font-semibold text-zinc-300 transition-colors self-start"
        >
          <Download size={14} /> Export CSV
        </button>
      </div>

      {/* Toolbar */}
      <div className="glass-panel p-4 rounded-xl flex flex-col md:flex-row md:items-center justify-between gap-4">
        
        {/* Search */}
        <div className="relative flex-1 max-w-sm">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-500" />
          <input
            type="text"
            placeholder="Search by User, Transaction ID..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 text-xs bg-zinc-900 border border-zinc-800 rounded-lg text-white focus:outline-none focus:border-indigo-500"
          />
        </div>

        {/* Type Filter */}
        <div className="flex items-center gap-2">
          <span className="text-xs text-zinc-500 font-medium">Type:</span>
          <select
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value)}
            className="bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none focus:border-indigo-500"
          >
            <option value="all">All Types</option>
            <option value="recharge">Recharge</option>
            <option value="call_deduction">Call Deduction</option>
            <option value="bonus">Bonus Coins</option>
            <option value="referral">Referral Reward</option>
            <option value="refund">Refund</option>
            <option value="admin_adjustment">Admin Adjustment</option>
          </select>
        </div>

      </div>

      {/* Transactions Table */}
      <div className="glass-panel rounded-2xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="border-b border-zinc-800 text-zinc-400 bg-zinc-900/30">
                <th className="p-4 font-semibold">Transaction ID</th>
                <th className="p-4 font-semibold">User</th>
                <th className="p-4 font-semibold">Type</th>
                <th className="p-4 font-semibold text-right">Amount</th>
                <th className="p-4 font-semibold text-right">Balance After</th>
                <th className="p-4 font-semibold text-right">Date / Time</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-900">
              {filteredTxns.length > 0 ? (
                filteredTxns.map((t) => (
                  <tr key={t.id} className="hover:bg-zinc-900/30 text-zinc-300">
                    <td className="p-4 font-mono font-medium text-zinc-400">{t.id}</td>
                    <td className="p-4">
                      <span className="font-semibold text-white">{t.userName}</span>
                      <span className="block text-[10px] text-zinc-500 mt-0.5">{t.userId}</span>
                    </td>
                    <td className="p-4 capitalize">
                      <span className={`inline-flex items-center gap-1 text-[10px] font-bold ${
                        t.type === 'recharge' ? 'text-emerald-400' :
                        t.type === 'call_deduction' ? 'text-rose-400' :
                        t.type === 'bonus' ? 'text-amber-400' :
                        'text-indigo-400'
                      }`}>
                        {t.type.replace('_', ' ')}
                      </span>
                    </td>
                    <td className={`p-4 text-right font-bold ${t.amount >= 0 ? 'text-emerald-400' : 'text-rose-400'}`}>
                      {t.amount >= 0 ? '+' : ''}{t.amount} coins
                    </td>
                    <td className="p-4 text-right font-medium text-zinc-400">{t.balanceAfter} coins</td>
                    <td className="p-4 text-right text-zinc-500">
                      {new Date(t.date).toLocaleString()}
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={6} className="p-8 text-center text-zinc-500">
                    No transactions matching filter.
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
