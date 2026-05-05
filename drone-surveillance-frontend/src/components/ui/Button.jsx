const variants = {
  primary: 'bg-[#4a90d9] text-white hover:bg-[#3a7bc8]',
  secondary: 'border border-[#2a2a2a] text-[#a0a0a0] hover:border-[#4a90d9] hover:text-white',
  danger: 'text-red-400 hover:text-red-300 hover:bg-red-400/10',
};

export default function Button({ children, variant = 'primary', className = '', ...props }) {
  return (
    <button
      className={`px-4 py-2 rounded-md text-sm font-medium transition-colors cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed ${variants[variant] || variants.primary} ${className}`}
      {...props}
    >
      {children}
    </button>
  );
}
