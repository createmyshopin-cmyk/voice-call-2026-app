'use client';

import React from 'react';
import { Activity, Server, Gauge } from 'lucide-react';
import PageHeader from '../ui/PageHeader';
import StatCard from '../ui/StatCard';
import LiveDataBanner from '../LiveDataBanner';
import { useAdminQuery } from '../../lib/hooks/useAdminQuery';
import { operationsApi } from '../../lib/api/operations';

interface HealthResponse {
  status: string;
  checks?: Record<string, { ok: boolean; latency_ms?: number }>;
}

interface SlosResponse {
  slos?: { name: string; target: number; current: number; status: string }[];
}

export default function SystemHealthView() {
  const { data: health, isLive: hLive } = useAdminQuery<HealthResponse>(operationsApi.ready());
  const { data: slos, isLive: sLive } = useAdminQuery<SlosResponse>(operationsApi.slos());

  return (
    <div>
      <PageHeader title="System Health" description="Health, readiness, SLOs, and observability" />
      <LiveDataBanner isLive={hLive && sLive} label="system health" />

      <div className="grid grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
        <StatCard label="Status" value={health?.status ?? 'unknown'} icon={Activity} />
        <StatCard
          label="Supabase"
          value={health?.checks?.supabase?.ok ? 'OK' : 'Degraded'}
          sub={health?.checks?.supabase?.latency_ms != null ? `${health.checks.supabase.latency_ms}ms` : undefined}
          icon={Server}
        />
        <StatCard label="SLOs" value={slos?.slos?.length ?? '—'} icon={Gauge} />
      </div>

      {slos?.slos?.length ? (
        <div className="rounded-xl border border-border bg-card overflow-hidden">
          <table className="w-full text-xs">
            <thead>
              <tr className="border-b border-border bg-secondary/30">
                <th className="text-left px-4 py-3 font-semibold text-muted-foreground">SLO</th>
                <th className="text-left px-4 py-3 font-semibold text-muted-foreground">Target</th>
                <th className="text-left px-4 py-3 font-semibold text-muted-foreground">Current</th>
                <th className="text-left px-4 py-3 font-semibold text-muted-foreground">Status</th>
              </tr>
            </thead>
            <tbody>
              {slos.slos.map((s) => (
                <tr key={s.name} className="border-b border-border/50">
                  <td className="px-4 py-3">{s.name}</td>
                  <td className="px-4 py-3 tabular-nums">{(s.target * 100).toFixed(1)}%</td>
                  <td className="px-4 py-3 tabular-nums">{(s.current * 100).toFixed(1)}%</td>
                  <td className="px-4 py-3">
                    <span className={s.status === 'ok' ? 'text-emerald-400' : 'text-amber-400'}>{s.status}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : null}
    </div>
  );
}
