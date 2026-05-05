export default function Card({ children, className = '' }) {
  return (
    <div className={`bg-[#111111] border border-[#2a2a2a] rounded-lg p-5 ${className}`}>
      {children}
    </div>
  );
}
