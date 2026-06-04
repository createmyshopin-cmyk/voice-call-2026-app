'use client';

import React from 'react';

export function TableSkeleton({ rows = 8 }: { rows?: number }) {
  return (
    <div className="animate-pulse space-y-0">
      {Array.from({ length: rows }).map((_, i) => (
        <div
          key={i}
          className="flex items-center gap-4 p-4 border-b border-border/60"
        >
          <div className="w-10 h-10 rounded-full bg-secondary" />
          <div className="flex-1 space-y-2">
            <div className="h-3 w-32 bg-secondary rounded" />
            <div className="h-2 w-20 bg-secondary/70 rounded" />
          </div>
          <div className="h-3 w-12 bg-secondary rounded hidden sm:block" />
          <div className="h-3 w-16 bg-secondary rounded hidden md:block" />
          <div className="h-6 w-14 bg-secondary rounded" />
        </div>
      ))}
    </div>
  );
}

export function DetailSkeleton() {
  return (
    <div className="animate-pulse space-y-6">
      <div className="flex gap-6 items-start">
        <div className="w-28 h-28 rounded-full bg-secondary" />
        <div className="space-y-3 flex-1">
          <div className="h-8 w-48 bg-secondary rounded" />
          <div className="h-4 w-64 bg-secondary/70 rounded" />
          <div className="flex gap-2">
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className="h-6 w-20 bg-secondary rounded-full" />
            ))}
          </div>
        </div>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {[1, 2, 3].map((i) => (
          <div key={i} className="h-24 rounded-xl bg-secondary/50 border border-border" />
        ))}
      </div>
    </div>
  );
}
