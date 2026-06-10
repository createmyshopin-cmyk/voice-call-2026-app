'use client';

import React from 'react';
import { Flame, Coins } from 'lucide-react';
import PageHeader from '../ui/PageHeader';
import StatCard from '../ui/StatCard';
import DataTable from '../ui/DataTable';
import LiveDataBanner from '../LiveDataBanner';
import { useAdminQuery } from '../../lib/hooks/useAdminQuery';
import { engagementApi } from '../../lib/api/engagement';

interface StreaksOverview {
  activeStreaks: number;
  streakRewardCoins: number;
  longestStreaks: { userName: string; metric: number; secondaryMetric?: number }[];
}

export default function StreaksView() {
  const { data, loading, isLive } = useAdminQuery<StreaksOverview>(engagementApi.streaksOverview());

  return (
    <div>
      <PageHeader title="Streaks" description="Longest streaks, rewards, and retention metrics" />
      <LiveDataBanner isLive={isLive} label="streaks" />
      <div className="grid grid-cols-2 gap-4 mb-6">
        <StatCard label="Active Streaks" value={data?.activeStreaks ?? '—'} icon={Flame} />
        <StatCard label="Reward Coins" value={(data?.streakRewardCoins ?? 0).toLocaleString()} icon={Coins} />
      </div>
      <h2 className="text-sm font-bold mb-3">Longest Streaks</h2>
      <DataTable
        loading={loading}
        rows={data?.longestStreaks ?? []}
        rowKey={(r) => r.userName}
        columns={[
          { key: 'user', header: 'User', render: (r) => r.userName },
          { key: 'longest', header: 'Longest', render: (r) => r.metric },
          { key: 'current', header: 'Current', render: (r) => r.secondaryMetric ?? '—' },
        ]}
      />
    </div>
  );
}
