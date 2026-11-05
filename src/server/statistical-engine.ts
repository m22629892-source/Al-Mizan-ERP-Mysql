import Decimal from 'decimal.js';

/**
 * Mathematical & Statistical Special Functions
 * High-precision implementations of Gamma, Beta, and Distributions
 */

// Lanczos approximation coefficients for log-gamma (g=7, n=9)
const LANCZOS_P = [
  0.99999999999980993,
  676.5209340678222,
  -1259.1392167224028,
  771.32342877765313,
  -176.61502916214059,
  12.507343278686905,
  -0.1385710958572050,
  9.9843695780195716e-6,
  1.5056327351493116e-7
];

export function logGamma(z: number): number {
  if (z < 0.5) {
    // Reflection formula: Gamma(1-z) * Gamma(z) = pi / sin(pi * z)
    return Math.log(Math.PI / Math.sin(Math.PI * z)) - logGamma(1 - z);
  }
  z -= 1;
  let x = LANCZOS_P[0];
  for (let i = 1; i < LANCZOS_P.length; i++) {
    x += LANCZOS_P[i] / (z + i);
  }
  const t = z + 7.5;
  return 0.5 * Math.log(2 * Math.PI) + (z + 0.5) * Math.log(t) - t + Math.log(x);
}

export function gamma(z: number): number {
  return Math.exp(logGamma(z));
}

export function logFactorial(n: number): number {
  if (n <= 1) return 0;
  return logGamma(n + 1);
}

/**
 * Regularized lower incomplete gamma function P(a, x) = gamma(a, x) / Gamma(a)
 * Series expansion for x < a + 1
 */
function incompleteGammaLowerSeries(a: number, x: number): number {
  if (x <= 0) return 0;
  let sum = 1 / a;
  let term = 1 / a;
  for (let n = 1; n < 200; n++) {
    term *= x / (a + n);
    sum += term;
    if (Math.abs(term / sum) < 1e-14) break;
  }
  return sum * Math.exp(-x + a * Math.log(x) - logGamma(a));
}

/**
 * Regularized upper incomplete gamma function Q(a, x) = Gamma(a, x) / Gamma(a)
 * Continued fraction for x >= a + 1
 */
function incompleteGammaUpperCF(a: number, x: number): number {
  const maxIterations = 200;
  const epsilon = 1e-14;
  let b = x + 1 - a;
  let c = 1 / 1e-30;
  let d = 1 / b;
  let h = d;

  for (let i = 1; i <= maxIterations; i++) {
    const an = -i * (i - a);
    b += 2;
    d = an * d + b;
    if (Math.abs(d) < 1e-30) d = 1e-30;
    c = b + an / c;
    if (Math.abs(c) < 1e-30) c = 1e-30;
    d = 1 / d;
    const del = d * c;
    h *= del;
    if (Math.abs(del - 1) < epsilon) break;
  }

  return Math.exp(-x + a * Math.log(x) - logGamma(a)) * h;
}

export function regularizedGammaP(a: number, x: number): number {
  if (x <= 0) return 0;
  if (a <= 0) return 0;
  if (x < a + 1) {
    return Math.min(1, Math.max(0, incompleteGammaLowerSeries(a, x)));
  }
  return Math.min(1, Math.max(0, 1 - incompleteGammaUpperCF(a, x)));
}

export function regularizedGammaQ(a: number, x: number): number {
  return Math.min(1, Math.max(0, 1 - regularizedGammaP(a, x)));
}

/**
 * Regularized incomplete beta function I_x(a, b)
 * Evaluated via continued fraction
 */
export function regularizedIncompleteBeta(x: number, a: number, b: number): number {
  if (x <= 0) return 0;
  if (x >= 1) return 1;

  // Use symmetry transformation if x > (a + 1) / (a + b + 2)
  if (x > (a + 1) / (a + b + 2)) {
    return 1 - regularizedIncompleteBeta(1 - x, b, a);
  }

  const factor = Math.exp(
    a * Math.log(x) + b * Math.log(1 - x) - logGamma(a) - logGamma(b) + logGamma(a + b)
  ) / a;

  // Continued fraction (Modified Lentz's method)
  let c = 1;
  let d = 1 - (a + b) * x / (a + 1);
  if (Math.abs(d) < 1e-30) d = 1e-30;
  d = 1 / d;
  let h = d;

  for (let m = 1; m <= 200; m++) {
    // Even step
    let num = (m * (b - m) * x) / ((a + 2 * m - 1) * (a + 2 * m));
    d = 1 + num * d;
    if (Math.abs(d) < 1e-30) d = 1e-30;
    c = 1 + num / c;
    if (Math.abs(c) < 1e-30) c = 1e-30;
    d = 1 / d;
    h *= d * c;

    // Odd step
    num = -((a + m) * (a + b + m) * x) / ((a + 2 * m) * (a + 2 * m + 1));
    d = 1 + num * d;
    if (Math.abs(d) < 1e-30) d = 1e-30;
    c = 1 + num / c;
    if (Math.abs(c) < 1e-30) c = 1e-30;
    d = 1 / d;
    const del = d * c;
    h *= del;

    if (Math.abs(del - 1) < 1e-12) break;
  }

  return Math.min(1, Math.max(0, factor * h));
}

/**
 * Standard Normal Distribution
 */
export function normalCdf(z: number): number {
  // Approximation of error function using Abramowitz and Stegun formula 7.1.26
  const sign = z < 0 ? -1 : 1;
  const x = Math.abs(z) / Math.SQRT2;
  const t = 1.0 / (1.0 + 0.3275911 * x);
  const a1 = 0.254829592;
  const a2 = -0.284496736;
  const a3 = 1.421413741;
  const a4 = -1.453152027;
  const a5 = 1.061405429;
  const erf = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * Math.exp(-x * x);
  return 0.5 * (1.0 + sign * erf);
}

/**
 * Inverse Normal CDF (Probit function) using Peter J. Acklam's high-precision algorithm.
 * Error < 1.15e-9 across entire domain [0, 1].
 */
