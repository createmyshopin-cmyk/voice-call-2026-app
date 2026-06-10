'use client';

import React from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';

interface CursorPaginationProps {
  hasMore: boolean;
  onNext?: () => void;
  onPrev?: () => void;
  canPrev?: boolean;
}

export default function CursorPagination({ hasMore, onNext, onPrev, canPrev }: CursorPaginationProps) {
  return (
    <div className="flex items-center justify-end gap-2 mt-4">
      <button
        type="button"
        disabled={!canPrev}
        onClick={onPrev}
        className="flex items-center gap-1 px-3 py-1.5 rounded-lg border border-border text-xs font-semibold disabled:opacity-40 hover:bg-secondary/50"
      >
        <ChevronLeft size={14} /> Previous
      </button>
      <button
        type="button"
        disabled={!hasMore}
        onClick={onNext}
        className="flex items-center gap-1 px-3 py-1.5 rounded-lg border border-border text-xs font-semibold disabled:opacity-40 hover:bg-secondary/50"
      >
        Next <ChevronRight size={14} />
      </button>
    </div>
  );
}
