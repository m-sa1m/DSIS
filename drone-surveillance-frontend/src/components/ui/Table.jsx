export default function Table({ headers, rows, renderRow }) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm text-left">
        <thead>
          <tr className="border-b border-[#2a2a2a]">
            {headers.map((h) => (
              <th key={h} className="px-4 py-3 text-xs font-medium text-[#a0a0a0] uppercase tracking-wider">
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.length === 0 ? (
            <tr>
              <td colSpan={headers.length} className="px-4 py-8 text-center text-[#a0a0a0]">
                No data available
              </td>
            </tr>
          ) : (
            rows.map((row, i) => (
              <tr key={i} className={`border-b border-[#1a1a1a] ${i % 2 === 0 ? 'bg-[#111111]' : 'bg-[#0f0f0f]'} hover:bg-[#1a1a1a] transition-colors`}>
                {renderRow(row)}
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  );
}
