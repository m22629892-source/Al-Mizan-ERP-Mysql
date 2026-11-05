import Decimal from 'decimal.js';
import * as XLSX from 'xlsx';
import {
  runDescriptiveTest,
  runCorrelationTest,
  runTwoIndependentGroupsTest,
  runPairedSamplesTest,
  runAnovaAndKruskalTest,
  runContingencyTest,
  StatisticalTestType,
  StatisticalTestResult
} from './statistical-engine.js';

/**
 * Data types supported for spreadsheet columns
 */
export type ColumnDataType = 'number' | 'date' | 'text' | 'category' | 'currency';

export interface ColumnMeta {
  name: string;
  originalName: string;
  index: number;
  inferredType: ColumnDataType;
  userType?: ColumnDataType;
  totalCount: number;
  nonEmptyCount: number;
  nullCount: number;
  uniqueCount: number;
  sampleValues: any[];
}

export interface SheetColumnMapping {
  amountColumn?: string;
  currencyColumn?: string;
  typeColumn?: string;
  invoiceColumn?: string;
  dateColumn?: string;
  dataLevel?: 'line_item' | 'invoice'; // If 'invoice', deduplicate invoice total before summing
}

export interface SheetAnalysis {
  name: string;
  totalRows: number;
  headerRowIndex: number; // 0-indexed
  columns: ColumnMeta[];
  duplicateRowsCount: number;
  currenciesDetected: string[];
  hasInvoiceNumbers: boolean;
  hasSalesAndReturns: boolean;
  columnMapping?: SheetColumnMapping;
}

export interface NumericColumnStats {
  column: string;
  currency: string;
  count: number;
  sum: string;
  average: string;
  median: string;
  min: string;
  max: string;
  minRowIndices?: number[];
  maxRowIndices?: number[];
}

export interface MultiCurrencyStats {
  column: string;
  isMultiCurrency: boolean;
  currencies: Record<string, NumericColumnStats>;
  primaryStats?: NumericColumnStats;
  unspecifiedCurrencyStats?: NumericColumnStats;
  unspecifiedCount: number;
  totalValidCount: number;
  excludedCount: number;
  excludedReasons: Record<string, number>;
}

export interface GroupByResult {
  groupColumn: string;
  groupedBy: 'period' | 'customer' | 'supplier' | 'item' | 'branch' | 'custom';
  items: Array<{
    key: string;
    label: string;
    count: number;
    sum: string;
    currency: string;
    matchingRowIndices: number[];
  }>;
}

export interface NetSalesCalculation {
  grossSales: string;
  salesCount: number;
  salesDistinctInvoices: number;
  totalReturns: string;
  returnsCount: number;
  returnsDistinctInvoices: number;
  netSales: string;
  currency: string;
  assumptionUsed: string;
  salesRowIndices: number[];
  returnsRowIndices: number[];
}

export interface MultiCurrencyNetSales {
  byCurrency: Record<string, NetSalesCalculation>;
  primaryCalculation?: NetSalesCalculation;
  isMultiCurrency: boolean;
}

export interface AnalysisPlan {
  sheetName?: string;
  goal: string;
  operation:
    | 'sum'
    | 'average'
    | 'median'
    | 'min_max'
    | 'count'
    | 'distinct_count'
    | 'net_sales'
    | 'group_by'
    | 'filter_list'
    | 'statistical_test';
  targetColumn?: string;
  secondaryColumn?: string;
  currencyColumn?: string;
  invoiceColumn?: string;
  typeColumn?: string;
  groupByColumn?: string;
  dateColumn?: string;
  dataLevel?: 'line_item' | 'invoice';
  statisticalTestType?: StatisticalTestType;
  alpha?: number;
  periodFilter?: {
    startDate?: string;
    endDate?: string;
    month?: string;
    year?: string;
  };
  filters?: Array<{
    column: string;
    operator: 'equals' | 'contains' | 'greater_than' | 'less_than' | 'in';
    value: any;
  }>;
  limit?: number;
  sortOrder?: 'asc' | 'desc';
}

export interface PlanExecutionResult {
  success: boolean;
  goal: string;
  sheetName: string;
  operation: string;
  primaryValue?: string;
  secondaryValue?: string;
  unitOrCurrency?: string;
  periodDescription?: string;
  matchingRowCount: number;
  matchingRowIndices: number[];
  columnsUsed: string[];
  assumptionUsed?: string;
  breakdown?: Array<{ label: string; value: string; count: number; rowIndices: number[] }>;
  statisticalResult?: StatisticalTestResult;
  error?: string;
}

/**
 * Normalize Arabic digits (٠١٢٣٤٥٦٧٨٩) and Persian digits (۰۱۲۳۴۵۶۷۸۹) to standard ASCII 0-9
 */
export function normalizeArabicDigits(str: string): string {
  if (!str) return '';
  return String(str)
    .replace(/[٠۰]/g, '0')
    .replace(/[١۱]/g, '1')
    .replace(/[٢۲]/g, '2')
    .replace(/[٣۳]/g, '3')
    .replace(/[٤۴]/g, '4')
    .replace(/[٥۵]/g, '5')
    .replace(/[٦۶]/g, '6')
    .replace(/[٧۷]/g, '7')
    .replace(/[٨۸]/g, '8')
    .replace(/[٩۹]/g, '9');
}

/**
 * Clean and parse a financial or numeric cell value.
 * Handles currencies (ج.م, EGP, $, USD, etc.), percentages, Arabic commas and decimals.
 */
export function parseNumericValue(val: any): { isNumber: boolean; value?: Decimal; rawClean?: string; currency?: string } {
  if (val === null || val === undefined || val === '') {
    return { isNumber: false };
  }

  if (typeof val === 'number') {
    if (isNaN(val) || !isFinite(val)) return { isNumber: false };
    return { isNumber: true, value: new Decimal(val) };
  }

  let str = normalizeArabicDigits(String(val)).trim();

  // Detect and extract currency symbol
  let currency: string | undefined;
  if (/ج\.م|جم|جنيه|egp|l\.e/i.test(str)) {
    currency = 'EGP';
  } else if (/\$|usd|دولار/i.test(str)) {
    currency = 'USD';
  } else if (/€|eur|يورو/i.test(str)) {
    currency = 'EUR';
  } else if (/ر\.س|رس|sar|ريال/i.test(str)) {
    currency = 'SAR';
  }

  // Remove currency words, spaces, symbols
  str = str.replace(/[ج\.مجمجنيهegpl\$usdدولار€eurيورور\.سرسsarريال%]/gi, '').trim();

  // Accounting negative numbers in parentheses: (1,250.00) => -1250.00
  let isNegative = false;
  if (str.startsWith('(') && str.endsWith(')')) {
    isNegative = true;
    str = str.slice(1, -1).trim();
  } else if (str.startsWith('-')) {
    isNegative = true;
    str = str.slice(1).trim();
  }

  // Comma & dot handling
  if (str.includes(',') && str.includes('.')) {
    str = str.replace(/,/g, '');
  } else if (str.includes(',')) {
    const parts = str.split(',');
    if (parts.length === 2 && parts[1].length <= 2) {
      str = parts[0] + '.' + parts[1];
    } else {
      str = str.replace(/,/g, '');
    }
  }

  // Arabic decimal separator (٫)
  str = str.replace(/٫/g, '.').replace(/٬/g, '');

  if (!/^-?\d+(\.\d+)?$/.test(str)) {
    return { isNumber: false, rawClean: str };
  }

  try {
    let d = new Decimal(str);
    if (isNegative) d = d.negated();
    return { isNumber: true, value: d, rawClean: str, currency };
  } catch {
    return { isNumber: false, rawClean: str };
  }
}

/**
 * Parse date values supporting Excel date serial numbers, ISO strings, Egyptian standard formats
 */
