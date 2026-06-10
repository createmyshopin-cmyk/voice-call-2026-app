'use client';

import React, { useCallback, useEffect, useState } from 'react';
import { Bell, Save, Send } from 'lucide-react';
import PageHeader from '../ui/PageHeader';
import ModuleTabs from '../ui/ModuleTabs';
import DataTable from '../ui/DataTable';
import LiveDataBanner from '../LiveDataBanner';
import { fetchJsonAuth } from '../../lib/api';
import {
  releasesApi,
  type AppRelease,
  type AppVersionSettings,
  type NotificationTarget,
  type VersionAnalytics,
} from '../../lib/api/releases';

const TABS = [
  { id: 'current', label: 'Current Version' },
  { id: 'history', label: 'Release History' },
  { id: 'notifications', label: 'Notifications' },
  { id: 'analytics', label: 'Analytics' },
  { id: 'maintenance', label: 'Maintenance Mode' },
];

const NOTIFY_TARGETS: { id: NotificationTarget; label: string }[] = [
  { id: 'all', label: 'All' },
  { id: 'users', label: 'Users' },
  { id: 'creators', label: 'Creators' },
  { id: 'legend_superhosts', label: 'Legend Superhosts' },
];

export default function ReleaseManagementView() {
  const [tab, setTab] = useState('current');
  const [isLive, setIsLive] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [settings, setSettings] = useState<AppVersionSettings | null>(null);
  const [releases, setReleases] = useState<AppRelease[]>([]);
  const [analytics, setAnalytics] = useState<VersionAnalytics | null>(null);
  const [selectedRelease, setSelectedRelease] = useState<AppRelease | null>(null);
  const [notifyTarget, setNotifyTarget] = useState<NotificationTarget>('all');
  const [notifyTitle, setNotifyTitle] = useState('');
  const [notifyBody, setNotifyBody] = useState('');
  const [toast, setToast] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(null), 3000);
  };

  const loadSettings = useCallback(async () => {
    const res = await fetchJsonAuth<{ settings?: AppVersionSettings } & AppVersionSettings>(
      releasesApi.settings(),
    );
    if (res.ok && res.data) {
      const s = 'settings' in res.data && res.data.settings ? res.data.settings : res.data;
      setSettings(s as AppVersionSettings);
      setIsLive(true);
    } else setIsLive(false);
    setLoading(false);
  }, []);

  const loadReleases = useCallback(async () => {
    const res = await fetchJsonAuth<AppRelease[]>(releasesApi.list());
    if (res.ok && res.data) setReleases(res.data);
  }, []);

  const loadAnalytics = useCallback(async () => {
    const res = await fetchJsonAuth<VersionAnalytics>(releasesApi.analytics());
    if (res.ok && res.data) setAnalytics(res.data);
  }, []);

  useEffect(() => {
    loadSettings();
    loadReleases();
    loadAnalytics();
  }, [loadSettings, loadReleases, loadAnalytics]);

  const saveSettings = async (patch: Partial<AppVersionSettings>) => {
    if (!settings) return;
    setSaving(true);
    const body = { ...settings, ...patch };
    const res = await fetchJsonAuth(releasesApi.settings(), {
      method: 'PUT',
      body: JSON.stringify({
        latestVersion: body.latestVersion,
        minimumSupportedVersion: body.minimumSupportedVersion,
        forceUpdate: body.forceUpdate,
        releaseType: body.releaseType,
        title: body.title,
        message: body.message,
        playStoreUrl: body.playStoreUrl,
        appStoreUrl: body.appStoreUrl,
        maintenanceMode: body.maintenanceMode,
        maintenanceTitle: body.maintenanceTitle,
        maintenanceMessage: body.maintenanceMessage,
        maintenanceDurationMinutes: body.maintenanceDurationMinutes,
      }),
    });
    setSaving(false);
    if (res.ok) {
      showToast('Settings saved');
      loadSettings();
    } else showToast('Failed to save settings');
  };

  const sendNotification = async () => {
    const res = await fetchJsonAuth(releasesApi.sendNotification(), {
      method: 'POST',
      body: JSON.stringify({
        target: notifyTarget,
        title: notifyTitle || undefined,
        body: notifyBody || undefined,
        releaseId: selectedRelease?.id,
      }),
    });
    if (res.ok) {
      const data = res.data as { tokensSent?: number };
      showToast(`Notification sent to ${data.tokensSent ?? 0} devices`);
    } else showToast('Failed to send notification');
  };

  if (loading) {
    return <div className="text-sm text-muted-foreground p-6">Loading release management…</div>;
  }

  const historyColumns = [
    { key: 'version', header: 'Version', render: (r: AppRelease) => <span className="font-bold">{r.version}</span> },
    { key: 'build', header: 'Build', render: (r: AppRelease) => r.buildNumber },
    { key: 'type', header: 'Type', render: (r: AppRelease) => (
      <span className="text-[10px] uppercase font-bold px-2 py-0.5 rounded-full bg-secondary">{r.releaseType}</span>
    )},
    { key: 'date', header: 'Date', render: (r: AppRelease) => new Date(r.createdAt).toLocaleDateString() },
    { key: 'status', header: 'Status', render: (r: AppRelease) => (
      <span className={r.isActive ? 'text-emerald-400' : 'text-muted-foreground'}>
        {r.isActive ? 'Active' : 'Archived'}
      </span>
    )},
    { key: 'creator', header: 'Creator', render: (r: AppRelease) => (
      <span className="font-mono text-[10px]">{r.createdBy?.slice(0, 8) ?? '—'}…</span>
    )},
  ];

  return (
    <div className="space-y-6">
      <PageHeader
        title="Release Management"
        description="Force updates, maintenance mode, release history, and adoption analytics"
      />
      <LiveDataBanner isLive={isLive} label="release management" />
      {toast && (
        <div className="fixed bottom-6 right-6 z-50 px-4 py-2 rounded-lg bg-emerald-600 text-white text-sm shadow-lg">
          {toast}
        </div>
      )}

      <ModuleTabs tabs={TABS} active={tab} onChange={setTab} />

      {tab === 'current' && settings && (
        <div className="glass-panel p-6 space-y-4 max-w-2xl">
          <div className="grid grid-cols-2 gap-4">
            <label className="block">
              <span className="text-xs text-muted-foreground">Latest Version</span>
              <input className="w-full mt-1 px-3 py-2 rounded-lg bg-secondary border border-border text-sm"
                value={settings.latestVersion} onChange={(e) => setSettings({ ...settings, latestVersion: e.target.value })} />
            </label>
            <label className="block">
              <span className="text-xs text-muted-foreground">Minimum Supported Version</span>
              <input className="w-full mt-1 px-3 py-2 rounded-lg bg-secondary border border-border text-sm"
                value={settings.minimumSupportedVersion} onChange={(e) => setSettings({ ...settings, minimumSupportedVersion: e.target.value })} />
            </label>
          </div>
          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" checked={settings.forceUpdate}
              onChange={(e) => setSettings({ ...settings, forceUpdate: e.target.checked })} />
            Force Update
          </label>
          <label className="block">
            <span className="text-xs text-muted-foreground">Release Type</span>
            <select className="w-full mt-1 px-3 py-2 rounded-lg bg-secondary border border-border text-sm"
              value={settings.releaseType} onChange={(e) => setSettings({ ...settings, releaseType: e.target.value as AppVersionSettings['releaseType'] })}>
              <option value="optional">optional</option>
              <option value="force">force</option>
              <option value="maintenance">maintenance</option>
            </select>
          </label>
          <label className="block">
            <span className="text-xs text-muted-foreground">Popup Title</span>
            <input className="w-full mt-1 px-3 py-2 rounded-lg bg-secondary border border-border text-sm"
              value={settings.title} onChange={(e) => setSettings({ ...settings, title: e.target.value })} />
          </label>
          <label className="block">
            <span className="text-xs text-muted-foreground">Popup Message</span>
            <textarea className="w-full mt-1 px-3 py-2 rounded-lg bg-secondary border border-border text-sm min-h-[80px]"
              value={settings.message} onChange={(e) => setSettings({ ...settings, message: e.target.value })} />
          </label>
          <label className="block">
            <span className="text-xs text-muted-foreground">Play Store URL</span>
            <input className="w-full mt-1 px-3 py-2 rounded-lg bg-secondary border border-border text-sm"
              value={settings.playStoreUrl} onChange={(e) => setSettings({ ...settings, playStoreUrl: e.target.value })} />
          </label>
          <label className="block">
            <span className="text-xs text-muted-foreground">App Store URL</span>
            <input className="w-full mt-1 px-3 py-2 rounded-lg bg-secondary border border-border text-sm"
              value={settings.appStoreUrl} onChange={(e) => setSettings({ ...settings, appStoreUrl: e.target.value })} />
          </label>
          <button type="button" disabled={saving} onClick={() => saveSettings(settings)}
            className="flex items-center gap-2 px-4 py-2 rounded-lg bg-indigo-600 text-white text-sm font-semibold hover:bg-indigo-500 disabled:opacity-50">
            <Save size={14} /> Save
          </button>
        </div>
      )}

      {tab === 'history' && (
        <div className="space-y-4">
          <DataTable
            columns={historyColumns}
            rows={releases}
            rowKey={(r) => r.id}
          />
          <div className="flex flex-wrap gap-2">
            {releases.map((r) => (
              <button
                key={r.id}
                type="button"
                onClick={() => setSelectedRelease(r)}
                className={`px-3 py-1 rounded-lg text-xs border ${
                  selectedRelease?.id === r.id
                    ? 'border-indigo-500 bg-indigo-500/20'
                    : 'border-border'
                }`}
              >
                {r.version} ({r.buildNumber})
              </button>
            ))}
          </div>
          {selectedRelease && (
            <div className="glass-panel p-6 space-y-3 max-w-xl">
              <h3 className="font-bold text-lg">Version {selectedRelease.version} ({selectedRelease.buildNumber})</h3>
              <p className="text-sm"><strong>Title:</strong> {selectedRelease.title}</p>
              <p className="text-sm"><strong>Message:</strong> {selectedRelease.message}</p>
              <p className="text-sm whitespace-pre-wrap"><strong>Changelog:</strong><br />{selectedRelease.changelog || '—'}</p>
              <p className="text-sm text-muted-foreground">Released {new Date(selectedRelease.createdAt).toLocaleString()}</p>
              <p className="text-xs break-all">Play: {selectedRelease.playStoreUrl}</p>
              <p className="text-xs break-all">App Store: {selectedRelease.appStoreUrl}</p>
            </div>
          )}
        </div>
      )}

      {tab === 'notifications' && (
        <div className="glass-panel p-6 max-w-lg space-y-4">
          <h3 className="font-semibold flex items-center gap-2"><Bell size={16} /> Send Update Notification</h3>
          <label className="block">
            <span className="text-xs text-muted-foreground">Target</span>
            <select className="w-full mt-1 px-3 py-2 rounded-lg bg-secondary border border-border text-sm"
              value={notifyTarget} onChange={(e) => setNotifyTarget(e.target.value as NotificationTarget)}>
              {NOTIFY_TARGETS.map((t) => <option key={t.id} value={t.id}>{t.label}</option>)}
            </select>
          </label>
          <label className="block">
            <span className="text-xs text-muted-foreground">Title (optional)</span>
            <input className="w-full mt-1 px-3 py-2 rounded-lg bg-secondary border border-border text-sm"
              placeholder="🚀 Creomine 2.3.0 Available" value={notifyTitle} onChange={(e) => setNotifyTitle(e.target.value)} />
          </label>
          <label className="block">
            <span className="text-xs text-muted-foreground">Body (optional)</span>
            <textarea className="w-full mt-1 px-3 py-2 rounded-lg bg-secondary border border-border text-sm"
              placeholder="Improved call quality…" value={notifyBody} onChange={(e) => setNotifyBody(e.target.value)} />
          </label>
          <button type="button" onClick={sendNotification}
            className="flex items-center gap-2 px-4 py-2 rounded-lg bg-indigo-600 text-white text-sm font-semibold hover:bg-indigo-500">
            <Send size={14} /> Send Update Notification
          </button>
        </div>
      )}

      {tab === 'analytics' && analytics && (
        <div className="space-y-4">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="glass-panel p-4"><p className="text-xs text-muted-foreground">Reported Users</p><p className="text-2xl font-bold">{analytics.totalReported}</p></div>
            <div className="glass-panel p-4"><p className="text-xs text-muted-foreground">On Latest</p><p className="text-2xl font-bold text-emerald-400">{analytics.onLatest}</p></div>
            <div className="glass-panel p-4"><p className="text-xs text-muted-foreground">Outdated</p><p className="text-2xl font-bold text-amber-400">{analytics.outdated}</p></div>
            <div className="glass-panel p-4"><p className="text-xs text-muted-foreground">Adoption %</p><p className="text-2xl font-bold">{analytics.adoptionPercent}%</p></div>
          </div>
          <div className="glass-panel p-4">
            <h4 className="text-sm font-bold mb-3">Users by Version</h4>
            {(analytics.usersByVersion as { version: string; count: number; platform?: string }[]).length === 0 ? (
              <p className="text-sm text-muted-foreground">No version data yet</p>
            ) : (
              <ul className="space-y-2">
                {(analytics.usersByVersion as { version: string; count: number; platform?: string }[]).map((row, i) => (
                  <li key={i} className="flex justify-between text-sm border-b border-border/50 pb-2">
                    <span>{row.version} {row.platform ? `(${row.platform})` : ''}</span>
                    <span className="font-bold tabular-nums">{row.count}</span>
                  </li>
                ))}
              </ul>
            )}
          </div>
          <p className="text-xs text-muted-foreground">Blocked (below minimum): {analytics.blocked}</p>
        </div>
      )}

      {tab === 'maintenance' && settings && (
        <div className="glass-panel p-6 max-w-lg space-y-4">
          <label className="flex items-center gap-2 text-sm font-semibold">
            <input type="checkbox" checked={settings.maintenanceMode}
              onChange={(e) => setSettings({ ...settings, maintenanceMode: e.target.checked })} />
            Maintenance Mode
          </label>
          <label className="block">
            <span className="text-xs text-muted-foreground">Title</span>
            <input className="w-full mt-1 px-3 py-2 rounded-lg bg-secondary border border-border text-sm"
              value={settings.maintenanceTitle} onChange={(e) => setSettings({ ...settings, maintenanceTitle: e.target.value })} />
          </label>
          <label className="block">
            <span className="text-xs text-muted-foreground">Message</span>
            <textarea className="w-full mt-1 px-3 py-2 rounded-lg bg-secondary border border-border text-sm"
              value={settings.maintenanceMessage} onChange={(e) => setSettings({ ...settings, maintenanceMessage: e.target.value })} />
          </label>
          <label className="block">
            <span className="text-xs text-muted-foreground">Estimated duration (minutes)</span>
            <input type="number" min={0} className="w-full mt-1 px-3 py-2 rounded-lg bg-secondary border border-border text-sm"
              value={settings.maintenanceDurationMinutes}
              onChange={(e) => setSettings({ ...settings, maintenanceDurationMinutes: Number(e.target.value) })} />
          </label>
          <button type="button" disabled={saving} onClick={() => saveSettings(settings)}
            className="flex items-center gap-2 px-4 py-2 rounded-lg bg-amber-600 text-white text-sm font-semibold hover:bg-amber-500 disabled:opacity-50">
            <Save size={14} /> Save
          </button>
        </div>
      )}
    </div>
  );
}
