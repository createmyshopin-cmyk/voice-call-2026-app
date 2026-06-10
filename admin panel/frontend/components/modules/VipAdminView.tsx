'use client';

import React from 'react';
import { Crown, RefreshCw, Clock, Coins } from 'lucide-react';
import PageHeader from '../ui/PageHeader';
import StatCard from '../ui/StatCard';
import DataTable from '../ui/DataTable';
import LiveDataBanner from '../LiveDataBanner';
import { useAdminQuery } from '../../lib/hooks/useAdminQuery';
import { engagementApi } from '../../lib/api/engagement';

interface VipOverview {
  plans: { id: string; name: string; tier: string; price_coins: number; duration_days: number }[];
  activeSubscriptions: number;
  expiringWithin7Days: number;
  totalRevenue: number;
}

export default function VipAdminView() {
  const { data, loading, isLive } = useAdminQuery<VipOverview>(engagementApi.vipOverview());

  return (
    <div>
      <PageHeader title="VIP Membership" description="Plans, subscriptions, renewals, and revenue" />
      <LiveDataBanner isLive={isLive} label="VIP membership" />

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <StatCard label="Active" value={data?.activeSubscriptions ?? '—'} icon={Crown} />
        <StatCard label="Expiring (7d)" value={data?.expiringWithin7Days ?? '—'} icon={Clock} />
        <StatCard label="Revenue" value={(data?.totalRevenue ?? 0).toLocaleString()} icon={Coins} />
        <StatCard label="Plans" value={data?.plans?.length ?? '—'} icon={RefreshCw} />
      </div>

      <h2 className="text-sm font-bold mb-3">Plans</h2>
      <DataTable
        loading={loading}
        rows={data?.plans ?? []}
        rowKey={(p) => p.id}
        columns={[
          { key: 'name', header: 'Plan', render: (p) => p.name },
          { key: 'tier', header: 'Tier', render: (p) => p.tier },
          { key: 'price', header: 'Price (coins)', render: (p) => p.price_coins.toLocaleString() },
          { key: 'days', header: 'Duration', render: (p) => `${p.duration_days}d` },
        ]}
      />
    </div>
  );
}