export function parseDateValue(val: any): { isDate: boolean; date?: Date; formatted?: string } {
  if (val === null || val === undefined || val === '') {
    return { isDate: false };
  }

  if (val instanceof Date) {
    if (isNaN(val.getTime())) return { isDate: false };
    const formatted = val.toISOString().slice(0, 10);
    return { isDate: true, date: val, formatted };
  }

  // Excel serial number date
  if (typeof val === 'number' && val > 20000 && val < 70000) {
    const epoch = new Date(1899, 11, 30);
    const d = new Date(epoch.getTime() + val * 86400000);
    if (!isNaN(d.getTime())) {
      const formatted = d.toISOString().slice(0, 10);
      return { isDate: true, date: d, formatted };
    }
  }

  let str = normalizeArabicDigits(String(val)).trim();
  str = str.split('T')[0].split(' ')[0];

  // Try standard YYYY-MM-DD
  if (/^\d{4}[-/.]\d{1,2}[-/.]\d{1,2}$/.test(str)) {
    const parts = str.split(/[-/.]/).map(p => parseInt(p, 10));
    const d = new Date(parts[0], parts[1] - 1, parts[2]);
    if (!isNaN(d.getTime())) {
      const formatted = `${parts[0]}-${String(parts[1]).padStart(2, '0')}-${String(parts[2]).padStart(2, '0')}`;
      return { isDate: true, date: d, formatted };
    }
  }

  // Try Egyptian DD/MM/YYYY or DD-MM-YYYY
  if (/^\d{1,2}[-/.]\d{1,2}[-/.]\d{4}$/.test(str)) {
    const parts = str.split(/[-/.]/).map(p => parseInt(p, 10));
    const d = new Date(parts[2], parts[1] - 1, parts[0]);
    if (!isNaN(d.getTime())) {
      const formatted = `${parts[2]}-${String(parts[1]).padStart(2, '0')}-${String(parts[0]).padStart(2, '0')}`;
      return { isDate: true, date: d, formatted };
    }
  }

  return { isDate: false };
}

/**
 * Infer best column data type from sample values
 */
export function inferColumnType(values: any[], colName: string): ColumnDataType {
  const nameLower = colName.toLowerCase();

  if (/مبلغ|سعر|قيمة|إجمالي|صافي|ضريبة|تكلفة|amount|price|total|net|tax|cost|vat/i.test(nameLower)) {
    return 'number';
  }
  if (/تاريخ|يوم|شهر|سنة|date|day|month|year/i.test(nameLower)) {
    return 'date';
  }
  if (/عملة|currency/i.test(nameLower)) {
    return 'currency';
  }

  const nonEmpties = values.filter(v => v !== null && v !== undefined && String(v).trim() !== '');
  if (nonEmpties.length === 0) return 'text';

  let numCount = 0;
  let dateCount = 0;

  for (const v of nonEmpties) {
    if (parseNumericValue(v).isNumber) numCount++;
    if (parseDateValue(v).isDate) dateCount++;
  }

  const threshold = nonEmpties.length * 0.7;
  if (numCount >= threshold) return 'number';
  if (dateCount >= threshold) return 'date';

  const uniqueCount = new Set(nonEmpties.map(String)).size;
  if (uniqueCount <= 12 && nonEmpties.length >= 10) return 'category';

  return 'text';
}

/**
 * Parse an Excel worksheet into structured row objects with formula detection and metadata
 */
export function parseSheetData(
  worksheet: XLSX.WorkSheet,
  sheetName: string,
  headerRowIndex: number = 0,
  userTypeOverrides?: Record<string, ColumnDataType>
): {
  sheetAnalysis: SheetAnalysis;
  rawHeaders: string[];
  rows: Array<Record<string, any>>;
  rawRows: any[][];
  unreadableCellsCount: number;
} {
  const cellRefRegex = /^([A-Z]+)(\d+)$/;
  const rawGrid: any[][] = [];
  let maxCol = 0;
  let maxRow = 0;
  let unreadableCellsCount = 0;

  for (const cellKey of Object.keys(worksheet)) {
    if (cellKey.startsWith('!')) continue;
    const match = cellKey.match(cellRefRegex);
    if (!match) continue;

    const colLetters = match[1];
    const rowNum = parseInt(match[2], 10) - 1;

    let colNum = 0;
    for (let i = 0; i < colLetters.length; i++) {
      colNum = colNum * 26 + (colLetters.charCodeAt(i) - 64);
    }
    colNum -= 1;

    if (rowNum > maxRow) maxRow = rowNum;
    if (colNum > maxCol) maxCol = colNum;

    if (!rawGrid[rowNum]) rawGrid[rowNum] = [];

    const cellObj = worksheet[cellKey];
    let val: any = cellObj.v;

    if (cellObj.f) {
      if (cellObj.t === 'e' || val === undefined) {
        val = cellObj.w || '[صيغة بدون قيمة محفوظة]';
        unreadableCellsCount++;
      } else {
        val = cellObj.v !== undefined ? cellObj.v : cellObj.w;
      }
    } else if (cellObj.w !== undefined && typeof cellObj.v !== 'number' && typeof cellObj.v !== 'boolean') {
      val = cellObj.w;
    }

    rawGrid[rowNum][colNum] = val;
  }

  const effectiveHeaderRow = Math.min(headerRowIndex, Math.max(0, rawGrid.length - 1));
  const rawHeadersRow = rawGrid[effectiveHeaderRow] || [];

  const rawHeaders: string[] = [];
  const colCount = Math.max(maxCol + 1, rawHeadersRow.length);

  for (let c = 0; c < colCount; c++) {
    const rawVal = rawHeadersRow[c];
    let name = rawVal ? String(rawVal).trim() : '';
    if (!name) name = `عمود_${c + 1}`;
    let finalName = name;
    let dupCounter = 1;
    while (rawHeaders.includes(finalName)) {
      dupCounter++;
      finalName = `${name}_${dupCounter}`;
    }
    rawHeaders.push(finalName);
  }

  const rows: Array<Record<string, any>> = [];
  const seenRowStrings = new Set<string>();
  let duplicateRowsCount = 0;

  for (let r = effectiveHeaderRow + 1; r <= maxRow; r++) {
    const gridRow = rawGrid[r] || [];
    const isCompletelyEmpty = gridRow.every(cell => cell === null || cell === undefined || String(cell).trim() === '');
    if (isCompletelyEmpty) continue;

    const rowObj: Record<string, any> = { __rowIndex: r + 1 };
    const rowValuesForDupCheck: string[] = [];

    for (let c = 0; c < rawHeaders.length; c++) {
      const colName = rawHeaders[c];
      const cellVal = gridRow[c] !== undefined ? gridRow[c] : null;
      rowObj[colName] = cellVal;
      rowValuesForDupCheck.push(String(cellVal ?? ''));
    }

    const rowHash = rowValuesForDupCheck.join('|||');
    if (seenRowStrings.has(rowHash)) {
      duplicateRowsCount++;
    } else {
      seenRowStrings.add(rowHash);
    }

    rows.push(rowObj);
  }

  const columns: ColumnMeta[] = [];
  const currenciesSet = new Set<string>();
  let hasInvoiceNumbers = false;
  let hasSalesAndReturns = false;

  for (let c = 0; c < rawHeaders.length; c++) {
    const colName = rawHeaders[c];
    const colValues = rows.map(r => r[colName]);
    const nonEmpty = colValues.filter(v => v !== null && v !== undefined && String(v).trim() !== '');

    const inferred = inferColumnType(colValues, colName);
    const userType = userTypeOverrides?.[colName];

    for (const v of colValues) {
      const numRes = parseNumericValue(v);
      if (numRes.currency) currenciesSet.add(numRes.currency);
    }

    if (/عملة|currency/i.test(colName)) {
      for (const v of nonEmpty) {
        const str = String(v).trim().toUpperCase();
        if (str.length >= 2 && str.length <= 4) currenciesSet.add(str);
      }
    }

    if (/رقم_الفاتورة|رقم الفاتورة|الفاتورة|invoice_no|invoice_number|inv_no/i.test(colName)) {
      hasInvoiceNumbers = true;
    }

    if (/نوع_الحركة|نوع الفاتورة|البيان|مرتجع|مردود|return|type/i.test(colName)) {
      hasSalesAndReturns = true;
    }

    const uniqueSet = new Set(nonEmpty.map(String));

    columns.push({
      name: colName,
      originalName: rawHeadersRow[c] ? String(rawHeadersRow[c]) : colName,
      index: c,
      inferredType: inferred,
      userType,
      totalCount: colValues.length,
      nonEmptyCount: nonEmpty.length,
      nullCount: colValues.length - nonEmpty.length,
      uniqueCount: uniqueSet.size,
      sampleValues: nonEmpty.slice(0, 5)
    });
  }

  const currenciesDetected = Array.from(currenciesSet);

  // Auto-detect default column mapping
  const amountCol = columns.find(c => /إجمالي|صافي|مبلغ|قيمة|total|net|amount|price/i.test(c.name))?.name;
  const currencyCol = columns.find(c => /عملة|currency/i.test(c.name))?.name;
  const typeCol = columns.find(c => /نوع_الحركة|نوع الفاتورة|البيان|مرتجع|type/i.test(c.name))?.name;
  const invoiceCol = columns.find(c => /رقم_الفاتورة|رقم الفاتورة|الفاتورة|invoice/i.test(c.name))?.name;
  const dateCol = columns.find(c => /تاريخ|date/i.test(c.name))?.name;

  const columnMapping: SheetColumnMapping = {
    amountColumn: amountCol,
    currencyColumn: currencyCol,
    typeColumn: typeCol,
    invoiceColumn: invoiceCol,
    dateColumn: dateCol,
    dataLevel: 'line_item'
  };

  const sheetAnalysis: SheetAnalysis = {
    name: sheetName,
    totalRows: rows.length,
    headerRowIndex: effectiveHeaderRow,
    columns,
    duplicateRowsCount,
    currenciesDetected,
    hasInvoiceNumbers,
    hasSalesAndReturns,
    columnMapping
  };

  return {
    sheetAnalysis,
    rawHeaders,
    rows,
    rawRows: rawGrid,
    unreadableCellsCount
  };
}

