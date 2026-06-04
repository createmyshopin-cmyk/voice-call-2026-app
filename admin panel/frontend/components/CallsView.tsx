// components/CallsView.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { Search, PhoneCall, PhoneOff, Video, VideoOff, Play, ShieldAlert } from 'lucide-react';
import { MockDatabase, Call } from '../lib/mockDb';
import { API_BASE, getHeaders } from '../lib/api';

export default function CallsView() {
  const [calls, setCalls] = useState<Call[]>([]);
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [activeTab, setActiveTab] = useState<'history' | 'active'>('active');

  // Simulated live ticking state for active calls
  const [activeCallList, setActiveCallList] = useState<Call[]>([]);

  const [isLive, setIsLive] = useState(false);

  const loadData = async () => {
    try {
      const activeRes = await fetch(`${API_BASE}/calls/active`, { headers: getHeaders() });
      const historyRes = await fetch(`${API_BASE}/calls`, { headers: getHeaders() });

      if (activeRes.ok && historyRes.ok) {
        const activeData = await activeRes.json();
        const historyData = await historyRes.json();

        const mappedActiveCalls = activeData.map((c: any) => ({
          id: c.id,
          callerId: c.callerId,
          callerName: c.callerName || 'User',
          listenerId: c.creatorId,
          listenerName: c.creatorName || 'Host',
          type: c.type || 'voice',
          status: 'active' as const,
          duration: c.durationSeconds || 0,
          coinsConsumed: c.coinsSpent || 0,
          date: c.startedAt || new Date().toISOString()
        }));

        const mappedHistoryCalls = historyData.map((c: any) => ({
          id: c.id,
          callerId: c.callerId,
          callerName: c.callerName || 'User',
          listenerId: c.creatorId,
          listenerName: c.creatorName || 'Host',
          type: c.type || 'voice',
          status: c.status || 'completed',
          duration: c.durationSeconds || 0,
          coinsConsumed: c.coinsSpent || 0,
          date: c.startedAt || new Date().toISOString()
        }));

        setCalls([...mappedActiveCalls, ...mappedHistoryCalls]);
        setActiveCallList(mappedActiveCalls);
        setIsLive(true);
        return;
      }
    } catch (e) {
      console.warn('CallsView failed to fetch calls from API:', e);
    }
    const all: Call[] = [];
    setCalls(all);
    setActiveCallList(all.filter(c => c.status === 'active'));
    setIsLive(false);
  };

  useEffect(() => {
    loadData();
  }, []);

  // Set interval to increment ongoing call durations
  useEffect(() => {
    if (activeTab !== 'active') return;

    const timer = setInterval(() => {
      setActiveCallList(prevList => 
        prevList.map(call => {
          const nextDur = call.duration + 1;
          const coinRate = call.type === 'video' ? 15 : 10;
          const nextCoins = Math.floor(nextDur / 60) * coinRate + (nextDur % 60 > 0 ? coinRate : 0);
          return {
            ...call,
            duration: nextDur,
            coinsConsumed: nextCoins
          };
        })
      );
    }, 1000);

    return () => clearInterval(timer);
  }, [activeTab]);

  const endLiveCall = async (callId: string) => {
    if (!window.confirm('Force disconnect this ongoing call?')) return;
    
    const target = activeCallList.find(c => c.id === callId);
    if (!target) return;

    try {
      const res = await fetch(`${API_BASE}/calls/active/${callId}/end`, {
        method: 'POST',
        headers: getHeaders(),
        body: JSON.stringify({
          duration: target.duration,
          endedReason: 'insufficient_coins'
        })
      });
      if (res.ok) {
        loadData();
        return;
      }
    } catch (e) {
      console.warn('Failed to force end call session via API:', e);
    }

    // Fallback if API fails
    const allCalls = MockDatabase.getCalls();
    const updatedCalls = allCalls.map(c => {
      if (c.id === callId) {
        return { 
          ...c, 
          status: 'completed' as const, 
          duration: target.duration, 
          coinsConsumed: target.coinsConsumed 
        };
      }
      return c;
    });

    MockDatabase.saveCalls(updatedCalls);
    setCalls(updatedCalls);
    setActiveCallList(activeCallList.filter(c => c.id !== callId));
    loadData();
  };

  // Filter history list
  const filteredHistory = calls
    .filter(c => c.status !== 'active')
    .filter(c => {
      const matchesSearch = c.callerName.toLowerCase().includes(search.toLowerCase()) || 
                            c.listenerName.toLowerCase().includes(search.toLowerCase()) || 
                            c.id.toLowerCase().includes(search.toLowerCase());
      const matchesType = typeFilter === 'all' || c.type === typeFilter;
      const matchesStatus = statusFilter === 'all' || c.status === statusFilter;
      return matchesSearch && matchesType && matchesStatus;
    });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-white sm:text-3xl">Call Connections</h1>
          <p className="text-sm text-zinc-400">Monitor live customer voice/video feeds and investigate session history.</p>
        </div>

        {/* Tab switcher */}
        <div className="flex bg-zinc-900 border border-zinc-800 p-0.5 rounded-lg text-xs self-start">
          <button
            onClick={() => setActiveTab('active')}
            className={`px-3 py-1.5 rounded-md font-semibold transition-colors flex items-center gap-1.5 ${
              activeTab === 'active' ? 'bg-zinc-800 text-white' : 'text-zinc-400 hover:text-zinc-200'
            }`}
          >
            <span className="relative flex h-1.5 w-1.5">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-rose-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-1.5 w-1.5 bg-rose-500"></span>
            </span>
            Ongoing Live ({activeCallList.length})
          </button>
          <button
            onClick={() => setActiveTab('history')}
            className={`px-3 py-1.5 rounded-md font-semibold transition-colors ${
              activeTab === 'history' ? 'bg-zinc-800 text-white' : 'text-zinc-400 hover:text-zinc-200'
            }`}
          >
            Call History
          </button>
        </div>
      </div>

      {activeTab === 'active' ? (
        /* Live Ongoing View */
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {activeCallList.length > 0 ? (
            activeCallList.map((call) => (
              <div key={call.id} className="glass-panel p-5 rounded-2xl border border-zinc-900 glow-indigo flex flex-col justify-between space-y-4">
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-2">
                    <span className="p-2 bg-indigo-500/10 rounded-lg text-indigo-400">
                      {call.type === 'video' ? <Video size={16} /> : <PhoneCall size={16} />}
                    </span>
                    <div>
                      <span className="text-[10px] text-zinc-500 font-mono leading-none">{call.id}</span>
                      <h3 className="text-sm font-bold text-white capitalize mt-0.5">{call.type} Call Session</h3>
                    </div>
                  </div>
                  <span className="inline-flex px-1.5 py-0.5 bg-rose-500/10 border border-rose-500/20 text-rose-400 rounded text-[9px] font-extrabold items-center gap-1 animate-pulse">
                    Live Ongoing
                  </span>
                </div>

                {/* Connection details */}
                <div className="bg-zinc-900/40 border border-zinc-900 p-3 rounded-xl flex items-center justify-between">
                  <div className="text-center flex-1">
                    <span className="text-[10px] text-zinc-500 leading-none">Caller</span>
                    <span className="block text-xs font-semibold text-white mt-1">{call.callerName}</span>
                  </div>
                  <div className="px-2 text-zinc-600 font-bold text-sm">→</div>
                  <div className="text-center flex-1">
                    <span className="text-[10px] text-zinc-500 leading-none">Host Listener</span>
                    <span className="block text-xs font-semibold text-indigo-300 mt-1">{call.listenerName}</span>
                  </div>
                </div>

                {/* Real-time counters */}
                <div className="grid grid-cols-2 gap-4 text-center">
                  <div className="bg-zinc-900/30 p-2.5 rounded-lg border border-zinc-900">
                    <span className="text-[9px] text-zinc-500">Duration</span>
                    <span className="text-sm font-bold text-white block mt-1">
                      {Math.floor(call.duration / 60)}m {call.duration % 60}s
                    </span>
                  </div>
                  <div className="bg-zinc-900/30 p-2.5 rounded-lg border border-zinc-900">
                    <span className="text-[9px] text-zinc-500">Coins Consumed</span>
                    <span className="text-sm font-bold text-amber-400 block mt-1">
                      {call.coinsConsumed} coins
                    </span>
                  </div>
                </div>

                <button
                  onClick={() => endLiveCall(call.id)}
                  className="w-full py-2 bg-red-950/20 hover:bg-red-900/30 text-red-400 border border-red-900/30 rounded-lg text-xs font-semibold transition-colors flex items-center justify-center gap-1.5"
                >
                  <PhoneOff size={14} /> Disconnect Call Session
                </button>
              </div>
            ))
          ) : (
            <div className="col-span-2 glass-panel p-8 text-center text-zinc-500 rounded-2xl">
              No live active calls ongoing at this time.
            </div>
          )}
        </div>
      ) : (
        /* Call History View */
        <div className="space-y-4">
          {/* History Search & Filters */}
          <div className="glass-panel p-4 rounded-xl flex flex-col md:flex-row md:items-center justify-between gap-4">
            
            {/* Search */}
            <div className="relative flex-1 max-w-sm">
              <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-500" />
              <input
                type="text"
                placeholder="Search Caller, Host Listener..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full pl-9 pr-4 py-2 text-xs bg-zinc-900 border border-zinc-800 rounded-lg text-white focus:outline-none focus:border-indigo-500"
              />
            </div>

            {/* Filters */}
            <div className="flex flex-wrap items-center gap-3">
              <div className="flex items-center gap-2">
                <span className="text-xs text-zinc-500 font-medium">Type:</span>
                <select
                  value={typeFilter}
                  onChange={(e) => setTypeFilter(e.target.value)}
                  className="bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none"
                >
                  <option value="all">All Types</option>
                  <option value="voice">Voice</option>
                  <option value="video">Video</option>
                </select>
              </div>
              
              <div className="flex items-center gap-2">
                <span className="text-xs text-zinc-500 font-medium">Status:</span>
                <select
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value)}
                  className="bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-1.5 text-xs text-white focus:outline-none"
                >
                  <option value="all">All Statuses</option>
                  <option value="completed">Completed</option>
                  <option value="missed">Missed</option>
                  <option value="rejected">Rejected</option>
                  <option value="cancelled">Cancelled</option>
                </select>
              </div>
            </div>

          </div>

          {/* History Data Table */}
          <div className="glass-panel rounded-2xl overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse text-xs">
                <thead>
                  <tr className="border-b border-zinc-800 text-zinc-400 bg-zinc-900/30">
                    <th className="p-4 font-semibold">Call ID</th>
                    <th className="p-4 font-semibold">Caller</th>
                    <th className="p-4 font-semibold">Host Listener</th>
                    <th className="p-4 font-semibold">Type</th>
                    <th className="p-4 font-semibold text-right">Duration</th>
                    <th className="p-4 font-semibold text-right">Coins Deducted</th>
                    <th className="p-4 font-semibold text-right">Date / Time</th>
                    <th className="p-4 font-semibold text-right">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-zinc-900">
                  {filteredHistory.length > 0 ? (
                    filteredHistory.map((c) => (
                      <tr key={c.id} className="hover:bg-zinc-900/30 text-zinc-300">
                        <td className="p-4 font-mono font-medium text-zinc-400">{c.id}</td>
                        <td className="p-4 font-semibold text-white">{c.callerName}</td>
                        <td className="p-4 font-semibold text-indigo-300">{c.listenerName}</td>
                        <td className="p-4 capitalize">
                          <span className="flex items-center gap-1">
                            {c.type === 'video' ? <Video size={12} className="text-zinc-500" /> : <PhoneCall size={12} className="text-zinc-500" />}
                            {c.type}
                          </span>
                        </td>
                        <td className="p-4 text-right font-medium">
                          {c.duration === 0 ? '-' : `${Math.floor(c.duration / 60)}m ${c.duration % 60}s`}
                        </td>
                        <td className="p-4 text-right font-bold text-amber-400">
                          {c.coinsConsumed > 0 ? `-${c.coinsConsumed}` : '0'}
                        </td>
                        <td className="p-4 text-right text-zinc-500">{new Date(c.date).toLocaleString()}</td>
                        <td className="p-4 text-right">
                          <span className={`inline-flex px-1.5 py-0.5 rounded text-[9px] font-bold capitalize ${
                            c.status === 'completed' ? 'bg-emerald-500/10 text-emerald-400' :
                            c.status === 'missed' ? 'bg-amber-500/10 text-amber-400' : 'bg-red-500/10 text-red-400'
                          }`}>
                            {c.status}
                          </span>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan={8} className="p-8 text-center text-zinc-500">
                        No call history matches filters.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
