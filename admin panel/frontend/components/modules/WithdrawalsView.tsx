'use client';

import React, { useCallback, useEffect, useState } from 'react';
import { Download, Search } from 'lucide-react';
import PageHeader from '../ui/PageHeader';
import ModuleTabs from '../ui/ModuleTabs';
import DataTable from '../ui/DataTable';
import CursorPagination from '../ui/CursorPagination';
import LiveDataBanner from '../LiveDataBanner';
import { withdrawalsApi, normalizeWithdrawalList, type WithdrawalStatus } from '../../lib/api/withdrawals';
import { downloadCsv } from '../../lib/api/analytics';
import { fetchJsonAuth } from '../../lib/api';

interface Withdrawal {
  id: string;
  creatorId: string;
  amount: number;
  status: string;
  requestedAt: string;
  paidAt?: string;
  paymentReference?: string;
}

interface PaginatedWithdrawals {
  items: Withdrawal[];
  hasMore: boolean;
  nextCursor: string | null;
}

const STATUS_TABS: { id: WithdrawalStatus | 'all'; label: string }[] = [
  { id: 'pending', label: 'Pending' },
  { id: 'approved', label: 'Approved' },
  { id: 'paid', label: 'Paid' },
  { id: 'rejected', label: 'Rejected' },
  { id: 'failed', label: 'Failed' },
  { id: 'cancelled', label: 'Cancelled' },
];

export default function WithdrawalsView() {
  const [status, setStatus] = useState<WithdrawalStatus>('pending');
  const [items, setItems] = useState<Withdrawal[]>([]);
  const [hasMore, setHasMore] = useState(false);
  const [cursor, setCursor] = useState<string | undefined>();
  const [cursorStack, setCursorStack] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [isLive, setIsLive] = useState(false);
  const [search, setSearch] = useState('');
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');

  const load = useCallback(async (nextCursor?: string, reset = false) => {
    setLoading(true);
    const path = withdrawalsApi.list({
      status,
      cursor: nextCursor,
      limit: 20,
      search: search || undefined,
      from: from || undefined,
      to: to || undefined,
    });
    const res = await fetchJsonAuth<PaginatedWithdrawals>(path);
    if (res.ok && res.data) {
      const paginated = normalizeWithdrawalList(res.data);
      setItems(paginated.items as unknown as Withdrawal[]);
      setHasMore(paginated.hasMore);
      setCursor(paginated.nextCursor ?? undefined);
      setIsLive(true);
      if (reset) setCursorStack([]);
    } else setIsLive(false);
    setLoading(false);
  }, [status, search, from, to]);

  useEffect(() => { load(undefined, true); }, [load]);

  const columns = [
    { key: 'id', header: 'ID', render: (w: Withdrawal) => <span className="font-mono text-[10px]">{w.id.slice(0, 8)}…</span> },
    { key: 'creator', header: 'Creator', render: (w: Withdrawal) => <span className="font-mono text-[10px]">{w.creatorId.slice(0, 8)}…</span> },
    { key: 'amount', header: 'Amount', render: (w: Withdrawal) => <span className="font-bold tabular-nums">{w.amount.toLocaleString()}</span> },
    { key: 'status', header: 'Status', render: (w: Withdrawal) => (
      <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase ${
        w.status === 'pending' ? 'bg-amber-500/20 text-amber-400' :
        w.status === 'paid' ? 'bg-emerald-500/20 text-emerald-400' :
        w.status === 'rejected' ? 'bg-red-500/20 text-red-400' :
        'bg-secondary text-muted-foreground'
      }`}>{w.status}</span>
    )},
    { key: 'requested', header: 'Requested', render: (w: Withdrawal) => new Date(w.requestedAt).toLocaleString() },
    { key: 'ref', header: 'Reference', render: (w: Withdrawal) => w.paymentReference ?? '—' },
  ];

  return (
    <div>
      <PageHeader
        title="Withdrawals"
        description="Payout requests with cursor pagination and CSV export"
        actions={
          <button
            type="button"
            onClick={() => downloadCsv(withdrawalsApi.export({ status, from, to }), `withdrawals-${status}.csv`)}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-indigo-600 text-white text-xs font-semibold hover:bg-indigo-500"
          >
            <Download size={14} /> Export CSV
          </button>
        }
      />
      <LiveDataBanner isLive={isLive} label="withdrawals" />
      <ModuleTabs tabs={STATUS_TABS} active={status} onChange={(id) => setStatus(id as WithdrawalStatus)} />

      <div className="flex flex-wrap gap-3 mb-4">
        <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg border border-border bg-card">
          <Search size={14} className="text-muted-foreground" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search ID, creator, reference…"
            className="bg-transparent text-xs outline-none w-48"
          />
        </div>
        <input type="date" value={from} onChange={(e) => setFrom(e.target.value)} className="px-2 py-1.5 rounded-lg border border-border bg-card text-xs" />
        <input type="date" value={to} onChange={(e) => setTo(e.target.value)} className="px-2 py-1.5 rounded-lg border border-border bg-card text-xs" />
        <button type="button" onClick={() => load(undefined, true)} className="px-3 py-1.5 rounded-lg border border-border text-xs font-semibold hover:bg-secondary/50">Apply</button>
      </div>

      <DataTable columns={columns} rows={items} loading={loading} rowKey={(w) => w.id} />
      <CursorPagination
        hasMore={hasMore}
        canPrev={cursorStack.length > 0}
        onNext={() => { if (cursor) { setCursorStack((s) => [...s, cursor]); load(cursor); } }}
        onPrev={() => {
          const stack = [...cursorStack];
          stack.pop();
          setCursorStack(stack);
          load(stack[stack.length - 1], false);
        }}
      />
    </div>
  );
}
