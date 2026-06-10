'use client';

import React, { useState } from 'react';
import { Heart, UserPlus } from 'lucide-react';
import PageHeader from '../ui/PageHeader';
import ModuleTabs from '../ui/ModuleTabs';
import DataTable from '../ui/DataTable';
import LiveDataBanner from '../LiveDataBanner';
import { useAdminQuery } from '../../lib/hooks/useAdminQuery';
import { engagementApi } from '../../lib/api/engagement';

interface Leaderboard {
  type: string;
  items: { creatorProfileId: string; creatorName: string; count: number }[];
}

const TABS = [
  { id: 'follows', label: 'Most Followed' },
  { id: 'favorites', label: 'Most Favorited' },
];

export default function FollowFavoriteView() {
  const [type, setType] = useState<'follows' | 'favorites'>('follows');
  const { data, loading, isLive } = useAdminQuery<Leaderboard>(
    engagementApi.followsLeaderboard(type),
  );

  return (
    <div>
      <PageHeader title="Follow & Favorite" description="Creator leaderboards" />
      <LiveDataBanner isLive={isLive} label="follow & favorite" />
      <ModuleTabs tabs={TABS} active={type} onChange={(id) => setType(id as 'follows' | 'favorites')} />
      <DataTable
        loading={loading}
        rows={data?.items ?? []}
        rowKey={(r) => r.creatorProfileId}
        columns={[
          { key: 'name', header: 'Creator', render: (r) => r.creatorName },
          { key: 'count', header: type === 'follows' ? 'Followers' : 'Favorites', render: (r) => r.count.toLocaleString() },
        ]}
      />
    </div>
  );
}
