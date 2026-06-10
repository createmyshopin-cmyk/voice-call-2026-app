'use client';

import React from 'react';
import { Video, Upload, FolderOpen } from 'lucide-react';
import PageHeader from '../ui/PageHeader';

export default function TrainingVideosView() {
  return (
    <div>
      <PageHeader
        title="Training Videos CMS"
        description="Future-ready module for creator onboarding content"
      />
      <div className="rounded-xl border border-dashed border-border bg-card/50 p-12 text-center">
        <div className="flex justify-center gap-4 mb-4 text-muted-foreground">
          <Video size={32} />
          <FolderOpen size={32} />
          <Upload size={32} />
        </div>
        <h2 className="text-sm font-bold text-foreground mb-2">Coming Soon</h2>
        <p className="text-xs text-muted-foreground max-w-md mx-auto leading-relaxed">
          Categories, upload, edit, delete, visibility, order, and search will be available
          when the media pipeline is deployed. Schema and UI shell are ready.
        </p>
      </div>
    </div>
  );
}
