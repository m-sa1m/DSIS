const colorMap = {
  Active: 'bg-emerald-400/10 text-emerald-400 border-emerald-400/20',
  Inactive: 'bg-zinc-400/10 text-zinc-400 border-zinc-400/20',
  'Under Maintenance': 'bg-amber-400/10 text-amber-400 border-amber-400/20',
  Low: 'bg-emerald-400/10 text-emerald-400 border-emerald-400/20',
  Medium: 'bg-amber-400/10 text-amber-400 border-amber-400/20',
  High: 'bg-red-400/10 text-red-400 border-red-400/20',
  Critical: 'bg-red-500/15 text-red-500 border-red-500/20',
  New: 'bg-blue-400/10 text-blue-400 border-blue-400/20',
  Acknowledged: 'bg-amber-400/10 text-amber-400 border-amber-400/20',
  Resolved: 'bg-emerald-400/10 text-emerald-400 border-emerald-400/20',
  Scheduled: 'bg-blue-400/10 text-blue-400 border-blue-400/20',
  'In Progress': 'bg-amber-400/10 text-amber-400 border-amber-400/20',
  Completed: 'bg-emerald-400/10 text-emerald-400 border-emerald-400/20',
  Aborted: 'bg-red-400/10 text-red-400 border-red-400/20',
  Open: 'bg-blue-400/10 text-blue-400 border-blue-400/20',
  'Under Review': 'bg-amber-400/10 text-amber-400 border-amber-400/20',
  Archived: 'bg-zinc-400/10 text-zinc-400 border-zinc-400/20',
  Admin: 'bg-purple-400/10 text-purple-400 border-purple-400/20',
  Operator: 'bg-blue-400/10 text-blue-400 border-blue-400/20',
  Analyst: 'bg-teal-400/10 text-teal-400 border-teal-400/20',
};

export default function Badge({ children }) {
  const colors = colorMap[children] || 'bg-zinc-400/10 text-zinc-400 border-zinc-400/20';
  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded text-xs font-medium border ${colors}`}>
      {children}
    </span>
  );
}
