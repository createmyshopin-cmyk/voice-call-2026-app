// components/SafetyView.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { Search, ShieldAlert, Ban, CheckCircle2, UserMinus, Plus, Trash2, Eye } from 'lucide-react';
import { MockDatabase, SafetyReport, DeviceBan, User } from '../lib/mockDb';

export default function SafetyView() {
  const [reports, setReports] = useState<SafetyReport[]>([]);
  const [bans, setBans] = useState<DeviceBan[]>([]);
  const [search, setSearch] = useState('');
  const [activeTab, setActiveTab] = useState<'reports' | 'device_bans'>('reports');

  // Form State for adding a device ban
  const [isAddingBan, setIsAddingBan] = useState(false);
  const [banDeviceId, setBanDeviceId] = useState('');
  const [banUserName, setBanUserName] = useState('');
  const [banReason, setBanReason] = useState('Violated community safety standards');

  // Toast
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'info' | 'error' } | null>(null);

  const triggerToast = (msg: string, type: 'success' | 'info' | 'error' = 'success') => {
    setToast({ message: msg, type });
    setTimeout(() => setToast(null), 3000);
  };

  const loadData = () => {
    setReports(MockDatabase.getReports());
    setBans(MockDatabase.getDeviceBans());
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleUpdate = () => {
    loadData();
  };

  // 1. Resolve Report
  const closeReport = (reportId: string) => {
    const updated = reports.map(r => {
      if (r.id === reportId) {
        triggerToast(`Moderation report ${reportId} resolved`, 'success');
        return { ...r, status: 'resolved' as const };
      }
      return r;
    });
    MockDatabase.saveReports(updated);
    setReports(updated);
  };

  // 2. Warn Reported User
  const warnUser = (report: SafetyReport) => {
    triggerToast(`Warning warning sent to ${report.reportedUserName}`, 'info');
    closeReport(report.id);
  };

  // 3. Suspend / Ban User from report
  const banUser = (report: SafetyReport) => {
    if (!window.confirm(`Permanently ban user ${report.reportedUserName}?`)) return;

    const allUsers = MockDatabase.getUsers();
    const updatedUsers = allUsers.map(u => {
      if (u.id === report.reportedUserId) {
        return { ...u, status: 'blocked' as const, safetyScore: 20 };
      }
      return u;
    });
    MockDatabase.saveUsers(updatedUsers);

    // If report is unresolved, resolve it
    closeReport(report.id);
    triggerToast(`Banned user ${report.reportedUserName}`, 'error');
  };

  // 4. Lift Device Ban
  const liftDeviceBan = (banId: string, deviceId: string) => {
    if (!window.confirm(`Lift ban for device ID: ${deviceId}?`)) return;
    const updatedBans = bans.filter(b => b.id !== banId);
    MockDatabase.saveDeviceBans(updatedBans);
    setBans(updatedBans);
    triggerToast(`Device ban lifted`, 'success');
  };

  // 5. Add Device Ban
  const addDeviceBanSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!banDeviceId || !banUserName) {
      triggerToast('Device ID and username are required', 'error');
      return;
    }

    const newBan: DeviceBan = {
      id: `BAN${Date.now().toString().slice(-4)}`,
      deviceId: banDeviceId,
      userId: `USR${Date.now().toString().slice(-3)}`,
      userName: banUserName,
      reason: banReason,
      date: new Date().toISOString()
    };

    const updated = [...bans, newBan];
    MockDatabase.saveDeviceBans(updated);
    setBans(updated);
    setIsAddingBan(false);
    setBanDeviceId('');
    setBanUserName('');
    setBanReason('Violated community safety standards');
    triggerToast(`Device ${banDeviceId} banned successfully`, 'error');
  };

  const filteredReports = reports.filter(r => {
    const matchesSearch = r.reportedUserName.toLowerCase().includes(search.toLowerCase()) || 
                          r.reporterName.toLowerCase().includes(search.toLowerCase()) || 
                          r.reason.toLowerCase().includes(search.toLowerCase()) || 
                          r.id.toLowerCase().includes(search.toLowerCase());
    return matchesSearch;
  });

  const filteredBans = bans.filter(b => {
    const matchesSearch = b.deviceId.toLowerCase().includes(search.toLowerCase()) || 
                          b.userName.toLowerCase().includes(search.toLowerCase());
    return matchesSearch;
  });

  return (
    <div className="space-y-6 relative">
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

      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-white sm:text-3xl">Safety & Moderation</h1>
          <p className="text-sm text-zinc-400">Review reported profile content, issue bans, and blacklists.</p>
        </div>

        {/* Tab Switcher */}
        <div className="flex bg-zinc-900 border border-zinc-800 p-0.5 rounded-lg text-xs self-start">
          <button
            onClick={() => { setActiveTab('reports'); setSearch(''); }}
            className={`px-3 py-1.5 rounded-md font-semibold transition-colors flex items-center gap-1.5 ${
              activeTab === 'reports' ? 'bg-zinc-800 text-white' : 'text-zinc-400 hover:text-zinc-200'
            }`}
          >
            User Reports ({reports.filter(r => r.status === 'pending').length})
          </button>
          <button
            onClick={() => { setActiveTab('device_bans'); setSearch(''); }}
            className={`px-3 py-1.5 rounded-md font-semibold transition-colors ${
              activeTab === 'device_bans' ? 'bg-zinc-800 text-white' : 'text-zinc-400 hover:text-zinc-200'
            }`}
          >
            Banned Devices ({bans.length})
          </button>
        </div>
      </div>

      {activeTab === 'reports' ? (
        /* User Reports Table */
        <div className="space-y-4">
          <div className="flex justify-between items-center max-w-sm">
            <div className="relative w-full">
              <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-500" />
              <input
                type="text"
                placeholder="Search reports..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full pl-9 pr-4 py-2 text-xs bg-zinc-900 border border-zinc-800 rounded-lg text-white focus:outline-none focus:border-indigo-500"
              />
            </div>
          </div>

          <div className="glass-panel rounded-2xl overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse text-xs">
                <thead>
                  <tr className="border-b border-zinc-800 text-zinc-400 bg-zinc-900/30">
                    <th className="p-4 font-semibold">Report ID</th>
                    <th className="p-4 font-semibold">Reported User</th>
                    <th className="p-4 font-semibold">Reporter</th>
                    <th className="p-4 font-semibold">Reason</th>
                    <th className="p-4 font-semibold">Details</th>
                    <th className="p-4 font-semibold">Date</th>
                    <th className="p-4 font-semibold">Status</th>
                    <th className="p-4 font-semibold text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-zinc-900">
                  {filteredReports.length > 0 ? (
                    filteredReports.map((r) => (
                      <tr key={r.id} className="hover:bg-zinc-900/30 text-zinc-300">
                        <td className="p-4 font-mono font-medium text-zinc-400">{r.id}</td>
                        <td className="p-4">
                          <span className="font-semibold text-white">{r.reportedUserName}</span>
                          <span className="block text-[10px] text-zinc-500 capitalize mt-0.5">{r.reportedUserRole}</span>
                        </td>
                        <td className="p-4 font-semibold text-zinc-300">{r.reporterName}</td>
                        <td className="p-4 capitalize text-amber-400 font-semibold">
                          {r.reason.replace('_', ' ')}
                        </td>
                        <td className="p-4 text-zinc-400 max-w-xs truncate" title={r.description}>
                          {r.description}
                        </td>
                        <td className="p-4 text-zinc-500">{new Date(r.date).toLocaleDateString()}</td>
                        <td className="p-4">
                          <span className={`inline-flex px-1.5 py-0.5 rounded text-[9px] font-bold capitalize ${
                            r.status === 'pending' ? 'bg-amber-500/10 text-amber-400' : 'bg-emerald-500/10 text-emerald-400'
                          }`}>
                            {r.status}
                          </span>
                        </td>
                        <td className="p-4 text-right">
                          <div className="flex justify-end gap-1.5">
                            {r.status === 'pending' ? (
                              <>
                                <button
                                  onClick={() => warnUser(r)}
                                  className="px-2 py-1 bg-zinc-900 hover:bg-zinc-800 border border-zinc-800 text-zinc-300 rounded text-[10px] font-semibold transition-colors"
                                >
                                  Warn
                                </button>
                                <button
                                  onClick={() => banUser(r)}
                                  className="px-2 py-1 bg-red-950/20 hover:bg-red-900/30 border border-red-900/30 text-red-400 rounded text-[10px] font-semibold transition-colors"
                                >
                                  Ban Account
                                </button>
                                <button
                                  onClick={() => closeReport(r.id)}
                                  className="px-2 py-1 bg-emerald-950/20 hover:bg-emerald-900/30 border border-emerald-950/20 text-emerald-400 rounded text-[10px] font-semibold transition-colors"
                                >
                                  Close
                                </button>
                              </>
                            ) : (
                              <span className="text-[10px] text-zinc-500 font-medium">Addressed</span>
                            )}
                          </div>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan={8} className="p-8 text-center text-zinc-500">
                        No reports matching filters.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      ) : (
        /* Device Ban view */
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Table List */}
          <div className="lg:col-span-2 space-y-4">
            <div className="flex justify-between items-center max-w-sm">
              <div className="relative w-full">
                <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-500" />
                <input
                  type="text"
                  placeholder="Search banned hardware IDs..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="w-full pl-9 pr-4 py-2 text-xs bg-zinc-900 border border-zinc-800 rounded-lg text-white focus:outline-none focus:border-indigo-500"
                />
              </div>
            </div>

            <div className="glass-panel rounded-2xl overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse text-xs">
                  <thead>
                    <tr className="border-b border-zinc-800 text-zinc-400 bg-zinc-900/30">
                      <th className="p-4 font-semibold">Device Hardware ID</th>
                      <th className="p-4 font-semibold">Associated Account</th>
                      <th className="p-4 font-semibold">Ban Reason</th>
                      <th className="p-4 font-semibold">Banned Date</th>
                      <th className="p-4 font-semibold text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-zinc-900">
                    {filteredBans.length > 0 ? (
                      filteredBans.map((ban) => (
                        <tr key={ban.id} className="hover:bg-zinc-900/30 text-zinc-300">
                          <td className="p-4 font-mono font-semibold text-rose-400">{ban.deviceId}</td>
                          <td className="p-4">
                            <span className="font-semibold text-white">{ban.userName}</span>
                            <span className="block text-[10px] text-zinc-500 mt-0.5">{ban.userId}</span>
                          </td>
                          <td className="p-4 text-zinc-400 max-w-xs truncate">{ban.reason}</td>
                          <td className="p-4 text-zinc-500">{new Date(ban.date).toLocaleDateString()}</td>
                          <td className="p-4 text-right">
                            <button
                              onClick={() => liftDeviceBan(ban.id, ban.deviceId)}
                              className="px-2 py-1 bg-zinc-900 border border-zinc-800 hover:bg-zinc-800 text-zinc-300 rounded text-[10px] font-semibold transition-colors"
                            >
                              Lift Ban
                            </button>
                          </td>
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td colSpan={5} className="p-8 text-center text-zinc-500">
                          No device hardware bans registered.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          {/* Form to ban a device ID */}
          <div className="glass-panel p-5 rounded-2xl border border-zinc-900 h-fit space-y-4">
            <div>
              <h2 className="text-base font-semibold text-white">Ban Hardware Device</h2>
              <p className="text-xs text-zinc-400">Strictly blocks device access to prevent repeat harassment.</p>
            </div>

            <form onSubmit={addDeviceBanSubmit} className="space-y-4 text-xs">
              <div>
                <label className="block text-zinc-500 mb-1">Device ID / UUID</label>
                <input
                  type="text"
                  placeholder="e.g. DEV-F8293X928B3"
                  value={banDeviceId}
                  onChange={(e) => setBanDeviceId(e.target.value)}
                  className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-indigo-500 font-mono"
                  required
                />
              </div>

              <div>
                <label className="block text-zinc-500 mb-1">Username Reference</label>
                <input
                  type="text"
                  placeholder="e.g. Kabir Singh"
                  value={banUserName}
                  onChange={(e) => setBanUserName(e.target.value)}
                  className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-indigo-500"
                  required
                />
              </div>

              <div>
                <label className="block text-zinc-500 mb-1">Reason for Ban</label>
                <textarea
                  rows={3}
                  value={banReason}
                  onChange={(e) => setBanReason(e.target.value)}
                  className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-indigo-500 leading-relaxed"
                  required
                />
              </div>

              <button
                type="submit"
                className="w-full py-2.5 bg-red-600 hover:bg-red-500 text-white rounded-lg font-semibold shadow transition-colors flex items-center justify-center gap-1.5"
              >
                <Ban size={14} /> Commit Hardware Ban
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
