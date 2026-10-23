export function Avatar({ name }: { name: string }) {
  const initials = name.trim().split(/\s+/).filter(Boolean).slice(-2).map(word => Array.from(word)[0]).join('').toLocaleUpperCase('vi');
  return <span className="ec-avatar" aria-hidden="true">{initials}</span>;
}
