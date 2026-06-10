'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { fetchJsonAuth } from '../api';

interface UseAdminQueryOptions {
  enabled?: boolean;
  pollIntervalMs?: number;
}

export function useAdminQuery<T>(
  path: string | null,
  options: UseAdminQueryOptions = {},
) {
  const { enabled = true, pollIntervalMs } = options;
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(Boolean(path && enabled));
  const [error, setError] = useState<string | null>(null);
  const [isLive, setIsLive] = useState(false);
  const abortRef = useRef<AbortController | null>(null);

  const refresh = useCallback(async () => {
    if (!path || !enabled) return;
    abortRef.current?.abort();
    const controller = new AbortController();
    abortRef.current = controller;
    setLoading(true);
    setError(null);

    const result = await fetchJsonAuth<T>(path, { signal: controller.signal });
    if (controller.signal.aborted) return;

    if (result.ok) {
      setData(result.data);
      setIsLive(true);
      setError(null);
    } else {
      setError(result.status === 403 ? 'Access denied' : 'Failed to load data');
      setIsLive(false);
    }
    setLoading(false);
  }, [path, enabled]);

  useEffect(() => {
    refresh();
    return () => abortRef.current?.abort();
  }, [refresh]);

  useEffect(() => {
    if (!pollIntervalMs || !enabled) return;
    const id = setInterval(refresh, pollIntervalMs);
    return () => clearInterval(id);
  }, [pollIntervalMs, enabled, refresh]);

  return { data, loading, error, isLive, refresh };
}
