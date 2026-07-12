type CsvValue = string | number | boolean | null | undefined;

function escapeCell(value: CsvValue): string {
  const s = value === null || value === undefined ? "" : String(value);
  // Quote only when the cell contains a delimiter, quote, or newline (RFC 4180).
  return /[",\r\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

// Minimal RFC 4180 CSV serializer (CRLF line endings, quote-escaped cells).
// Hand-rolled to keep the dependency footprint small — see PLAN.md §8.2.
export function toCsv(headers: string[], rows: CsvValue[][]): string {
  return [headers, ...rows].map((row) => row.map(escapeCell).join(",")).join("\r\n") + "\r\n";
}