/**
 * Determine the currency of a specific row given column settings or value content.
 * Never silently defaults to EGP! If ambiguous or absent, classifies as '(عملة غير محددة)'.
 */
export function resolveRowCurrency(row: Record<string, any>, colName: string, currencyCol?: string): string {
  if (currencyCol && row[currencyCol]) {
    const c = String(row[currencyCol]).trim().toUpperCase();
    if (c) return c;
  }
  const parsed = parseNumericValue(row[colName]);
  if (parsed.currency) return parsed.currency;
  return '(عملة غير محددة)';
}

/**
 * Compute multi-currency descriptive statistics for a numeric column using Decimal.js precision.
 * Strictly separates different currencies (e.g. EGP vs USD) and never mixes them.
 */
export function computeMultiCurrencyColumnStats(
  rows: Array<Record<string, any>>,
  colName: string,
  currencyCol?: string,
  targetCurrency?: string
): MultiCurrencyStats {
  const groups: Record<string, Array<{ val: Decimal; rowIdx: number; exRow: number }>> = {};
  const excludedReasons: Record<string, number> = {
    'خلايا فارغة': 0,
    'قيم غير رقمية': 0
  };

  let totalValidCount = 0;
  let unspecifiedCount = 0;

  rows.forEach((row, idx) => {
    const rawVal = row[colName];
    if (rawVal === null || rawVal === undefined || String(rawVal).trim() === '') {
      excludedReasons['خلايا فارغة']++;
      return;
    }

    const numRes = parseNumericValue(rawVal);
    if (!numRes.isNumber || !numRes.value) {
      excludedReasons['قيم غير رقمية']++;
      return;
    }

    const curr = resolveRowCurrency(row, colName, currencyCol);
    if (curr === '(عملة غير محددة)') unspecifiedCount++;

    if (!groups[curr]) groups[curr] = [];
    groups[curr].push({
      val: numRes.value,
      rowIdx: idx,
      exRow: row.__rowIndex || idx + 1
    });
    totalValidCount++;
  });

  const currenciesStats: Record<string, NumericColumnStats> = {};

  for (const [curr, items] of Object.entries(groups)) {
    if (items.length === 0) continue;

    let sum = new Decimal(0);
    let minItem = items[0];
    let maxItem = items[0];

    for (const item of items) {
      sum = sum.plus(item.val);
      if (item.val.lessThan(minItem.val)) minItem = item;
      if (item.val.greaterThan(maxItem.val)) maxItem = item;
    }

    const avg = sum.dividedBy(items.length);

    // Median
    const sorted = [...items].sort((a, b) => a.val.comparedTo(b.val));
    const mid = Math.floor(sorted.length / 2);
    let median: Decimal;
    if (sorted.length % 2 === 0) {
      median = sorted[mid - 1].val.plus(sorted[mid].val).dividedBy(2);
    } else {
      median = sorted[mid].val;
    }

    // Min and Max row indices (including ties)
    const minRowIndices = items.filter(it => it.val.equals(minItem.val)).map(it => it.rowIdx);
    const maxRowIndices = items.filter(it => it.val.equals(maxItem.val)).map(it => it.rowIdx);

    currenciesStats[curr] = {
      column: colName,
      currency: curr,
      count: items.length,
      sum: sum.toFixed(2),
      average: avg.toFixed(2),
      median: median.toFixed(2),
      min: minItem.val.toFixed(2),
      max: maxItem.val.toFixed(2),
      minRowIndices,
      maxRowIndices
    };
  }

  const distinctCurrs = Object.keys(currenciesStats);
  const isMultiCurrency = distinctCurrs.length > 1;

  let primaryStats: NumericColumnStats | undefined;
  if (targetCurrency && currenciesStats[targetCurrency]) {
    primaryStats = currenciesStats[targetCurrency];
  } else if (distinctCurrs.length === 1) {
    primaryStats = currenciesStats[distinctCurrs[0]];
  }

  const totalExcluded = Object.values(excludedReasons).reduce((a, b) => a + b, 0);

  return {
    column: colName,
    isMultiCurrency,
    currencies: currenciesStats,
    primaryStats,
    unspecifiedCurrencyStats: currenciesStats['(عملة غير محددة)'],
    unspecifiedCount,
    totalValidCount,
    excludedCount: totalExcluded,
    excludedReasons
  };
}

/**
 * Backward compatible single-result computeNumericColumnStats.
 * When called without specific currency, if all rows share 1 currency, returns that.
 * If multiple currencies exist, separates them and returns target currency or primary currency.
 */
export function computeNumericColumnStats(
  rows: Array<Record<string, any>>,
  colName: string,
  targetCurrency?: string,
  currencyCol?: string
): NumericColumnStats | null {
  const multi = computeMultiCurrencyColumnStats(rows, colName, currencyCol, targetCurrency);
  if (multi.primaryStats) return multi.primaryStats;

  const currs = Object.keys(multi.currencies);
  if (currs.length > 0) {
    // Return first available currency stats
    return multi.currencies[currs[0]];
  }

  return null;
}

/**
 * Compute Net Sales vs Returns per currency with explicit assumptions.
 * Handles positive or negative returns correctly (deducts return amount once).
 * Differentiates unique invoices count from line items count.
 * Deduplicates repeated invoice totals if dataLevel === 'invoice'.
 */
export function calculateNetSales(
  rows: Array<Record<string, any>>,
  amountCol: string,
  typeCol?: string,
  invoiceCol?: string,
  currencyCol?: string,
  targetCurrency?: string,
  dataLevel: 'line_item' | 'invoice' = 'line_item'
): NetSalesCalculation {
  const multi = calculateMultiCurrencyNetSales(
    rows,
    amountCol,
    typeCol,
    invoiceCol,
    currencyCol,
    dataLevel
  );

  if (targetCurrency && multi.byCurrency[targetCurrency]) {
    return multi.byCurrency[targetCurrency];
  }

  if (multi.primaryCalculation) {
    return multi.primaryCalculation;
  }

  // Return first available or empty fallback
  const firstCurr = Object.keys(multi.byCurrency)[0];
  if (firstCurr) return multi.byCurrency[firstCurr];

  return {
    grossSales: '0.00',
    salesCount: 0,
    salesDistinctInvoices: 0,
    totalReturns: '0.00',
    returnsCount: 0,
    returnsDistinctInvoices: 0,
    netSales: '0.00',
    currency: targetCurrency || '(عملة غير محددة)',
    assumptionUsed: 'لا توجد حركات مبيعات أو مرتجعات مطابقة.',
    salesRowIndices: [],
    returnsRowIndices: []
  };
}

