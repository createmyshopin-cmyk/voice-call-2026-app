import { describe, it, expect } from 'vitest';
import { releasesApi } from './releases';

describe('releasesApi', () => {
  it('builds admin endpoints', () => {
    expect(releasesApi.settings()).toContain('/admin/app-version');
    expect(releasesApi.list()).toContain('/admin/releases');
    expect(releasesApi.sendNotification()).toContain('/send-notification');
    expect(releasesApi.analytics()).toContain('/analytics');
  });
});
