'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import {
  ArrowLeft,
  Phone,
  Calendar,
  Coins,
  Shield,
  ShieldOff,
  UserCheck,
  Clock,
  TrendingDown,
  CheckCircle2,
  XCircle,
} from 'lucide-react';
import {
  AdminUserDetail,
  fetchAdminUserDetail,
  formatDate,
  formatDateTime,
  blockUser,
  unblockUser,
  suspendUser,
  reactivateUser,
} from '../../../lib/adminUsers';
import { API_BASE, connectionErrorMessage, classifyApiFailure } from '../../../lib/api';
import LiveDataBanner from '../../LiveDataBanner';
import UserAvatar from './UserAvatar';
import { DetailSkeleton } from './TableSkeleton';

interface UserDetailViewProps {
  userId: string;
}

export default function UserDetailView({ userId }: UserDetailViewProps) {
  const [user, setUser] = useState<AdminUserDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [isLive, setIsLive] = useState(false);
  const [loadError, setLoadError] = useState<string | undefined>();
  const [updating, setUpdating] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  const handleStatusAction = async (action: 'block' | 'unblock' | 'suspend' | 'reactivate') => {
    setUpdating(true);
    setActionError(null);
    let res;
    if (action === 'block') res = await blockUser(userId);
    else if (action === 'unblock') res = await unblockUser(userId);
    else if (action === 'suspend') res = await suspendUser(userId);
    else if (action === 'reactivate') res = await reactivateUser(userId);

    if (res && res.ok && res.data) {
      setUser(res.data as AdminUserDetail);
    } else {
      setActionError((res?.data as any)?.message || 'Failed to update user status.');
    }
    setUpdating(false);
  };

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      const res = await fetchAdminUserDetail(userId);
      if (cancelled) return;
      if (res.ok && res.data) {
        setUser(res.data as AdminUserDetail);
        setIsLive(true);
        setLoadError(undefined);
      } else {
        setUser(null);
        setIsLive(false);
        setLoadError(
          res.status === 404
            ? 'User not found.'
            : res.status
              ? connectionErrorMessage(classifyApiFailure(res.status))
              : connectionErrorMessage('network'),
        );
      }
      setLoading(false);
    })();
    return () => {
      cancelled = true;
    };
  }, [userId]);

  if (loading) {
    return (
      <div className="max-w-5xl mx-auto space-y-6">
        <Link
          href="/admin/users"
          className="inline-flex items-center gap-1.5 text-xs text-muted-foreground"
        >
          <ArrowLeft size={14} />
          Users
        </Link>
        <DetailSkeleton />
      </div>
    );
  }

  if (!user) {
    return (
      <div className="max-w-lg mx-auto text-center py-16 space-y-4">
        <XCircle size={48} className="mx-auto text-red-400/60" />
        <p className="text-foreground font-semibold">{loadError || 'User not found'}</p>
        <Link
          href="/admin/users"
          className="inline-flex items-center gap-1 text-indigo-400 text-sm hover:underline"
        >
          <ArrowLeft size={14} />
          Back to users
        </Link>
      </div>
    );
  }

  const stats = user.callStatistics;

  return (
    <div className="max-w-5xl mx-auto space-y-6 pb-12">
      <Link
        href="/admin/users"
        className="inline-flex items-center gap-1.5 text-xs text-muted-foreground hover:text-foreground transition-colors"
      >
        <ArrowLeft size={14} />
        Back to users
      </Link>

      <LiveDataBanner
        isLive={isLive}
        label="user profile"
        errorMessage={loadError}
        apiBase={API_BASE}
      />

      {/* Profile hero card */}
      <div className="glass-panel rounded-2xl p-6 sm:p-8 border border-border overflow-hidden relative">
        <div className="absolute top-0 right-0 w-64 h-64 bg-indigo-600/10 rounded-full blur-3xl -translate-y-1/2 translate-x-1/3 pointer-events-none" />
        <div className="flex flex-col sm:flex-row gap-6 items-start relative">
          <UserAvatar src={user.avatarUrl} name={user.fullName} size="xl" />
          <div className="flex-1 min-w-0 space-y-3">
            <h1 className="text-2xl sm:text-3xl font-bold text-foreground tracking-tight">
              {user.fullName}
            </h1>
            <div className="flex flex-wrap gap-2">
              {user.gender && <Badge variant="muted">{user.gender}</Badge>}
              {user.ageLabel && <Badge variant="muted">{user.ageLabel}</Badge>}
              <Badge variant={user.onlineStatus === 'online' ? 'success' : 'muted'}>
                {user.onlineStatus === 'online' ? 'Online' : 'Offline'}
              </Badge>
              <Badge variant="accent">
                <Coins size={11} className="inline mr-0.5" />
                {user.walletBalance.toLocaleString()} coins
              </Badge>
              {user.isCreator && (
                <Badge variant="purple">
                  <UserCheck size={11} className="inline mr-0.5" />
                  Active Creator
                </Badge>
              )}
              {user.status === 'blocked' && (
                <Badge variant="danger">
                  <ShieldOff size={11} className="inline mr-0.5" />
                  Blocked
                </Badge>
              )}
              {user.status === 'suspended' && (
                <Badge variant="danger">
                  <ShieldOff size={11} className="inline mr-0.5" />
                  Suspended
                </Badge>
              )}
            </div>
            <div className="flex flex-wrap gap-4 text-xs text-muted-foreground">
              <span className="flex items-center gap-1.5">
                <Phone size={13} />
                {user.phone || '—'}
              </span>
              <span className="flex items-center gap-1.5">
                <Calendar size={13} />
                Joined {formatDate(user.accountCreatedAt)}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Stats row */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <StatCard label="Total Calls" value={stats.totalCalls} icon={Phone} />
        <StatCard
          label="Completed"
          value={stats.completedCalls}
          icon={CheckCircle2}
          tone="success"
        />
        <StatCard
          label="Rejected"
          value={stats.rejectedCalls}
          icon={XCircle}
          tone="danger"
        />
        <StatCard
          label="Total Minutes"
          value={stats.totalMinutes}
          icon={Clock}
          suffix=" min"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Profile section */}
        <section className="glass-panel rounded-xl p-5 border border-border space-y-4">
          <h2 className="text-sm font-bold text-foreground uppercase tracking-wider">
            Profile
          </h2>
          <dl className="space-y-3 text-xs">
            <DetailRow label="Full Name" value={user.fullName} />
            <DetailRow label="Gender" value={user.gender ?? '—'} />
            <DetailRow
              label="Date of Birth"
              value={user.dateOfBirth ? formatDate(user.dateOfBirth) : '—'}
            />
            <DetailRow label="Age" value={user.ageLabel ?? '—'} />
            <DetailRow label="Phone" value={user.phone || '—'} mono />
            <DetailRow label="Email" value={user.email ?? '—'} />
            <DetailRow label="Language" value={user.language ?? '—'} />
            <DetailRow label="Firebase UID" value={user.firebaseUid ?? '—'} mono />
            <DetailRow label="User UUID" value={user.id} mono />
            <DetailRow
              label="Created"
              value={formatDateTime(user.accountCreatedAt)}
            />
            <DetailRow
              label="Last Updated"
              value={user.updatedAt ? formatDateTime(user.updatedAt) : '—'}
            />
          </dl>
        </section>

        {/* Account status */}
        <section className="glass-panel rounded-xl p-5 border border-border space-y-4">
          <h2 className="text-sm font-bold text-foreground uppercase tracking-wider">
            Account Status
          </h2>
          <dl className="space-y-3 text-xs">
            <DetailRow
              label="Online Status"
              value={user.onlineStatus === 'online' ? 'Online' : 'Offline'}
            />
            <DetailRow
              label="Onboarding"
              value={user.onboardingCompleted ? 'Completed' : 'Not Completed'}
            />
            <DetailRow
              label="Wallet Balance"
              value={`${user.walletBalance.toLocaleString()} coins`}
            />
            <DetailRow
              label="Account Role"
              value={user.isCreator ? 'Active Creator' : 'User'}
            />
            <DetailRow
              label="Mobile App Mode"
              value={
                user.isCreator || user.creatorStatus === 'active'
                  ? 'Creator mode — Start Earnings + Listener dashboard'
                  : 'User mode — Become a Listener'
              }
            />
            <DetailRow
              label="Verified"
              value={user.isVerified ? 'Yes' : 'No'}
            />
            <DetailRow
              label="Account Status"
              value={user.status ? user.status.charAt(0).toUpperCase() + user.status.slice(1) : 'Active'}
            />
          </dl>
          <div className="pt-4 border-t border-border/60 flex flex-wrap gap-2">
            {user.status === 'blocked' ? (
              <button
                disabled={updating}
                onClick={() => handleStatusAction('unblock')}
                className="px-3 py-1.5 rounded-lg bg-emerald-500/15 hover:bg-emerald-500/25 text-emerald-400 border border-emerald-500/30 text-xs font-semibold disabled:opacity-50 transition-colors cursor-pointer"
              >
                Unblock Account
              </button>
            ) : (
              <button
                disabled={updating}
                onClick={() => handleStatusAction('block')}
                className="px-3 py-1.5 rounded-lg bg-red-500/15 hover:bg-red-500/25 text-red-400 border border-red-500/30 text-xs font-semibold disabled:opacity-50 transition-colors cursor-pointer"
              >
                Block Account
              </button>
            )}

            {user.status === 'suspended' ? (
              <button
                disabled={updating}
                onClick={() => handleStatusAction('reactivate')}
                className="px-3 py-1.5 rounded-lg bg-indigo-500/15 hover:bg-indigo-500/25 text-indigo-300 border border-indigo-500/30 text-xs font-semibold disabled:opacity-50 transition-colors cursor-pointer"
              >
                Reactivate Account
              </button>
            ) : (
              <button
                disabled={updating}
                onClick={() => handleStatusAction('suspend')}
                className="px-3 py-1.5 rounded-lg bg-amber-500/15 hover:bg-amber-500/25 text-amber-400 border border-amber-500/30 text-xs font-semibold disabled:opacity-50 transition-colors cursor-pointer"
              >
                Suspend Account
              </button>
            )}
          </div>
          {actionError && (
            <p className="text-[11px] text-red-400 mt-2 font-medium">{actionError}</p>
          )}
        </section>
      </div>

      {/* Call statistics */}
      <section className="glass-panel rounded-xl p-5 border border-border space-y-4">
        <h2 className="text-sm font-bold text-foreground uppercase tracking-wider">
          Call Statistics
        </h2>
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
          <MiniStat label="Total Calls" value={stats.totalCalls} />
          <MiniStat label="Completed" value={stats.completedCalls} />
          <MiniStat label="Rejected" value={stats.rejectedCalls} />
          <MiniStat label="Minutes" value={stats.totalMinutes} />
          <MiniStat label="Coins Spent" value={stats.totalCoinsSpent} />
          <MiniStat
            label="Avg Duration"
            value={stats.averageCallDurationLabel}
            isText
          />
        </div>
      </section>

      {/* Transactions */}
      <section className="glass-panel rounded-xl overflow-hidden border border-border">
        <div className="p-5 border-b border-border flex items-center justify-between">
          <h2 className="text-sm font-bold text-foreground uppercase tracking-wider flex items-center gap-2">
            <TrendingDown size={16} className="text-indigo-400" />
            Recent Wallet Transactions
          </h2>
          <span className="text-[10px] text-muted-foreground">
            Last {user.recentTransactions.length} entries
          </span>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-xs text-left">
            <thead>
              <tr className="border-b border-border bg-secondary/30 text-muted-foreground">
                <th className="p-4 font-semibold">Date</th>
                <th className="p-4 font-semibold">Type</th>
                <th className="p-4 font-semibold text-right">Coins</th>
                <th className="p-4 font-semibold">Description</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border/80">
              {user.recentTransactions.length === 0 ? (
                <tr>
                  <td colSpan={4} className="p-8 text-center text-muted-foreground">
                    No transactions recorded yet.
                  </td>
                </tr>
              ) : (
                user.recentTransactions.map((tx) => (
                  <tr key={tx.id} className="hover:bg-secondary/20">
                    <td className="p-4 text-muted-foreground">{tx.date}</td>
                    <td className="p-4">
                      <span
                        className={`font-bold ${
                          tx.type === 'DEBIT' ? 'text-red-400' : 'text-emerald-400'
                        }`}
                      >
                        {tx.type}
                      </span>
                    </td>
                    <td
                      className={`p-4 text-right font-mono font-semibold ${
                        tx.coins < 0 ? 'text-red-400' : 'text-emerald-400'
                      }`}
                    >
                      {tx.coins > 0 ? '+' : ''}
                      {tx.coins}
                    </td>
                    <td className="p-4 text-foreground">{tx.description}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </section>

      <div className="flex gap-2 text-[10px] text-muted-foreground">
        <Shield size={12} />
        Admin-only view · User data from onboarding profile
      </div>
    </div>
  );
}

function Badge({
  children,
  variant,
}: {
  children: React.ReactNode;
  variant: 'muted' | 'success' | 'accent' | 'purple' | 'danger';
}) {
  const styles = {
    muted: 'bg-secondary text-muted-foreground border-border',
    success: 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30',
    accent: 'bg-amber-500/15 text-amber-400 border-amber-500/30',
    purple: 'bg-indigo-500/15 text-indigo-300 border-indigo-500/30',
    danger: 'bg-red-500/15 text-red-400 border-red-500/30',
  };
  return (
    <span
      className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold border ${styles[variant]}`}
    >
      {children}
    </span>
  );
}

function StatCard({
  label,
  value,
  icon: Icon,
  tone,
  suffix = '',
}: {
  label: string;
  value: number;
  icon: React.ComponentType<{ size?: number; className?: string }>;
  tone?: 'success' | 'danger';
  suffix?: string;
}) {
  const toneClass =
    tone === 'success'
      ? 'text-emerald-400'
      : tone === 'danger'
        ? 'text-red-400'
        : 'text-foreground';
  return (
    <div className="glass-panel rounded-xl p-4 border border-border">
      <div className="flex items-center justify-between mb-2">
        <span className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">
          {label}
        </span>
        <Icon size={14} className="text-indigo-400/80" />
      </div>
      <p className={`text-xl font-bold ${toneClass}`}>
        {value.toLocaleString()}
        {suffix}
      </p>
    </div>
  );
}

function MiniStat({
  label,
  value,
  isText,
}: {
  label: string;
  value: number | string;
  isText?: boolean;
}) {
  return (
    <div className="rounded-lg bg-secondary/40 border border-border/60 p-3">
      <p className="text-[10px] text-muted-foreground font-semibold uppercase tracking-wide mb-1">
        {label}
      </p>
      <p className="text-sm font-bold text-foreground">
        {isText ? value : Number(value).toLocaleString()}
      </p>
    </div>
  );
}

function DetailRow({
  label,
  value,
  mono,
}: {
  label: string;
  value: string;
  mono?: boolean;
}) {
  return (
    <div className="flex flex-col sm:flex-row sm:justify-between gap-0.5 sm:gap-4">
      <dt className="text-muted-foreground font-medium shrink-0">{label}</dt>
      <dd
        className={`text-foreground font-semibold sm:text-right break-all ${mono ? 'font-mono text-[11px]' : ''}`}
      >
        {value}
      </dd>
    </div>
  );
}
