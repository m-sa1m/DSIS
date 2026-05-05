export default function Input({ label, error, ...props }) {
  return (
    <div className="mb-3">
      {label && <label className="block text-xs font-medium text-[#a0a0a0] mb-1">{label}</label>}
      <input
        className={`w-full px-3 py-2 bg-[#0a0a0a] border rounded-md text-sm text-white placeholder-[#555] focus:border-[#4a90d9] transition-colors ${
          error ? 'border-red-500' : 'border-[#2a2a2a]'
        }`}
        {...props}
      />
      {error && <p className="mt-1 text-xs text-red-400">{error}</p>}
    </div>
  );
}