export function calculateMultiCurrencyNetSales(
  rows: Array<Record<string, any>>,
  amountCol: string,
  typeCol?: string,
  invoiceCol?: string,
  currencyCol?: string,
  dataLevel: 'line_item' | 'invoice' = 'line_item'
): MultiCurrencyNetSales {
  const byCurr: Record<
    string,
    {
      grossSales: Decimal;
      totalReturns: Decimal;
      salesRowIndices: number[];
      returnsRowIndices: number[];
      salesInvoices: Set<string>;
      returnsInvoices: Set<string>;
      seenInvoices: Set<string>;
    }
  > = {};

  let assumptionUsed = '';
  if (typeCol) {
    assumptionUsed = `تم تصنيف العمليات بالاعتماد على عمود [${typeCol}]؛ حيث احتُسبت الصفوف المحتوية على 'مرتجع' أو 'مردود' كمرتجعات، وخُصمت قيمتها من المبيعات بغض النظر عن إشارة المبلغ (موجب أو سالب) لتفادي الخصم المزدوج.`;
  } else {
    assumptionUsed = `تم اعتبار القيم الموجبة في عمود [${amountCol}] كمبيعات، والقيم السالبة كمرتجعات تُخصم قيمتها المطلقة.`;
  }

  if (dataLevel === 'invoice' && invoiceCol) {
    assumptionUsed += ` وتم احتساب إجمالي الفاتورة مرة واحدة لكل رقم فاتورة منعاً لتكرار حساب إجمالي الفاتورة مع كل بند.`;
  }

  rows.forEach((row, idx) => {
    const numRes = parseNumericValue(row[amountCol]);
    if (!numRes.isNumber || !numRes.value) return;

    const val = numRes.value;
    const invNo = invoiceCol && row[invoiceCol] ? String(row[invoiceCol]).trim() : '';
    const curr = resolveRowCurrency(row, amountCol, currencyCol);

    if (!byCurr[curr]) {
      byCurr[curr] = {
        grossSales: new Decimal(0),
        totalReturns: new Decimal(0),
        salesRowIndices: [],
        returnsRowIndices: [],
        salesInvoices: new Set<string>(),
        returnsInvoices: new Set<string>(),
        seenInvoices: new Set<string>()
      };
    }

    const group = byCurr[curr];

    // If data level is invoice and invoice already accounted for
    if (dataLevel === 'invoice' && invNo && group.seenInvoices.has(invNo)) {
      return;
    }
    if (invNo) group.seenInvoices.add(invNo);

    let isReturn = false;
    if (typeCol && row[typeCol]) {
      const typeStr = String(row[typeCol]).trim().toLowerCase();
      if (/مرتجع|مردود|return|credit_note|خصم/i.test(typeStr)) {
        isReturn = true;
      }
    } else if (val.isNegative()) {
      isReturn = true;
    }

    if (isReturn) {
      // Always add absolute value so positive or negative returns are deducted once
      group.totalReturns = group.totalReturns.plus(val.abs());
      group.returnsRowIndices.push(idx);
      if (invNo) group.returnsInvoices.add(invNo);
    } else {
      group.grossSales = group.grossSales.plus(val);
      group.salesRowIndices.push(idx);
      if (invNo) group.salesInvoices.add(invNo);
    }
  });

  const results: Record<string, NetSalesCalculation> = {};
  for (const [curr, g] of Object.entries(byCurr)) {
    const net = g.grossSales.minus(g.totalReturns);
    results[curr] = {
      grossSales: g.grossSales.toFixed(2),
      salesCount: g.salesRowIndices.length,
      salesDistinctInvoices: g.salesInvoices.size || g.salesRowIndices.length,
      totalReturns: g.totalReturns.toFixed(2),
      returnsCount: g.returnsRowIndices.length,
      returnsDistinctInvoices: g.returnsInvoices.size || g.returnsRowIndices.length,
      netSales: net.toFixed(2),
      currency: curr,
      assumptionUsed,
      salesRowIndices: g.salesRowIndices,
      returnsRowIndices: g.returnsRowIndices
    };
  }

  const currs = Object.keys(results);
  const isMultiCurrency = currs.length > 1;
  const primaryCalculation = currs.length === 1 ? results[currs[0]] : undefined;

  return {
    byCurrency: results,
    primaryCalculation,
    isMultiCurrency
  };
}

/**
 * Group and aggregate rows by period, customer, supplier, item, or custom column.
 * Strictly separates different currencies so sums are not mixed.
 */
export function groupRows(
  rows: Array<Record<string, any>>,
  groupCol: string,
  amountCol: string,
  groupType: 'period' | 'customer' | 'supplier' | 'item' | 'branch' | 'custom' = 'custom',
  currencyCol?: string
): GroupByResult {
  const map = new Map<string, { label: string; sum: Decimal; count: number; currency: string; rowIndices: number[] }>();

  rows.forEach((row, idx) => {
    let rawKey = row[groupCol];
    if (rawKey === null || rawKey === undefined || String(rawKey).trim() === '') {
      rawKey = '(غير محدد)';
    }

    let keyStr = String(rawKey).trim();
    let label = keyStr;

    if (groupType === 'period') {
      const dRes = parseDateValue(rawKey);
      if (dRes.isDate && dRes.formatted) {
        keyStr = dRes.formatted.slice(0, 7);
        label = keyStr;
      }
    }

    const numRes = parseNumericValue(row[amountCol]);
    const amount = numRes.isNumber && numRes.value ? numRes.value : new Decimal(0);
    const curr = resolveRowCurrency(row, amountCol, currencyCol);

    // Group key includes currency to prevent mixing
    const compoundKey = `${keyStr}___${curr}`;

    if (!map.has(compoundKey)) {
      map.set(compoundKey, { label, sum: new Decimal(0), count: 0, currency: curr, rowIndices: [] });
    }

    const item = map.get(compoundKey)!;
    item.sum = item.sum.plus(amount);
    item.count += 1;
    item.rowIndices.push(idx);
  });

  const items = Array.from(map.entries())
    .map(([_, data]) => ({
      key: data.label,
      label: data.label,
      count: data.count,
      sum: data.sum.toFixed(2),
      currency: data.currency,
      matchingRowIndices: data.rowIndices
    }))
    .sort((a, b) => new Decimal(b.sum).comparedTo(new Decimal(a.sum)));

  return {
    groupColumn: groupCol,
    groupedBy: groupType,
    items
  };
}

/**
 * Server-Side Restricted Safe Execution Engine for Structured Analysis Plans.
 * Handles arithmetic, aggregations, min_max, currency separation, and statistical tests.
 * NEVER evaluates arbitrary JS or SQL!
 */
