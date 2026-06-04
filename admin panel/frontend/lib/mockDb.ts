// lib/mockDb.ts

export interface User {
  id: string;
  name: string;
  image: string;
  phone: string;
  email: string;
  coins: number;
  totalCalls: number;
  totalDuration: number; // in minutes
  totalRecharge: number; // in ₹
  totalSpent: number; // in coins
  country: string;
  device: string;
  registeredAt: string;
  status: 'active' | 'blocked';
  reportsCount: number;
  safetyScore: number;
}

export interface Listener {
  id: string;
  name: string;
  image: string;
  phone: string;
  email: string;
  bio: string;
  languages: string[];
  gender: 'Male' | 'Female' | 'Other';
  experience: string;
  status: 'pending' | 'active' | 'suspended';
  rating: number;
  completedCalls: number;
  revenueGenerated: number; // in ₹
  commissionRate: number; // percentage
  joinDate: string;
  acceptanceRate: number; // %
  missedCallRate: number; // %
  earningsToday: number;
  earningsWeek: number;
  earningsMonth: number;
  earningsLifetime: number;
}

export interface WithdrawRequest {
  id: string;
  listenerId: string;
  listenerName: string;
  amount: number; // in ₹
  upiId: string;
  bankDetails: {
    bankName: string;
    accountNo: string;
    ifsc: string;
    holderName: string;
  };
  requestDate: string;
  status: 'pending' | 'approved' | 'paid' | 'rejected';
  adminNote?: string;
}

export interface Transaction {
  id: string;
  userId: string;
  userName: string;
  type: 'recharge' | 'call_deduction' | 'bonus' | 'referral' | 'refund' | 'admin_adjustment';
  amount: number; // in coins
  balanceAfter: number;
  date: string;
}

export interface CoinPackage {
  id: string;
  name: string;
  coins: number;
  bonusCoins: number;
  price: number; // in ₹
  enabled: boolean;
}

export interface Payment {
  id: string;
  userId: string;
  userName: string;
  amount: number; // in ₹
  coins: number;
  gateway: string;
  transactionId: string;
  status: 'success' | 'failed' | 'pending';
  date: string;
}

export interface Call {
  id: string;
  callerId: string;
  callerName: string;
  listenerId: string;
  listenerName: string;
  type: 'voice' | 'video';
  status: 'completed' | 'missed' | 'rejected' | 'cancelled' | 'active';
  duration: number; // in seconds
  coinsConsumed: number;
  date: string;
}

export interface PushNotification {
  id: string;
  title: string;
  message: string;
  image?: string;
  audience: 'all_users' | 'all_listeners' | 'selected_users' | 'selected_listeners';
  date: string;
  status: 'sent' | 'scheduled';
}

export interface SafetyReport {
  id: string;
  reportedUserId: string;
  reportedUserName: string;
  reportedUserRole: 'user' | 'listener';
  reporterId: string;
  reporterName: string;
  reason: 'sexual_content' | 'harassment' | 'spam' | 'fake_profile' | 'abuse' | 'other';
  description: string;
  date: string;
  status: 'pending' | 'resolved';
}

export interface DeviceBan {
  id: string;
  deviceId: string;
  userId: string;
  userName: string;
  reason: string;
  date: string;
}

export interface SystemSettings {
  appName: string;
  supportEmail: string;
  supportWhatsapp: string;
  voiceCallsOn: boolean;
  videoCallsOn: boolean;
  callTimeout: number; // seconds
  coinRatePerMin: number; // coins per min
  minRecharge: number; // ₹
  referralBonus: number; // coins
  commissionRate: number; // %
  minWithdrawal: number; // ₹
  autoApproval: boolean;
  maintenanceMode: boolean;
}

export interface Admin {
  id: string;
  name: string;
  email: string;
  role: 'super_admin' | 'finance_admin' | 'support_admin' | 'moderator';
  permissions: string[];
  joinedAt: string;
}

