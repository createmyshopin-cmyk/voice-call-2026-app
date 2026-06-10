import { API_BASE } from '../api';

export const engagementApi = {
  missionsOverview: () => `${API_BASE}/admin/engagement/missions/overview`,
  streaksOverview: () => `${API_BASE}/admin/engagement/streaks/overview`,
  followsLeaderboard: (type: 'follows' | 'favorites' = 'follows') =>
    `${API_BASE}/admin/engagement/follows/leaderboard?type=${type}`,
  levelsDistribution: () => `${API_BASE}/admin/engagement/levels/distribution`,
  vipOverview: () => `${API_BASE}/admin/engagement/vip/overview`,
  messagesOverview: () => `${API_BASE}/admin/engagement/messages/overview`,
  combosOverview: () => `${API_BASE}/admin/engagement/combos/overview`,
  giftsAnalytics: () => `${API_BASE}/admin/gifts/analytics`,
  giftsList: () => `${API_BASE}/admin/gifts`,
};
