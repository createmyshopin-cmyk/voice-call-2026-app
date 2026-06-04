'use client';

import React from 'react';
import { useParams } from 'next/navigation';
import UserDetailView from '../../../../components/admin/users/UserDetailView';

export default function AdminUserDetailPage() {
  const params = useParams();
  const id = typeof params.id === 'string' ? params.id : params.id?.[0];

  if (!id) {
    return (
      <p className="text-center text-muted-foreground py-12 text-sm">
        Invalid user ID
      </p>
    );
  }

  return <UserDetailView userId={id} />;
}
