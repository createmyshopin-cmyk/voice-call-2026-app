'use client';

import React from 'react';
import { Phone, Users, UserCheck, CreditCard, Wallet, AlertTriangle } from 'lucide-react';
import PageHeader from '../ui/PageHeader';
import StatCard from '../ui/StatCard';
import DataTable from '../ui/DataTable';
import LiveDataBanner from '../LiveDataBanner';
import { useAdminQuery } from '../../lib/hooks/useAdminQuery';
import { operationsApi } from '../../lib/api/operations';

interface OpsSnapshot {
  timestamp: string;
  liveCalls: number;
  onlineCreators: number;
  activeUsers: number;
  pendingPayments: number;
  pendingWithdrawals: number;
  openFindings: number;
  alerts: { check_id: string; severity: string; entity_type: string; last_seen_at: string }[];
  recentPayments: { id: string; amount_inr: number; status: string; created_at: string }[];
  recentWithdrawals: { id: string; amount: number; status: string; created_at: string }[];
}

export default function OperationsCenterView() {
  const { data, loading, isLive } = useAdminQuery<OpsSnapshot>(
    operationsApi.snapshot(),
    { pollIntervalMs: 30000 },
  );

  return (
    <div>
      <PageHeader
        title="Operations Center"
        description="Live platform snapshot — refreshes every 30s"
        actions={
          data?.timestamp ? (
            <span className="text-[10px] text-muted-foreground">
              Updated {new Date(data.timestamp).toLocaleTimeString()}
            </span>
          ) : null
        }
      />
      <LiveDataBanner isLive={isLive} label="operations center" />

      <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4 mb-6">
        <StatCard label="Live Calls" value={data?.liveCalls ?? '—'} icon={Phone} />
        <StatCard label="Online Creators" value={data?.onlineCreators ?? '—'} icon={UserCheck} />
        <StatCard label="Active Users" value={data?.activeUsers ?? '—'} icon={Users} />
        <StatCard label="Pending Payments" value={data?.pendingPayments ?? '—'} icon={CreditCard} />
        <StatCard label="Pending Withdrawals" value={data?.pendingWithdrawals ?? '—'} icon={Wallet} />
        <StatCard label="Open Findings" value={data?.openFindings ?? '—'} icon={AlertTriangle} />
      </div>

      <div className="grid lg:grid-cols-2 gap-6">
        <div>
          <h2 className="text-sm font-bold mb-3">P0/P1 Alerts</h2>
          <DataTable
            loading={loading}
            rows={data?.alerts ?? []}
            rowKey={(a) => a.check_id + a.last_seen_at}
            emptyMessage="No active P0/P1 alerts"
            columns={[
              { key: 'check', header: 'Check', render: (a) => a.check_id },
              { key: 'sev', header: 'Severity', render: (a) => (
                <span className={a.severity === 'P0' ? 'text-red-400 font-bold' : 'text-amber-400'}>{a.severity}</span>
              )},
              { key: 'entity', header: 'Entity', render: (a) => a.entity_type },
              { key: 'time', header: 'Seen', render: (a) => new Date(a.last_seen_at).toLocaleString() },
            ]}
          />
        </div>
        <div>
          <h2 className="text-sm font-bold mb-3">Recent Withdrawals (1h)</h2>
          <DataTable
            loading={loading}
            rows={data?.recentWithdrawals ?? []}
            rowKey={(w) => w.id}
            columns={[
              { key: 'amount', header: 'Amount', render: (w) => w.amount.toLocaleString() },
              { key: 'status', header: 'Status', render: (w) => w.status },
              { key: 'time', header: 'Time', render: (w) => new Date(w.created_at).toLocaleString() },
            ]}
          />
        </div>
      </div>
    </div>
  );
}
