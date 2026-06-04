/** Normalize API languages field (string or string[]). */
export function normalizeLanguages(languages: unknown): string[] {
  if (Array.isArray(languages)) {
    return languages.map(String).filter(Boolean);
  }
  if (typeof languages === 'string' && languages.trim()) {
    return languages.split(',').map((l) => l.trim()).filter(Boolean);
  }
  return ['English'];
}
