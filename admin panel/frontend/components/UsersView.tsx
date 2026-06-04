// components/UsersView.tsx — embeds full users management (links to /admin/users/[id])
'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import UsersManagement from './admin/users/UsersManagement';

interface UsersViewProps {
  embedded?: boolean;
  onRefreshStats?: () => void;
  selectedUserId?: string;
  onClearSelectedUser?: () => void;
}

export default function UsersView({
  embedded = true,
  selectedUserId,
  onClearSelectedUser,
}: UsersViewProps) {
  const router = useRouter();

  useEffect(() => {
    if (selectedUserId) {
      router.push(`/admin/users/${selectedUserId}`);
      onClearSelectedUser?.();
    }
  }, [selectedUserId, router, onClearSelectedUser]);

  return <UsersManagement embedded={embedded} />;
}