export function executeAnalysisPlan(
  plan: AnalysisPlan,
  sheetData: {
    sheetAnalysis: SheetAnalysis;
    rows: Array<Record<string, any>>;
  }
): PlanExecutionResult {
  const { sheetAnalysis, rows } = sheetData;
  const columnsUsed: string[] = [];

  // Filter rows if filters provided
  let filteredIndices: number[] = rows.map((_, i) => i);

  if (plan.periodFilter && plan.dateColumn) {
    const dateCol = plan.dateColumn;
    columnsUsed.push(dateCol);

    const { startDate, endDate, month, year } = plan.periodFilter;

    filteredIndices = filteredIndices.filter(i => {
      const row = rows[i];
      const d = parseDateValue(row[dateCol]);
      if (!d.isDate || !d.formatted) return false;

      const dateStr = d.formatted;
      if (startDate && dateStr < startDate) return false;
      if (endDate && dateStr > endDate) return false;

      if (year && !dateStr.startsWith(year)) return false;

      if (month) {
        const monthNum = normalizeMonthInput(month);
        const rowMonth = dateStr.slice(5, 7);
        if (monthNum && rowMonth !== monthNum) return false;
      }

      return true;
    });
  }

  if (plan.filters && Array.isArray(plan.filters)) {
    for (const f of plan.filters) {
      if (!f.column) continue;
      columnsUsed.push(f.column);

      filteredIndices = filteredIndices.filter(i => {
        const row = rows[i];
        const val = row[f.column];
        if (val === null || val === undefined) return false;

        const valStr = String(val).trim().toLowerCase();
        const targetStr = String(f.value).trim().toLowerCase();

        switch (f.operator) {
          case 'equals':
            return valStr === targetStr;
          case 'contains':
            return valStr.includes(targetStr);
          case 'greater_than': {
            const n1 = parseNumericValue(val);
            const n2 = parseNumericValue(f.value);
            return n1.isNumber && n2.isNumber && n1.value!.greaterThan(n2.value!);
          }
          case 'less_than': {
            const n1 = parseNumericValue(val);
            const n2 = parseNumericValue(f.value);
            return n1.isNumber && n2.isNumber && n1.value!.lessThan(n2.value!);
          }
          case 'in':
            if (Array.isArray(f.value)) {
              return f.value.map(v => String(v).trim().toLowerCase()).includes(valStr);
            }
            return false;
          default:
            return true;
        }
      });
    }
  }

  const matchingRows = filteredIndices.map(i => rows[i]);

  if (matchingRows.length === 0) {
    return {
      success: true,
      goal: plan.goal,
      sheetName: sheetAnalysis.name,
      operation: plan.operation,
      primaryValue: '0.00',
      matchingRowCount: 0,
      matchingRowIndices: [],
      columnsUsed,
      periodDescription: describePeriodFilter(plan.periodFilter),
      breakdown: []
    };
  }

  // Find target numeric column if needed
  let targetCol = plan.targetColumn || sheetAnalysis.columnMapping?.amountColumn;
  if (!targetCol && ['sum', 'average', 'median', 'min_max', 'net_sales'].includes(plan.operation)) {
    const numCol = sheetAnalysis.columns.find(c => c.inferredType === 'number' || c.userType === 'number');
    if (numCol) targetCol = numCol.name;
  }
  if (targetCol) columnsUsed.push(targetCol);

  // Currency column
  let currCol = plan.currencyColumn || sheetAnalysis.columnMapping?.currencyColumn;
  if (!currCol) {
    const cCol = sheetAnalysis.columns.find(c => c.inferredType === 'currency' || /عملة|currency/i.test(c.name));
    if (cCol) currCol = cCol.name;
  }
  if (currCol) columnsUsed.push(currCol);

  // Execute operation
  switch (plan.operation) {
    case 'count': {
      return {
        success: true,
        goal: plan.goal,
        sheetName: sheetAnalysis.name,
        operation: 'count',
        primaryValue: String(matchingRows.length),
        unitOrCurrency: 'صف / سجل',
        periodDescription: describePeriodFilter(plan.periodFilter),
        matchingRowCount: matchingRows.length,
        matchingRowIndices: filteredIndices,
        columnsUsed
      };
    }

    case 'distinct_count': {
      const invCol =
        plan.invoiceColumn ||
        sheetAnalysis.columnMapping?.invoiceColumn ||
        sheetAnalysis.columns.find(c => /فاتورة|invoice|كود|رقم/i.test(c.name))?.name;
      if (invCol) columnsUsed.push(invCol);
      const uniqueVals = new Set(matchingRows.map(r => (invCol ? String(r[invCol] ?? '') : JSON.stringify(r))));

      return {
        success: true,
        goal: plan.goal,
        sheetName: sheetAnalysis.name,
        operation: 'distinct_count',
        primaryValue: String(uniqueVals.size),
        secondaryValue: `من أصل ${matchingRows.length} بند / سطر في الملف`,
        unitOrCurrency: invCol ? `قيم فريدة (${invCol})` : 'سجل مميز',
        periodDescription: describePeriodFilter(plan.periodFilter),
        matchingRowCount: matchingRows.length,
        matchingRowIndices: filteredIndices,
        columnsUsed
      };
    }

    case 'min_max': {
      if (!targetCol) {
        return {
          success: false,
          goal: plan.goal,
          sheetName: sheetAnalysis.name,
          operation: 'min_max',
          matchingRowCount: 0,
          matchingRowIndices: [],
          columnsUsed,
          error: 'لم يتم العثور على عمود رقمي لحساب الحدين الأدنى والأقصى.'
        };
      }

      const multiStats = computeMultiCurrencyColumnStats(matchingRows, targetCol, currCol);
      const currs = Object.keys(multiStats.currencies);

      if (currs.length === 0 || multiStats.totalValidCount === 0) {
        return {
          success: false,
          goal: plan.goal,
          sheetName: sheetAnalysis.name,
          operation: 'min_max',
          matchingRowCount: 0,
          matchingRowIndices: [],
          columnsUsed,
          error: 'لا توجد قيم صالحة لحساب الحد الأدنى والأقصى.'
        };
      }

      // Collect tie rows for min and max across all currencies
      const allMinIndices: number[] = [];
      const allMaxIndices: number[] = [];
      const breakdown: Array<{ label: string; value: string; count: number; rowIndices: number[] }> = [];

      for (const curr of currs) {
        const cStat = multiStats.currencies[curr];
        const minAbs = (cStat.minRowIndices || []).map(localIdx => filteredIndices[localIdx]);
        const maxAbs = (cStat.maxRowIndices || []).map(localIdx => filteredIndices[localIdx]);

        allMinIndices.push(...minAbs);
        allMaxIndices.push(...maxAbs);

        breakdown.push({
          label: `الحد الأدنى (${curr})`,
          value: `${cStat.min} ${curr}`,
          count: minAbs.length,
          rowIndices: minAbs
        });

        breakdown.push({
          label: `الحد الأقصى (${curr})`,
          value: `${cStat.max} ${curr}`,
          count: maxAbs.length,
          rowIndices: maxAbs
        });
      }

      const primaryParts = currs.map(c => {
        const s = multiStats.currencies[c];
        return `الأدنى: ${s.min} ${c} | الأقصى: ${s.max} ${c}`;
      });

      const uniqueMinMaxIndices = Array.from(new Set([...allMinIndices, ...allMaxIndices]));

      return {
        success: true,
        goal: plan.goal,
        sheetName: sheetAnalysis.name,
        operation: 'min_max',
        primaryValue: primaryParts.join(' || '),
        secondaryValue: `تم رصد ${allMinIndices.length} سطر للحد الأدنى و${allMaxIndices.length} سطر للحد الأقصى (شاملاً التعادلات)`,
        unitOrCurrency: currs.length === 1 ? currs[0] : 'مفصول بالعملات',
        periodDescription: describePeriodFilter(plan.periodFilter),
        matchingRowCount: uniqueMinMaxIndices.length,
        matchingRowIndices: uniqueMinMaxIndices,
        columnsUsed,
        breakdown
      };
    }

    case 'sum': {
      if (!targetCol) {
        return {
          success: false,
          goal: plan.goal,
          sheetName: sheetAnalysis.name,
          operation: 'sum',
          matchingRowCount: 0,
          matchingRowIndices: [],
          columnsUsed,
          error: 'لم يتم العثور على عمود مالي أو رقمي لحساب الإجمالي.'
        };
      }

      const multiStats = computeMultiCurrencyColumnStats(matchingRows, targetCol, currCol);
      const currs = Object.keys(multiStats.currencies);

      if (currs.length > 1) {
        const breakdown: Array<{ label: string; value: string; count: number; rowIndices: number[] }> = [];
        for (const curr of currs) {
          const cStat = multiStats.currencies[curr];
          const cIndices: number[] = [];
          matchingRows.forEach((r, idx) => {
            if (resolveRowCurrency(r, targetCol!, currCol) === curr) {
              cIndices.push(filteredIndices[idx]);
            }
          });
          breakdown.push({
            label: curr,
            value: cStat.sum,
            count: cStat.count,
            rowIndices: cIndices
          });
        }

        const primaryStr = breakdown.map(b => `${b.value} ${b.label}`).join(' + ');

        return {
          success: true,
          goal: plan.goal,
          sheetName: sheetAnalysis.name,
          operation: 'sum',
          primaryValue: primaryStr,
          unitOrCurrency: 'مفصول بالعملات',
          periodDescription: describePeriodFilter(plan.periodFilter),
          matchingRowCount: matchingRows.length,
          matchingRowIndices: filteredIndices,
          columnsUsed,
          breakdown
        };
      }

      const singleStat = multiStats.primaryStats || (currs[0] ? multiStats.currencies[currs[0]] : null);
      const totalStr = singleStat ? singleStat.sum : '0.00';
      const currStr = singleStat ? singleStat.currency : '(عملة غير محددة)';

      return {
        success: true,
        goal: plan.goal,
        sheetName: sheetAnalysis.name,
        operation: 'sum',
        primaryValue: totalStr,
        unitOrCurrency: currStr,
        periodDescription: describePeriodFilter(plan.periodFilter),
        matchingRowCount: matchingRows.length,
        matchingRowIndices: filteredIndices,
        columnsUsed
      };
    }

    case 'average': {
      if (!targetCol) {
        return {
          success: false,
          goal: plan.goal,
          sheetName: sheetAnalysis.name,
          operation: 'average',
          matchingRowCount: 0,
          matchingRowIndices: [],
          columnsUsed,
          error: 'عمود رقمي غير محدد'
        };
      }

      const multiStats = computeMultiCurrencyColumnStats(matchingRows, targetCol, currCol);
      const currs = Object.keys(multiStats.currencies);

      if (currs.length > 1) {
        const breakdown = currs.map(c => {
          const s = multiStats.currencies[c];
          const indices = matchingRows
            .map((r, idx) => (resolveRowCurrency(r, targetCol!, currCol) === c ? filteredIndices[idx] : -1))
            .filter(i => i >= 0);
          return {
            label: `متوسط (${c})`,
            value: s.average,
            count: s.count,
            rowIndices: indices
          };
        });

        const primaryStr = currs.map(c => `${multiStats.currencies[c].average} ${c}`).join(' | ');

        return {
          success: true,
          goal: plan.goal,
          sheetName: sheetAnalysis.name,
          operation: 'average',
          primaryValue: primaryStr,
          unitOrCurrency: 'مفصول بالعملات',
          periodDescription: describePeriodFilter(plan.periodFilter),
          matchingRowCount: matchingRows.length,
          matchingRowIndices: filteredIndices,
          columnsUsed,
          breakdown
        };
      }

      const singleStat = multiStats.primaryStats || (currs[0] ? multiStats.currencies[currs[0]] : null);
      return {
        success: true,
        goal: plan.goal,
        sheetName: sheetAnalysis.name,
        operation: 'average',
        primaryValue: singleStat ? singleStat.average : '0.00',
        unitOrCurrency: singleStat ? singleStat.currency : '(عملة غير محددة)',
        periodDescription: describePeriodFilter(plan.periodFilter),
        matchingRowCount: matchingRows.length,
        matchingRowIndices: filteredIndices,
        columnsUsed
      };
    }

    case 'median': {
      if (!targetCol) {
        return {
          success: false,
          goal: plan.goal,
          sheetName: sheetAnalysis.name,
          operation: 'median',
          matchingRowCount: 0,
          matchingRowIndices: [],
          columnsUsed,
          error: 'عمود رقمي غير محدد'
        };
      }

      const multiStats = computeMultiCurrencyColumnStats(matchingRows, targetCol, currCol);
      const currs = Object.keys(multiStats.currencies);

      if (currs.length > 1) {
        const breakdown = currs.map(c => {
          const s = multiStats.currencies[c];
          const indices = matchingRows
            .map((r, idx) => (resolveRowCurrency(r, targetCol!, currCol) === c ? filteredIndices[idx] : -1))
            .filter(i => i >= 0);
          return {
            label: `وسيط (${c})`,
            value: s.median,
            count: s.count,
            rowIndices: indices
          };
        });

        const primaryStr = currs.map(c => `${multiStats.currencies[c].median} ${c}`).join(' | ');

        return {
          success: true,
          goal: plan.goal,
          sheetName: sheetAnalysis.name,
          operation: 'median',
          primaryValue: primaryStr,
          unitOrCurrency: 'مفصول بالعملات',
          periodDescription: describePeriodFilter(plan.periodFilter),
          matchingRowCount: matchingRows.length,
          matchingRowIndices: filteredIndices,
          columnsUsed,
          breakdown
        };
      }

      const singleStat = multiStats.primaryStats || (currs[0] ? multiStats.currencies[currs[0]] : null);
      return {
        success: true,
        goal: plan.goal,
        sheetName: sheetAnalysis.name,
        operation: 'median',
        primaryValue: singleStat ? singleStat.median : '0.00',
        unitOrCurrency: singleStat ? singleStat.currency : '(عملة غير محددة)',
        periodDescription: describePeriodFilter(plan.periodFilter),
        matchingRowCount: matchingRows.length,
        matchingRowIndices: filteredIndices,
        columnsUsed
      };
    }

    case 'net_sales': {
      if (!targetCol) {
        return {
          success: false,
          goal: plan.goal,
          sheetName: sheetAnalysis.name,
          operation: 'net_sales',
          matchingRowCount: 0,
          matchingRowIndices: [],
          columnsUsed,
          error: 'عمود مالي غير محدد'
        };
      }

      const typeCol =
        plan.typeColumn ||
        sheetAnalysis.columnMapping?.typeColumn ||
        sheetAnalysis.columns.find(c => /نوع_الحركة|نوع الفاتورة|البيان|مرتجع|نوع/i.test(c.name))?.name;
      const invCol =
        plan.invoiceColumn ||
        sheetAnalysis.columnMapping?.invoiceColumn ||
        sheetAnalysis.columns.find(c => /فاتورة|invoice/i.test(c.name))?.name;

      if (typeCol) columnsUsed.push(typeCol);
      if (invCol) columnsUsed.push(invCol);

      const dataLevel = plan.dataLevel || sheetAnalysis.columnMapping?.dataLevel || 'line_item';

      const multiNet = calculateMultiCurrencyNetSales(
        matchingRows,
        targetCol,
        typeCol,
        invCol,
        currCol,
        dataLevel
      );

      const currs = Object.keys(multiNet.byCurrency);
      if (currs.length === 0) {
        return {
          success: true,
          goal: plan.goal,
          sheetName: sheetAnalysis.name,
          operation: 'net_sales',
          primaryValue: '0.00',
          matchingRowCount: 0,
          matchingRowIndices: [],
          columnsUsed,
          breakdown: []
        };
      }

      const breakdown: Array<{ label: string; value: string; count: number; rowIndices: number[] }> = [];

      for (const curr of currs) {
        const netCalc = multiNet.byCurrency[curr];
        const sAbs = netCalc.salesRowIndices.map(localIdx => filteredIndices[localIdx]);
        const rAbs = netCalc.returnsRowIndices.map(localIdx => filteredIndices[localIdx]);

        breakdown.push({
          label: `المبيعات (${curr})`,
          value: netCalc.grossSales,
          count: netCalc.salesCount,
          rowIndices: sAbs
        });
        breakdown.push({
          label: `المرتجعات (${curr})`,
          value: netCalc.totalReturns,
          count: netCalc.returnsCount,
          rowIndices: rAbs
        });
        breakdown.push({
          label: `صافي المبيعات (${curr})`,
          value: netCalc.netSales,
          count: sAbs.length + rAbs.length,
          rowIndices: [...sAbs, ...rAbs]
        });
      }

      const primaryParts = currs.map(c => `${multiNet.byCurrency[c].netSales} ${c}`);
      const secondaryParts = currs.map(
        c =>
          `[${c}]: مبيعات ${multiNet.byCurrency[c].grossSales} (${multiNet.byCurrency[c].salesDistinctInvoices} ف.) - مرتجعات ${multiNet.byCurrency[c].totalReturns} (${multiNet.byCurrency[c].returnsDistinctInvoices} م.)`
      );

      return {
        success: true,
        goal: plan.goal,
        sheetName: sheetAnalysis.name,
        operation: 'net_sales',
        primaryValue: primaryParts.join(' + '),
        secondaryValue: secondaryParts.join(' | '),
        unitOrCurrency: currs.length === 1 ? currs[0] : 'مفصول بالعملات',
        periodDescription: describePeriodFilter(plan.periodFilter),
        matchingRowCount: matchingRows.length,
        matchingRowIndices: filteredIndices,
        columnsUsed,
        assumptionUsed: multiNet.byCurrency[currs[0]].assumptionUsed,
        breakdown
      };
    }

    case 'group_by': {
      if (!targetCol) {
        return {
          success: false,
          goal: plan.goal,
          sheetName: sheetAnalysis.name,
          operation: 'group_by',
          matchingRowCount: 0,
          matchingRowIndices: [],
          columnsUsed,
          error: 'عمود القيمة المالية غير محدد'
        };
      }
      let groupCol = plan.groupByColumn;
      if (!groupCol) {
        groupCol = sheetAnalysis.columns.find(c => /عميل|مورد|صنف|فرع|customer|supplier|item|branch/i.test(c.name))?.name;
      }
      if (!groupCol) {
        groupCol = sheetAnalysis.columns[0]?.name;
      }
      columnsUsed.push(groupCol);

      const grpRes = groupRows(matchingRows, groupCol, targetCol, 'custom', currCol);
      let items = grpRes.items;
      if (plan.sortOrder === 'asc') {
        items.sort((a, b) => new Decimal(a.sum).comparedTo(new Decimal(b.sum)));
      } else {
        items.sort((a, b) => new Decimal(b.sum).comparedTo(new Decimal(a.sum)));
      }
      if (plan.limit && plan.limit > 0) {
        items = items.slice(0, plan.limit);
      }

      const breakdown = items.map(item => ({
        label: `${item.label} (${item.currency})`,
        value: item.sum,
        count: item.count,
        rowIndices: item.matchingRowIndices.map(localIdx => filteredIndices[localIdx])
      }));

      const topItem = items[0];

      return {
        success: true,
        goal: plan.goal,
        sheetName: sheetAnalysis.name,
        operation: 'group_by',
        primaryValue: topItem ? `${topItem.label}: ${topItem.sum} ${topItem.currency}` : 'لا توجد بيانات',
        secondaryValue: `مجموعات مصنفة حسب: ${groupCol} (إجمالي ${items.length} مجموعة مفصولة بالعملات)`,
        unitOrCurrency: topItem ? topItem.currency : 'EGP',
        periodDescription: describePeriodFilter(plan.periodFilter),
        matchingRowCount: matchingRows.length,
        matchingRowIndices: filteredIndices,
        columnsUsed,
        breakdown
      };
    }

    case 'statistical_test': {
      const testType = plan.statisticalTestType || 'correlation';
      const alpha = plan.alpha || 0.05;
      let statRes: StatisticalTestResult;

      const col1 = targetCol || sheetAnalysis.columns[0]?.name;
      const col2 = plan.secondaryColumn || sheetAnalysis.columns[1]?.name;

      if (testType === 'descriptive') {
        statRes = runDescriptiveTest(matchingRows, col1, undefined, alpha, sheetAnalysis.name);
      } else if (testType === 'correlation') {
        statRes = runCorrelationTest(matchingRows, col1, col2, undefined, alpha, sheetAnalysis.name);
      } else if (testType === 'two_independent_groups') {
        const grpValues = Array.from(new Set(matchingRows.map(r => String(r[col2] ?? '').trim()))).filter(Boolean);
        statRes = runTwoIndependentGroupsTest(
          matchingRows,
          col1,
          col2,
          grpValues[0] || 'المجموعة 1',
          grpValues[1] || 'المجموعة 2',
          undefined,
          alpha,
          sheetAnalysis.name
        );
      } else if (testType === 'paired_samples') {
        statRes = runPairedSamplesTest(
          matchingRows,
          col1,
          col2,
          plan.invoiceColumn,
          undefined,
          alpha,
          sheetAnalysis.name
        );
      } else if (testType === 'anova_kruskal') {
        statRes = runAnovaAndKruskalTest(matchingRows, col1, col2, undefined, alpha, sheetAnalysis.name);
      } else {
        statRes = runContingencyTest(matchingRows, col1, col2, alpha, sheetAnalysis.name);
      }

      // Map used rows back to absolute dataset row indices
      const absUsedIndices = statRes.usedRowIndices.map(localIdx => filteredIndices[localIdx]);

      return {
        success: statRes.canExecuteNormally,
        goal: plan.goal || statRes.testNameAr,
        sheetName: sheetAnalysis.name,
        operation: 'statistical_test',
        primaryValue: `${statRes.statistics.primaryStatName} = ${statRes.statistics.primaryStatValue} (p = ${statRes.statistics.pValue})`,
        secondaryValue: statRes.explanationAr,
        unitOrCurrency: statRes.statistics.isSignificant ? 'دلالة إحصائية مؤكدة' : 'لا توجد دلالة إحصائية كافية',
        matchingRowCount: statRes.usedRowsCount,
        matchingRowIndices: absUsedIndices,
        columnsUsed: statRes.columnsUsed,
        statisticalResult: statRes,
        error: statRes.canExecuteNormally ? undefined : statRes.explanationAr
      };
    }

    default:
      return {
        success: true,
        goal: plan.goal,
        sheetName: sheetAnalysis.name,
        operation: plan.operation,
        primaryValue: String(matchingRows.length),
        unitOrCurrency: 'سجل',
        periodDescription: describePeriodFilter(plan.periodFilter),
        matchingRowCount: matchingRows.length,
        matchingRowIndices: filteredIndices,
        columnsUsed
      };
  }
}

