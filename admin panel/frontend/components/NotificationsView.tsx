// components/NotificationsView.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { Send, Bell, Calendar, Clock, CheckCircle2, History, AlertCircle } from 'lucide-react';
import { MockDatabase, PushNotification } from '../lib/mockDb';

export default function NotificationsView() {
  const [history, setHistory] = useState<PushNotification[]>([]);
  
  // Form State
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [audience, setAudience] = useState<'all_users' | 'all_listeners' | 'selected_users' | 'selected_listeners'>('all_users');
  const [scheduleType, setScheduleType] = useState<'now' | 'schedule'>('now');
  const [scheduleTime, setScheduleTime] = useState('');

  // Toast
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const triggerToast = (msg: string, type: 'success' | 'error' = 'success') => {
    setToast({ message: msg, type });
    setTimeout(() => setToast(null), 3000);
  };

  const loadData = () => {
    setHistory(MockDatabase.getNotifications());
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title || !message) {
      triggerToast('Title and message are required', 'error');
      return;
    }

    const newNotification: PushNotification = {
      id: `NOT${Date.now().toString().slice(-4)}`,
      title,
      message,
      image: imageUrl || undefined,
      audience,
      date: scheduleType === 'now' ? new Date().toISOString() : new Date(scheduleTime).toISOString(),
      status: scheduleType === 'now' ? 'sent' : 'scheduled'
    };

    const updated = [newNotification, ...history];
    MockDatabase.saveNotifications(updated);
    setHistory(updated);

    // Reset Form
    setTitle('');
    setMessage('');
    setImageUrl('');
    setScheduleTime('');
    setScheduleType('now');

    triggerToast(
      scheduleType === 'now' 
        ? 'Push notification dispatched immediately!' 
        : 'Notification scheduled successfully!', 
      'success'
    );
  };

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
        <h1 className="text-2xl font-bold tracking-tight text-white sm:text-3xl">Push Notifications</h1>
        <p className="text-sm text-zinc-400">Broadcast updates, promo campaigns, or service announcements.</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Compose Panel */}
        <div className="glass-panel p-5 rounded-2xl border border-zinc-900 space-y-4 h-fit">
          <div className="flex items-center gap-2 text-white">
            <Bell size={18} className="text-indigo-400" />
            <h2 className="text-base font-semibold">Compose Notification</h2>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4 text-xs">
            <div>
              <label className="block text-zinc-500 mb-1 font-medium">Audience Group</label>
              <select
                value={audience}
                onChange={(e: any) => setAudience(e.target.value)}
                className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-indigo-500 font-semibold"
              >
                <option value="all_users">All Customers (Users)</option>
                <option value="all_listeners">All Host Listeners</option>
                <option value="selected_users">Selected Active Customers</option>
                <option value="selected_listeners">Top Rated Listeners Only</option>
              </select>
            </div>

            <div>
              <label className="block text-zinc-500 mb-1 font-medium">Notification Title</label>
              <input
                type="text"
                placeholder="e.g. Free Coins Recharge Bonus!"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-indigo-500 font-medium"
                required
              />
            </div>

            <div>
              <label className="block text-zinc-500 mb-1 font-medium">Message Body</label>
              <textarea
                rows={3}
                placeholder="Write your push announcement body..."
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-indigo-500 leading-relaxed"
                required
              />
            </div>

            <div>
              <label className="block text-zinc-500 mb-1 font-medium">Banner Image URL (Optional)</label>
              <input
                type="url"
                placeholder="https://example.com/banner.png"
                value={imageUrl}
                onChange={(e) => setImageUrl(e.target.value)}
                className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-indigo-500"
              />
            </div>

            <div className="border-t border-zinc-900 pt-3">
              <label className="block text-zinc-500 mb-2 font-medium">Delivery Schedule</label>
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => setScheduleType('now')}
                  className={`py-1.5 rounded-lg border font-semibold text-center transition-colors ${
                    scheduleType === 'now'
                      ? 'bg-zinc-800 border-zinc-700 text-white'
                      : 'bg-zinc-900 border-zinc-900 text-zinc-400 hover:text-zinc-300'
                  }`}
                >
                  Send Immediately
                </button>
                <button
                  type="button"
                  onClick={() => setScheduleType('schedule')}
                  className={`py-1.5 rounded-lg border font-semibold text-center transition-colors ${
                    scheduleType === 'schedule'
                      ? 'bg-zinc-800 border-zinc-700 text-white'
                      : 'bg-zinc-900 border-zinc-900 text-zinc-400 hover:text-zinc-300'
                  }`}
                >
                  Schedule Date
                </button>
              </div>
            </div>

            {scheduleType === 'schedule' && (
              <div className="space-y-1">
                <label className="block text-zinc-500 mb-1">Target Date & Time</label>
                <input
                  type="datetime-local"
                  value={scheduleTime}
                  onChange={(e) => setScheduleTime(e.target.value)}
                  className="w-full bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-indigo-500"
                  required
                />
              </div>
            )}

            <button
              type="submit"
              className="w-full py-2.5 bg-indigo-600 hover:bg-indigo-500 text-white rounded-lg font-bold shadow transition-colors flex items-center justify-center gap-1.5 mt-2"
            >
              <Send size={14} /> 
              {scheduleType === 'now' ? 'Dispatch Push Announcement' : 'Schedule Announcement'}
            </button>
          </form>
        </div>

        {/* Sent Logs Panel */}
        <div className="lg:col-span-2 glass-panel p-5 rounded-2xl border border-zinc-900 space-y-4">
          <div className="flex items-center gap-2 text-white">
            <History size={18} className="text-zinc-400" />
            <h2 className="text-base font-semibold">Notification Logs</h2>
          </div>

          <div className="space-y-3">
            {history.length > 0 ? (
              history.map((item) => (
                <div 
                  key={item.id} 
                  className="p-4 rounded-xl bg-zinc-900/40 border border-zinc-900 flex flex-col sm:flex-row justify-between sm:items-start gap-4 hover:border-zinc-800/80 transition-colors"
                >
                  <div className="space-y-1.5 flex-1 text-xs">
                    <div className="flex items-center gap-2">
                      <span className="text-[10px] text-zinc-500 font-mono">{item.id}</span>
                      <span className={`inline-flex px-1.5 py-0.5 rounded text-[8px] font-extrabold capitalize ${
                        item.status === 'sent' ? 'bg-emerald-500/10 text-emerald-400' : 'bg-amber-500/10 text-amber-400'
                      }`}>
                        {item.status === 'sent' ? 'Sent' : 'Scheduled'}
                      </span>
                    </div>
                    <h3 className="text-sm font-semibold text-white leading-tight">{item.title}</h3>
                    <p className="text-zinc-400 leading-relaxed font-medium">{item.message}</p>
                    {item.image && (
                      <a href={item.image} target="_blank" rel="noopener noreferrer" className="text-[10px] text-indigo-400 hover:underline inline-block">
                        Attached Image Banner
                      </a>
                    )}
                  </div>
                  
                  <div className="text-right text-[10px] text-zinc-500 space-y-1">
                    <span className="block font-semibold capitalize text-zinc-400">
                      To: {item.audience.replace('_', ' ')}
                    </span>
                    <span className="block">
                      {new Date(item.date).toLocaleString()}
                    </span>
                  </div>
                </div>
              ))
            ) : (
              <div className="p-8 text-center text-zinc-500 text-xs">
                No notification broadcast logs found.
              </div>
            )}
          </div>
        </div>

      </div>
    </div>
  );
}
