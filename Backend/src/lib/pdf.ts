import PDFDocument from "pdfkit";

type Cell = string | number | null;

const MARGIN = 40;
const HEADER_FONT = "Helvetica-Bold";
const BODY_FONT = "Helvetica";
const FONT_SIZE = 9;
const CELL_PADDING = 4;

// Renders a single-table report as an A4 landscape PDF. pdfkit buffers the
// content, so callers pipe the returned doc to the response and call end().
export function tablePdf(title: string, headers: string[], rows: Cell[][]): PDFKit.PDFDocument {
  const doc = new PDFDocument({ size: "A4", layout: "landscape", margin: MARGIN });
  const tableWidth = doc.page.width - MARGIN * 2;
  const colWidth = tableWidth / headers.length;

  doc.font(HEADER_FONT).fontSize(16).text(title);
  doc
    .font(BODY_FONT)
    .fontSize(FONT_SIZE)
    .fillColor("#666666")
    .text(`Generated ${new Date().toISOString()}`)
    .fillColor("#000000")
    .moveDown();

  const drawHeaderRow = () => {
    drawCells(headers, HEADER_FONT);
    doc
      .moveTo(MARGIN, doc.y)
      .lineTo(MARGIN + tableWidth, doc.y)
      .strokeColor("#999999")
      .stroke();
    doc.moveDown(0.3);
  };

  const drawCells = (cells: Cell[], font: string) => {
    doc.font(font).fontSize(FONT_SIZE);
    const texts = cells.map((cell) => (cell === null ? "—" : String(cell)));
    const rowHeight =
      Math.max(...texts.map((t) => doc.heightOfString(t, { width: colWidth - CELL_PADDING }))) +
      CELL_PADDING;

    if (doc.y + rowHeight > doc.page.height - MARGIN) {
      doc.addPage();
      if (font !== HEADER_FONT) drawHeaderRow();
    }

    const y = doc.y;
    texts.forEach((text, i) =>
      doc.text(text, MARGIN + i * colWidth, y, { width: colWidth - CELL_PADDING }),
    );
    doc.y = y + rowHeight;
    doc.x = MARGIN;
  };

  drawHeaderRow();
  for (const row of rows) drawCells(row, BODY_FONT);
  if (rows.length === 0) doc.font(BODY_FONT).fontSize(FONT_SIZE).text("No data.");

  return doc;
}
