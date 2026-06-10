'use client';

import React from 'react';

interface MiniChartProps {
  data: number[];
  height?: number;
  color?: string;
}

export default function MiniChart({ data, height = 48, color = '#6366f1' }: MiniChartProps) {
  if (!data.length) return null;
  const max = Math.max(...data, 1);
  const w = 100 / data.length;

  return (
    <svg viewBox="0 0 100 40" className="w-full" style={{ height }} preserveAspectRatio="none">
      {data.map((v, i) => {
        const barH = (v / max) * 36;
        return (
          <rect
            key={i}
            x={i * w + 1}
            y={40 - barH}
            width={Math.max(w - 2, 1)}
            height={barH}
            fill={color}
            opacity={0.85}
            rx={1}
          />
        );
      })}
    </svg>
  );
}
