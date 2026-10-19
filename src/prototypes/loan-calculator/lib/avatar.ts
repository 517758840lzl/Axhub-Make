import type { ProfileGender } from './types';

export const DEFAULT_AVATAR: Record<ProfileGender, string> = {
  private: '🧑‍💼',
  male: '👨',
  female: '👩',
};

const LEGACY_DEFAULT_AVATARS = ['👱‍♀️'];

export function defaultAvatar(gender: ProfileGender = 'private'): string {
  return DEFAULT_AVATAR[gender] ?? DEFAULT_AVATAR.private;
}

export function isDefaultAvatar(avatar: string): boolean {
  const value = avatar.trim();
  return value === '' || Object.values(DEFAULT_AVATAR).includes(value) || LEGACY_DEFAULT_AVATARS.includes(value);
}

export function resolvedAvatar(avatar: string, gender: ProfileGender = 'private'): string {
  return isDefaultAvatar(avatar) ? defaultAvatar(gender) : avatar.trim();
}
