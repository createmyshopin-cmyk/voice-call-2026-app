'use client';

import React from 'react';
import Link from 'next/link';
import { AlertCircle } from 'lucide-react';

interface LiveDataBannerProps {
  isLive: boolean;
  label?: string;
  errorMessage?: string;
  apiBase?: string;
}

export default function LiveDataBanner({
  isLive,
  label = 'this section',
  errorMessage,
  apiBase,
}: LiveDataBannerProps) {
  if (isLive) return null;
  return (
    <div className="mb-4 flex items-start gap-2 rounded-lg border border-amber-500/30 bg-amber-500/10 px-4 py-3 text-xs text-amber-200">
      <AlertCircle size={16} className="mt-0.5 shrink-0" />
      <div>
        <p className="font-semibold">Live data unavailable for {label}</p>
        <p className="mt-0.5 text-amber-200/80">
          {errorMessage ||
            'Sign in with an admin account (not the mobile app token). After changing Vercel env vars, redeploy the site.'}
        </p>
        {apiBase && (
          <p className="mt-1 text-amber-200/60 font-mono text-[10px] break-all">API: {apiBase}</p>
        )}
        <Link href="/login" className="mt-2 inline-block font-semibold underline">
          Go to sign in
        </Link>
      </div>
    </div>
  );
}
