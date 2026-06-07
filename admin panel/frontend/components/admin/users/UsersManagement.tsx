'use client';

import React, { useCallback, useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import {
  Search,
  ChevronLeft,
  ChevronRight,
  Users,
  Eye,
  ArrowLeft,
} from 'lucide-react';
import {
  AdminUserListItem,
  AdminUsersListResponse,
  fetchAdminUsers,
  formatDate,
  ListUsersParams,
} from '../../../lib/adminUsers';
import { API_BASE, connectionErrorMessage, classifyApiFailure } from '../../../lib/api';
import LiveDataBanner from '../../LiveDataBanner';
import UserAvatar from './UserAvatar';
import { TableSkeleton } from './TableSkeleton';

const PAGE_SIZE = 20;

type SortField = NonNullable<ListUsersParams['sortBy']>;

export default function UsersManagement({ embedded }: { embedded?: boolean }) {
  const router = useRouter();
  const [users, setUsers] = useState<AdminUserListItem[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [searchInput, setSearchInput] = useState('');
  const [search, setSearch] = useState('');
  const [gender, setGender] = useState<ListUsersParams['gender']>('all');
  const [status, setStatus] = useState<ListUsersParams['status']>('all');
  const [onboarding, setOnboarding] =
    useState<ListUsersParams['onboarding']>('all');
  const [isCreator, setIsCreator] =
    useState<ListUsersParams['isCreator']>('all');
  const [sortBy, setSortBy] = useState<SortField>('createdAt');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');
  const [loading, setLoading] = useState(true);
  const [isLive, setIsLive] = useState(false);
  const [loadError, setLoadError] = useState<string | undefined>();

  useEffect(() => {
    const t = setTimeout(() => {
      setSearch(searchInput);
      setPage(1);
    }, 300);
    return () => clearTimeout(t);
  }, [searchInput]);

  const loadUsers = useCallback(async () => {
    setLoading(true);
    setLoadError(undefined);
    const res = await fetchAdminUsers({
      page,
      limit: PAGE_SIZE,
      search,
      gender,
      status,
      onboarding,
      sortBy,
      sortOrder,
      isCreator,
    });

    if (res.ok && res.data) {
      const payload = res.data as AdminUsersListResponse;
      setUsers(payload.users ?? []);
      setTotal(payload.total ?? 0);
      setIsLive(true);
      setLoading(false);
      return;
    }

    setUsers([]);
    setTotal(0);
    setIsLive(false);
    setLoadError(
      res.status
        ? connectionErrorMessage(classifyApiFailure(res.status))
        : connectionErrorMessage('network'),
    );
    setLoading(false);
  }, [page, search, gender, status, onboarding, sortBy, sortOrder, isCreator]);

  useEffect(() => {
    loadUsers();
  }, [loadUsers]);

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  const toggleSort = (field: SortField) => {
    if (sortBy === field) {
      setSortOrder((o) => (o === 'asc' ? 'desc' : 'asc'));
    } else {
      setSortBy(field);
      setSortOrder('desc');
    }
    setPage(1);
  };

  const sortIndicator = (field: SortField) =>
    sortBy === field ? (sortOrder === 'asc' ? ' ↑' : ' ↓') : '';

  return (
    <div className="space-y-6 max-w-[1400px] mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          {!embedded && (
            <Link
              href="/"
              className="inline-flex items-center gap-1.5 text-xs text-muted-foreground hover:text-foreground mb-3"
            >
              <ArrowLeft size={14} />
              Back to console
            </Link>
          )}
          <h1 className="text-2xl sm:text-3xl font-bold tracking-tight text-foreground flex items-center gap-2">
            <Users className="text-indigo-400" size={28} />
            Users Management
          </h1>
          <p className="text-sm text-muted-foreground mt-1">
            Full names, creator roles, wallet balances, and call activity.
          </p>
        </div>
        <div className="text-xs text-muted-foreground font-medium">
          {total.toLocaleString()} users total
        </div>
      </div>

      <LiveDataBanner
        isLive={isLive}
        label="users"
        errorMessage={loadError}
        apiBase={API_BASE}
      />

      <div className="glass-panel rounded-xl p-4 flex flex-col lg:flex-row gap-4 lg:items-center lg:justify-between">
        <div className="relative flex-1 max-w-md">
          <Search
            size={16}
            className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground"
          />
          <input
            type="search"
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            placeholder="Search name, phone, or user ID…"
            className="w-full pl-9 pr-4 py-2.5 text-xs bg-background border border-border rounded-lg text-foreground focus:outline-none focus:ring-1 focus:ring-indigo-500"
          />
        </div>

        <div className="flex flex-wrap gap-2">
          <FilterSelect
            label="Gender"
            value={gender ?? 'all'}
            options={[
              { value: 'all', label: 'All' },
              { value: 'male', label: 'Male' },
              { value: 'female', label: 'Female' },
            ]}
            onChange={(v) => {
              setGender(v as ListUsersParams['gender']);
              setPage(1);
            }}
          />
          <FilterSelect
            label="Status"
            value={status ?? 'all'}
            options={[
              { value: 'all', label: 'All' },
              { value: 'online', label: 'Online' },
              { value: 'offline', label: 'Offline' },
            ]}
            onChange={(v) => {
              setStatus(v as ListUsersParams['status']);
              setPage(1);
            }}
          />
          <FilterSelect
            label="Onboarding"
            value={onboarding ?? 'all'}
            options={[
              { value: 'all', label: 'All' },
              { value: 'completed', label: 'Completed' },
              { value: 'not_completed', label: 'Not Completed' },
            ]}
            onChange={(v) => {
              setOnboarding(v as ListUsersParams['onboarding']);
              setPage(1);
            }}
          />
          <FilterSelect
            label="Creator"
            value={isCreator ?? 'all'}
            options={[
              { value: 'all', label: 'All users' },
              { value: 'listener', label: 'Active creators' },
              { value: 'non_listener', label: 'Users only' },
            ]}
            onChange={(v) => {
              setIsCreator(v as ListUsersParams['isCreator']);
              setPage(1);
            }}
          />
        </div>
      </div>

      <div className="glass-panel rounded-2xl overflow-hidden border border-border">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="border-b border-border bg-secondary/30 text-muted-foreground">
                <th className="p-4 font-semibold">Avatar</th>
                <th
                  className="p-4 font-semibold cursor-pointer select-none"
                  onClick={() => toggleSort('fullName')}
                >
                  Full Name{sortIndicator('fullName')}
                </th>
                <th className="p-4 font-semibold hidden sm:table-cell">Role</th>
                <th className="p-4 font-semibold hidden md:table-cell">Gender</th>
                <th className="p-4 font-semibold hidden lg:table-cell">Age</th>
                <th className="p-4 font-semibold hidden xl:table-cell">Phone</th>
                <th
                  className="p-4 font-semibold text-right cursor-pointer select-none"
                  onClick={() => toggleSort('coins')}
                >
                  Coins{sortIndicator('coins')}
                </th>
                <th
                  className="p-4 font-semibold text-right cursor-pointer select-none hidden sm:table-cell"
                  onClick={() => toggleSort('totalCalls')}
                >
                  Calls{sortIndicator('totalCalls')}
                </th>
                <th className="p-4 font-semibold">Status</th>
                <th
                  className="p-4 font-semibold hidden md:table-cell cursor-pointer select-none"
                  onClick={() => toggleSort('createdAt')}
                >
                  Created{sortIndicator('createdAt')}
                </th>
                <th className="p-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border/80">
              {loading ? (
                <tr>
                  <td colSpan={11}>
                    <TableSkeleton rows={6} />
                  </td>
                </tr>
              ) : users.length === 0 ? (
                <tr>
                  <td colSpan={11} className="p-12 text-center">
                    <Users
                      size={40}
                      className="mx-auto text-muted-foreground/40 mb-3"
                    />
                    <p className="text-muted-foreground font-medium">
                      No users match your filters
                    </p>
                    <p className="text-[11px] text-muted-foreground/70 mt-1">
                      Try clearing search or filters
                    </p>
                  </td>
                </tr>
              ) : (
                users.map((user) => (
                  <tr
                    key={user.id}
                    className="hover:bg-secondary/20 transition-colors text-foreground"
                  >
                    <td className="p-4">
                      <UserAvatar src={user.avatarUrl} name={user.fullName} size="sm" />
                    </td>
                    <td className="p-4">
                      <span className="font-semibold block">{user.fullName}</span>
                      {!user.onboardingCompleted && (
                        <span className="text-[10px] text-amber-400 font-medium block mt-0.5">
                          Onboarding pending
                        </span>
                      )}
                    </td>
                    <td className="p-4 hidden sm:table-cell">
                      <RoleBadge isCreator={user.isCreator} />
                    </td>
                    <td className="p-4 hidden md:table-cell text-muted-foreground">
                      {user.gender ?? '—'}
                    </td>
                    <td className="p-4 hidden lg:table-cell text-muted-foreground">
                      {user.ageLabel ?? '—'}
                    </td>
                    <td className="p-4 hidden xl:table-cell font-mono text-[11px] text-muted-foreground">
                      {user.phone}
                    </td>
                    <td className="p-4 text-right font-semibold text-amber-400">
                      {user.walletBalance.toLocaleString()}
                    </td>
                    <td className="p-4 text-right hidden sm:table-cell text-muted-foreground">
                      {user.totalCalls}
                    </td>
                    <td className="p-4">
                      <StatusBadge online={user.onlineStatus === 'online'} />
                    </td>
                    <td className="p-4 hidden md:table-cell text-muted-foreground">
                      {formatDate(user.createdAt)}
                    </td>
                    <td className="p-4 text-right">
                      <Link
                        href={`/admin/users/${user.id}`}
                        className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-secondary border border-border text-foreground hover:bg-indigo-600/20 hover:border-indigo-500/40 hover:text-indigo-300 transition-colors font-semibold"
                      >
                        <Eye size={13} />
                        View
                      </Link>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {!loading && totalPages > 1 && (
          <div className="border-t border-border p-4 flex flex-col sm:flex-row items-center justify-between gap-3">
            <span className="text-muted-foreground text-[11px]">
              Page {page} of {totalPages} · {(page - 1) * PAGE_SIZE + 1}–
              {Math.min(page * PAGE_SIZE, total)} of {total}
            </span>
            <div className="flex items-center gap-1">
              <button
                type="button"
                disabled={page <= 1}
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                className="p-2 rounded-lg border border-border bg-secondary disabled:opacity-40 hover:bg-secondary/80"
              >
                <ChevronLeft size={16} />
              </button>
              <button
                type="button"
                disabled={page >= totalPages}
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                className="p-2 rounded-lg border border-border bg-secondary disabled:opacity-40 hover:bg-secondary/80"
              >
                <ChevronRight size={16} />
              </button>
            </div>
          </div>
        )}
      </div>

      {embedded && (
        <button
          type="button"
          onClick={() => router.push('/admin/users')}
          className="text-xs text-indigo-400 hover:underline"
        >
          Open full users management →
        </button>
      )}
    </div>
  );
}

function RoleBadge({ isCreator }: { isCreator: boolean }) {
  if (isCreator) {
    return (
      <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-purple-500/15 text-purple-300 border border-purple-500/30">
        Active Creator
      </span>
    );
  }
  return (
    <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-zinc-500/10 text-zinc-400 border border-zinc-500/20">
      User
    </span>
  );
}

function StatusBadge({ online }: { online: boolean }) {
  return (
    <span
      className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[10px] font-bold ${
        online
          ? 'bg-emerald-500/15 text-emerald-400'
          : 'bg-zinc-500/15 text-zinc-400'
      }`}
    >
      <span
        className={`w-1.5 h-1.5 rounded-full ${online ? 'bg-emerald-400 animate-pulse' : 'bg-zinc-500'}`}
      />
      {online ? 'Online' : 'Offline'}
    </span>
  );
}

function FilterSelect({
  label,
  value,
  options,
  onChange,
}: {
  label: string;
  value: string;
  options: { value: string; label: string }[];
  onChange: (v: string) => void;
}) {
  return (
    <label className="flex flex-col gap-1">
      <span className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">
        {label}
      </span>
      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="px-2.5 py-1.5 rounded-lg bg-background border border-border text-xs text-foreground focus:outline-none focus:ring-1 focus:ring-indigo-500"
      >
        {options.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </select>
    </label>
  );
}
