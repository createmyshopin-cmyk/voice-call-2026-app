'use client';

import React from 'react';

interface Tab {
  id: string;
  label: string;
}

interface ModuleTabsProps {
  tabs: Tab[];
  active: string;
  onChange: (id: string) => void;
}

export default function ModuleTabs({ tabs, active, onChange }: ModuleTabsProps) {
  return (
    <div className="flex flex-wrap gap-1 border-b border-border mb-6">
      {tabs.map((tab) => (
        <button
          key={tab.id}
          type="button"
          onClick={() => onChange(tab.id)}
          className={`px-4 py-2 text-xs font-semibold border-b-2 -mb-px transition-colors ${
            active === tab.id
              ? 'border-indigo-500 text-foreground'
              : 'border-transparent text-muted-foreground hover:text-foreground'
          }`}
        >
          {tab.label}
        </button>
      ))}
    </div>
  );
}
