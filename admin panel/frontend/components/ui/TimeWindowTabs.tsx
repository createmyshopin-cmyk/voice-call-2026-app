'use client';

import React from 'react';

export type TimeWindow = '7d' | '30d' | 'lifetime';

interface TimeWindowTabsProps {
  value: TimeWindow;
  onChange: (v: TimeWindow) => void;
}

const OPTIONS: { id: TimeWindow; label: string }[] = [
  { id: '7d', label: '7d' },
  { id: '30d', label: '30d' },
  { id: 'lifetime', label: 'Lifetime' },
];

export default function TimeWindowTabs({ value, onChange }: TimeWindowTabsProps) {
  return (
    <div className="inline-flex rounded-lg border border-border bg-secondary/30 p-0.5">
      {OPTIONS.map((opt) => (
        <button
          key={opt.id}
          type="button"
          onClick={() => onChange(opt.id)}
          className={`px-3 py-1.5 rounded-md text-[10px] font-bold uppercase tracking-wider transition-colors ${
            value === opt.id ? 'bg-indigo-600 text-white' : 'text-muted-foreground hover:text-foreground'
          }`}
        >
          {opt.label}
        </button>
      ))}
    </div>
  );
}
