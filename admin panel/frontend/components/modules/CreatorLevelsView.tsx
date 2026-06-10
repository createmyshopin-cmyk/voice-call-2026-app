'use client';

import React from 'react';
import { Award, BarChart3 } from 'lucide-react';
import PageHeader from '../ui/PageHeader';
import StatCard from '../ui/StatCard';
import DataTable from '../ui/DataTable';
import MiniChart from '../ui/MiniChart';
import LiveDataBanner from '../LiveDataBanner';
import { useAdminQuery } from '../../lib/hooks/useAdminQuery';
import { engagementApi } from '../../lib/api/engagement';

interface LevelsData {
  distribution: { level: number; count: number }[];
  topXpCreators: { creatorName: string; totalXp: number; level: number }[];
}

export default function CreatorLevelsView() {
  const { data, loading, isLive } = useAdminQuery<LevelsData>(engagementApi.levelsDistribution());
  const chartData = (data?.distribution ?? []).map((d) => d.count);
  const totalCreators = chartData.reduce((a, b) => a + b, 0);

  return (
    <div>
      <PageHeader title="Creator Levels" description="XP distribution and top creators" />
      <LiveDataBanner isLive={isLive} label="creator levels" />
      <div className="grid grid-cols-2 gap-4 mb-6">
        <StatCard label="Leveled Creators" value={totalCreators || '—'} icon={Award} />
        <StatCard label="Max Level" value={Math.max(...(data?.distribution?.map((d) => d.level) ?? [1]), 1)} icon={BarChart3} />
      </div>
      {chartData.length > 0 && (
        <div className="rounded-xl border border-border bg-card p-4 mb-6">
          <h2 className="text-xs font-bold text-muted-foreground mb-2 uppercase">Level Distribution</h2>
          <MiniChart data={chartData} height={64} />
        </div>
      )}
      <h2 className="text-sm font-bold mb-3">Top XP Creators</h2>
      <DataTable
        loading={loading}
        rows={data?.topXpCreators ?? []}
        rowKey={(r) => r.creatorName}
        columns={[
          { key: 'name', header: 'Creator', render: (r) => r.creatorName },
          { key: 'level', header: 'Level', render: (r) => r.level },
          { key: 'xp', header: 'Total XP', render: (r) => r.totalXp.toLocaleString() },
        ]}
      />
    </div>
  );
}
