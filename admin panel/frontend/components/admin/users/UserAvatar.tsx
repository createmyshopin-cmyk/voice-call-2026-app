'use client';

import React from 'react';
import { DEFAULT_AVATAR } from '../../../lib/adminUsers';

interface UserAvatarProps {
  src?: string | null;
  name: string;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
}

const sizeMap = {
  sm: 'w-8 h-8 text-[10px]',
  md: 'w-11 h-11 text-xs',
  lg: 'w-20 h-20 text-lg',
  xl: 'w-28 h-28 text-2xl',
};

export default function UserAvatar({
  src,
  name,
  size = 'md',
  className = '',
}: UserAvatarProps) {
  const initials = name
    .split(' ')
    .filter(Boolean)
    .map((p) => p[0])
    .join('')
    .slice(0, 2)
    .toUpperCase();

  return (
    <div
      className={`relative shrink-0 rounded-full overflow-hidden border border-border bg-secondary flex items-center justify-center font-bold text-muted-foreground ${sizeMap[size]} ${className}`}
    >
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        src={src || DEFAULT_AVATAR}
        alt={name}
        className="absolute inset-0 w-full h-full object-cover"
        onError={(e) => {
          (e.target as HTMLImageElement).style.display = 'none';
        }}
      />
      <span className="relative z-0">{initials || '?'}</span>
    </div>
  );
}
