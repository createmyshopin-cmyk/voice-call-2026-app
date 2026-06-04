'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { LayoutDashboard, LogOut } from 'lucide-react';
import { isAuthenticated, clearSession, getAdminUser } from '../../lib/auth';

export default function AdminSectionLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    if (!isAuthenticated()) {
      router.replace('/login?next=/admin/users');
      return;
    }
    setReady(true);
  }, [router]);

  if (!ready) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background text-sm text-muted-foreground">
        Loading…
      </div>
    );
  }

  const admin = getAdminUser();
  const initials = (admin?.name || 'A')
    .split(' ')
    .map((p) => p[0])
    .join('')
    .slice(0, 2)
    .toUpperCase();

  return (
    <div className="dark min-h-screen bg-background text-foreground">
      <header className="sticky top-0 z-20 border-b border-border bg-card/90 backdrop-blur px-4 sm:px-6 h-14 flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Link href="/" className="flex items-center gap-2 text-xs font-bold">
            <span className="p-1 bg-indigo-600 rounded text-white text-[10px]">CC</span>
            <span className="hidden sm:inline text-foreground">CoinCalling</span>
          </Link>
          <span className="text-border hidden sm:inline">|</span>
          <span className="text-xs text-muted-foreground font-semibold">Admin</span>
        </div>
        <div className="flex items-center gap-2">
          <Link
            href="/"
            className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold text-muted-foreground hover:text-foreground hover:bg-secondary border border-transparent hover:border-border transition-colors"
          >
            <LayoutDashboard size={14} />
            Console
          </Link>
          <div className="hidden sm:flex items-center gap-2 pl-2 border-l border-border">
            <div className="w-7 h-7 rounded-full bg-indigo-600 flex items-center justify-center text-[10px] font-bold text-white">
              {initials}
            </div>
            <span className="text-xs font-medium max-w-[120px] truncate">
              {admin?.name || 'Admin'}
            </span>
          </div>
          <button
            type="button"
            onClick={() => {
              clearSession();
              router.replace('/login');
            }}
            className="p-2 rounded-lg text-muted-foreground hover:text-foreground hover:bg-secondary"
            title="Sign out"
          >
            <LogOut size={15} />
          </button>
        </div>
      </header>
      <main className="p-4 sm:p-6 glow-indigo">{children}</main>
    </div>
  );
}
