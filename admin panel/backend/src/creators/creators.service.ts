import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

/** Online when last heartbeat was within this window (seconds). */
export const CREATOR_ONLINE_THRESHOLD_SECONDS = 60;

export interface Creator {
  id: string;
  name: string;
  phone: string;
  email: string;
  bio: string;
  languages: string[];
  gender: string;
  experience: string;
  status: 'pending' | 'active' | 'suspended';
  rating: number;
  completedCalls: number;
  revenueGenerated: number;
  ratePerMinute: number;
  isOnline: boolean;
  lastSeenAt?: string;
  profileImage: string;
  createdAt?: string;
  isNew?: boolean;
}

@Injectable()
export class CreatorsService {
  /** In-memory last_seen when Supabase is unavailable (keyed by user id). */
  private readonly lastSeenByUserId = new Map<string, string>();

  private creators: Creator[] = [
    {
      id: 'CRT001',
      name: 'Anjali',
      phone: '+91 91234 56789',
      email: 'anjali@gmail.com',
      bio: 'Compassionate listener and Malayalam language advisor.',
      languages: ['Malayalam'],
      gender: 'Female',
      experience: '2 Years',
      status: 'active',
      rating: 4.8,
      completedCalls: 142,
      revenueGenerated: 8520,
      ratePerMinute: 10,
      isOnline: true,
      profileImage: 'https://i.pravatar.cc/150?u=anjali',
      isNew: true,
    },
    {
      id: 'CRT002',
      name: 'Arjun',
      phone: '+91 92345 67890',
      email: 'arjun@gmail.com',
      bio: 'Certified relationship counselor and counselor.',
      languages: ['Malayalam', 'Tamil'],
      gender: 'Male',
      experience: '3 Years',
      status: 'active',
      rating: 4.9,
      completedCalls: 98,
      revenueGenerated: 7840,
      ratePerMinute: 10,
      isOnline: true,
      profileImage: 'https://i.pravatar.cc/150?u=arjun',
    },
    {
      id: 'CRT003',
      name: 'srevya',
      phone: '+91 93456 78901',
      email: 'srevya@gmail.com',
      bio: 'Empathetic listener and counselor.',
      languages: ['Telugu', 'Hindi'],
      gender: 'Female',
      experience: '1 Year',
      status: 'active',
      rating: 4.5,
      completedCalls: 45,
      revenueGenerated: 2700,
      ratePerMinute: 10,
      isOnline: true,
      profileImage: 'https://i.pravatar.cc/150?u=srevya',
    },
    {
      id: 'CRT004',
      name: 'Karthik',
      phone: '+91 94567 89012',
      email: 'karthik@gmail.com',
      bio: 'Tech advisor by day, listener by night.',
      languages: ['Malayalam', 'Kannada'],
      gender: 'Male',
      experience: '1 Year',
      status: 'active',
      rating: 4.0,
      completedCalls: 0,
      revenueGenerated: 0,
      ratePerMinute: 10,
      isOnline: true,
      profileImage: 'https://i.pravatar.cc/150?u=karthik',
    },
    {
      id: 'CRT005',
      name: 'Sangeetha',
      phone: '+91 95678 90123',
      email: 'sangeetha@gmail.com',
      bio: 'Deep thinker and empathetic listener.',
      languages: ['Malayalam', 'Hindi'],
      gender: 'Female',
      experience: '4 Years',
      status: 'active',
      rating: 4.7,
      completedCalls: 12,
      revenueGenerated: 120,
      ratePerMinute: 10,
      isOnline: true,
      profileImage: 'https://i.pravatar.cc/150?u=sangeetha',
      isNew: true,
    },
  ];

  constructor(private readonly supabase: SupabaseService) {}

  mapToDto(creator: Creator) {
    return {
      id: creator.id,
      name: creator.name,
      language: creator.languages[0] || 'English',
      gender: creator.gender,
      ratePerMinute: creator.ratePerMinute,
      isOnline: creator.isOnline,
      lastSeenAt: creator.lastSeenAt ?? null,
      lastSeenLabel: this.formatLastSeenLabel(creator.lastSeenAt, creator.isOnline),
      profileImage: creator.profileImage,
      isNew: creator.isNew ?? this.isRecentlyJoined(creator.createdAt),
    };
  }

  /** UI copy: "Online" or "Last seen 5 min ago". */
  formatLastSeenLabel(lastSeenAt?: string | null, isOnline?: boolean): string {
    if (isOnline) return 'Online';
    if (!lastSeenAt) return 'Offline';
    const elapsedMs = Date.now() - new Date(lastSeenAt).getTime();
    const minutes = Math.floor(elapsedMs / 60_000);
    if (minutes < 1) return 'Last seen just now';
    if (minutes < 60) return `Last seen ${minutes} min ago`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `Last seen ${hours}h ago`;
    const days = Math.floor(hours / 24);
    return `Last seen ${days}d ago`;
  }

  private isRecentlyJoined(createdAt?: string): boolean {
    if (!createdAt) return false;
    const created = new Date(createdAt).getTime();
    const sevenDaysAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
    return created >= sevenDaysAgo;
  }

  /** Online if last_seen_at is within CREATOR_ONLINE_THRESHOLD_SECONDS. */
  computeIsOnline(
    lastSeenAt?: string | null,
    onlineStatusFallback?: boolean,
  ): boolean {
    if (lastSeenAt) {
      const elapsedMs = Date.now() - new Date(lastSeenAt).getTime();
      return elapsedMs < CREATOR_ONLINE_THRESHOLD_SECONDS * 1000;
    }
    return Boolean(onlineStatusFallback);
  }

