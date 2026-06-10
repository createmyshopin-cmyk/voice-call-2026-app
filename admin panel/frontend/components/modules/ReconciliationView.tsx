'use client';

import React, { useState } from 'react';
import { AlertTriangle, CheckCircle, Shield, Play } from 'lucide-react';
import PageHeader from '../ui/PageHeader';
import ModuleTabs from '../ui/ModuleTabs';
import StatCard from '../ui/StatCard';
import DataTable from '../ui/DataTable';
import LiveDataBanner from '../LiveDataBanner';
import { useAdminQuery } from '../../lib/hooks/useAdminQuery';
import { reconciliationApi } from '../../lib/api/reconciliation';
import { getHeaders } from '../../lib/api';

interface Finding {
  id: string;
  checkId: string;
  tier: string;
  severity: string;
  status: string;
  entityType: string | null;
  entityId: string | null;
  lastSeenAt: string;
}

interface Health {
  openFindings: number;
  p0Count: number;
  p1Count: number;
  frozenWallets: number;
  lastRunByTier?: Record<string, string>;
}

const TIER_TABS = [
  { id: 'all', label: 'All Findings' },
  { id: 'P0', label: 'P0' },
  { id: 'P1', label: 'P1' },
  { id: 'T5', label: 'T5' },
  { id: 'T6', label: 'T6' },
  { id: 'T7', label: 'T7' },
  { id: 'T8', label: 'T8' },
];

export default function ReconciliationView() {
  const [filter, setFilter] = useState('all');
  const { data: health, isLive: hLive } = useAdminQuery<Health>(reconciliationApi.health());
  const severity = filter === 'P0' || filter === 'P1' ? filter : undefined;
  const tier = ['T5', 'T6', 'T7', 'T8'].includes(filter) ? filter : undefined;
  const findingsPath = reconciliationApi.findings({
    severity,
    check_id: tier ? undefined : undefined,
    limit: 50,
    status: 'open',
  });
  const { data: findings, loading, isLive: fLive, refresh } = useAdminQuery<Finding[]>(findingsPath);

  const filtered = (findings ?? []).filter((f) => {
    if (tier) return f.tier === tier;
    return true;
  });

  const runTier = async (tierName: string) => {
    await fetch(reconciliationApi.runNow(), {
      method: 'POST',
      headers: getHeaders(),
      body: JSON.stringify({ tier: tierName }),
    });
    refresh();
  };

  return (
    <div>
      <PageHeader
        title="Reconciliation"
        description="T5–T8 drift checks, findings, freeze flags"
        actions={
          <div className="flex gap-2">
            {['T5', 'T6', 'T7', 'T8'].map((t) => (
              <button
                key={t}
                type="button"
                onClick={() => runTier(t)}
                className="flex items-center gap-1 px-2 py-1 rounded-lg border border-border text-[10px] font-bold hover:bg-secondary/50"
              >
                <Play size={10} /> {t}
              </button>
            ))}
          </div>
        }
      />
      <LiveDataBanner isLive={hLive && fLive} label="reconciliation" />

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <StatCard label="Open Findings" value={health?.openFindings ?? '—'} icon={AlertTriangle} />
        <StatCard label="P0" value={health?.p0Count ?? '—'} icon={Shield} />
        <StatCard label="P1" value={health?.p1Count ?? '—'} icon={AlertTriangle} />
        <StatCard label="Frozen Wallets" value={health?.frozenWallets ?? '—'} icon={CheckCircle} />
      </div>

      <ModuleTabs tabs={TIER_TABS} active={filter} onChange={setFilter} />
      <DataTable
        loading={loading}
        rows={filtered}
        rowKey={(f) => f.id}
        columns={[
          { key: 'check', header: 'Check', render: (f) => <span className="font-mono text-[10px]">{f.checkId}</span> },
          { key: 'tier', header: 'Tier', render: (f) => f.tier },
          {
            key: 'severity',
            header: 'Severity',
            render: (f) => (
              <span className={`font-bold ${f.severity === 'P0' ? 'text-red-400' : f.severity === 'P1' ? 'text-amber-400' : ''}`}>
                {f.severity}
              </span>
            ),
          },
          { key: 'entity', header: 'Entity', render: (f) => `${f.entityType ?? '—'} / ${f.entityId?.slice(0, 8) ?? '—'}` },
          { key: 'seen', header: 'Last Seen', render: (f) => new Date(f.lastSeenAt).toLocaleString() },
        ]}
      />
    </div>
  );
}