/**
 * Normalizes user-entered month names/numbers to two digits "01" - "12"
 */
export function normalizeMonthInput(input: string): string | null {
  if (!input) return null;
  const str = normalizeArabicDigits(String(input)).trim().toLowerCase();

  if (/^\d{4}-(\d{2})$/.test(str)) {
    return str.split('-')[1];
  }

  const num = parseInt(str.replace(/\D/g, ''), 10);
  if (!isNaN(num) && num >= 1 && num <= 12) {
    return String(num).padStart(2, '0');
  }

  const monthMap: Record<string, string> = {
    يناير: '01',
    'كانون الثاني': '01',
    jan: '01',
    january: '01',
    فبراير: '02',
    شباط: '02',
    feb: '02',
    february: '02',
    مارس: '03',
    آذار: '03',
    mar: '03',
    march: '03',
    أبريل: '04',
    ابريل: '04',
    نيسان: '04',
    apr: '04',
    april: '04',
    مايو: '05',
    أيار: '05',
    may: '05',
    يونيو: '06',
    حزيران: '06',
    jun: '06',
    june: '06',
    يوليو: '07',
    تموز: '07',
    jul: '07',
    july: '07',
    أغسطس: '08',
    اغسطس: '08',
    آب: '08',
    aug: '08',
    august: '08',
    سبتمبر: '09',
    أيلول: '09',
    sep: '09',
    september: '09',
    أكتوبر: '10',
    اكتوبر: '10',
    'تشرين الأول': '10',
    oct: '10',
    october: '10',
    نوفمبر: '11',
    'تشرين الثاني': '11',
    nov: '11',
    november: '11',
    ديسمبر: '12',
    'كانون الأول': '12',
    dec: '12',
    december: '12'
  };

  for (const [k, v] of Object.entries(monthMap)) {
    if (str.includes(k)) return v;
  }

  return null;
}

