'use client';

import React from 'react';
import { Gift, Sparkles, Users } from 'lucide-react';
import PageHeader from '../ui/PageHeader';
import StatCard from '../ui/StatCard';
import DataTable from '../ui/DataTable';
import LiveDataBanner from '../LiveDataBanner';
import { useAdminQuery } from '../../lib/hooks/useAdminQuery';
import { engagementApi } from '../../lib/api/engagement';

interface GiftAnalytics {
  totalGiftsSent?: number;
  totalCoinsSpent?: number;
  totalRevenue?: number;
  topGifts?: { giftName: string; count: number; coins: number }[];
}

interface CombosOverview {
  totalCombos: number;
  comboClaims: number;
  premiumGifts: number;
  topGiftSenders: { userName: string; metric: number }[];
}

export default function GiftsAdminView() {
  const { data: analytics, loading: aLoading, isLive: aLive } = useAdminQuery<GiftAnalytics>(engagementApi.giftsAnalytics());
  const { data: combos, loading: cLoading, isLive: cLive } = useAdminQuery<CombosOverview>(engagementApi.combosOverview());

  const isLive = aLive && cLive;

  return (
    <div>
      <PageHeader title="Gifts" description="Gift statistics, premium gifts, and combo analytics" />
      <LiveDataBanner isLive={isLive} label="gifts" />

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <StatCard label="Total Gifts" value={(analytics as GiftAnalytics)?.totalGiftsSent ?? '—'} icon={Gift} />
        <StatCard label="Coins Spent" value={((analytics as GiftAnalytics)?.totalCoinsSpent ?? 0).toLocaleString()} icon={Sparkles} />
        <StatCard label="Premium Gifts" value={combos?.premiumGifts ?? '—'} icon={Gift} />
        <StatCard label="Combo Claims" value={combos?.comboClaims ?? '—'} icon={Sparkles} />
      </div>

      <h2 className="text-sm font-bold mb-3">Top Gift Senders</h2>
      <DataTable
        loading={cLoading}
        rows={combos?.topGiftSenders ?? []}
        rowKey={(r) => r.userName}
        columns={[
          { key: 'user', header: 'User', render: (r) => r.userName },
          { key: 'coins', header: 'Coins Spent', render: (r) => r.metric.toLocaleString() },
        ]}
      />

      {!aLoading && (analytics as GiftAnalytics)?.topGifts?.length ? (
        <>
          <h2 className="text-sm font-bold mt-6 mb-3">Top Gifts</h2>
          <DataTable
            rows={(analytics as GiftAnalytics).topGifts!}
            rowKey={(r) => r.giftName}
            columns={[
              { key: 'name', header: 'Gift', render: (r) => r.giftName },
              { key: 'count', header: 'Count', render: (r) => r.count.toLocaleString() },
              { key: 'coins', header: 'Coins', render: (r) => r.coins.toLocaleString() },
            ]}
          />
        </>
      ) : null}
    </div>
  );
}