  async recordHeartbeat(userId: string): Promise<{ ok: true; lastSeenAt: string }> {
    const now = new Date().toISOString();

    if (this.supabase.isConfigured) {
      const client = this.supabase.getClient();

      const { data: userRow, error: userErr } = await client
        .from('users')
        .select('is_creator')
        .eq('id', userId)
        .maybeSingle();

      if (userErr) {
        throw new BadRequestException(userErr.message);
      }
      if (!userRow?.is_creator) {
        throw new ForbiddenException('Only creators can send heartbeat');
      }

      const { data: updated, error } = await client
        .from('creator_profiles')
        .update({ last_seen_at: now, online_status: true, is_online: true })
        .eq('user_id', userId)
        .select('last_seen_at')
        .maybeSingle();

      if (error) {
        throw new BadRequestException(error.message);
      }
      if (!updated) {
        throw new ForbiddenException('Creator profile not found');
      }

      return { ok: true, lastSeenAt: (updated.last_seen_at as string) || now };
    }

    this.lastSeenByUserId.set(userId, now);
    return { ok: true, lastSeenAt: now };
  }

  private async fetchActiveFromSupabase(): Promise<Creator[]> {
    const { data, error } = await this.supabase.getClient().from('users').select(`
        id,
        name,
        email,
        phone,
        gender,
        profile_image,
        status,
        created_at,
        creator_profiles!inner (
          bio,
          languages,
          experience,
          price_per_minute,
          rating,
          total_calls,
          total_earnings,
          online_status,
          is_online,
          last_seen_at
        )
      `)
      .eq('is_creator', true)
      .eq('status', 'active');

    if (error) {
      throw new Error(error.message);
    }

    if (!data?.length) {
      return [];
    }

    return data.map((row: Record<string, unknown>) => {
      const profile = row.creator_profiles as Record<string, unknown> | Record<string, unknown>[];
      const cp = Array.isArray(profile) ? profile[0] : profile;
      const languagesRaw = (cp?.languages as string) || '';
      const languages = languagesRaw
        ? languagesRaw.split(',').map((l) => l.trim()).filter(Boolean)
        : ['English'];
      const createdAt = row.created_at as string | undefined;

      return {
        id: row.id as string,
        name: (row.name as string) || 'Creator',
        phone: (row.phone as string) || '',
        email: (row.email as string) || '',
        bio: (cp?.bio as string) || '',
        languages,
        gender: (row.gender as string) || 'Female',
        experience: (cp?.experience as string) || '',
        status: 'active' as const,
        rating: Number(cp?.rating) || 0,
        completedCalls: Number(cp?.total_calls) || 0,
        revenueGenerated: Number(cp?.total_earnings) || 0,
        ratePerMinute: Number(cp?.price_per_minute) || 10,
        lastSeenAt:
          (cp?.last_seen_at as string) || this.lastSeenByUserId.get(row.id as string),
        isOnline: this.computeIsOnline(
          (cp?.last_seen_at as string) || this.lastSeenByUserId.get(row.id as string),
          Boolean(cp?.is_online ?? cp?.online_status),
        ),
        profileImage: (row.profile_image as string) || `https://i.pravatar.cc/150?u=${row.name}`,
        createdAt,
        isNew: this.isRecentlyJoined(createdAt),
      };
    });
  }

  async getActive(): Promise<Creator[]> {
    if (this.supabase.isConfigured) {
      try {
        const fromDb = await this.fetchActiveFromSupabase();
        if (fromDb.length > 0) {
          return fromDb;
        }
      } catch (e) {
        console.warn('Supabase creators fetch failed, using in-memory fallback:', (e as Error).message);
      }
    }
    return this.creators.filter((c) => c.status === 'active');
  }

  async getPending() {
    return this.creators.filter((c) => c.status === 'pending');
  }

  async getSuspended() {
    return this.creators.filter((c) => c.status === 'suspended');
  }

  async findOne(id: string) {
    if (this.supabase.isConfigured) {
      try {
        const active = await this.fetchActiveFromSupabase();
        const match = active.find((c) => c.id === id);
        if (match) return match;
      } catch {
        // fall through to in-memory
      }
    }
    const creator = this.creators.find((c) => c.id === id);
    if (!creator) {
      throw new NotFoundException(`Host listener with ID ${id} not found`);
    }
    return creator;
  }

  async approve(id: string) {
    const creator = await this.findOne(id);
    if (creator.status !== 'pending') {
      throw new BadRequestException('Profile is not in pending state');
    }
    creator.status = 'active';
    return {
      message: `Host profile ${creator.name} approved successfully`,
      creator,
    };
  }

  async reject(id: string) {
    const creator = await this.findOne(id);
    if (creator.status !== 'pending') {
      throw new BadRequestException('Profile is not in pending state');
    }
    this.creators = this.creators.filter((c) => c.id !== id);
    return {
      message: `Host application for ${creator.name} rejected`,
    };
  }

  async suspend(id: string) {
    const creator = await this.findOne(id);
    creator.status = creator.status === 'suspended' ? 'active' : 'suspended';
    return {
      message: `Host profile status toggled to ${creator.status}`,
      creator,
    };
  }
}
