export function Logo({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 36 36" className={className} aria-hidden>
      <rect width="36" height="36" rx="10" fill="#3b3bd6" />
      <path
        d="M10 10 H26 V18 H10 V26 H26"
        fill="none"
        stroke="#ffd36b"
        strokeWidth="4"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <circle cx="10" cy="10" r="3" fill="#fff" />
      <circle cx="26" cy="26" r="3" fill="#fff" />
    </svg>
  );
}
