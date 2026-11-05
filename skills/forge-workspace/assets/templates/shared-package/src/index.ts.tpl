export function normalizeLabel(value: string): string {
  return value.trim().replace(/\s+/g, ' ');
}