// Initial Mock Data
const initialUsers: User[] = [
  { id: 'USR001', name: 'Aarav Sharma', image: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150', phone: '+91 98765 43210', email: 'aarav@gmail.com', coins: 450, totalCalls: 24, totalDuration: 184, totalRecharge: 1496, totalSpent: 1840, country: 'India', device: 'OnePlus 11', registeredAt: '2026-01-15T10:30:00Z', status: 'active', reportsCount: 0, safetyScore: 98 },
  { id: 'USR002', name: 'Rohan Mehta', image: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150', phone: '+91 98123 45678', email: 'rohan@yahoo.com', coins: 15, totalCalls: 45, totalDuration: 320, totalRecharge: 2999, totalSpent: 3200, country: 'India', device: 'Samsung S23', registeredAt: '2026-02-10T14:15:00Z', status: 'active', reportsCount: 1, safetyScore: 85 },
  { id: 'USR003', name: 'Priya Patel', image: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150', phone: '+91 97777 88888', email: 'priya.p@outlook.com', coins: 1250, totalCalls: 12, totalDuration: 96, totalRecharge: 1998, totalSpent: 960, country: 'India', device: 'iPhone 15 Pro', registeredAt: '2026-03-01T08:45:00Z', status: 'active', reportsCount: 0, safetyScore: 100 },
  { id: 'USR004', name: 'Kabir Singh', image: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150', phone: '+91 96666 55555', email: 'kabir.s@gmail.com', coins: 0, totalCalls: 58, totalDuration: 412, totalRecharge: 3996, totalSpent: 4200, country: 'India', device: 'iQOO Neo 7', registeredAt: '2026-01-20T19:22:00Z', status: 'blocked', reportsCount: 4, safetyScore: 35 },
  { id: 'USR005', name: 'Ananya Iyer', image: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150', phone: '+91 95555 44444', email: 'ananya@gmail.com', coins: 890, totalCalls: 8, totalDuration: 42, totalRecharge: 999, totalSpent: 420, country: 'India', device: 'iPhone 13', registeredAt: '2026-04-12T11:05:00Z', status: 'active', reportsCount: 0, safetyScore: 99 },
  { id: 'USR006', name: 'Vikram Singh', image: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150', phone: '+91 94444 33333', email: 'vikram@gmail.com', coins: 120, totalCalls: 15, totalDuration: 75, totalRecharge: 699, totalSpent: 750, country: 'India', device: 'Xiaomi 13 Pro', registeredAt: '2026-04-30T17:50:00Z', status: 'active', reportsCount: 0, safetyScore: 95 },
  { id: 'USR007', name: 'Neha Gupta', image: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150', phone: '+91 93333 22222', email: 'neha.g@gmail.com', coins: 3400, totalCalls: 4, totalDuration: 28, totalRecharge: 2999, totalSpent: 280, country: 'India', device: 'iPhone 14', registeredAt: '2026-05-18T09:12:00Z', status: 'active', reportsCount: 0, safetyScore: 100 }
];

const initialListeners: Listener[] = [
  { id: 'LIS001', name: 'Ishita Sen (RJ)', image: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150', phone: '+91 91234 56789', email: 'ishita@gmail.com', bio: 'Professional radio jockey and voiceover artist. Love to listen, talk about music, books, and life.', languages: ['Bengali', 'Hindi', 'English'], gender: 'Female', experience: '5 Years', status: 'active', rating: 4.8, completedCalls: 142, revenueGenerated: 8520, commissionRate: 60, joinDate: '2026-01-20', acceptanceRate: 94, missedCallRate: 3, earningsToday: 420, earningsWeek: 2100, earningsMonth: 8520, earningsLifetime: 32400 },
  { id: 'LIS002', name: 'Karan Malhotra', image: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=150', phone: '+91 92345 67890', email: 'karan@gmail.com', bio: 'Certified relationship counselor. Let\'s talk about what\'s bothering you.', languages: ['Hindi', 'English'], gender: 'Male', experience: '3 Years', status: 'active', rating: 4.9, completedCalls: 98, revenueGenerated: 7840, commissionRate: 60, joinDate: '2026-02-05', acceptanceRate: 88, missedCallRate: 6, earningsToday: 180, earningsWeek: 1540, earningsMonth: 7840, earningsLifetime: 21500 },
  { id: 'LIS003', name: 'Sneha Rao', image: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150', phone: '+91 93456 78901', email: 'sneha.r@gmail.com', bio: 'Passionate conversationalist and mental health advocate. I offer a warm, safe space to share.', languages: ['Telugu', 'Kannada', 'English', 'Hindi'], gender: 'Female', experience: '2 Years', status: 'active', rating: 4.6, completedCalls: 210, revenueGenerated: 12600, commissionRate: 65, joinDate: '2026-01-10', acceptanceRate: 98, missedCallRate: 1, earningsToday: 650, earningsWeek: 3100, earningsMonth: 12600, earningsLifetime: 48900 },
  { id: 'LIS004', name: 'Aditya Varma', image: 'https://images.unsplash.com/photo-1489980508314-941910ded1f4?w=150', phone: '+91 94567 89012', email: 'aditya@gmail.com', bio: 'Tech engineer by day, friendly listener by night. Let\'s talk startups, career, or general advice.', languages: ['English', 'Malayalam', 'Tamil'], gender: 'Male', experience: '1 Year', status: 'pending', rating: 0.0, completedCalls: 0, revenueGenerated: 0, commissionRate: 60, joinDate: '2026-06-01', acceptanceRate: 0, missedCallRate: 0, earningsToday: 0, earningsWeek: 0, earningsMonth: 0, earningsLifetime: 0 },
  { id: 'LIS005', name: 'Riya Deshmukh', image: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=150', phone: '+91 95678 90123', email: 'riya.d@gmail.com', bio: 'Lively, expressive host. Love sharing jokes, mimicry and light-hearted banter.', languages: ['Marathi', 'Hindi'], gender: 'Female', experience: '4 Years', status: 'pending', rating: 0.0, completedCalls: 0, revenueGenerated: 0, commissionRate: 60, joinDate: '2026-06-03', acceptanceRate: 0, missedCallRate: 0, earningsToday: 0, earningsWeek: 0, earningsMonth: 0, earningsLifetime: 0 },
  { id: 'LIS006', name: 'Rahul Joshi', image: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150', phone: '+91 96789 01234', email: 'rahul.j@gmail.com', bio: 'Deep thinker and empathetic listener. Let\'s explore philosophy, life\'s deep questions.', languages: ['Gujarati', 'Hindi', 'English'], gender: 'Male', experience: '6 Years', status: 'suspended', rating: 4.1, completedCalls: 45, revenueGenerated: 2700, commissionRate: 60, joinDate: '2026-03-15', acceptanceRate: 75, missedCallRate: 20, earningsToday: 0, earningsWeek: 0, earningsMonth: 0, earningsLifetime: 6800 }
];

const initialWithdrawRequests: WithdrawRequest[] = [
  { id: 'WDR001', listenerId: 'LIS001', listenerName: 'Ishita Sen (RJ)', amount: 5000, upiId: 'ishita@okaxis', bankDetails: { bankName: 'HDFC Bank', accountNo: '501002345678', ifsc: 'HDFC0000240', holderName: 'Ishita Sen' }, requestDate: '2026-06-02T10:00:00Z', status: 'pending' },
  { id: 'WDR002', listenerId: 'LIS003', listenerName: 'Sneha Rao', amount: 8000, upiId: 'snehar@paytm', bankDetails: { bankName: 'ICICI Bank', accountNo: '000401567890', ifsc: 'ICIC0000004', holderName: 'Sneha Rao' }, requestDate: '2026-06-01T15:30:00Z', status: 'approved' },
  { id: 'WDR003', listenerId: 'LIS002', listenerName: 'Karan Malhotra', amount: 3000, upiId: 'karan@ybl', bankDetails: { bankName: 'SBI', accountNo: '30245678901', ifsc: 'SBIN0000690', holderName: 'Karan Malhotra' }, requestDate: '2026-05-28T11:00:00Z', status: 'paid' },
  { id: 'WDR004', listenerId: 'LIS001', listenerName: 'Ishita Sen (RJ)', amount: 2000, upiId: 'ishita@okaxis', bankDetails: { bankName: 'HDFC Bank', accountNo: '501002345678', ifsc: 'HDFC0000240', holderName: 'Ishita Sen' }, requestDate: '2026-05-20T09:00:00Z', status: 'rejected' }
];

const initialTransactions: Transaction[] = [
  { id: 'TXN001', userId: 'USR001', userName: 'Aarav Sharma', type: 'recharge', amount: 500, balanceAfter: 500, date: '2026-06-03T18:00:00Z' },
  { id: 'TXN002', userId: 'USR001', userName: 'Aarav Sharma', type: 'call_deduction', amount: -50, balanceAfter: 450, date: '2026-06-03T18:15:00Z' },
  { id: 'TXN003', userId: 'USR003', userName: 'Priya Patel', type: 'recharge', amount: 1000, balanceAfter: 1250, date: '2026-06-02T12:00:00Z' },
  { id: 'TXN004', userId: 'USR002', userName: 'Rohan Mehta', type: 'call_deduction', amount: -100, balanceAfter: 15, date: '2026-06-03T20:30:00Z' },
  { id: 'TXN005', userId: 'USR005', userName: 'Ananya Iyer', type: 'bonus', amount: 50, balanceAfter: 890, date: '2026-06-03T10:00:00Z' },
  { id: 'TXN006', userId: 'USR004', userName: 'Kabir Singh', type: 'admin_adjustment', amount: -200, balanceAfter: 0, date: '2026-05-29T14:00:00Z' }
];

const initialCoinPackages: CoinPackage[] = [
  { id: 'PKG001', name: 'Starter Pack', coins: 100, bonusCoins: 0, price: 99, enabled: true },
  { id: 'PKG002', name: 'Value Pack', coins: 500, bonusCoins: 50, price: 399, enabled: true },
  { id: 'PKG003', name: 'Popular Pack', coins: 1000, bonusCoins: 150, price: 699, enabled: true },
  { id: 'PKG004', name: 'VIP Pack', coins: 5000, bonusCoins: 1000, price: 2999, enabled: true }
];

const initialPayments: Payment[] = [
  { id: 'PAY001', userId: 'USR001', userName: 'Aarav Sharma', amount: 399, coins: 550, gateway: 'Razorpay', transactionId: 'pay_Nz82Bcx90P', status: 'success', date: '2026-06-03T18:00:00Z' },
  { id: 'PAY002', userId: 'USR003', userName: 'Priya Patel', amount: 699, coins: 1150, gateway: 'Razorpay', transactionId: 'pay_Oz93Ccx91Q', status: 'success', date: '2026-06-02T12:00:00Z' },
  { id: 'PAY003', userId: 'USR002', userName: 'Rohan Mehta', amount: 99, coins: 100, gateway: 'UPI-Intent', transactionId: 'upi_230918239', status: 'failed', date: '2026-06-03T19:00:00Z' },
  { id: 'PAY004', userId: 'USR006', userName: 'Vikram Singh', amount: 699, coins: 1150, gateway: 'Stripe', transactionId: 'ch_1M8x92Hxb', status: 'pending', date: '2026-06-03T23:45:00Z' }
];

const initialCalls: Call[] = [
  { id: 'CAL001', callerId: 'USR001', callerName: 'Aarav Sharma', listenerId: 'LIS001', listenerName: 'Ishita Sen (RJ)', type: 'voice', status: 'completed', duration: 300, coinsConsumed: 50, date: '2026-06-03T18:10:00Z' },
  { id: 'CAL002', callerId: 'USR002', callerName: 'Rohan Mehta', listenerId: 'LIS002', listenerName: 'Karan Malhotra', type: 'video', status: 'completed', duration: 600, coinsConsumed: 100, date: '2026-06-03T20:20:00Z' },
  { id: 'CAL003', callerId: 'USR005', callerName: 'Ananya Iyer', listenerId: 'LIS003', listenerName: 'Sneha Rao', type: 'voice', status: 'missed', duration: 0, coinsConsumed: 0, date: '2026-06-03T21:40:00Z' },
  { id: 'CAL004', callerId: 'USR007', callerName: 'Neha Gupta', listenerId: 'LIS001', listenerName: 'Ishita Sen (RJ)', type: 'video', status: 'active', duration: 420, coinsConsumed: 70, date: '2026-06-03T23:55:00Z' }
];

const initialNotifications: PushNotification[] = [
  { id: 'NOT001', title: 'Double Coins Recharge Offer!', message: 'Recharge today and get 2x bonus coins on VIP packages. Limited time only!', audience: 'all_users', date: '2026-06-01T12:00:00Z', status: 'sent' },
  { id: 'NOT002', title: 'New Listeners Are Online', message: 'Chat with certified counselors now and solve your mid-week worries.', audience: 'all_users', date: '2026-06-03T16:00:00Z', status: 'sent' }
];

const initialReports: SafetyReport[] = [
  { id: 'REP001', reportedUserId: 'USR004', reportedUserName: 'Kabir Singh', reportedUserRole: 'user', reporterId: 'LIS001', reporterName: 'Ishita Sen (RJ)', reason: 'sexual_content', description: 'User made explicit remarks and gestures during the video call.', date: '2026-06-02T19:30:00Z', status: 'pending' },
  { id: 'REP002', reportedUserId: 'USR002', reportedUserName: 'Rohan Mehta', reportedUserRole: 'user', reporterId: 'LIS002', reporterName: 'Karan Malhotra', reason: 'harassment', description: 'Kept calling repeatedly and shouting.', date: '2026-06-03T14:22:00Z', status: 'pending' },
  { id: 'REP003', reportedUserId: 'LIS006', reportedUserName: 'Rahul Joshi', reportedUserRole: 'listener', reporterId: 'USR001', reporterName: 'Aarav Sharma', reason: 'abuse', description: 'Listener was rude and used foul language when I asked a simple question.', date: '2026-05-14T11:00:00Z', status: 'resolved' }
];

const initialDeviceBans: DeviceBan[] = [
  { id: 'BAN001', deviceId: 'DEV-F8293X928B3', userId: 'USR004', userName: 'Kabir Singh', reason: 'Multiple reports of sexual harassment on video call.', date: '2026-06-03T22:00:00Z' }
];

const initialSettings: SystemSettings = {
  appName: 'CoinCalling',
  supportEmail: 'support@coincalling.com',
  supportWhatsapp: '+91 99999 88888',
  voiceCallsOn: true,
  videoCallsOn: true,
  callTimeout: 45,
  coinRatePerMin: 10,
  minRecharge: 99,
  referralBonus: 50,
  commissionRate: 60,
  minWithdrawal: 1000,
  autoApproval: false,
  maintenanceMode: false
};

const initialAdmins: Admin[] = [
  { id: 'ADM001', name: 'Super Admin', email: 'admin@coincalling.com', role: 'super_admin', permissions: ['users', 'wallet', 'payments', 'calls', 'notifications', 'reports', 'settings', 'admins'], joinedAt: '2026-01-01' },
  { id: 'ADM002', name: 'Rohan Fin', email: 'rohan.fin@coincalling.com', role: 'finance_admin', permissions: ['wallet', 'payments'], joinedAt: '2026-02-15' },
  { id: 'ADM003', name: 'Sarah Mod', email: 'sarah.mod@coincalling.com', role: 'moderator', permissions: ['users', 'calls', 'reports'], joinedAt: '2026-03-20' }
];

// DB Helper Class
export class MockDatabase {
  private static getStore<T>(key: string, initial: T): T {
    if (typeof window === 'undefined') return initial;
    const item = localStorage.getItem(`coincall_${key}`);
    return item ? JSON.parse(item) as T : initial;
  }

  private static setStore<T>(key: string, value: T): void {
    if (typeof window === 'undefined') return;
    localStorage.setItem(`coincall_${key}`, JSON.stringify(value));
  }

  // Users
  static getUsers(): User[] {
    return this.getStore('users', initialUsers);
  }
  static saveUsers(users: User[]) {
    this.setStore('users', users);
  }

  // Listeners
  static getListeners(): Listener[] {
    return this.getStore('listeners', initialListeners);
  }
  static saveListeners(listeners: Listener[]) {
    this.setStore('listeners', listeners);
  }

  // Withdraw requests
  static getWithdrawRequests(): WithdrawRequest[] {
    return this.getStore('withdraws', initialWithdrawRequests);
  }
  static saveWithdrawRequests(reqs: WithdrawRequest[]) {
    this.setStore('withdraws', reqs);
  }

  // Transactions
  static getTransactions(): Transaction[] {
    return this.getStore('transactions', initialTransactions);
  }
  static saveTransactions(txns: Transaction[]) {
    this.setStore('transactions', txns);
  }

  // Coin packages
  static getCoinPackages(): CoinPackage[] {
    return this.getStore('packages', initialCoinPackages);
  }
  static saveCoinPackages(pkgs: CoinPackage[]) {
    this.setStore('packages', pkgs);
  }

  // Payments
  static getPayments(): Payment[] {
    return this.getStore('payments', initialPayments);
  }
  static savePayments(payments: Payment[]) {
    this.setStore('payments', payments);
  }

  // Calls
  static getCalls(): Call[] {
    return this.getStore('calls', initialCalls);
  }
  static saveCalls(calls: Call[]) {
    this.setStore('calls', calls);
  }

  // Notifications
  static getNotifications(): PushNotification[] {
    return this.getStore('notifications', initialNotifications);
  }
  static saveNotifications(notifications: PushNotification[]) {
    this.setStore('notifications', notifications);
  }

  // Safety Reports
  static getReports(): SafetyReport[] {
    return this.getStore('reports', initialReports);
  }
  static saveReports(reports: SafetyReport[]) {
    this.setStore('reports', reports);
  }

  // Device Bans
  static getDeviceBans(): DeviceBan[] {
    return this.getStore('devicebans', initialDeviceBans);
  }
  static saveDeviceBans(bans: DeviceBan[]) {
    this.setStore('devicebans', bans);
  }

  // Settings
  static getSettings(): SystemSettings {
    return this.getStore('settings', initialSettings);
  }
  static saveSettings(settings: SystemSettings) {
    this.setStore('settings', settings);
  }

  // Admins
  static getAdmins(): Admin[] {
    return this.getStore('admins', initialAdmins);
  }
  static saveAdmins(admins: Admin[]) {
    this.setStore('admins', admins);
  }
}
