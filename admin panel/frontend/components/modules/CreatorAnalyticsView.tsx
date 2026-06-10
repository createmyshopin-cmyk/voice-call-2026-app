'use client';

import React, { useEffect, useState } from 'react';
import { TrendingUp, Gift, Phone, Users, Radio } from 'lucide-react';
import PageHeader from '../ui/PageHeader';
import StatCard from '../ui/StatCard';
import DataTable from '../ui/DataTable';
import TimeWindowTabs, { type TimeWindow } from '../ui/TimeWindowTabs';
import ModuleTabs from '../ui/ModuleTabs';
import CursorPagination from '../ui/CursorPagination';
import LiveDataBanner from '../LiveDataBanner';
import { analyticsApi } from '../../lib/api/analytics';
import { fetchJsonAuth } from '../../lib/api';

interface RankItem {
  creatorProfileId: string;
  creatorId: string;
  creatorName: string;
  metric: number;
  secondaryMetric?: number;
}

interface PaginatedRank {
  items: RankItem[];
  hasMore: boolean;
  nextCursor: string | null;
}

interface Overview {
  window: string;
  totalCreators: number;
  onlineCreators: number;
  totalEarnings: number;
  totalCalls: number;
  totalGifts: number;
}

const TABS = [
  { id: 'overview', label: 'Overview' },
  { id: 'earners', label: 'Top Earners' },
  { id: 'gifts', label: 'Top Gifts' },
  { id: 'calls', label: 'Top Calls' },
  { id: 'messages', label: 'Top Messages' },
  { id: 'online', label: 'Online' },
  { id: 'new', label: 'New' },
  { id: 'inactive', label: 'Inactive' },
];

export default function CreatorAnalyticsView() {
  const [tab, setTab] = useState('overview');
  const [window, setWindow] = useState<TimeWindow>('7d');
  const [overview, setOverview] = useState<Overview | null>(null);
  const [ranked, setRanked] = useState<RankItem[]>([]);
  const [hasMore, setHasMore] = useState(false);
  const [cursor, setCursor] = useState<string | undefined>();
  const [cursorStack, setCursorStack] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [isLive, setIsLive] = useState(false);

  const loadOverview = async () => {
    setLoading(true);
    const res = await fetchJsonAuth<Overview>(analyticsApi.creatorsOverview(window));
    if (res.ok) { setOverview(res.data as Overview); setIsLive(true); }
    else setIsLive(false);
    setLoading(false);
  };

  const loadRanked = async (nextCursor?: string, reset = false) => {
    setLoading(true);
    const endpoints: Record<string, string> = {
      earners: analyticsApi.topEarners(window, nextCursor),
      gifts: analyticsApi.topGifts(window, nextCursor),
      calls: analyticsApi.topCalls(window, nextCursor),
      messages: analyticsApi.topMessages(window, nextCursor),
      online: analyticsApi.online(nextCursor),
      new: analyticsApi.newCreators(window === 'lifetime' ? '30d' : window, nextCursor),
      inactive: analyticsApi.inactive(30, nextCursor),
    };
    const path = endpoints[tab];
    if (!path) return;
    const res = await fetchJsonAuth<PaginatedRank>(path);
    if (res.ok && res.data) {
      const data = res.data as PaginatedRank;
      setRanked(data.items ?? []);
      setHasMore(data.hasMore ?? false);
      setCursor(data.nextCursor ?? undefined);
      setIsLive(true);
      if (reset) setCursorStack([]);
    } else setIsLive(false);
    setLoading(false);
  };

  useEffect(() => {
    if (tab === 'overview') loadOverview();
    else loadRanked(undefined, true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tab, window]);

  const rankColumns = [
    { key: 'name', header: 'Creator', render: (r: RankItem) => <span className="font-semibold">{r.creatorName}</span> },
    { key: 'metric', header: 'Primary', render: (r: RankItem) => <span className="tabular-nums font-mono">{r.metric.toLocaleString()}</span> },
    {
      key: 'secondary',
      header: 'Secondary',
      render: (r: RankItem) => (
        <span className="tabular-nums text-muted-foreground">
          {r.secondaryMetric != null ? r.secondaryMetric.toLocaleString() : '—'}
        </span>
      ),
    },
  ];

  return (
    <div>
      <PageHeader
        title="Creator Analytics"
        description="Performance metrics across calls, gifts, and messages"
        actions={<TimeWindowTabs value={window} onChange={setWindow} />}
      />
      <LiveDataBanner isLive={isLive} label="creator analytics" />
      <ModuleTabs tabs={TABS} active={tab} onChange={setTab} />

      {tab === 'overview' && (
        <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
          <StatCard label="Total Creators" value={overview?.totalCreators ?? '—'} icon={Users} />
          <StatCard label="Online Now" value={overview?.onlineCreators ?? '—'} icon={Radio} />
          <StatCard label="Earnings" value={(overview?.totalEarnings ?? 0).toLocaleString()} icon={TrendingUp} sub={`${window} window`} />
          <StatCard label="Calls" value={(overview?.totalCalls ?? 0).toLocaleString()} icon={Phone} />
          <StatCard label="Gifts" value={(overview?.totalGifts ?? 0).toLocaleString()} icon={Gift} />
          <StatCard label="Window" value={window.toUpperCase()} sub="Analytics period" />
        </div>
      )}

      {tab !== 'overview' && (
        <>
          <DataTable columns={rankColumns} rows={ranked} loading={loading} rowKey={(r) => r.creatorProfileId} />
          <CursorPagination
            hasMore={hasMore}
            canPrev={cursorStack.length > 0}
            onNext={() => {
              if (cursor) {
                setCursorStack((s) => [...s, cursor]);
                loadRanked(cursor);
              }
            }}
            onPrev={() => {
              const stack = [...cursorStack];
              stack.pop();
              const prev = stack[stack.length - 1];
              setCursorStack(stack);
              loadRanked(prev, false);
            }}
          />
        </>
      )}
    </div>
  );
}