export function normalQuantile(p: number): number {
  if (isNaN(p) || p < 0 || p > 1) return NaN;
  if (p === 0) return -Infinity;
  if (p === 1) return Infinity;
  if (p === 0.5) return 0;

  // Coefficients in rational approximations
  const a = [
    -3.969683028665376e+01,
     2.209460984245205e+02,
    -2.759285104469687e+02,
     1.383577518672690e+02,
    -3.066479806614716e+01,
     2.506628277459239e+00
  ];
  const b = [
    -5.447609879822406e+01,
     1.615858368580409e+02,
    -1.556989798598866e+02,
     6.680131188771972e+01,
    -1.328068155288572e+01
  ];
  const c = [
    -7.784894002430293e-03,
    -3.223964580411365e-01,
    -2.400758277161838e+00,
    -2.549732539343734e+00,
     4.374664141464968e+00,
     2.938163982698783e+00
  ];
  const d = [
     7.784695709041462e-03,
     3.224671290700398e-01,
     2.445134137142996e+00,
     3.754408661907416e+00
  ];

  const p_low = 0.02425;
  const p_high = 1 - p_low;

  let x: number;
  if (p < p_low) {
    // Rational approximation for lower tail:
    const q = Math.sqrt(-2 * Math.log(p));
    x = (((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]) /
        ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
  } else if (p <= p_high) {
    // Rational approximation for central region:
    const q = p - 0.5;
    const r = q * q;
    x = (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r + a[5]) * q /
        (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1);
  } else {
    // Rational approximation for upper tail:
    const q = Math.sqrt(-2 * Math.log(1 - p));
    x = -(((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]) /
         ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
  }

  return x;
}

/**
 * Student's t-distribution Two-tailed p-value
 */
export function studentTPValue(t: number, df: number): number {
  if (df <= 0 || isNaN(df) || isNaN(t)) return 1;
  const absT = Math.abs(t);
  const x = df / (df + absT * absT);
  const p = regularizedIncompleteBeta(x, df / 2, 0.5);
  return Math.min(1, Math.max(0, p));
}

/**
 * Student's t-distribution critical value (two-tailed, e.g. alpha = 0.05)
 */
export function studentTCritical(alpha: number, df: number): number {
  if (df <= 0 || isNaN(df) || alpha <= 0 || alpha >= 1 || isNaN(alpha)) return NaN;
  if (df >= 1000) return normalQuantile(1 - alpha / 2);
  // Root finding via bisection method
  let low = 0.0;
  let high = 100.0;
  for (let iter = 0; iter < 50; iter++) {
    const mid = (low + high) / 2;
    const p = studentTPValue(mid, df);
    if (p > alpha) {
      low = mid;
    } else {
      high = mid;
    }
  }
  return (low + high) / 2;
}

/**
 * Chi-Square distribution p-value (upper tail: P(X >= chi2))
 */
export function chiSquarePValue(chi2: number, df: number): number {
  if (chi2 <= 0 || df <= 0) return 1;
  return regularizedGammaQ(df / 2, chi2 / 2);
}

/**
 * Fisher's F-distribution p-value (upper tail: P(X >= F))
 */
export function fDistPValue(f: number, df1: number, df2: number): number {
  if (f <= 0 || df1 <= 0 || df2 <= 0) return 1;
  const x = df2 / (df2 + df1 * f);
  return regularizedIncompleteBeta(x, df2 / 2, df1 / 2);
}

export function parseStatisticalNumber(val: any): { isValid: boolean; num: number; currency?: string } {
  if (val === null || val === undefined || val === '') return { isValid: false, num: 0 };
  if (typeof val === 'number') {
    if (isNaN(val) || !isFinite(val)) return { isValid: false, num: 0 };
    return { isValid: true, num: val };
  }
  let str = String(val)
    .replace(/[٠۰]/g, '0').replace(/[١۱]/g, '1').replace(/[٢۲]/g, '2').replace(/[٣۳]/g, '3')
    .replace(/[٤۴]/g, '4').replace(/[٥۵]/g, '5').replace(/[٦۶]/g, '6').replace(/[٧۷]/g, '7')
    .replace(/[٨۸]/g, '8').replace(/[٩۹]/g, '9').trim();

  let currency: string | undefined;
  if (/ج\.م|جم|جنيه|egp|l\.e/i.test(str)) currency = 'EGP';
  else if (/\$|usd|دولار/i.test(str)) currency = 'USD';
  else if (/€|eur|يورو/i.test(str)) currency = 'EUR';
  else if (/ر\.س|رس|sar|ريال/i.test(str)) currency = 'SAR';

  str = str.replace(/[ج\.مجمجنيهegpl\$usdدولار€eurيورور\.سرسsarريال%]/gi, '').trim();

  let isNegative = false;
  if (str.startsWith('(') && str.endsWith(')')) {
    isNegative = true;
    str = str.slice(1, -1).trim();
  } else if (str.startsWith('-')) {
    isNegative = true;
    str = str.slice(1).trim();
  }

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
  str = str.replace(/٫/g, '.').replace(/٬/g, '');

  if (!/^-?\d+(\.\d+)?$/.test(str)) {
    return { isValid: false, num: 0, currency };
  }

  const parsed = parseFloat(str);
  if (isNaN(parsed) || !isFinite(parsed)) return { isValid: false, num: 0, currency };
  return { isValid: true, num: isNegative ? -parsed : parsed, currency };
}

export function extractRowCurrency(row: Record<string, any>, colName: string, cellDetectedCurrency?: string): string {
  const currColKey = Object.keys(row).find(k => /عملة|currency/i.test(k));
  if (currColKey && row[currColKey]) {
    const val = String(row[currColKey]).trim().toUpperCase();
    if (val) return val;
  }
  if (cellDetectedCurrency) return cellDetectedCurrency;
  return '(عملة غير محددة)';
}

// =========================================================================
// STATISTICAL TEST DATA TYPES & INTERFACES
// =========================================================================

export type StatisticalTestType =
  | 'descriptive'
  | 'correlation'
  | 'two_independent_groups'
  | 'paired_samples'
  | 'anova_kruskal'
  | 'contingency_table';

export interface PreconditionCheck {
  condition: string;
  satisfied: boolean;
  message: string;
  recommendation?: string;
}

export interface StatisticalTestResult {
  testId: StatisticalTestType;
  testNameAr: string;
  testNameEn: string;
  sheetName: string;
  columnsUsed: string[];
  currency?: string;
  alpha: number; // Significance level (0.05, 0.01, 0.10)
  sampleSizes: Record<string, number>;
  totalRowsMatchingFilter: number;
  usedRowsCount: number;
  excludedRowsCount: number;
  excludedReasons: Record<string, number>;
  usedRowIndices: number[]; // Absolute indices in dataset
  originalExcelRowNumbers: number[]; // 1-indexed Excel row numbers
  hypotheses?: {
    nullHypothesis: string; // H0
    altHypothesis: string;  // H1
  };
  assumptions: PreconditionCheck[];
  canExecuteNormally: boolean;
  statistics: {
    primaryStatName: string;
    primaryStatValue: number;
    secondaryStatName?: string;
    secondaryStatValue?: number;
    degreesOfFreedom?: number | string;
    pValue?: number;
    isSignificant?: boolean;
    effectSize?: {
      name: string;
      value: number;
      interpretation: string;
    };
    confidenceInterval?: {
      level: number;
      lower: number;
      upper: number;
      parameterName: string;
    };
  };
  explanationAr: string;
  visualData?: any;
}

// =========================================================================
// 1. DESCRIPTIVE STATISTICS & OUTLIERS (Single Numeric Column)
// =========================================================================

export interface DescriptiveResult extends StatisticalTestResult {
  descriptiveMetrics: {
    mean: string;
    median: string;
    sampleStdDev: string;
    variance: string;
    min: string;
    max: string;
    q1: string;
    q3: string;
    iqr: string;
    outlierThresholdLower: string;
    outlierThresholdUpper: string;
    outliersCount: number;
    outliers: Array<{ value: number; excelRow: number }>;
    histogramBins: Array<{ binStart: number; binEnd: number; count: number; label: string }>;
  };
}

export function runDescriptiveTest(
  rows: Array<Record<string, any>>,
  colName: string,
  currency?: string,
  alpha: number = 0.05,
  sheetName: string = 'الورقة'
): DescriptiveResult {
  const usedDecimals: Decimal[] = [];
  const usedIndices: number[] = [];
  const excelRowNumbers: number[] = [];
  const excludedReasons: Record<string, number> = {
    'خلايا فارغة أو غير محددة': 0,
    'قيم غير رقمية': 0
  };

  const detectedCurrs = new Set<string>();

  rows.forEach((row, idx) => {
    const raw = row[colName];
    if (raw === null || raw === undefined || String(raw).trim() === '') {
      excludedReasons['خلايا فارغة أو غير محددة']++;
      return;
    }
    const parsed = parseStatisticalNumber(raw);
    if (!parsed.isValid) {
      excludedReasons['قيم غير رقمية']++;
      return;
    }

    const rowCurr = extractRowCurrency(row, colName, parsed.currency);
    if (rowCurr !== '(عملة غير محددة)') {
      detectedCurrs.add(rowCurr);
    }

    if (currency && currency !== 'all' && rowCurr !== currency) {
      const reasonKey = `عملة مستبعدة (غير ${currency})`;
      excludedReasons[reasonKey] = (excludedReasons[reasonKey] || 0) + 1;
      return;
    }

    usedDecimals.push(new Decimal(parsed.num));
    usedIndices.push(idx);
    excelRowNumbers.push(row.__rowIndex || idx + 1);
  });

  const n = usedDecimals.length;
  const isMultiCurrencyDetected = !currency && detectedCurrs.size > 1;

  const assumptions: PreconditionCheck[] = [
    {
      condition: 'حجم العينة الأدنى (n >= 3)',
      satisfied: n >= 3,
      message: n >= 3 ? `حجم العينة (${n}) كافٍ للتحليل الوصفي.` : `حجم العينة (${n}) صغير جدًا للتحليل الإحصائي الموثوق.`,
      recommendation: n < 3 ? 'يُفضل جمع المزيد من البيانات لتوفير تمثيل إحصائي كافٍ.' : undefined
    }
  ];

  if (isMultiCurrencyDetected) {
    assumptions.push({
      condition: 'فصل العملات للمبالغ المالية',
      satisfied: false,
      message: `العمود يحتوي على مبالغ بعملات متعددة (${Array.from(detectedCurrs).join(' ، ')}). تجنباً لخلط العملات في الحساب، يجب اختيار عملة محددة.`,
      recommendation: 'اختر العملة المطلوبة لإجراء الاختبار عليها حصراً.'
    });
  }

  if (n === 0) {
    return {
      testId: 'descriptive',
      testNameAr: 'الإحصاء الوصفي واكتشاف القيم الشاذة',
      testNameEn: 'Descriptive Statistics & Outlier Detection',
      sheetName,
      columnsUsed: [colName],
      currency,
      alpha,
      sampleSizes: { [colName]: 0 },
      totalRowsMatchingFilter: rows.length,
      usedRowsCount: 0,
      excludedRowsCount: rows.length,
      excludedReasons,
      usedRowIndices: [],
      originalExcelRowNumbers: [],
      assumptions,
      canExecuteNormally: false,
      statistics: {
        primaryStatName: 'المتوسط',
        primaryStatValue: 0
      },
      explanationAr: 'لا توجد بيانات رقمية صالحة لإجراء التحليل الوصفي.',
      descriptiveMetrics: {
        mean: '0.00', median: '0.00', sampleStdDev: '0.00', variance: '0.00',
        min: '0.00', max: '0.00', q1: '0.00', q3: '0.00', iqr: '0.00',
        outlierThresholdLower: '0.00', outlierThresholdUpper: '0.00',
        outliersCount: 0, outliers: [], histogramBins: []
      }
    };
  }

  // Sorted values for quantiles & median
  const sorted = [...usedDecimals].sort((a, b) => a.comparedTo(b));
  let sum = new Decimal(0);
  for (const d of sorted) sum = sum.plus(d);

  const mean = sum.dividedBy(n);
  const min = sorted[0];
  const max = sorted[sorted.length - 1];

  // Median
  const mid = Math.floor(n / 2);
  const median = n % 2 === 0 ? sorted[mid - 1].plus(sorted[mid]).dividedBy(2) : sorted[mid];

  // Sample Standard Deviation
  let sumSqDiff = new Decimal(0);
  for (const d of sorted) {
    const diff = d.minus(mean);
    sumSqDiff = sumSqDiff.plus(diff.times(diff));
  }
  const variance = n > 1 ? sumSqDiff.dividedBy(n - 1) : new Decimal(0);
  const stdDev = variance.greaterThan(0) ? new Decimal(Math.sqrt(variance.toNumber())) : new Decimal(0);

  // Quartiles (Method 7 / Linear interpolation)
  const getPercentile = (p: number): Decimal => {
    if (n === 1) return sorted[0];
    const index = p * (n - 1);
    const lower = Math.floor(index);
    const upper = Math.ceil(index);
    const weight = index - lower;
    if (lower === upper) return sorted[lower];
    return sorted[lower].times(1 - weight).plus(sorted[upper].times(weight));
  };

  const q1 = getPercentile(0.25);
  const q3 = getPercentile(0.75);
  const iqr = q3.minus(q1);

  // Outliers: Tukey's 1.5 * IQR rule
  const lowerThreshold = q1.minus(iqr.times(1.5));
  const upperThreshold = q3.plus(iqr.times(1.5));

  const outliers: Array<{ value: number; excelRow: number }> = [];
  usedDecimals.forEach((d, i) => {
    if (d.lessThan(lowerThreshold) || d.greaterThan(upperThreshold)) {
      outliers.push({
        value: d.toNumber(),
        excelRow: excelRowNumbers[i]
      });
    }
  });

  // Histogram bins (5 bins)
  const range = max.minus(min).toNumber();
  const binCount = Math.min(8, Math.max(4, Math.round(Math.sqrt(n))));
  const binWidth = range > 0 ? range / binCount : 1;
  const histogramBins: Array<{ binStart: number; binEnd: number; count: number; label: string }> = [];

  for (let b = 0; b < binCount; b++) {
    const bStart = min.toNumber() + b * binWidth;
    const bEnd = b === binCount - 1 ? max.toNumber() : bStart + binWidth;
    histogramBins.push({
      binStart: parseFloat(bStart.toFixed(2)),
      binEnd: parseFloat(bEnd.toFixed(2)),
      count: 0,
      label: `${bStart.toFixed(1)} - ${bEnd.toFixed(1)}`
    });
  }

  for (const d of sorted) {
    const val = d.toNumber();
    let placed = false;
    for (let b = 0; b < binCount; b++) {
      if (b === binCount - 1) {
        if (val >= histogramBins[b].binStart && val <= histogramBins[b].binEnd + 0.00001) {
          histogramBins[b].count++;
          placed = true;
          break;
        }
      } else if (val >= histogramBins[b].binStart && val < histogramBins[b].binEnd) {
        histogramBins[b].count++;
        placed = true;
        break;
      }
    }
    if (!placed && histogramBins.length > 0) histogramBins[histogramBins.length - 1].count++;
  }

  const currSuffix = currency ? ` ${currency}` : '';
  const explanation = `يبلغ متوسط القيم ${mean.toFixed(2)}${currSuffix} مع وسيط ${median.toFixed(2)}${currSuffix} وانحراف معياري قدره ${stdDev.toFixed(2)}. المدى الربيعي (IQR) يساوي ${iqr.toFixed(2)}${currSuffix}. ووفق قاعدة تيوكي (1.5 × IQR)، تم رصد ${outliers.length} قيمة شاذة تتجاوز الحدود المعتادة [${lowerThreshold.toFixed(2)} إلى ${upperThreshold.toFixed(2)}].`;

  return {
    testId: 'descriptive',
    testNameAr: 'الإحصاء الوصفي ومخطط التوزيع والقيم الشاذة',
    testNameEn: 'Descriptive Statistics & Outlier Analysis',
    sheetName,
    columnsUsed: [colName],
    currency,
    alpha,
    sampleSizes: { [colName]: n },
    totalRowsMatchingFilter: rows.length,
    usedRowsCount: n,
    excludedRowsCount: rows.length - n,
    excludedReasons,
    usedRowIndices: usedIndices,
    originalExcelRowNumbers: excelRowNumbers,
    assumptions,
    canExecuteNormally: true,
    statistics: {
      primaryStatName: 'المتوسط الحسابي',
      primaryStatValue: parseFloat(mean.toFixed(2)),
      secondaryStatName: 'الوسيط',
      secondaryStatValue: parseFloat(median.toFixed(2)),
      degreesOfFreedom: n - 1
    },
    explanationAr: explanation,
    descriptiveMetrics: {
      mean: mean.toFixed(2),
      median: median.toFixed(2),
      sampleStdDev: stdDev.toFixed(2),
      variance: variance.toFixed(2),
      min: min.toFixed(2),
      max: max.toFixed(2),
      q1: q1.toFixed(2),
      q3: q3.toFixed(2),
      iqr: iqr.toFixed(2),
      outlierThresholdLower: lowerThreshold.toFixed(2),
      outlierThresholdUpper: upperThreshold.toFixed(2),
      outliersCount: outliers.length,
      outliers,
      histogramBins
    },
    visualData: {
      type: 'histogram',
      bins: histogramBins
    }
  };
}

// =========================================================================
// 2. CORRELATION (Pearson & Spearman between Two Numeric Columns)
// =========================================================================

export interface CorrelationResult extends StatisticalTestResult {
  correlationMetrics: {
    pearsonR: number;
    pearsonPValue: number;
    spearmanRho: number;
    spearmanPValue: number;
    rSquared: number;
    regressionSlope: number;
    regressionIntercept: number;
    scatterPoints: Array<{ x: number; y: number; excelRow: number }>;
  };
}

export function runCorrelationTest(
  rows: Array<Record<string, any>>,
  colX: string,
  colY: string,
  currency?: string,
  alpha: number = 0.05,
  sheetName: string = 'الورقة'
): CorrelationResult {
  const pairs: Array<{ x: number; y: number; idx: number; excelRow: number }> = [];
  const excludedReasons: Record<string, number> = {
    'بيانات مفقودة في أحد العمودين': 0,
    'قيم غير رقمية': 0
  };

  rows.forEach((r, idx) => {
    const vx = r[colX];
    const vy = r[colY];
    if (vx === null || vx === undefined || String(vx).trim() === '' ||
        vy === null || vy === undefined || String(vy).trim() === '') {
      excludedReasons['بيانات مفقودة في أحد العمودين']++;
      return;
    }
    const px = parseStatisticalNumber(vx);
    const py = parseStatisticalNumber(vy);
    if (!px.isValid || !py.isValid) {
      excludedReasons['قيم غير رقمية']++;
      return;
    }

    if (currency && currency !== 'all') {
      const rowCurr = extractRowCurrency(r, colX, px.currency || py.currency);
      if (rowCurr !== '(عملة غير محددة)' && rowCurr !== currency) {
        const reasonKey = `عملة مستبعدة (غير ${currency})`;
        excludedReasons[reasonKey] = (excludedReasons[reasonKey] || 0) + 1;
        return;
      }
    }

    pairs.push({ x: px.num, y: py.num, idx, excelRow: r.__rowIndex || idx + 1 });
  });

  const n = pairs.length;
  const assumptions: PreconditionCheck[] = [
    {
      condition: 'حجم العينة الأدنى (n >= 4)',
      satisfied: n >= 4,
      message: n >= 4 ? `حجم العينة المشترك (${n}) كافٍ لاختبار الارتباط.` : `حجم العينة (${n}) غير كافٍ لإجراء اختبار ارتباط ذي دلالة إحصائية.`,
      recommendation: n < 4 ? 'تأكد من توفر 4 أزواج بيانات على الأقل.' : undefined
    }
  ];

  if (n < 3) {
    return {
      testId: 'correlation',
      testNameAr: 'معامل ارتباط بيرسون وسبيرمان (Pearson & Spearman)',
      testNameEn: 'Pearson and Spearman Correlation Test',
      sheetName,
      columnsUsed: [colX, colY],
      currency,
      alpha,
      sampleSizes: { [colX]: n, [colY]: n },
      totalRowsMatchingFilter: rows.length,
      usedRowsCount: n,
      excludedRowsCount: rows.length - n,
      excludedReasons,
      usedRowIndices: pairs.map(p => p.idx),
      originalExcelRowNumbers: pairs.map(p => p.excelRow),
      hypotheses: {
        nullHypothesis: `لا يوجد ارتباط خطي أو رتبي بين [${colX}] و[${colY}] (الارتباط = 0).`,
        altHypothesis: `يوجد ارتباط ذو دلالة إحصائية بين [${colX}] و[${colY}] (الارتباط != 0).`
      },
      assumptions,
      canExecuteNormally: false,
      statistics: {
        primaryStatName: 'معامل ارتباط بيرسون (r)',
        primaryStatValue: 0
      },
      explanationAr: 'لا تتوفر أزواج كافية من القيم الرقمية لحساب معامل الارتباط (يتطلب الارتباط 3 أزواج على الأقل، وفترة الثقة 4 أزواج على الأقل).',
      correlationMetrics: {
        pearsonR: 0, pearsonPValue: 1, spearmanRho: 0, spearmanPValue: 1,
        rSquared: 0, regressionSlope: 0, regressionIntercept: 0, scatterPoints: []
      }
    };
  }

  // Means
  let sumX = 0;
  let sumY = 0;
  for (const p of pairs) {
    sumX += p.x;
    sumY += p.y;
  }
  const meanX = sumX / n;
  const meanY = sumY / n;

  let ssX = 0;
  let ssY = 0;
  let ssXY = 0;
  for (const p of pairs) {
    const dx = p.x - meanX;
    const dy = p.y - meanY;
    ssX += dx * dx;
    ssY += dy * dy;
    ssXY += dx * dy;
  }

  // Check constant columns (variance == 0)
  const isConstantX = ssX <= 1e-12;
  const isConstantY = ssY <= 1e-12;
  if (isConstantX || isConstantY) {
    assumptions.push({
      condition: 'تباين الأعمدة غير صفري',
      satisfied: false,
      message: `أحد العمودين يحتوي على قيم متطابقة بدون تباين (${isConstantX ? colX : colY}). لا يمكن حساب الارتباط للقيم الثابتة.`,
      recommendation: 'اختر عموداً يحتوي على تباين في القيم.'
    });

    return {
      testId: 'correlation',
      testNameAr: 'معامل ارتباط بيرسون وسبيرمان (Pearson & Spearman)',
      testNameEn: 'Pearson and Spearman Correlation Test',
      sheetName,
      columnsUsed: [colX, colY],
      currency,
      alpha,
      sampleSizes: { [colX]: n, [colY]: n },
      totalRowsMatchingFilter: rows.length,
      usedRowsCount: n,
      excludedRowsCount: rows.length - n,
      excludedReasons,
      usedRowIndices: pairs.map(p => p.idx),
      originalExcelRowNumbers: pairs.map(p => p.excelRow),
      hypotheses: {
        nullHypothesis: `لا يوجد ارتباط خطي بين [${colX}] و[${colY}].`,
        altHypothesis: `يوجد ارتباط خطي بين [${colX}] و[${colY}].`
      },
      assumptions,
      canExecuteNormally: false,
      statistics: {
        primaryStatName: 'معامل ارتباط بيرسون (r)',
        primaryStatValue: 0
      },
      explanationAr: `تعذر حساب الارتباط لأن عمود [${isConstantX ? colX : colY}] يحتوي على قيم متطابقة تماماً (التباين = 0).`,
      correlationMetrics: {
        pearsonR: 0, pearsonPValue: 1, spearmanRho: 0, spearmanPValue: 1,
        rSquared: 0, regressionSlope: 0, regressionIntercept: meanY,
        scatterPoints: pairs.map(p => ({ x: p.x, y: p.y, excelRow: p.excelRow }))
      }
    };
  }

  // Pearson r
  const r = ssXY / Math.sqrt(ssX * ssY);
  const clampedR = Math.max(-1, Math.min(1, r));
  const df = n - 2;
  const tStat = Math.abs(clampedR) >= 0.999999
    ? 999.0
    : clampedR * Math.sqrt(df / (1 - clampedR * clampedR));
  const pearsonP = studentTPValue(tStat, df);

  // Linear Regression y = slope * x + intercept
  const slope = ssXY / ssX;
  const intercept = meanY - slope * meanX;
  const rSquared = clampedR * clampedR;

  // Spearman Rank Correlation
  const ranksX = getFractionalRanks(pairs.map(p => p.x));
  const ranksY = getFractionalRanks(pairs.map(p => p.y));
  let rankMeanX = (n + 1) / 2;
  let rankMeanY = (n + 1) / 2;
  let rankSsX = 0;
  let rankSsY = 0;
  let rankSsXY = 0;
  for (let i = 0; i < n; i++) {
    const rx = ranksX[i] - rankMeanX;
    const ry = ranksY[i] - rankMeanY;
    rankSsX += rx * rx;
    rankSsY += ry * ry;
    rankSsXY += rx * ry;
  }
  const spearmanRho = rankSsX > 0 && rankSsY > 0 ? Math.max(-1, Math.min(1, rankSsXY / Math.sqrt(rankSsX * rankSsY))) : 0;
  const spearmanT = Math.abs(spearmanRho) >= 0.999999 ? 999.0 : spearmanRho * Math.sqrt(df / (1 - spearmanRho * spearmanRho));
  const spearmanP = studentTPValue(spearmanT, df);

  // Confidence Interval for Pearson r (Fisher's z-transformation)
  let ciLower: number | undefined;
  let ciUpper: number | undefined;

  if (n >= 4) {
    if (clampedR >= 0.9999999) {
      ciLower = 1.0;
      ciUpper = 1.0;
    } else if (clampedR <= -0.9999999) {
      ciLower = -1.0;
      ciUpper = -1.0;
    } else {
      const zFisher = 0.5 * Math.log((1 + clampedR) / (1 - clampedR));
      const seZ = 1 / Math.sqrt(n - 3);
      const zCrit = normalQuantile(1 - alpha / 2);
      const zLower = zFisher - zCrit * seZ;
      const zUpper = zFisher + zCrit * seZ;
      ciLower = Math.tanh(zLower);
      ciUpper = Math.tanh(zUpper);
    }
  } else {
    assumptions.push({
      condition: 'حجم العينة لحساب فترة الثقة (n >= 4)',
      satisfied: false,
      message: `حجم العينة (${n}) غير كافٍ لحساب فترة الثقة لمعامل الارتباط (يتطلب 4 أزواج على الأقل).`,
      recommendation: 'يُفضل جمع عينات أكبر لحساب فترات الثقة.'
    });
  }

  const isSignificant = pearsonP < alpha;
  const dirStr = clampedR > 0 ? 'طردي إيجابي' : 'عكسي سلبي';
  const strengthStr = Math.abs(clampedR) > 0.7 ? 'قوي جداً' : Math.abs(clampedR) > 0.4 ? 'متوسط' : 'ضعيف';

  let explanationAr = '';
  if (isSignificant) {
    explanationAr = `يوجد ارتباط خطي ذو دلالة إحصائية (${dirStr}، ${strengthStr}) بين [${colX}] و[${colY}] بقيمة r = ${clampedR.toFixed(3)}، p = ${pearsonP < 0.001 ? '< 0.001' : pearsonP.toFixed(4)}. ومعامل ارتباط الرتب لسبيرمان هو ρ = ${spearmanRho.toFixed(3)}. وتفسر العلاقة الخطية نحو ${(rSquared * 100).toFixed(1)}% من التباين المشترك (R²).${ciLower !== undefined && ciUpper !== undefined ? ` فترة الثقة ${(1 - alpha) * 100}% لمعامل الارتباط هي [${ciLower.toFixed(3)}، ${ciUpper.toFixed(3)}].` : ''} تنبيه علمي رقابي: الارتباط الإحصائي يقيس درجة الاقتران الخطي في العينة ولا يثبت بالضرورة وجود علاقة سببية مباشرة بين المتغيرين.`;
  } else {
    explanationAr = `الأدلة غير كافية لرفض الفرضية الصفرية عند مستوى دلالة ${(alpha * 100)}% (p = ${pearsonP.toFixed(4)} >= ${alpha}). قيمة الارتباط هي r = ${clampedR.toFixed(3)}، وتفسر النتيجة عدم كفاية البيانات لإثبات وجود علاقة خطية في المجتمع الإحصائي وليس إثباتاً قاطعاً لعدم وجودها. تنبيه علمي رقابي: الارتباط الإحصائي يقيس التزامن العددي ولا يثبت السببية.`;
  }

  return {
    testId: 'correlation',
    testNameAr: 'معامل ارتباط بيرسون وسبيرمان (Pearson & Spearman)',
    testNameEn: 'Pearson and Spearman Correlation Test',
    sheetName,
    columnsUsed: [colX, colY],
    currency,
    alpha,
    sampleSizes: { [colX]: n, [colY]: n },
    totalRowsMatchingFilter: rows.length,
    usedRowsCount: n,
    excludedRowsCount: rows.length - n,
    excludedReasons,
    usedRowIndices: pairs.map(p => p.idx),
    originalExcelRowNumbers: pairs.map(p => p.excelRow),
    hypotheses: {
      nullHypothesis: `لا يوجد ارتباط خطي بين [${colX}] و[${colY}] في المجتمع الإحصائي (r = 0).`,
      altHypothesis: `يوجد ارتباط خطي بين [${colX}] و[${colY}] يختلف عن الصفر (r != 0).`
    },
    assumptions,
    canExecuteNormally: true,
    statistics: {
      primaryStatName: 'معامل ارتباط بيرسون (r)',
      primaryStatValue: parseFloat(clampedR.toFixed(4)),
      secondaryStatName: 'معامل ارتباط سبيرمان (ρ)',
      secondaryStatValue: parseFloat(spearmanRho.toFixed(4)),
      degreesOfFreedom: df,
      pValue: parseFloat(pearsonP.toFixed(4)),
      isSignificant,
      effectSize: {
        name: 'معامل التحديد (R²)',
        value: parseFloat(rSquared.toFixed(4)),
        interpretation: `يفسر ${(rSquared * 100).toFixed(1)}% من التباين المشترك`
      },
      confidenceInterval: ciLower !== undefined && ciUpper !== undefined ? {
        level: (1 - alpha) * 100,
        lower: parseFloat(ciLower.toFixed(6)),
        upper: parseFloat(ciUpper.toFixed(6)),
        parameterName: 'مجال ثقة معامل الارتباط (r)'
      } : undefined
    },
    explanationAr,
    correlationMetrics: {
      pearsonR: parseFloat(clampedR.toFixed(4)),
      pearsonPValue: parseFloat(pearsonP.toFixed(4)),
      spearmanRho: parseFloat(spearmanRho.toFixed(4)),
      spearmanPValue: parseFloat(spearmanP.toFixed(4)),
      rSquared: parseFloat(rSquared.toFixed(4)),
      regressionSlope: parseFloat(slope.toFixed(4)),
      regressionIntercept: parseFloat(intercept.toFixed(4)),
      scatterPoints: pairs.map(p => ({ x: p.x, y: p.y, excelRow: p.excelRow }))
    },
    visualData: {
      type: 'scatter',
      xCol: colX,
      yCol: colY,
      slope,
      intercept,
      points: pairs.map(p => ({ x: p.x, y: p.y, excelRow: p.excelRow }))
    }
  };
}

// =========================================================================
// 3. TWO INDEPENDENT GROUPS (Welch's t-test & Mann-Whitney U test)
// =========================================================================

export interface TwoGroupResult extends StatisticalTestResult {
  twoGroupMetrics: {
    group1Name: string;
    group2Name: string;
    mean1: number;
    mean2: number;
    stdDev1: number;
    stdDev2: number;
    meanDifference: number;
    welchT: number;
    welchDf: number;
    welchPValue: number;
    mannWhitneyU: number;
    mannWhitneyPValue: number;
    cohensD: number;
  };
}

export function runTwoIndependentGroupsTest(
  rows: Array<Record<string, any>>,
  numericCol: string,
  groupCol: string,
  group1Value: string,
  group2Value: string,
  currency?: string,
  alpha: number = 0.05,
  sheetName: string = 'الورقة'
): TwoGroupResult {
  const g1Values: number[] = [];
  const g2Values: number[] = [];
  const g1Indices: number[] = [];
  const g2Indices: number[] = [];
  const g1ExcelRows: number[] = [];
  const g2ExcelRows: number[] = [];
  const excludedReasons: Record<string, number> = {
    'خارج المجموعتين المحددين': 0,
    'قيمة رقمية مفقودة أو غير صالحة': 0
  };

  rows.forEach((r, idx) => {
    const rawGrp = String(r[groupCol] ?? '').trim();
    if (rawGrp !== group1Value && rawGrp !== group2Value) {
      excludedReasons['خارج المجموعتين المحددين']++;
      return;
    }
    const rawNum = r[numericCol];
    if (rawNum === null || rawNum === undefined || String(rawNum).trim() === '') {
      excludedReasons['قيمة رقمية مفقودة أو غير صالحة']++;
      return;
    }
    const pNum = parseStatisticalNumber(rawNum);
    if (!pNum.isValid) {
      excludedReasons['قيمة رقمية مفقودة أو غير صالحة']++;
      return;
    }

    if (currency && currency !== 'all') {
      const rowCurr = extractRowCurrency(r, numericCol, pNum.currency);
      if (rowCurr !== '(عملة غير محددة)' && rowCurr !== currency) {
        const reasonKey = `عملة مستبعدة (غير ${currency})`;
        excludedReasons[reasonKey] = (excludedReasons[reasonKey] || 0) + 1;
        return;
      }
    }

    const exRow = r.__rowIndex || idx + 1;
    if (rawGrp === group1Value) {
      g1Values.push(pNum.num);
      g1Indices.push(idx);
      g1ExcelRows.push(exRow);
    } else {
      g2Values.push(pNum.num);
      g2Indices.push(idx);
      g2ExcelRows.push(exRow);
    }
  });

  const n1 = g1Values.length;
  const n2 = g2Values.length;

  const assumptions: PreconditionCheck[] = [
    {
      condition: 'استقلالية العينات وحجم كل مجموعة (n1, n2 >= 2)',
      satisfied: n1 >= 2 && n2 >= 2,
      message: n1 >= 2 && n2 >= 2
        ? `المجموعتان تلبيان الحد الأدنى للمقارنة (${group1Value}: n=${n1}، ${group2Value}: n=${n2}).`
        : `حجم إحدى المجموعتين غير كافٍ للمقارنة (${group1Value}: n=${n1}، ${group2Value}: n=${n2}).`,
      recommendation: (n1 < 2 || n2 < 2) ? 'تأكد من وجود قيمتين على الأقل لكل مجموعة مستهدفة.' : undefined
    }
  ];

  if (n1 < 2 || n2 < 2) {
    return {
      testId: 'two_independent_groups',
      testNameAr: 'اختبار ويلش للمجموعات المستقلة ومان-ويتني (Welch & Mann-Whitney)',
      testNameEn: "Welch's t-test and Mann-Whitney U test",
      sheetName,
      columnsUsed: [numericCol, groupCol],
      currency,
      alpha,
      sampleSizes: { [group1Value]: n1, [group2Value]: n2 },
      totalRowsMatchingFilter: rows.length,
      usedRowsCount: n1 + n2,
      excludedRowsCount: rows.length - (n1 + n2),
      excludedReasons,
      usedRowIndices: [...g1Indices, ...g2Indices],
      originalExcelRowNumbers: [...g1ExcelRows, ...g2ExcelRows],
      hypotheses: {
        nullHypothesis: `لا يوجد فرق ذو دلالة إحصائية بين متوسط [${group1Value}] ومتوسط [${group2Value}].`,
        altHypothesis: `يوجد فرق ذو دلالة إحصائية بين المجموعتين.`
      },
      assumptions,
      canExecuteNormally: false,
      statistics: {
        primaryStatName: 'إحصائية ويلش (t)',
        primaryStatValue: 0,
        pValue: 1.0,
        isSignificant: false
      },
      explanationAr: 'لا تتوفر بيانات كافية في إحدى المجموعتين لإجراء المقارنة المستقلة.',
      twoGroupMetrics: {
        group1Name: group1Value, group2Name: group2Value,
        mean1: 0, mean2: 0, stdDev1: 0, stdDev2: 0, meanDifference: 0,
        welchT: 0, welchDf: 1, welchPValue: 1, mannWhitneyU: 0, mannWhitneyPValue: 1, cohensD: 0
      }
    };
  }

  // Means & Variances
  const mean1 = g1Values.reduce((a, b) => a + b, 0) / n1;
  const mean2 = g2Values.reduce((a, b) => a + b, 0) / n2;
  const var1 = g1Values.reduce((a, b) => a + Math.pow(b - mean1, 2), 0) / (n1 - 1);
  const var2 = g2Values.reduce((a, b) => a + Math.pow(b - mean2, 2), 0) / (n2 - 1);
  const s1 = Math.sqrt(var1);
  const s2 = Math.sqrt(var2);

  const meanDiff = mean1 - mean2;
  const se1 = var1 / n1;
  const se2 = var2 / n2;
  const seDiff = Math.sqrt(se1 + se2);

  // Welch t & Welch-Satterthwaite degrees of freedom
  let welchT = 0;
  let welchDf = n1 + n2 - 2;
  let welchP = 1.0;

  if (seDiff > 1e-12) {
    welchT = meanDiff / seDiff;
    const num = Math.pow(se1 + se2, 2);
    const den = (Math.pow(se1, 2) / (n1 - 1)) + (Math.pow(se2, 2) / (n2 - 1));
    welchDf = den > 0 ? num / den : n1 + n2 - 2;
    welchP = studentTPValue(welchT, welchDf);
  }

  // Cohen's d (pooled standard deviation)
  const pooledVar = ((n1 - 1) * var1 + (n2 - 1) * var2) / (n1 + n2 - 2);
  const pooledSd = Math.sqrt(pooledVar);
  const cohensD = pooledSd > 0 ? meanDiff / pooledSd : 0;

  // Confidence Interval for mean difference
  const tCrit = studentTCritical(alpha, welchDf);
  const ciLower = meanDiff - tCrit * seDiff;
  const ciUpper = meanDiff + tCrit * seDiff;

  // Mann-Whitney U test
  const combined = [
    ...g1Values.map(v => ({ v, g: 1 })),
    ...g2Values.map(v => ({ v, g: 2 }))
  ];
  const ranks = getFractionalRanks(combined.map(c => c.v));
  let rankSum1 = 0;
  for (let i = 0; i < combined.length; i++) {
    if (combined[i].g === 1) rankSum1 += ranks[i];
  }
  const u1 = rankSum1 - (n1 * (n1 + 1)) / 2;
  const u2 = n1 * n2 - u1;
  const uStat = Math.min(u1, u2);

  // Normal approximation for Mann-Whitney U
  const meanU = (n1 * n2) / 2;
  const tieTerm = computeTieCorrectionTerm(combined.map(c => c.v));
  const N = n1 + n2;
  const varU = (n1 * n2 / 12) * ((N + 1) - tieTerm / (N * (N - 1)));
  const sdU = Math.sqrt(Math.max(1e-10, varU));
  const zU = (Math.abs(uStat - meanU) - 0.5) / sdU;
  const mannWhitneyP = Math.min(1, Math.max(0, 2 * (1 - normalCdf(zU))));

  const isSignificant = welchP < alpha;
  const currSuffix = currency ? ` ${currency}` : '';

  let explanationAr = '';
  if (isSignificant) {
    explanationAr = `يوجد فرق ذو دلالة إحصائية بين متوسط [${group1Value}] (${mean1.toFixed(2)}${currSuffix}) ومتوسط [${group2Value}] (${mean2.toFixed(2)}${currSuffix}) وفق اختبار ويلش (t = ${welchT.toFixed(3)}، df = ${welchDf.toFixed(1)}، p = ${welchP < 0.001 ? '< 0.001' : welchP.toFixed(4)} < ${alpha}). حجم الأثر (Cohen's d = ${cohensD.toFixed(3)}). واختبار مان-ويتني اللابارامتري يعطي p = ${mannWhitneyP.toFixed(4)}. نرفض الفرضية الصفرية لصالح فرضية وجود اختلاف حقيقي بين المجموعتين.`;
  } else {
    explanationAr = `الأدلة غير كافية لرفض الفرضية الصفرية عند مستوى دلالة ${(alpha * 100)}% (p = ${welchP.toFixed(4)} >= ${alpha}). متوسط [${group1Value}] هو ${mean1.toFixed(2)}${currSuffix} مقابل ${mean2.toFixed(2)}${currSuffix} لـ [${group2Value}] بفارق ${meanDiff.toFixed(2)}${currSuffix}. لا يوجد دليل إحصائي كافٍ على أن هذا الفارق ناتج عن سبب جوهري وليس مجرد تباين عشوائي.`;
  }

  return {
    testId: 'two_independent_groups',
    testNameAr: 'مقارنة مجموعتين مستقلتين (Welch t-test & Mann-Whitney U)',
    testNameEn: "Welch's t-test and Mann-Whitney U test",
    sheetName,
    columnsUsed: [numericCol, groupCol],
    currency,
    alpha,
    sampleSizes: { [group1Value]: n1, [group2Value]: n2 },
    totalRowsMatchingFilter: rows.length,
    usedRowsCount: n1 + n2,
    excludedRowsCount: rows.length - (n1 + n2),
    excludedReasons,
    usedRowIndices: [...g1Indices, ...g2Indices],
    originalExcelRowNumbers: [...g1ExcelRows, ...g2ExcelRows],
    hypotheses: {
      nullHypothesis: `متوسط المجتمع لـ [${group1Value}] يساوي متوسط المجتمع لـ [${group2Value}] (الفرق = 0).`,
      altHypothesis: `متوسط [${group1Value}] يختلف معنوياً عن متوسط [${group2Value}] (الفرق != 0).`
    },
    assumptions,
    canExecuteNormally: true,
    statistics: {
      primaryStatName: 'إحصائية ويلش (t)',
      primaryStatValue: parseFloat(welchT.toFixed(4)),
      secondaryStatName: 'إحصائية مان-ويتني (U)',
      secondaryStatValue: parseFloat(uStat.toFixed(2)),
      degreesOfFreedom: parseFloat(welchDf.toFixed(2)),
      pValue: parseFloat(welchP.toFixed(4)),
      isSignificant,
      effectSize: {
        name: "حجم الأثر (Cohen's d)",
        value: parseFloat(cohensD.toFixed(3)),
        interpretation: Math.abs(cohensD) > 0.8 ? 'أثر كبير' : Math.abs(cohensD) > 0.5 ? 'أثر متوسط' : 'أثر صغير'
      },
      confidenceInterval: {
        level: (1 - alpha) * 100,
        lower: parseFloat(ciLower.toFixed(2)),
        upper: parseFloat(ciUpper.toFixed(2)),
        parameterName: 'فترة ثقة فرق المتوسطين'
      }
    },
    explanationAr,
    twoGroupMetrics: {
      group1Name: group1Value,
      group2Name: group2Value,
      mean1: parseFloat(mean1.toFixed(2)),
      mean2: parseFloat(mean2.toFixed(2)),
      stdDev1: parseFloat(s1.toFixed(2)),
      stdDev2: parseFloat(s2.toFixed(2)),
      meanDifference: parseFloat(meanDiff.toFixed(2)),
      welchT: parseFloat(welchT.toFixed(4)),
      welchDf: parseFloat(welchDf.toFixed(2)),
      welchPValue: parseFloat(welchP.toFixed(4)),
      mannWhitneyU: parseFloat(uStat.toFixed(2)),
      mannWhitneyPValue: parseFloat(mannWhitneyP.toFixed(4)),
      cohensD: parseFloat(cohensD.toFixed(3))
    },
    visualData: {
      type: 'two_group_comparison',
      groups: [
        { name: group1Value, mean: mean1, stdDev: s1, n: n1 },
        { name: group2Value, mean: mean2, stdDev: s2, n: n2 }
      ]
    }
  };
}

// =========================================================================
// 4. PAIRED SAMPLES (Paired t-test & Wilcoxon Signed-Rank Test)
// =========================================================================

export interface PairedResult extends StatisticalTestResult {
  pairedMetrics: {
    meanBefore: number;
    meanAfter: number;
    meanDifference: number;
    stdDevDifference: number;
    tStatistic: number;
    df: number;
    tPValue: number;
    wilcoxonW: number;
    wilcoxonPValue: number;
    cohensDz: number;
  };
}

export function runPairedSamplesTest(
  rows: Array<Record<string, any>>,
  colBefore: string,
  colAfter: string,
  keyCol?: string,
  currency?: string,
  alpha: number = 0.05,
  sheetName: string = 'الورقة'
): PairedResult {
  const pairedData: Array<{ id: string; before: number; after: number; diff: number; idx: number; excelRow: number }> = [];
  const excludedReasons: Record<string, number> = {
    'بيانات قبل أو بعد مفقودة': 0,
    'قيم غير رقمية': 0,
    'معرفات مكررة أو أزواج ناقصة': 0
  };

  const seenKeys = new Set<string>();

  rows.forEach((r, idx) => {
    const rawKey = keyCol ? String(r[keyCol] ?? '').trim() : `row_${idx}`;
    if (keyCol && seenKeys.has(rawKey)) {
      excludedReasons['معرفات مكررة أو أزواج ناقصة']++;
      return;
    }
    if (keyCol && rawKey) seenKeys.add(rawKey);

    const vb = r[colBefore];
    const va = r[colAfter];
    if (vb === null || vb === undefined || String(vb).trim() === '' ||
        va === null || va === undefined || String(va).trim() === '') {
      excludedReasons['بيانات قبل أو بعد مفقودة']++;
      return;
    }
    const pb = parseStatisticalNumber(vb);
    const pa = parseStatisticalNumber(va);
    if (!pb.isValid || !pa.isValid) {
      excludedReasons['قيم غير رقمية']++;
      return;
    }

    if (currency && currency !== 'all') {
      const rowCurr = extractRowCurrency(r, colBefore, pb.currency || pa.currency);
      if (rowCurr !== '(عملة غير محددة)' && rowCurr !== currency) {
        const reasonKey = `عملة مستبعدة (غير ${currency})`;
        excludedReasons[reasonKey] = (excludedReasons[reasonKey] || 0) + 1;
        return;
      }
    }

    pairedData.push({
      id: rawKey,
      before: pb.num,
      after: pa.num,
      diff: pa.num - pb.num,
      idx,
      excelRow: r.__rowIndex || idx + 1
    });
  });

  const n = pairedData.length;
  const assumptions: PreconditionCheck[] = [
    {
      condition: 'حجم العينة المزدوجة (n >= 3)',
      satisfied: n >= 3,
      message: n >= 3 ? `عدد الأزواج المتطابقة (${n}) كافٍ للاختبار.` : `عدد الأزواج (${n}) صغير جداً للاختبار المزدوج.`,
      recommendation: n < 3 ? 'تأكد من توفر 3 أزواج قياسات مطابقة على الأقل.' : undefined
    }
  ];

  if (n < 2) {
    return {
      testId: 'paired_samples',
      testNameAr: 'اختبار العينات المزدوجة وويلكوكسون (Paired t & Wilcoxon)',
      testNameEn: 'Paired Samples t-test and Wilcoxon Signed-Rank Test',
      sheetName,
      columnsUsed: [colBefore, colAfter],
      currency,
      alpha,
      sampleSizes: { 'أزواج مكتملة': n },
      totalRowsMatchingFilter: rows.length,
      usedRowsCount: n,
      excludedRowsCount: rows.length - n,
      excludedReasons,
      usedRowIndices: pairedData.map(p => p.idx),
      originalExcelRowNumbers: pairedData.map(p => p.excelRow),
      hypotheses: {
        nullHypothesis: `متوسط الفروق بين [${colBefore}] و[${colAfter}] يساوي صفراً (لا يوجد تغير).`,
        altHypothesis: `متوسط الفروق يختلف معنوياً عن الصفر.`
      },
      assumptions,
      canExecuteNormally: false,
      statistics: {
        primaryStatName: 'إحصائية t للعينات المزدوجة',
        primaryStatValue: 0,
        pValue: 1.0,
        isSignificant: false
      },
      explanationAr: 'لا تتوفر أزواج قياسات مكتملة كافية لإجراء المقارنة قبل وبعد.',
      pairedMetrics: {
        meanBefore: 0, meanAfter: 0, meanDifference: 0, stdDevDifference: 0,
        tStatistic: 0, df: 1, tPValue: 1, wilcoxonW: 0, wilcoxonPValue: 1, cohensDz: 0
      }
    };
  }

  const meanBefore = pairedData.reduce((acc, p) => acc + p.before, 0) / n;
  const meanAfter = pairedData.reduce((acc, p) => acc + p.after, 0) / n;
  const diffs = pairedData.map(p => p.diff);
  const meanDiff = diffs.reduce((acc, d) => acc + d, 0) / n;

  let sumSqDiff = 0;
  for (const d of diffs) {
    sumSqDiff += Math.pow(d - meanDiff, 2);
  }
  const sdDiff = Math.sqrt(sumSqDiff / (n - 1));
  const seDiff = sdDiff / Math.sqrt(n);
  const df = n - 1;

  let tStat = 0;
  let tP = 1.0;
  if (seDiff > 1e-12) {
    tStat = meanDiff / seDiff;
    tP = studentTPValue(tStat, df);
  }

  const cohensDz = sdDiff > 0 ? meanDiff / sdDiff : 0;
  const tCrit = studentTCritical(alpha, df);
  const ciLower = meanDiff - tCrit * seDiff;
  const ciUpper = meanDiff + tCrit * seDiff;

  // Wilcoxon Signed-Rank Test
  // Exclude zero differences
  const nonZeroDiffs = diffs.filter(d => Math.abs(d) > 1e-10);
  const nNonZero = nonZeroDiffs.length;
  let wilcoxonW = 0;
  let wilcoxonP = 1.0;

  if (nNonZero >= 1) {
    const absRanks = getFractionalRanks(nonZeroDiffs.map(Math.abs));
    let wPlus = 0;
    let wMinus = 0;
    for (let i = 0; i < nNonZero; i++) {
      if (nonZeroDiffs[i] > 0) wPlus += absRanks[i];
      else wMinus += absRanks[i];
    }
    wilcoxonW = Math.min(wPlus, wMinus);

    if (nNonZero >= 5) {
      const meanW = (nNonZero * (nNonZero + 1)) / 4;
      const tieTerm = computeTieCorrectionTerm(nonZeroDiffs.map(Math.abs));
      const varW = (nNonZero * (nNonZero + 1) * (2 * nNonZero + 1) - tieTerm) / 24;
      const sdW = Math.sqrt(Math.max(1e-10, varW));
      const zW = (Math.abs(wilcoxonW - meanW) - 0.5) / sdW;
      wilcoxonP = Math.min(1, Math.max(0, 2 * (1 - normalCdf(zW))));
    } else {
      wilcoxonP = tP; // Small sample fallback
    }
  }

  const isSignificant = tP < alpha;
  const currSuffix = currency ? ` ${currency}` : '';

  let explanationAr = '';
  if (isSignificant) {
    explanationAr = `يوجد تغير ذو دلالة إحصائية بين القياسين المزدوجين [${colBefore}] و[${colAfter}]؛ حيث تغير المتوسط من ${meanBefore.toFixed(2)}${currSuffix} إلى ${meanAfter.toFixed(2)}${currSuffix} بمتوسط فرق قدره ${meanDiff.toFixed(2)}${currSuffix} (t = ${tStat.toFixed(3)}، df = ${df}، p = ${tP < 0.001 ? '< 0.001' : tP.toFixed(4)} < ${alpha}). حجم الأثر المزدوج (Cohen's d_z = ${cohensDz.toFixed(3)}). واختبار ويلكوكسون يعطي W = ${wilcoxonW.toFixed(1)}، p = ${wilcoxonP.toFixed(4)}. نرفض الفرضية الصفرية لثبوت وجود أثر حقيقي بين القياسين.`;
  } else {
    explanationAr = `الأدلة غير كافية لرفض الفرضية الصفرية عند مستوى دلالة ${(alpha * 100)}% (p = ${tP.toFixed(4)} >= ${alpha}). متوسط الفرق بين القياسين هو ${meanDiff.toFixed(2)}${currSuffix} (قبل: ${meanBefore.toFixed(2)}، بعد: ${meanAfter.toFixed(2)}). لا توجد أدلة إحصائية كافية تثبت أن هذا التغير ذو دلالة معنوية.`;
  }

  return {
    testId: 'paired_samples',
    testNameAr: 'اختبار العينات المزدوجة قبل وبعد (Paired t & Wilcoxon Signed-Rank)',
    testNameEn: 'Paired Samples t-test and Wilcoxon Signed-Rank Test',
    sheetName,
    columnsUsed: [colBefore, colAfter],
    currency,
    alpha,
    sampleSizes: { 'أزواج صالحة ومطابقة': n },
    totalRowsMatchingFilter: rows.length,
    usedRowsCount: n,
    excludedRowsCount: rows.length - n,
    excludedReasons,
    usedRowIndices: pairedData.map(p => p.idx),
    originalExcelRowNumbers: pairedData.map(p => p.excelRow),
    hypotheses: {
      nullHypothesis: `متوسط الفرق بين القياسين [${colBefore}] و[${colAfter}] يساوي 0.`,
      altHypothesis: `متوسط الفرق بين القياسين يختلف معنوياً عن الصفر.`
    },
    assumptions,
    canExecuteNormally: true,
    statistics: {
      primaryStatName: 'إحصائية t المزدوجة',
      primaryStatValue: parseFloat(tStat.toFixed(4)),
      secondaryStatName: 'إحصائية ويلكوكسون (W)',
      secondaryStatValue: parseFloat(wilcoxonW.toFixed(2)),
      degreesOfFreedom: df,
      pValue: parseFloat(tP.toFixed(4)),
      isSignificant,
      effectSize: {
        name: "حجم أثر الفروق المزدوجة (Cohen's dz)",
        value: parseFloat(cohensDz.toFixed(3)),
        interpretation: Math.abs(cohensDz) > 0.8 ? 'تغير كبير' : Math.abs(cohensDz) > 0.5 ? 'تغير متوسط' : 'تغير طفيف'
      },
      confidenceInterval: {
        level: (1 - alpha) * 100,
        lower: parseFloat(ciLower.toFixed(2)),
        upper: parseFloat(ciUpper.toFixed(2)),
        parameterName: 'فترة ثقة متوسط التغير'
      }
    },
    explanationAr,
    pairedMetrics: {
      meanBefore: parseFloat(meanBefore.toFixed(2)),
      meanAfter: parseFloat(meanAfter.toFixed(2)),
      meanDifference: parseFloat(meanDiff.toFixed(2)),
      stdDevDifference: parseFloat(sdDiff.toFixed(2)),
      tStatistic: parseFloat(tStat.toFixed(4)),
      df,
      tPValue: parseFloat(tP.toFixed(4)),
      wilcoxonW: parseFloat(wilcoxonW.toFixed(2)),
      wilcoxonPValue: parseFloat(wilcoxonP.toFixed(4)),
      cohensDz: parseFloat(cohensDz.toFixed(3))
    },
    visualData: {
      type: 'paired_comparison',
      meanBefore,
      meanAfter,
      pairs: pairedData.map(p => ({ before: p.before, after: p.after, excelRow: p.excelRow }))
    }
  };
}

// =========================================================================
// 5. THREE OR MORE INDEPENDENT GROUPS (One-way ANOVA & Kruskal-Wallis)
// =========================================================================

export interface AnovaResult extends StatisticalTestResult {
  anovaMetrics: {
    groupStats: Array<{ group: string; count: number; mean: number; stdDev: number }>;
    ssBetween: number;
    ssWithin: number;
    ssTotal: number;
    dfBetween: number;
    dfWithin: number;
    msBetween: number;
    msWithin: number;
    fStatistic: number;
    fPValue: number;
    etaSquared: number;
    kruskalH: number;
    kruskalPValue: number;
  };
}

export function runAnovaAndKruskalTest(
  rows: Array<Record<string, any>>,
  numericCol: string,
  groupCol: string,
  currency?: string,
  alpha: number = 0.05,
  sheetName: string = 'الورقة'
): AnovaResult {
  const groupsMap = new Map<string, Array<{ val: number; idx: number; excelRow: number }>>();
  const excludedReasons: Record<string, number> = {
    'مجموعة غير محددة أو فارغة': 0,
    'قيمة رقمية مفقودة أو غير صالحة': 0
  };

  rows.forEach((r, idx) => {
    const rawGrp = r[groupCol];
    if (rawGrp === null || rawGrp === undefined || String(rawGrp).trim() === '') {
      excludedReasons['مجموعة غير محددة أو فارغة']++;
      return;
    }
    const grpName = String(rawGrp).trim();
    const rawNum = r[numericCol];
    if (rawNum === null || rawNum === undefined || String(rawNum).trim() === '') {
      excludedReasons['قيمة رقمية مفقودة أو غير صالحة']++;
      return;
    }
    const pNum = parseStatisticalNumber(rawNum);
    if (!pNum.isValid) {
      excludedReasons['قيمة رقمية مفقودة أو غير صالحة']++;
      return;
    }

    if (currency && currency !== 'all') {
      const rowCurr = extractRowCurrency(r, numericCol, pNum.currency);
      if (rowCurr !== '(عملة غير محددة)' && rowCurr !== currency) {
        const reasonKey = `عملة مستبعدة (غير ${currency})`;
        excludedReasons[reasonKey] = (excludedReasons[reasonKey] || 0) + 1;
        return;
      }
    }

    if (!groupsMap.has(grpName)) groupsMap.set(grpName, []);
    groupsMap.get(grpName)!.push({ val: pNum.num, idx, excelRow: r.__rowIndex || idx + 1 });
  });

  const k = groupsMap.size;
  const groupNames = Array.from(groupsMap.keys());
  let totalN = 0;
  const sampleSizes: Record<string, number> = {};
  const allUsedIndices: number[] = [];
  const allExcelRows: number[] = [];

  groupsMap.forEach((items, gName) => {
    sampleSizes[gName] = items.length;
    totalN += items.length;
    items.forEach(it => {
      allUsedIndices.push(it.idx);
      allExcelRows.push(it.excelRow);
    });
  });

  const assumptions: PreconditionCheck[] = [
    {
      condition: 'عدد المجموعات (k >= 3)',
      satisfied: k >= 3,
      message: k >= 3 ? `يتوفر ${k} مجموعات للمقارنة المتعددة.` : `يتوفر ${k} مجموعات فقط. يُشترط 3 مجموعات على الأقل لتحليل التباين ANOVA.`,
      recommendation: k < 3 ? 'استخدم اختبار ويلش للمقارنة الثنائية إذا كان لديك مجموعتان فقط.' : undefined
    },
    {
      condition: 'حجم كل مجموعة (n_j >= 2)',
      satisfied: groupNames.every(g => (sampleSizes[g] || 0) >= 2),
      message: groupNames.every(g => (sampleSizes[g] || 0) >= 2)
        ? 'تحتوي جميع المجموعات على قيمتين على الأقل.'
        : 'تحتوي بعض المجموعات على أقل من قيمتين.',
      recommendation: 'يُفضل توفر عينتين على الأقل في كل تصنيف لحساب التباين الداخلي.'
    }
  ];

  if (k < 2 || totalN <= k) {
    return {
      testId: 'anova_kruskal',
      testNameAr: 'تحليل التباين أحادي الاتجاه وكروسكال-واليس (One-way ANOVA & Kruskal-Wallis)',
      testNameEn: 'One-way ANOVA and Kruskal-Wallis Test',
      sheetName,
      columnsUsed: [numericCol, groupCol],
      currency,
      alpha,
      sampleSizes,
      totalRowsMatchingFilter: rows.length,
      usedRowsCount: totalN,
      excludedRowsCount: rows.length - totalN,
      excludedReasons,
      usedRowIndices: allUsedIndices,
      originalExcelRowNumbers: allExcelRows,
      hypotheses: {
        nullHypothesis: `متوسطات جميع المجموعات متساوية في المجتمع (μ1 = μ2 = ... = μk).`,
        altHypothesis: `يوجد على الأقل متوسط مجموعة واحدة يختلف عن باقي المجموعات.`
      },
      assumptions,
      canExecuteNormally: false,
      statistics: {
        primaryStatName: 'إحصائية فيشر (F)',
        primaryStatValue: 0,
        pValue: 1.0,
        isSignificant: false
      },
      explanationAr: 'لا تتوفر مجموعات كافية لإجراء تحليل التباين (ANOVA).',
      anovaMetrics: {
        groupStats: [], ssBetween: 0, ssWithin: 0, ssTotal: 0,
        dfBetween: 1, dfWithin: 1, msBetween: 0, msWithin: 0,
        fStatistic: 0, fPValue: 1, etaSquared: 0, kruskalH: 0, kruskalPValue: 1
      }
    };
  }

  // Grand Mean & Group Means
  let grandSum = 0;
  const groupStats: Array<{ group: string; count: number; mean: number; stdDev: number }> = [];

  groupsMap.forEach((items, gName) => {
    const sum = items.reduce((a, b) => a + b.val, 0);
    const mean = sum / items.length;
    let sqDiff = 0;
    for (const it of items) sqDiff += Math.pow(it.val - mean, 2);
    const stdDev = items.length > 1 ? Math.sqrt(sqDiff / (items.length - 1)) : 0;
    grandSum += sum;
    groupStats.push({
      group: gName,
      count: items.length,
      mean,
      stdDev
    });
  });

  const grandMean = grandSum / totalN;

  // Sums of Squares
  let ssBetween = 0;
  let ssWithin = 0;

  groupsMap.forEach((items, gName) => {
    const mean = groupStats.find(g => g.group === gName)!.mean;
    ssBetween += items.length * Math.pow(mean - grandMean, 2);
    for (const it of items) {
      ssWithin += Math.pow(it.val - mean, 2);
    }
  });

  const ssTotal = ssBetween + ssWithin;
  const dfBetween = k - 1;
  const dfWithin = totalN - k;
  const msBetween = dfBetween > 0 ? ssBetween / dfBetween : 0;
  const msWithin = dfWithin > 0 ? ssWithin / dfWithin : 0;

  const fStat = msWithin > 1e-12 ? msBetween / msWithin : 0;
  const fP = fDistPValue(fStat, dfBetween, dfWithin);
  const etaSquared = ssTotal > 0 ? ssBetween / ssTotal : 0;

  // Kruskal-Wallis Test
  const allItems: Array<{ val: number; grp: string }> = [];
  groupsMap.forEach((items, gName) => {
    items.forEach(it => allItems.push({ val: it.val, grp: gName }));
  });
  const allRanks = getFractionalRanks(allItems.map(a => a.val));
  const rankSumsByGroup: Record<string, number> = {};
  for (let i = 0; i < allItems.length; i++) {
    const g = allItems[i].grp;
    rankSumsByGroup[g] = (rankSumsByGroup[g] || 0) + allRanks[i];
  }

  let hSum = 0;
  for (const gName of groupNames) {
    const rSum = rankSumsByGroup[gName] || 0;
    const nG = groupsMap.get(gName)!.length;
    hSum += Math.pow(rSum, 2) / nG;
  }
  let kruskalH = (12 / (totalN * (totalN + 1))) * hSum - 3 * (totalN + 1);

  // Tie correction for Kruskal-Wallis
  const tieTerm = computeTieCorrectionTerm(allItems.map(a => a.val));
  const denomH = 1 - tieTerm / (Math.pow(totalN, 3) - totalN);
  if (denomH > 0) kruskalH /= denomH;
  const kruskalP = chiSquarePValue(Math.max(0, kruskalH), dfBetween);

  const isSignificant = fP < alpha;
  const currSuffix = currency ? ` ${currency}` : '';

  let explanationAr = '';
  if (isSignificant) {
    explanationAr = `يوجد تباين ذو دلالة إحصائية بين متوسطات المجموعات (${groupNames.join('، ')}) وفق تحليل التباين أحادي الاتجاه (F(${dfBetween}, ${dfWithin}) = ${fStat.toFixed(3)}، p = ${fP < 0.001 ? '< 0.001' : fP.toFixed(4)} < ${alpha}). حجم الأثر (Eta² = ${etaSquared.toFixed(3)}) يوضح أن التصنيف يفسر ${(etaSquared * 100).toFixed(1)}% من التباين في عمود [${numericCol}]. واختبار كروسكال-واليس اللابارامتري يعطي H = ${kruskalH.toFixed(2)}، p = ${kruskalP.toFixed(4)}. نرفض الفرضية الصفرية لثبوت تمايز أحد المتوسطات على الأقل.`;
  } else {
    explanationAr = `الأدلة غير كافية لرفض الفرضية الصفرية عند مستوى دلالة ${(alpha * 100)}% (p = ${fP.toFixed(4)} >= ${alpha}). قيمة إحصائية فيشر F = ${fStat.toFixed(3)}. لا توجد أدلة إحصائية كافية تثبت وجود فروق جوهرية بين متوسطات هذه المجموعات في عمود [${numericCol}].`;
  }

  return {
    testId: 'anova_kruskal',
    testNameAr: 'تحليل التباين أحادي الاتجاه وكروسكال-واليس (ANOVA & Kruskal-Wallis)',
    testNameEn: 'One-way ANOVA and Kruskal-Wallis Test',
    sheetName,
    columnsUsed: [numericCol, groupCol],
    currency,
    alpha,
    sampleSizes,
    totalRowsMatchingFilter: rows.length,
    usedRowsCount: totalN,
    excludedRowsCount: rows.length - totalN,
    excludedReasons,
    usedRowIndices: allUsedIndices,
    originalExcelRowNumbers: allExcelRows,
    hypotheses: {
      nullHypothesis: `متوسطات المجموعات متكافئة إحصائياً (μ1 = μ2 = ... = μk).`,
      altHypothesis: `يوجد على الأقل متوسط مجموعة واحدة يختلف عن باقي المجموعات.`
    },
    assumptions,
    canExecuteNormally: true,
    statistics: {
      primaryStatName: 'إحصائية فيشر (F)',
      primaryStatValue: parseFloat(fStat.toFixed(4)),
      secondaryStatName: 'إحصائية كروسكال-واليس (H)',
      secondaryStatValue: parseFloat(kruskalH.toFixed(2)),
      degreesOfFreedom: `${dfBetween}, ${dfWithin}`,
      pValue: parseFloat(fP.toFixed(4)),
      isSignificant,
      effectSize: {
        name: 'مربع إيتا (η² - Eta-squared)',
        value: parseFloat(etaSquared.toFixed(3)),
        interpretation: etaSquared > 0.14 ? 'أثر كبير' : etaSquared > 0.06 ? 'أثر متوسط' : 'أثر صغير'
      }
    },
    explanationAr,
    anovaMetrics: {
      groupStats: groupStats.map(g => ({
        group: g.group,
        count: g.count,
        mean: parseFloat(g.mean.toFixed(2)),
        stdDev: parseFloat(g.stdDev.toFixed(2))
      })),
      ssBetween: parseFloat(ssBetween.toFixed(2)),
      ssWithin: parseFloat(ssWithin.toFixed(2)),
      ssTotal: parseFloat(ssTotal.toFixed(2)),
      dfBetween,
      dfWithin,
      msBetween: parseFloat(msBetween.toFixed(2)),
      msWithin: parseFloat(msWithin.toFixed(2)),
      fStatistic: parseFloat(fStat.toFixed(4)),
      fPValue: parseFloat(fP.toFixed(4)),
      etaSquared: parseFloat(etaSquared.toFixed(3)),
      kruskalH: parseFloat(kruskalH.toFixed(2)),
      kruskalPValue: parseFloat(kruskalP.toFixed(4))
    },
    visualData: {
      type: 'anova_bars',
      groups: groupStats
    }
  };
}

// =========================================================================
// 6. TWO CATEGORICAL COLUMNS (Contingency Table, Chi-Square, Fisher's Exact)
// =========================================================================

export interface ContingencyResult extends StatisticalTestResult {
  contingencyMetrics: {
    rowCategories: string[];
    colCategories: string[];
    observedMatrix: number[][];
    expectedMatrix: number[][];
    rowTotals: number[];
    colTotals: number[];
    grandTotal: number;
    chiSquare: number;
    df: number;
    chiPValue: number;
    cramersV: number;
    fisherExactPValue?: number;
    oddsRatio?: number;
    cellsBelow5Expected: number;
    pctCellsBelow5Expected: number;
  };
}

export function runContingencyTest(
  rows: Array<Record<string, any>>,
  colRow: string,
  colCol: string,
  alpha: number = 0.05,
  sheetName: string = 'الورقة'
): ContingencyResult {
  const validPairs: Array<{ rVal: string; cVal: string; idx: number; excelRow: number }> = [];
  const excludedReasons: Record<string, number> = {
    'بيانات فئوية مفقودة في أحد العمودين': 0
  };

  rows.forEach((r, idx) => {
    const vr = r[colRow];
    const vc = r[colCol];
    if (vr === null || vr === undefined || String(vr).trim() === '' ||
        vc === null || vc === undefined || String(vc).trim() === '') {
      excludedReasons['بيانات فئوية مفقودة في أحد العمودين']++;
      return;
    }
    validPairs.push({
      rVal: String(vr).trim(),
      cVal: String(vc).trim(),
      idx,
      excelRow: r.__rowIndex || idx + 1
    });
  });

  const totalN = validPairs.length;
  const rowCats = Array.from(new Set(validPairs.map(p => p.rVal))).sort();
  const colCats = Array.from(new Set(validPairs.map(p => p.cVal))).sort();
  const numRows = rowCats.length;
  const numCols = colCats.length;

  const assumptions: PreconditionCheck[] = [
    {
      condition: 'حجم الجدول التقاطعي وتكرار العينة (N >= 10)',
      satisfied: totalN >= 10 && numRows >= 2 && numCols >= 2,
      message: totalN >= 10 && numRows >= 2 && numCols >= 2
        ? `حجم العينة (${totalN}) وأبعاد الجدول (${numRows}×${numCols}) كافية للتحليل التقاطعي.`
        : `أبعاد الجدول أو حجم العينة غير كافٍ لاختبار كاي تربيع (${numRows} صفوف × ${numCols} أعمدة، الإجمالي: ${totalN}).`,
      recommendation: (numRows < 2 || numCols < 2) ? 'اختر عمودين يحتوي كل منهما على تصنيفين مختلفين على الأقل.' : undefined
    }
  ];

  if (numRows < 2 || numCols < 2 || totalN === 0) {
    return {
      testId: 'contingency_table',
      testNameAr: 'الجدول التقاطعي واختبار كاي تربيع (Chi-Square & Fisher)',
      testNameEn: "Contingency Table and Chi-Square Test of Independence",
      sheetName,
      columnsUsed: [colRow, colCol],
      alpha,
      sampleSizes: { [colRow]: numRows, [colCol]: numCols },
      totalRowsMatchingFilter: rows.length,
      usedRowsCount: totalN,
      excludedRowsCount: rows.length - totalN,
      excludedReasons,
      usedRowIndices: validPairs.map(p => p.idx),
      originalExcelRowNumbers: validPairs.map(p => p.excelRow),
      hypotheses: {
        nullHypothesis: `المتغيران [${colRow}] و[${colCol}] مستقلان عن بعضهما تماماً.`,
        altHypothesis: `توجد علاقة ارتباط واقتران غير مستقلة بين المتغيرين.`
      },
      assumptions,
      canExecuteNormally: false,
      statistics: {
        primaryStatName: 'إحصائية كاي تربيع (χ²)',
        primaryStatValue: 0,
        pValue: 1.0,
        isSignificant: false
      },
      explanationAr: 'لا تتوفر فئات كافية لتكوين جدول تقاطعي (مطلوب فئتان على الأقل في كل عمود).',
      contingencyMetrics: {
        rowCategories: rowCats, colCategories: colCats,
        observedMatrix: [], expectedMatrix: [], rowTotals: [], colTotals: [],
        grandTotal: totalN, chiSquare: 0, df: 1, chiPValue: 1, cramersV: 0,
        cellsBelow5Expected: 0, pctCellsBelow5Expected: 0
      }
    };
  }

  // Build Observed Matrix
  const observed: number[][] = Array(numRows).fill(0).map(() => Array(numCols).fill(0));
  for (const p of validPairs) {
    const rIdx = rowCats.indexOf(p.rVal);
    const cIdx = colCats.indexOf(p.cVal);
    if (rIdx >= 0 && cIdx >= 0) {
      observed[rIdx][cIdx]++;
    }
  }

  // Row and Column Totals
  const rowTotals = observed.map(row => row.reduce((a, b) => a + b, 0));
  const colTotals: number[] = Array(numCols).fill(0);
  for (let c = 0; c < numCols; c++) {
    for (let r = 0; r < numRows; r++) {
      colTotals[c] += observed[r][c];
    }
  }

  // Expected Matrix & Chi-Square Calculation
  const expected: number[][] = Array(numRows).fill(0).map(() => Array(numCols).fill(0));
  let chi2 = 0;
  let cellsBelow5 = 0;

  for (let r = 0; r < numRows; r++) {
    for (let c = 0; c < numCols; c++) {
      const expVal = (rowTotals[r] * colTotals[c]) / totalN;
      expected[r][c] = expVal;
      if (expVal < 5) cellsBelow5++;
      if (expVal > 0) {
        chi2 += Math.pow(observed[r][c] - expVal, 2) / expVal;
      }
    }
  }

  const df = (numRows - 1) * (numCols - 1);
  const chiP = chiSquarePValue(chi2, df);
  const minDim = Math.min(numRows - 1, numCols - 1);
  const cramersV = minDim > 0 && totalN > 0 ? Math.sqrt(chi2 / (totalN * minDim)) : 0;
  const pctCellsBelow5 = (cellsBelow5 / (numRows * numCols)) * 100;

  assumptions.push({
    condition: 'التكرارات المتوقعة (Cochran: أقل من 20% من الخلايا بها توقع < 5)',
    satisfied: pctCellsBelow5 <= 20,
    message: pctCellsBelow5 <= 20
      ? `تحقق شرط كوشران؛ نسبة الخلايا المتوقعة أقل من 5 هي ${pctCellsBelow5.toFixed(1)}%.`
      : `تحذير شرط كوشران: ${pctCellsBelow5.toFixed(1)}% من الخلايا المتوقعة أقل من 5. يُنصح بالاعتماد على اختبار فيشر الدقيق في الجداول الثنائية.`,
    recommendation: pctCellsBelow5 > 20 && numRows === 2 && numCols === 2 ? 'اختبار فيشر الدقيق تم حسابه تلقائياً أدناه كبديل موثوق.' : undefined
  });

  // Fisher's Exact Test for 2x2 Table
  let fisherP: number | undefined;
  let oddsRatio: number | undefined;

  if (numRows === 2 && numCols === 2) {
    const a = observed[0][0];
    const b = observed[0][1];
    const c = observed[1][0];
    const d = observed[1][1];
    fisherP = calculateFisherExact2x2(a, b, c, d);
    if (b > 0 && c > 0) {
      oddsRatio = (a * d) / (b * c);
    }
  }

  const effectiveP = (numRows === 2 && numCols === 2 && pctCellsBelow5 > 20 && fisherP !== undefined)
    ? fisherP
    : chiP;

  const isSignificant = effectiveP < alpha;

  let explanationAr = '';
  if (isSignificant) {
    explanationAr = `توجد علاقة اقتران ذات دلالة إحصائية بين [${colRow}] و[${colCol}] وفق اختبار كاي تربيع للاستقلالية (χ² = ${chi2.toFixed(3)}، df = ${df}، p = ${effectiveP < 0.001 ? '< 0.001' : effectiveP.toFixed(4)} < ${alpha}). معامل كرامر V = ${cramersV.toFixed(3)}، مما يشير إلى اقتران ${cramersV > 0.5 ? 'قوي' : cramersV > 0.3 ? 'متوسط' : 'ضعيف'}. نرفض الفرضية الصفرية لثبوت أن التوزيعات غير مستقلة.`;
    if (fisherP !== undefined) {
      explanationAr += ` الدلالة المحسوبة باختبار فيشر الدقيق هي p = ${fisherP.toFixed(4)}.`;
    }
  } else {
    explanationAr = `الأدلة غير كافية لرفض الفرضية الصفرية عند مستوى دلالة ${(alpha * 100)}% (p = ${effectiveP.toFixed(4)} >= ${alpha}). قيمة كاي تربيع χ² = ${chi2.toFixed(3)}. لا يوجد دليل إحصائي كافٍ على ارتباط تصنيفات [${colRow}] بتصنيفات [${colCol}].`;
  }

  return {
    testId: 'contingency_table',
    testNameAr: 'الجدول التقاطعي واختبار كاي تربيع للاستقلالية (Chi-Square & Fisher)',
    testNameEn: 'Contingency Table and Chi-Square Test of Independence',
    sheetName,
    columnsUsed: [colRow, colCol],
    alpha,
    sampleSizes: { 'إجمالي المشاهدات المتطابقة': totalN },
    totalRowsMatchingFilter: rows.length,
    usedRowsCount: totalN,
    excludedRowsCount: rows.length - totalN,
    excludedReasons,
    usedRowIndices: validPairs.map(p => p.idx),
    originalExcelRowNumbers: validPairs.map(p => p.excelRow),
    hypotheses: {
      nullHypothesis: `المتغيران [${colRow}] و[${colCol}] مستقلان تماماً في المجتمع الإحصائي.`,
      altHypothesis: `المتغيران مرتبطان ومقترنان بشكل غير مستقل في المجتمع الإحصائي.`
    },
    assumptions,
    canExecuteNormally: true,
    statistics: {
      primaryStatName: 'إحصائية كاي تربيع (χ²)',
      primaryStatValue: parseFloat(chi2.toFixed(4)),
      secondaryStatName: fisherP !== undefined ? 'دلالة فيشر الدقيقة (Fisher p)' : 'معامل كرامر (Cramer V)',
      secondaryStatValue: fisherP !== undefined ? parseFloat(fisherP.toFixed(4)) : parseFloat(cramersV.toFixed(4)),
      degreesOfFreedom: df,
      pValue: parseFloat(effectiveP.toFixed(4)),
      isSignificant,
      effectSize: {
        name: "معامل اقتران كرامر (Cramér's V)",
        value: parseFloat(cramersV.toFixed(3)),
        interpretation: cramersV > 0.5 ? 'اقتران قوي' : cramersV > 0.3 ? 'اقتران متوسط' : 'اقتران ضعيف'
      }
    },
    explanationAr,
    contingencyMetrics: {
      rowCategories: rowCats,
      colCategories: colCats,
      observedMatrix: observed,
      expectedMatrix: expected.map(r => r.map(v => parseFloat(v.toFixed(2)))),
      rowTotals,
      colTotals,
      grandTotal: totalN,
      chiSquare: parseFloat(chi2.toFixed(4)),
      df,
      chiPValue: parseFloat(chiP.toFixed(4)),
      cramersV: parseFloat(cramersV.toFixed(3)),
      fisherExactPValue: fisherP !== undefined ? parseFloat(fisherP.toFixed(4)) : undefined,
      oddsRatio: oddsRatio !== undefined ? parseFloat(oddsRatio.toFixed(3)) : undefined,
      cellsBelow5Expected: cellsBelow5,
      pctCellsBelow5Expected: parseFloat(pctCellsBelow5.toFixed(1))
    },
    visualData: {
      type: 'contingency_table',
      rowCats,
      colCats,
      observed,
      expected: expected.map(r => r.map(v => parseFloat(v.toFixed(2))))
    }
  };
}

// =========================================================================
// HELPER NUMERICAL UTILITIES
// =========================================================================

/**
 * Fractional ranks (handling ties with average rank)
 */
export function getFractionalRanks(arr: number[]): number[] {
  const n = arr.length;
  const indexed = arr.map((val, idx) => ({ val, idx }));
  indexed.sort((a, b) => a.val - b.val);

  const ranks = new Array(n);
  let i = 0;
  while (i < n) {
    let j = i;
    while (j < n - 1 && Math.abs(indexed[j + 1].val - indexed[j].val) < 1e-12) {
      j++;
    }
    const avgRank = (i + 1 + j + 1) / 2;
    for (let k = i; k <= j; k++) {
      ranks[indexed[k].idx] = avgRank;
    }
    i = j + 1;
  }
  return ranks;
}

/**
 * Compute tie correction term: sum(t_k^3 - t_k)
 */
function computeTieCorrectionTerm(arr: number[]): number {
  const counts = new Map<number, number>();
  for (const v of arr) {
    counts.set(v, (counts.get(v) || 0) + 1);
  }
  let sum = 0;
  counts.forEach(cnt => {
    if (cnt > 1) {
      sum += Math.pow(cnt, 3) - cnt;
    }
  });
  return sum;
}

/**
 * Two-tailed Fisher's exact test for 2x2 contingency table
 */
export function calculateFisherExact2x2(a: number, b: number, c: number, d: number): number {
  const n = a + b + c + d;
  const r1 = a + b;
  const r2 = c + d;
  const c1 = a + c;
  const c2 = b + d;

  const logHypergeometric = (x: number): number => {
    return (
      logFactorial(r1) +
      logFactorial(r2) +
      logFactorial(c1) +
      logFactorial(c2) -
      logFactorial(x) -
      logFactorial(r1 - x) -
      logFactorial(c1 - x) -
      logFactorial(r2 - c1 + x) -
      logFactorial(n)
    );
  };

  const observedLogP = logHypergeometric(a);
  const minX = Math.max(0, c1 - r2);
  const maxX = Math.min(r1, c1);

  let pTotal = 0;
  for (let x = minX; x <= maxX; x++) {
    const logP = logHypergeometric(x);
    // Two-tailed: include tables with probability <= observed probability (with small epsilon tolerance)
    if (logP <= observedLogP + 1e-9) {
      pTotal += Math.exp(logP);
    }
  }

  return Math.min(1.0, Math.max(0.0, pTotal));
}
