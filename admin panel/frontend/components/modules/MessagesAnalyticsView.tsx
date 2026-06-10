'use client';

import React from 'react';
import { MessageSquare, Mic, Users } from 'lucide-react';
import PageHeader from '../ui/PageHeader';
import StatCard from '../ui/StatCard';
import DataTable from '../ui/DataTable';
import LiveDataBanner from '../LiveDataBanner';
import { useAdminQuery } from '../../lib/hooks/useAdminQuery';
import { engagementApi } from '../../lib/api/engagement';

interface MessagesOverview {
  revenue30d: number;
  totalConversations: number;
  voiceMessages: number;
  textMessages: number;
  topCreators: { creatorName: string; revenue: number }[];
  topUsers: { userName: string; metric: number }[];
}

export default function MessagesAnalyticsView() {
  const { data, loading, isLive } = useAdminQuery<MessagesOverview>(engagementApi.messagesOverview());

  return (
    <div>
      <PageHeader title="Paid Messages" description="Revenue, conversations, and top performers (30d)" />
      <LiveDataBanner isLive={isLive} label="paid messages" />

      <div className="grid grid-cols-2 lg:grid-cols-5 gap-4 mb-6">
        <StatCard label="Revenue (30d)" value={(data?.revenue30d ?? 0).toLocaleString()} icon={MessageSquare} />
        <StatCard label="Conversations" value={data?.totalConversations ?? '—'} icon={Users} />
        <StatCard label="Voice" value={data?.voiceMessages ?? '—'} icon={Mic} />
        <StatCard label="Text" value={data?.textMessages ?? '—'} icon={MessageSquare} />
      </div>

      <div className="grid lg:grid-cols-2 gap-6">
        <div>
          <h2 className="text-sm font-bold mb-3">Top Creators</h2>
          <DataTable
            loading={loading}
            rows={data?.topCreators ?? []}
            rowKey={(r) => r.creatorName}
            columns={[
              { key: 'name', header: 'Creator', render: (r) => r.creatorName },
              { key: 'rev', header: 'Revenue', render: (r) => r.revenue.toLocaleString() },
            ]}
          />
        </div>
        <div>
          <h2 className="text-sm font-bold mb-3">Top Users</h2>
          <DataTable
            loading={loading}
            rows={data?.topUsers ?? []}
            rowKey={(r) => r.userName}
            columns={[
              { key: 'name', header: 'User', render: (r) => r.userName },
              { key: 'spent', header: 'Spent', render: (r) => r.metric.toLocaleString() },
            ]}
          />
        </div>
      </div>
    </div>
  );
}
