// components/SettingsView.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { Save, Settings, Phone, Coins, Users, AlertTriangle } from 'lucide-react';
import { MockDatabase, SystemSettings } from '../lib/mockDb';

export default function SettingsView() {
  const [settings, setSettings] = useState<SystemSettings | null>(null);

  // Form states
  const [appName, setAppName] = useState('');
  const [supportEmail, setSupportEmail] = useState('');
  const [supportWhatsapp, setSupportWhatsapp] = useState('');
  const [voiceCallsOn, setVoiceCallsOn] = useState(true);
  const [videoCallsOn, setVideoCallsOn] = useState(true);
  const [callTimeout, setCallTimeout] = useState(45);
  const [coinRatePerMin, setCoinRatePerMin] = useState(10);
  const [minRecharge, setMinRecharge] = useState(99);
  const [referralBonus, setReferralBonus] = useState(50);
  const [commissionRate, setCommissionRate] = useState(60);
  const [minWithdrawal, setMinWithdrawal] = useState(1000);
  const [autoApproval, setAutoApproval] = useState(false);
  const [maintenanceMode, setMaintenanceMode] = useState(false);

  // Toast
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const triggerToast = (msg: string, type: 'success' | 'error' = 'success') => {
    setToast({ message: msg, type });
    setTimeout(() => setToast(null), 3000);
  };

  useEffect(() => {
    const s = MockDatabase.getSettings();
    setSettings(s);

    setAppName(s.appName);
    setSupportEmail(s.supportEmail);
    setSupportWhatsapp(s.supportWhatsapp);
    setVoiceCallsOn(s.voiceCallsOn);
    setVideoCallsOn(s.videoCallsOn);
    setCallTimeout(s.callTimeout);
    setCoinRatePerMin(s.coinRatePerMin);
    setMinRecharge(s.minRecharge);
    setReferralBonus(s.referralBonus);
    setCommissionRate(s.commissionRate);
    setMinWithdrawal(s.minWithdrawal);
    setAutoApproval(s.autoApproval);
    setMaintenanceMode(s.maintenanceMode);
  }, []);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    const newSettings: SystemSettings = {
      appName,
      supportEmail,
      supportWhatsapp,
      voiceCallsOn,
      videoCallsOn,
      callTimeout,
      coinRatePerMin,
      minRecharge,
      referralBonus,
      commissionRate,
      minWithdrawal,
      autoApproval,
      maintenanceMode
    };

    MockDatabase.saveSettings(newSettings);
    setSettings(newSettings);
    triggerToast('System configurations updated successfully!', 'success');
  };

  if (!settings) {
    return <div className="text-zinc-500 text-xs">Loading system configurations...</div>;
  }

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
        <h1 className="text-2xl font-bold tracking-tight text-white sm:text-3xl">Platform Settings</h1>
        <p className="text-sm text-zinc-400">Configure core global configurations for calls, coin payouts, and support details.</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6 text-xs text-zinc-300">
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          
          {/* Section 1: General configurations */}
          <div className="glass-panel p-5 rounded-2xl border border-zinc-900 space-y-4">
            <div className="flex items-center gap-2 text-white font-semibold text-sm">
              <Settings size={16} className="text-indigo-400" />
              <h2>General Configurations</h2>
            </div>
            
            <div className="space-y-3">
              <div>
                <label className="block text-zinc-500 mb-1">Application Title Name</label>
                <input
                  type="text"
                  value={appName}
                  onChange={(e) => setAppName(e.target.value)}
                  className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-indigo-500"
                  required
                />
              </div>

              <div>
                <label className="block text-zinc-500 mb-1">Customer Support Email</label>
                <input
                  type="email"
                  value={supportEmail}
                  onChange={(e) => setSupportEmail(e.target.value)}
                  className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-indigo-500"
                  required
                />
              </div>

              <div>
                <label className="block text-zinc-500 mb-1">Customer Support WhatsApp Link/No.</label>
                <input
                  type="text"
                  value={supportWhatsapp}
                  onChange={(e) => setSupportWhatsapp(e.target.value)}
                  className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-indigo-500"
                  required
                />
              </div>
            </div>
          </div>

          {/* Section 2: Calling configurations */}
          <div className="glass-panel p-5 rounded-2xl border border-zinc-900 space-y-4">
            <div className="flex items-center gap-2 text-white font-semibold text-sm">
              <Phone size={16} className="text-indigo-400" />
              <h2>Calling Sessions Configurations</h2>
            </div>

            <div className="space-y-4">
              <div className="flex items-center justify-between bg-zinc-900/30 p-2.5 rounded-lg border border-zinc-900">
                <div>
                  <span className="block font-semibold text-white">Voice Calling Stream</span>
                  <span className="text-[10px] text-zinc-500">Allow users to initialize voice streams.</span>
                </div>
                <input
                  type="checkbox"
                  checked={voiceCallsOn}
                  onChange={(e) => setVoiceCallsOn(e.target.checked)}
                  className="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500"
                />
              </div>

              <div className="flex items-center justify-between bg-zinc-900/30 p-2.5 rounded-lg border border-zinc-900">
                <div>
                  <span className="block font-semibold text-white">Video Calling Stream</span>
                  <span className="text-[10px] text-zinc-500">Allow users to initialize camera video streams.</span>
                </div>
                <input
                  type="checkbox"
                  checked={videoCallsOn}
                  onChange={(e) => setVideoCallsOn(e.target.checked)}
                  className="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500"
                />
              </div>

              <div>
                <label className="block text-zinc-500 mb-1">Connection Ringing Timeout (Seconds)</label>
                <input
                  type="number"
                  value={callTimeout}
                  onChange={(e) => setCallTimeout(parseInt(e.target.value) || 0)}
                  className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-indigo-500"
                  required
                />
              </div>
            </div>
          </div>

          {/* Section 3: Coins & Charging rates */}
          <div className="glass-panel p-5 rounded-2xl border border-zinc-900 space-y-4">
            <div className="flex items-center gap-2 text-white font-semibold text-sm">
              <Coins size={16} className="text-indigo-400" />
              <h2>Coins Exchange & Pricing</h2>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-zinc-500 mb-1">Exchange rate (Coins / min)</label>
                <input
                  type="number"
                  value={coinRatePerMin}
                  onChange={(e) => setCoinRatePerMin(parseInt(e.target.value) || 0)}
                  className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-indigo-500"
                  required
                />
              </div>
              <div>
                <label className="block text-zinc-500 mb-1">Referral Reward (Coins)</label>
                <input
                  type="number"
                  value={referralBonus}
                  onChange={(e) => setReferralBonus(parseInt(e.target.value) || 0)}
                  className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-indigo-500"
                  required
                />
              </div>
            </div>
            <div>
              <label className="block text-zinc-500 mb-1">Minimum Recharge Allowed (₹ INR)</label>
              <input
                type="number"
                value={minRecharge}
                onChange={(e) => setMinRecharge(parseInt(e.target.value) || 0)}
                className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-indigo-500"
                required
              />
            </div>
          </div>

          {/* Section 4: Listener / host rules */}
          <div className="glass-panel p-5 rounded-2xl border border-zinc-900 space-y-4">
            <div className="flex items-center gap-2 text-white font-semibold text-sm">
              <Users size={16} className="text-indigo-400" />
              <h2>Hosts & Payout Auditing</h2>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-zinc-500 mb-1">Commission Rate Split (%)</label>
                <input
                  type="number"
                  max="100"
                  min="0"
                  value={commissionRate}
                  onChange={(e) => setCommissionRate(parseInt(e.target.value) || 0)}
                  className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-indigo-500"
                  required
                />
              </div>
              <div>
                <label className="block text-zinc-500 mb-1">Min Withdrawal Limit (₹ INR)</label>
                <input
                  type="number"
                  value={minWithdrawal}
                  onChange={(e) => setMinWithdrawal(parseInt(e.target.value) || 0)}
                  className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-indigo-500"
                  required
                />
              </div>
            </div>

            <div className="flex items-center justify-between bg-zinc-900/30 p-2.5 rounded-lg border border-zinc-900">
              <div>
                <span className="block font-semibold text-white">Auto Approve Onboarding Profiles</span>
                <span className="text-[10px] text-zinc-500">Skips admin approval step for new hosts.</span>
              </div>
              <input
                type="checkbox"
                checked={autoApproval}
                onChange={(e) => setAutoApproval(e.target.checked)}
                className="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500"
              />
            </div>
          </div>

        </div>

        {/* Maintenance mode alert card */}
        <div className="glass-panel p-5 rounded-2xl border border-red-950/20 bg-red-950/5 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div className="flex items-start gap-3">
            <AlertTriangle className="text-red-400 mt-0.5" size={20} />
            <div>
              <h3 className="text-sm font-semibold text-red-300">System Platform Maintenance Mode</h3>
              <p className="text-[10px] text-zinc-500 leading-normal mt-0.5">Enabling maintenance mode blocks all API traffic and displays a maintenance banner to app users.</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <span className="font-semibold text-xs text-zinc-400">Offline Maintenance:</span>
            <input
              type="checkbox"
              checked={maintenanceMode}
              onChange={(e) => setMaintenanceMode(e.target.checked)}
              className="w-4 h-4 rounded text-red-600 focus:ring-red-500 border-zinc-800"
            />
          </div>
        </div>

        <button
          type="submit"
          className="flex items-center gap-1.5 px-5 py-2.5 bg-indigo-600 hover:bg-indigo-500 text-white rounded-lg font-bold shadow-md shadow-indigo-600/10 transition-colors"
        >
          <Save size={14} /> Commit Settings Configurations
        </button>

      </form>
    </div>
  );
}
