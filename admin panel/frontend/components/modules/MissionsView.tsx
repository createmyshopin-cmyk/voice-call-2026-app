'use client';

import React from 'react';
import { Target, Coins } from 'lucide-react';
import PageHeader from '../ui/PageHeader';
import StatCard from '../ui/StatCard';
import DataTable from '../ui/DataTable';
import LiveDataBanner from '../LiveDataBanner';
import { useAdminQuery } from '../../lib/hooks/useAdminQuery';
import { engagementApi } from '../../lib/api/engagement';

interface MissionsOverview {
  claimsToday: number;
  totalRewardCoins: number;
  topMissionUsers: { userName: string; metric: number }[];
}

export default function MissionsView() {
  const { data, loading, isLive } = useAdminQuery<MissionsOverview>(engagementApi.missionsOverview());

  return (
    <div>
      <PageHeader title="Missions" description="Claims, rewards, and top mission users" />
      <LiveDataBanner isLive={isLive} label="missions" />
      <div className="grid grid-cols-2 gap-4 mb-6">
        <StatCard label="Claims Today" value={data?.claimsToday ?? '—'} icon={Target} />
        <StatCard label="Reward Coins" value={(data?.totalRewardCoins ?? 0).toLocaleString()} icon={Coins} />
      </div>
      <h2 className="text-sm font-bold mb-3">Top Mission Users</h2>
      <DataTable
        loading={loading}
        rows={data?.topMissionUsers ?? []}
        rowKey={(r) => r.userName}
        columns={[
          { key: 'user', header: 'User', render: (r) => r.userName },
          { key: 'coins', header: 'Coins Earned', render: (r) => r.metric.toLocaleString() },
        ]}
      />
    </div>
  );
}