function describePeriodFilter(pf?: AnalysisPlan['periodFilter']): string {
  if (!pf) return 'كامل الفترة الزمنية في الملف';
  if (pf.month && pf.year) return `فترة: شهر ${pf.month} لسنة ${pf.year}`;
  if (pf.month) return `فترة: شهر ${pf.month}`;
  if (pf.year) return `سنة ${pf.year}`;
  if (pf.startDate && pf.endDate) return `من ${pf.startDate} إلى ${pf.endDate}`;
  if (pf.startDate) return `منذ ${pf.startDate}`;
  return 'فترة مخصصة';
}

/**
 * Generate Multi-Scenario Multi-Sheet Test Workbook in Memory
 * Includes comprehensive test data for currency separation, net sales, min_max, and statistical benchmarks
 */
export function generateTestWorkbook(): XLSX.WorkBook {
  const wb = XLSX.utils.book_new();

  // Sheet 1: فواتير المبيعات 2026
  const salesData = [
    // Invoice 1 (3 items - multi-item invoice)
    {
      رقم_الفاتورة: 'INV-2026-001',
      التاريخ: '2026-10-05',
      نوع_الحركة: 'مبيعات',
      العميل: 'شركة النيل للخدمات الهندسية',
      الصنف: 'لابتوب ديل فوسترو 3520',
      الكمية: 2,
      سعر_الوحدة: 15000,
      إجمالي_القيمة: 30000,
      العملة: 'EGP',
      الفرع: 'فرع القاهرة'
    },
    {
      رقم_الفاتورة: 'INV-2026-001',
      التاريخ: '2026-10-05',
      نوع_الحركة: 'مبيعات',
      العميل: 'شركة النيل للخدمات الهندسية',
      الصنف: 'شاشة ديل 24 بوصة',
      الكمية: 2,
      سعر_الوحدة: 4500,
      إجمالي_القيمة: 9000,
      العملة: 'EGP',
      الفرع: 'فرع القاهرة'
    },
    {
      رقم_الفاتورة: 'INV-2026-001',
      التاريخ: '2026-10-05',
      نوع_الحركة: 'مبيعات',
      العميل: 'شركة النيل للخدمات الهندسية',
      الصنف: 'ماوس لاسلكي لوجيتك',
      الكمية: 4,
      سعر_الوحدة: 500,
      إجمالي_القيمة: 2000,
      العملة: 'EGP',
      الفرع: 'فرع القاهرة'
    },
    // Invoice 2
    {
      رقم_الفاتورة: 'INV-2026-002',
      التاريخ: '2026-10-12',
      نوع_الحركة: 'مبيعات',
      العميل: 'مؤسسة الأهرام للصحافة والتوزيع',
      الصنف: 'خادم HP ProLiant Gen10',
      الكمية: 1,
      سعر_الوحدة: 50000,
      إجمالي_القيمة: 50000,
      العملة: 'EGP',
      الفرع: 'فرع الإسكندرية'
    },
    // Invoice 3 (USD currency)
    {
      رقم_الفاتورة: 'INV-2026-003',
      التاريخ: '2026-10-18',
      نوع_الحركة: 'مبيعات',
      العميل: 'شركة النور للمقاولات والتوريدات',
      الصنف: 'اشتراك برمجيات سحابية سنوي',
      الكمية: 1,
      سعر_الوحدة: 2500,
      إجمالي_القيمة: 2500,
      العملة: 'USD',
      الفرع: 'فرع القاهرة'
    },
    // Invoice 4 (November)
    {
      رقم_الفاتورة: 'INV-2026-004',
      التاريخ: '2026-11-02',
      نوع_الحركة: 'مبيعات',
      العميل: 'شركة النيل للخدمات الهندسية',
      الصنف: 'لابتوب لينوفو ثينك باد',
      الكمية: 1,
      سعر_الوحدة: 22000,
      إجمالي_القيمة: 22000,
      العملة: 'EGP',
      الفرع: 'فرع القاهرة'
    },
    // Return Invoice (Sales Return)
    {
      رقم_الفاتورة: 'RET-2026-001',
      التاريخ: '2026-10-25',
      نوع_الحركة: 'مرتجع',
      العميل: 'شركة النيل للخدمات الهندسية',
      الصنف: 'شاشة ديل 24 بوصة (مرتجع)',
      الكمية: 1,
      سعر_الوحدة: 4500,
      إجمالي_القيمة: 4500,
      العملة: 'EGP',
      الفرع: 'فرع القاهرة'
    },
    // Arabic Digits Row
    {
      رقم_الفاتورة: 'INV-2026-005',
      التاريخ: '2026-10-20',
      نوع_الحركة: 'مبيعات',
      العميل: 'مؤسسة الشروق للبرمجيات',
      الصنف: 'طابعة ليزر إتش بي',
      الكمية: '٢',
      سعر_الوحدة: '٣٥٠٠',
      إجمالي_القيمة: '٧٠٠٠',
      العملة: 'EGP',
      الفرع: 'فرع القاهرة'
    },
    // Duplicate Row for duplicate detection verification
    {
      رقم_الفاتورة: 'INV-2026-005',
      التاريخ: '2026-10-20',
      نوع_الحركة: 'مبيعات',
      العميل: 'مؤسسة الشروق للبرمجيات',
      الصنف: 'طابعة ليزر إتش بي',
      الكمية: '٢',
      سعر_الوحدة: '٣٥٠٠',
      إجمالي_القيمة: '٧٠٠٠',
      العملة: 'EGP',
      الفرع: 'فرع القاهرة'
    }
  ];

  // Sheet 2: المشتريات والموردين
  const purchasesData = [
    {
      رقم_إذن_الشراء: 'PINV-01',
      التاريخ: '2026-10-01',
      المورد: 'الشركة الهندسية للاستيراد والتصدير',
      الصنف: 'معالجات إنتل كور i7',
      الكمية: 10,
      سعر_التكلفة: 9500,
      الإجمالي: 95000,
      العملة: 'EGP'
    },
    {
      رقم_إذن_الشراء: 'PINV-02',
      التاريخ: '2026-10-08',
      المورد: 'مؤسسة الدلتا للأجهزة الإلكترونية',
      الصنف: 'لوحات أم آسوس B760',
      الكمية: 15,
      سعر_التكلفة: 4200,
      الإجمالي: 63000,
      العملة: 'EGP'
    },
    {
      رقم_إذن_الشراء: 'PINV-03',
      التاريخ: '2026-10-22',
      المورد: 'الشركة الدولية لتكنولوجيا المعلومات',
      الصنف: 'سيرفرات فائقة الأداء',
      الكمية: 2,
      سعر_التكلفة: 3500,
      الإجمالي: 7000,
      العملة: 'USD'
    }
  ];

  // Sheet 3: بطاقات الأصناف والمخزون
  const itemsData = [
    { كود_الصنف: 'ITM-001', اسم_الصنف: 'لابتوب ديل فوسترو 3520', الفئة: 'حواسب آلية', رصيد_المخزن: 14, سعر_التكلفة: 13000, سعر_البيع: 15000 },
    { كود_الصنف: 'ITM-002', اسم_الصنف: 'شاشة ديل 24 بوصة', الفئة: 'شاشات', رصيد_المخزن: 25, سعر_التكلفة: 3800, سعر_البيع: 4500 },
    { كود_الصنف: 'ITM-003', اسم_الصنف: 'خادم HP ProLiant Gen10', الفئة: 'خوادم وشبكات', رصيد_المخزن: 3, سعر_التكلفة: 42000, سعر_البيع: 50000 }
  ];

  // Sheet 4: اختبارات_إحصائية_ومقارنات (Statistical Benchmark Datasets)
  const statsBenchmarkData = [
    // Benchmark 1: Exact test requested by user: [100, 30, 10]
    // Benchmark 2: Currency separation test: 100 EGP, 20 USD, 10 EGP (return)
    {
      معرف_البند: 'BM-01',
      قيمة_أحادية: 100,
      العملة: 'EGP',
      نوع_الحركة: 'مبيعات',
      الكمية: 10,
      السعر: 100,
      الفرع: 'فرع القاهرة',
      المبيعات_الشهرية: 5000,
      قبل_التدريب: 72,
      بعد_التدريب: 85,
      التصنيف_المخزني: 'حواسب',
      حالة_السداد: 'نقدي'
    },
    {
      معرف_البند: 'BM-02',
      قيمة_أحادية: 30,
      العملة: 'USD',
      نوع_الحركة: 'مبيعات',
      الكمية: 20,
      السعر: 20,
      الفرع: 'فرع القاهرة',
      المبيعات_الشهرية: 6200,
      قبل_التدريب: 68,
      بعد_التدريب: 79,
      التصنيف_المخزني: 'حواسب',
      حالة_السداد: 'نقدي'
    },
    {
      معرف_البند: 'BM-03',
      قيمة_أحادية: 10,
      العملة: 'EGP',
      نوع_الحركة: 'مرتجع',
      الكمية: 30,
      السعر: 300,
      الفرع: 'فرع الإسكندرية',
      المبيعات_الشهرية: 3100,
      قبل_التدريب: 55,
      بعد_التدريب: 65,
      التصنيف_المخزني: 'شاشات',
      حالة_السداد: 'آجل'
    },
    {
      معرف_البند: 'BM-04',
      قيمة_أحادية: 45,
      العملة: 'EGP',
      نوع_الحركة: 'مبيعات',
      الكمية: 40,
      السعر: 400,
      الفرع: 'فرع الإسكندرية',
      المبيعات_الشهرية: 3400,
      قبل_التدريب: 60,
      بعد_التدريب: 70,
      التصنيف_المخزني: 'شاشات',
      حالة_السداد: 'آجل'
    },
    {
      معرف_البند: 'BM-05',
      قيمة_أحادية: 60,
      العملة: 'EGP',
      نوع_الحركة: 'مبيعات',
      الكمية: 50,
      السعر: 500,
      الفرع: 'فرع الإسكندرية',
      المبيعات_الشهرية: 2900,
      قبل_التدريب: 74,
      بعد_التدريب: 88,
      التصنيف_المخزني: 'خوادم',
      حالة_السداد: 'نقدي'
    },
    {
      معرف_البند: 'BM-06',
      قيمة_أحادية: 80,
      العملة: 'EGP',
      نوع_الحركة: 'مبيعات',
      الكمية: 60,
      السعر: 600,
      الفرع: 'فرع القاهرة',
      المبيعات_الشهرية: 7100,
      قبل_التدريب: 80,
      بعد_التدريب: 92,
      التصنيف_المخزني: 'خوادم',
      حالة_السداد: 'آجل'
    }
  ];

  XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(salesData), 'فواتير_المبيعات_2026');
  XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(purchasesData), 'المشتريات_والموردين');
  XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(itemsData), 'الأصناف_والمخزون');
  XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(statsBenchmarkData), 'اختبارات_إحصائية_ومقارنات');

  return wb;
}
