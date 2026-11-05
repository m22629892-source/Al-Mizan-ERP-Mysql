import React, { useState, useEffect, useMemo } from 'react';
import {
  Activity,
  X,
  Play,
  RotateCcw,
  CheckCircle2,
  AlertTriangle,
  AlertOctagon,
  Download,
  Eye,
  Info,
  HelpCircle,
  TrendingUp,
  BarChart2,
  GitCommit,
  Split,
  Table,
  Sparkles,
  ArrowRight,
  ShieldCheck,
  RefreshCw,
  Coins,
  Layers
} from 'lucide-react';
import { apiClient } from '../services/apiClient';
import {
  SheetAnalysis,
  ColumnMeta,
  StatisticalTestType,
  StatisticalTestResult,
  PreconditionCheck
} from '../types';

interface StatisticalTestsModalProps {
  isOpen: boolean;
  onClose: () => void;
  sessionId: string | null;
  activeSheetName: string;
  sheetAnalysis: SheetAnalysis | null;
  filters: Array<{ column: string; operator: string; value: string }>;
  filteredRowCount: number;
  previewRows: any[];
  onOpenMatchingRows: (title: string, indices: number[]) => void;
  onExportTest: (testResult: StatisticalTestResult) => void;
}

export const StatisticalTestsModal: React.FC<StatisticalTestsModalProps> = ({
  isOpen,
  onClose,
  sessionId,
  activeSheetName,
  sheetAnalysis,
  filters,
  filteredRowCount,
  previewRows,
  onOpenMatchingRows,
  onExportTest
}) => {
  // Test selection
  const [testType, setTestType] = useState<StatisticalTestType>('descriptive');

  // Columns & Parameters
  const [col1, setCol1] = useState<string>('');
  const [col2, setCol2] = useState<string>('');
  const [keyCol, setKeyCol] = useState<string>('');
  const [group1Val, setGroup1Val] = useState<string>('');
  const [group2Val, setGroup2Val] = useState<string>('');
  const [alpha, setAlpha] = useState<number>(0.05);
  const [selectedCurrency, setSelectedCurrency] = useState<string>('all');

  // Execution State
  const [running, setRunning] = useState<boolean>(false);
  const [testResult, setTestResult] = useState<StatisticalTestResult | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  // Group options extracted from sample data
  const numColumns = useMemo(() => {
    return (sheetAnalysis?.columns || []).filter(c => c.inferredType === 'number' || c.userType === 'number');
  }, [sheetAnalysis]);

  const catColumns = useMemo(() => {
    return (sheetAnalysis?.columns || []).filter(c => c.inferredType === 'category' || c.inferredType === 'text' || c.userType === 'category' || c.userType === 'text');
  }, [sheetAnalysis]);

  const allColumns = sheetAnalysis?.columns || [];
  const currenciesDetected = sheetAnalysis?.currenciesDetected || [];

  // Initialize sensible column defaults when modal opens or testType changes
  useEffect(() => {
    if (!sheetAnalysis) return;

    if (testType === 'descriptive') {
      const defaultAmount = sheetAnalysis.columnMapping?.amountColumn || numColumns[0]?.name || allColumns[0]?.name || '';
      setCol1(defaultAmount);
    } else if (testType === 'correlation') {
      const c1 = numColumns[0]?.name || allColumns[0]?.name || '';
      const c2 = numColumns[1]?.name || allColumns[1]?.name || '';
      setCol1(c1);
      setCol2(c2);
    } else if (testType === 'two_independent_groups') {
      const defaultNum = sheetAnalysis.columnMapping?.amountColumn || numColumns[0]?.name || allColumns[0]?.name || '';
      const defaultGrp = catColumns.find(c => /فرع|نوع|حالة|مجموعة|branch|type|group/i.test(c.name))?.name || catColumns[0]?.name || '';
      setCol1(defaultNum);
      setCol2(defaultGrp);
    } else if (testType === 'paired_samples') {
      const cBefore = numColumns.find(c => /قبل|before|سابق|prior/i.test(c.name))?.name || numColumns[0]?.name || '';
      const cAfter = numColumns.find(c => /بعد|after|لاحق|post/i.test(c.name))?.name || numColumns[1]?.name || '';
      const cKey = sheetAnalysis.columnMapping?.invoiceColumn || allColumns.find(c => /معرف|كود|رقم|id|code/i.test(c.name))?.name || '';
      setCol1(cBefore);
      setCol2(cAfter);
      setKeyCol(cKey);
    } else if (testType === 'anova_kruskal') {
      const defaultNum = sheetAnalysis.columnMapping?.amountColumn || numColumns[0]?.name || allColumns[0]?.name || '';
      const defaultGrp = catColumns.find(c => /فرع|فئة|تصنيف|قسم|صنف|branch|category/i.test(c.name))?.name || catColumns[0]?.name || '';
      setCol1(defaultNum);
      setCol2(defaultGrp);
    } else if (testType === 'contingency_table') {
      const c1 = catColumns[0]?.name || allColumns[0]?.name || '';
      const c2 = catColumns[1]?.name || allColumns[1]?.name || '';
      setCol1(c1);
      setCol2(c2);
    }

    setTestResult(null);
    setErrorMsg(null);
  }, [testType, sheetAnalysis]);

  // Extract distinct group values for two_independent_groups when col2 changes
  const distinctGroupValues = useMemo(() => {
    if (!col2 || !previewRows.length) return [];
    const set = new Set<string>();
    previewRows.forEach(r => {
      const val = r[col2];
      if (val !== null && val !== undefined && String(val).trim()) {
        set.add(String(val).trim());
      }
    });
    return Array.from(set);
  }, [col2, previewRows]);

  useEffect(() => {
    if (testType === 'two_independent_groups' && distinctGroupValues.length >= 2) {
      if (!group1Val || !distinctGroupValues.includes(group1Val)) setGroup1Val(distinctGroupValues[0]);
      if (!group2Val || !distinctGroupValues.includes(group2Val)) setGroup2Val(distinctGroupValues[1]);
    }
  }, [testType, distinctGroupValues]);

  // Preconditions Live Evaluator
  const preconditions: PreconditionCheck[] = useMemo(() => {
    const list: PreconditionCheck[] = [];

    // 1. Sample Size Check
    const minRows = testType === 'contingency_table' ? 10 : testType === 'two_independent_groups' ? 4 : 3;
    list.push({
      condition: `حجم العينة المطابقة للفلاتر (N >= ${minRows})`,
      satisfied: filteredRowCount >= minRows,
      message: filteredRowCount >= minRows
        ? `حجم العينة الحالية (${filteredRowCount} صفاً) يفي بالحد الأدنى المطلوب.`
        : `حجم العينة المفلترة (${filteredRowCount} صفاً) قليل جدًا للحصول على نتائج ذات موثوقية إحصائية.`,
      recommendation: filteredRowCount < minRows ? 'قلل شروط التصفية أو أضف المزيد من السجلات.' : undefined
    });

    // 2. Column Requirements Check
    if (testType === 'correlation') {
      list.push({
        condition: 'اختيار عمودين كميين مختلفين',
        satisfied: !!col1 && !!col2 && col1 !== col2,
        message: col1 && col2 && col1 !== col2
          ? `تم تحديد متغيرين كميين: [${col1}] مقابل [${col2}].`
          : 'يجب اختيار عمودين كميين مستقلين لحساب معامل الارتباط.',
        recommendation: col1 === col2 ? 'اختر عموداً ثانياً مختلفاً عن العمود الأول.' : undefined
      });
    } else if (testType === 'two_independent_groups') {
      list.push({
        condition: 'وجود مجموعتين مستقلتين صالحتين للمقارنة',
        satisfied: !!group1Val && !!group2Val && group1Val !== group2Val,
        message: group1Val && group2Val && group1Val !== group2Val
          ? `المجموعتان المستهدفتان: [${group1Val}] مقابل [${group2Val}].`
          : 'يجب تحديد مجموعتين مستقلتين ومختلفتين في عمود التصنيف.',
        recommendation: 'اختر قيمتين مختلفتين من عمود المجموعة.'
      });
    } else if (testType === 'paired_samples') {
      list.push({
        condition: 'اختيار قياسين مترابطين (قبل وبعد) ومعرف رابط',
        satisfied: !!col1 && !!col2 && col1 !== col2,
        message: col1 && col2 && col1 !== col2
          ? `القياسان المترابطان: قبل [${col1}] وبعد [${col2}].`
          : 'يجب تحديد عمودي القياس قبل وبعد.',
        recommendation: !keyCol ? 'يُستحسن تحديد عمود المعرف لتفادي المطابقة العشوائية بالترتيب.' : undefined
      });
    } else if (testType === 'contingency_table') {
      list.push({
        condition: 'اختيار عمودين فئويين مختلفين',
        satisfied: !!col1 && !!col2 && col1 !== col2,
        message: col1 && col2 && col1 !== col2
          ? `المتغيران التصنيفيان: [${col1}] و [${col2}].`
          : 'يجب اختيار عمودين فئويين لتكوين جدول الاقتران التقاطعي.'
      });
    }

    // 3. Multi-Currency Discipline
    if (currenciesDetected.length > 1 && testType !== 'contingency_table') {
      list.push({
        condition: 'فصل العملات المالية وتفادي الخلط الحسابي',
        satisfied: selectedCurrency !== 'all',
        message: selectedCurrency !== 'all'
          ? `تم قصر الاختبار على عملة [${selectedCurrency}] حصراً، مما يضمن دقة الفروق والوسيط.`
          : `الملف يحتوي على عملات متعددة (${currenciesDetected.join(', ')}). يُنصح باختيار عملة واحدة لتفادي خلط الجنيه بالدولار في الإحصائيات.`,
        recommendation: selectedCurrency === 'all' ? 'اختر إحدى العملات من القائمة أدناه لتطبيق فصل العملات.' : undefined
      });
    }

    return list;
  }, [testType, col1, col2, keyCol, group1Val, group2Val, selectedCurrency, filteredRowCount, currenciesDetected]);

  if (!isOpen) return null;

  const handleRunTest = async () => {
    if (!sessionId) return;
    setRunning(true);
    setErrorMsg(null);
    setTestResult(null);

    try {
      const res = await apiClient.post(`/analytics/sessions/${sessionId}/statistical-test`, {
        testType,
        col1,
        col2,
        keyCol: keyCol || undefined,
        group1Value: group1Val || undefined,
        group2Value: group2Val || undefined,
        currency: selectedCurrency === 'all' ? undefined : selectedCurrency,
        filters,
        alpha
      });

      if (res && res.testResult) {
        setTestResult(res.testResult);
      } else {
        throw new Error('لم يتم استلام نتائج الاختبار الإحصائي.');
      }
    } catch (err: any) {
      setErrorMsg(err.message || 'فشل تشغيل الاختبار الإحصائي.');
    } finally {
      setRunning(false);
    }
  };

  const testsCatalog = [
    {
      id: 'descriptive',
      title: 'عمود رقمي واحد',
      subtitle: 'الإحصاء الوصفي واكتشاف القيم الشاذة',
      desc: 'المتوسط الحسابي، الوسيط، الانحراف المعياري، الربيعات والمدى الربيعي (IQR)، ومخطط التوزيع واكتشاف القيم الشاذة وفق قاعدة تيوكي (1.5 × IQR).',
      icon: <BarChart2 className="w-5 h-5 text-emerald-600" />
    },
    {
      id: 'correlation',
      title: 'عمودان رقميان',
      subtitle: 'ارتباط بيرسون وسبيرمان (Correlation)',
      desc: 'قياس قوة واتجاه العلاقة الخطية والرتبية بين متغيرين كميين مع خط الانحدار ونقاط الانتشار (Scatter Plot)، دون افتراض السببية.',
      icon: <TrendingUp className="w-5 h-5 text-blue-600" />
    },
    {
      id: 'two_independent_groups',
      title: 'عمود رقمي ومجموعتان مستقلتان',
      subtitle: 'اختبار ويلش (Welch t) ومان-ويتني (Mann-Whitney)',
      desc: 'مقارنة المتوسطات بين مجموعتين مستقلتين (مثل فرعين أو فئتين) دون افتراض تساوي التباين، مع حجم الأثر (Cohen\'s d).',
      icon: <Split className="w-5 h-5 text-indigo-600" />
    },
    {
      id: 'paired_samples',
      title: 'قياسان لنفس العناصر قبل وبعد',
      subtitle: 'اختبار t للعينات المزدوجة وويلكوكسون (Wilcoxon)',
      desc: 'قياس التغير لنفس العناصر قبل وبعد إجراء محدد، مع فحص المعرف الرابط لتفادي المطابقة العشوائية بالترتيب.',
      icon: <GitCommit className="w-5 h-5 text-purple-600" />
    },
    {
      id: 'anova_kruskal',
      title: 'عمود رقمي و3 مجموعات أو أكثر',
      subtitle: 'ANOVA أحادي الاتجاه وكروسكال-واليس (Kruskal-Wallis)',
      desc: 'مقارنة التباين والمتوسطات عبر 3 تصنيفات أو أكثر (مثل فروع الشركة أو خطوط الإنتاج)، مع نسبة التباين المفسر (Eta Squared).',
      icon: <Layers className="w-5 h-5 text-amber-600" />
    },
    {
      id: 'contingency_table',
      title: 'عمودان فئويان',
      subtitle: 'جدول الاقتران التقاطعي واختبار كاي تربيع (Chi-Square & Fisher)',
      desc: 'اختبار استقلالية المتغيرات الوصفية، التكرارات المشاهدة والمتوقعة، ومعامل كرامر (Cramer\'s V)، واختبار فيشر الدقيق لجدول 2×2.',
      icon: <Table className="w-5 h-5 text-rose-600" />
    }
  ];

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-slate-950/65 backdrop-blur-xs">
      <div className="bg-white rounded-3xl border border-slate-200 shadow-2xl w-full max-w-5xl max-h-[92vh] flex flex-col overflow-hidden">
        {/* Header */}
        <div className="p-5 border-b border-slate-200 flex items-center justify-between bg-slate-50/70">
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-2xl bg-indigo-600 text-white flex items-center justify-center shadow-md">
              <Activity className="w-6 h-6" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-base sm:text-lg font-bold text-slate-900">
                  منصة الاختبارات والتحليلات الإحصائية
                </h2>
                <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-indigo-100 text-indigo-800 border border-indigo-200">
                  دقة خوارزمية كاملة
                </span>
              </div>
              <p className="text-xs text-slate-500 mt-0.5">
                الورقة: <span className="font-bold text-slate-700 font-mono">{activeSheetName}</span> • الصفوف المطابقة للفلاتر: <span className="font-bold text-emerald-700">{filteredRowCount}</span> صفاً • تشغيل يدوي مباشر ومستقل عن المحادثة.
              </p>
            </div>
          </div>
          <button onClick={onClose} className="p-2 text-slate-400 hover:text-slate-700 rounded-xl cursor-pointer">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-5 sm:p-6 overflow-y-auto space-y-6 text-xs flex-1">
          {errorMsg && (
            <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs flex items-start gap-2.5 shadow-xs">
              <AlertOctagon className="w-4 h-4 text-rose-600 shrink-0 mt-0.5" />
              <div className="font-medium leading-relaxed">{errorMsg}</div>
            </div>
          )}

          {/* Step 1: Test Selection (6 Distinct Family Cards) */}
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="font-bold text-slate-800 text-xs flex items-center gap-2">
                <span className="w-5 h-5 rounded-full bg-indigo-100 text-indigo-800 flex items-center justify-center text-[11px] font-mono">1</span>
                <span>اختر نوع المقارنة الإحصائية وسؤال التحليل:</span>
              </span>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
              {testsCatalog.map(t => {
                const isSelected = testType === t.id;
                return (
                  <button
                    key={t.id}
                    type="button"
                    onClick={() => setTestType(t.id as StatisticalTestType)}
                    className={`p-4 rounded-2xl border text-right transition flex flex-col justify-between cursor-pointer space-y-2 ${
                      isSelected
                        ? 'bg-indigo-50/70 border-indigo-400 ring-2 ring-indigo-200 shadow-xs'
                        : 'bg-white border-slate-200 hover:bg-slate-50/80'
                    }`}
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div className="p-2 rounded-xl bg-white border border-slate-200/80 shadow-2xs">
                        {t.icon}
                      </div>
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${isSelected ? 'bg-indigo-600 text-white' : 'bg-slate-100 text-slate-600'}`}>
                        {t.title}
                      </span>
                    </div>

                    <div>
                      <h4 className="font-bold text-xs text-slate-900 leading-tight">{t.subtitle}</h4>
                      <p className="text-[11px] text-slate-500 mt-1 leading-relaxed line-clamp-3">
                        {t.desc}
                      </p>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Step 2: Columns, Parameters & Preconditions */}
          <div className="bg-slate-50/80 rounded-2xl border border-slate-200 p-4 sm:p-5 space-y-4">
            <span className="font-bold text-slate-800 text-xs flex items-center gap-2">
              <span className="w-5 h-5 rounded-full bg-indigo-100 text-indigo-800 flex items-center justify-center text-[11px] font-mono">2</span>
              <span>تحديد الأعمدة، المعاملات، وفحص الشروط المسبقة:</span>
            </span>

            {/* Dynamic Column Selectors based on Test Type */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
              {/* Col 1 */}
              <div className="space-y-1.5">
                <label className="font-bold text-slate-700 text-[11px] block">
                  {testType === 'paired_samples' ? 'عمود القياس قبل (Before):' : testType === 'contingency_table' ? 'متغير الصفوف (الفئة 1):' : 'العمود الرقمي الرئيسي:'}
                </label>
                <select
                  value={col1}
                  onChange={e => setCol1(e.target.value)}
                  className="w-full bg-white border border-slate-300 rounded-xl px-3 py-2 text-slate-800 font-bold outline-none cursor-pointer"
                >
                  <option value="">-- اختر العمود --</option>
                  {(testType === 'contingency_table' ? catColumns.length ? catColumns : allColumns : numColumns.length ? numColumns : allColumns).map(c => (
                    <option key={c.name} value={c.name}>
                      {c.name} ({c.userType || c.inferredType})
                    </option>
                  ))}
                </select>
              </div>

              {/* Col 2 (for tests requiring 2 variables) */}
              {testType !== 'descriptive' && (
                <div className="space-y-1.5">
                  <label className="font-bold text-slate-700 text-[11px] block">
                    {testType === 'correlation' ? 'العمود الرقمي الثاني (Y):' : testType === 'paired_samples' ? 'عمود القياس بعد (After):' : testType === 'contingency_table' ? 'متغير الأعمدة (الفئة 2):' : 'عمود المجموعات والتصنيف:'}
                  </label>
                  <select
                    value={col2}
                    onChange={e => setCol2(e.target.value)}
                    className="w-full bg-white border border-slate-300 rounded-xl px-3 py-2 text-slate-800 font-bold outline-none cursor-pointer"
                  >
                    <option value="">-- اختر العمود --</option>
                    {(testType === 'correlation' ? numColumns : testType === 'paired_samples' ? numColumns : catColumns.length ? catColumns : allColumns).map(c => (
                      <option key={c.name} value={c.name}>
                        {c.name} ({c.userType || c.inferredType})
                      </option>
                    ))}
                  </select>
                </div>
              )}

              {/* Sub-selectors for Independent Groups */}
              {testType === 'two_independent_groups' && (
                <>
                  <div className="space-y-1.5">
                    <label className="font-bold text-slate-700 text-[11px] block">المجموعة الأولى (Group 1):</label>
                    <select
                      value={group1Val}
                      onChange={e => setGroup1Val(e.target.value)}
                      className="w-full bg-white border border-slate-300 rounded-xl px-3 py-2 text-slate-800 font-bold outline-none cursor-pointer"
                    >
                      {distinctGroupValues.map(v => (
                        <option key={v} value={v}>{v}</option>
                      ))}
                    </select>
                  </div>

                  <div className="space-y-1.5">
                    <label className="font-bold text-slate-700 text-[11px] block">المجموعة الثانية (Group 2):</label>
                    <select
                      value={group2Val}
                      onChange={e => setGroup2Val(e.target.value)}
                      className="w-full bg-white border border-slate-300 rounded-xl px-3 py-2 text-slate-800 font-bold outline-none cursor-pointer"
                    >
                      {distinctGroupValues.map(v => (
                        <option key={v} value={v}>{v}</option>
                      ))}
                    </select>
                  </div>
                </>
              )}

              {/* Sub-selector for Paired Samples Identifier */}
              {testType === 'paired_samples' && (
                <div className="space-y-1.5">
                  <label className="font-bold text-slate-700 text-[11px] block">عمود المعرف الرابط (ID Key):</label>
                  <select
                    value={keyCol}
                    onChange={e => setKeyCol(e.target.value)}
                    className="w-full bg-white border border-slate-300 rounded-xl px-3 py-2 text-slate-800 font-bold outline-none cursor-pointer"
                  >
                    <option value="">-- اختياري (تلقائي برقم السطر) --</option>
                    {allColumns.map(c => (
                      <option key={c.name} value={c.name}>{c.name}</option>
                    ))}
                  </select>
                </div>
              )}

              {/* Alpha Level */}
              <div className="space-y-1.5">
                <label className="font-bold text-slate-700 text-[11px] block">مستوى الدلالة الإحصائية (α):</label>
                <div className="grid grid-cols-3 gap-1.5 bg-white p-1 rounded-xl border border-slate-300">
                  {[0.05, 0.01, 0.10].map(a => (
                    <button
                      key={a}
                      type="button"
                      onClick={() => setAlpha(a)}
                      className={`py-1 rounded-lg font-bold text-center transition cursor-pointer ${
                        alpha === a ? 'bg-indigo-600 text-white shadow-2xs' : 'text-slate-600 hover:bg-slate-100'
                      }`}
                    >
                      {a === 0.05 ? '0.05 (95%)' : a === 0.01 ? '0.01 (99%)' : '0.10 (90%)'}
                    </button>
                  ))}
                </div>
              </div>

              {/* Currency Selector (When multi-currency exists) */}
              {currenciesDetected.length > 0 && testType !== 'contingency_table' && (
                <div className="space-y-1.5">
                  <label className="font-bold text-slate-700 text-[11px] block flex items-center gap-1">
                    <Coins className="w-3.5 h-3.5 text-emerald-600" />
                    <span>تحديد العملة المالية:</span>
                  </label>
                  <select
                    value={selectedCurrency}
                    onChange={e => setSelectedCurrency(e.target.value)}
                    className="w-full bg-white border border-slate-300 rounded-xl px-3 py-2 text-slate-800 font-bold outline-none cursor-pointer"
                  >
                    <option value="all">كافة العملات (دون حصر عملة)</option>
                    {currenciesDetected.map(c => (
                      <option key={c} value={c}>{c}</option>
                    ))}
                  </select>
                </div>
              )}
            </div>

            {/* Preconditions Live Box */}
            <div className="p-3.5 bg-white rounded-xl border border-slate-200 space-y-2">
              <span className="font-bold text-slate-700 text-[11px] block flex items-center gap-1.5">
                <ShieldCheck className="w-4 h-4 text-indigo-600" />
                <span>التحقق من الشروط المسبقة للاختبار (Assumptions & Validation):</span>
              </span>

              <div className="space-y-1.5 pt-1">
                {preconditions.map((p, i) => (
                  <div key={i} className="flex items-start gap-2 text-[11px] leading-relaxed">
                    {p.satisfied ? (
                      <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                    ) : (
                      <AlertTriangle className="w-4 h-4 text-amber-500 shrink-0 mt-0.5" />
                    )}
                    <div>
                      <span className={`font-bold ${p.satisfied ? 'text-slate-800' : 'text-amber-800'}`}>
                        {p.condition}:{' '}
                      </span>
                      <span className={p.satisfied ? 'text-slate-600' : 'text-amber-900 font-medium'}>
                        {p.message}
                      </span>
                      {p.recommendation && (
                        <span className="block text-[10px] text-indigo-700 mt-0.5">
                          💡 <strong>توصية: </strong>{p.recommendation}
                        </span>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Run Button */}
            <div className="flex items-center justify-end pt-1">
              <button
                type="button"
                onClick={handleRunTest}
                disabled={running || !col1}
                className="flex items-center gap-2 px-6 py-2.5 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white rounded-xl font-bold transition shadow-sm cursor-pointer"
              >
                {running ? <RefreshCw className="w-4 h-4 animate-spin" /> : <Play className="w-4 h-4" />}
                <span>{running ? 'جارٍ تشغيل الحسابات الرياضية...' : 'تشغيل الاختبار الإحصائي الآن'}</span>
              </button>
            </div>
          </div>

          {/* Step 3: Test Results Showcase */}
          {testResult && (
            <div className="space-y-5 pt-2 border-t border-slate-200">
              <div className="flex flex-wrap items-center justify-between gap-3 bg-linear-to-r from-indigo-50 to-blue-50 p-4 rounded-2xl border border-indigo-200">
                <div className="flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-xl bg-indigo-600 text-white flex items-center justify-center font-bold">
                    ✓
                  </div>
                  <div>
                    <h3 className="font-bold text-sm text-indigo-950">
                      {testResult.testNameAr}
                    </h3>
                    <p className="text-[11px] text-indigo-800/80 font-mono">
                      {testResult.testNameEn} • α = {testResult.alpha}
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  <button
                    onClick={() => onOpenMatchingRows(`الصفوف المستخدمة في ${testResult.testNameAr}`, testResult.usedRowIndices)}
                    className="flex items-center gap-1.5 px-3 py-1.5 bg-white text-indigo-900 hover:bg-indigo-100 border border-indigo-300 rounded-xl font-bold transition cursor-pointer shadow-2xs"
                  >
                    <Eye className="w-3.5 h-3.5 text-indigo-600" />
                    <span>عرض الصفوف المستخدمة ({testResult.usedRowsCount})</span>
                  </button>

                  <button
                    onClick={() => onExportTest(testResult)}
                    className="flex items-center gap-1.5 px-3 py-1.5 bg-slate-900 hover:bg-slate-800 text-white rounded-xl font-bold transition cursor-pointer shadow-2xs"
                  >
                    <Download className="w-3.5 h-3.5" />
                    <span>تصدير النتائج Excel</span>
                  </button>
                </div>
              </div>

              {/* Hypotheses Card (Only for Inferential Tests) */}
              {testResult.testId !== 'descriptive' && testResult.hypotheses?.nullHypothesis && (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                  <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200 space-y-1">
                    <span className="font-bold text-slate-700 block">الفرضية الصفرية (H0):</span>
                    <p className="text-slate-600">{testResult.hypotheses.nullHypothesis}</p>
                  </div>
                  <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200 space-y-1">
                    <span className="font-bold text-slate-700 block">الفرضية البديلة (H1):</span>
                    <p className="text-slate-600">{testResult.hypotheses.altHypothesis}</p>
                  </div>
                </div>
              )}

              {/* Key Scorecards Grid */}
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                {testResult.testId === 'descriptive' ? (
                  <>
                    <div className="p-4 bg-white rounded-2xl border border-slate-200 shadow-xs flex flex-col justify-between">
                      <span className="text-[11px] font-bold text-slate-500">المتوسط الحسابي (Mean)</span>
                      <div className="text-xl font-black font-mono-numbers text-slate-900 mt-2">
                        {testResult.descriptiveMetrics?.mean || testResult.statistics.primaryStatValue}
                      </div>
                      <span className="text-[10px] text-slate-400 mt-1">النزعة المركزية</span>
                    </div>

                    <div className="p-4 bg-white rounded-2xl border border-slate-200 shadow-xs flex flex-col justify-between">
                      <span className="text-[11px] font-bold text-slate-500">الانحراف المعياري (Std Dev)</span>
                      <div className="text-xl font-black font-mono-numbers text-indigo-700 mt-2">
                        {testResult.descriptiveMetrics?.sampleStdDev || '-'}
                      </div>
                      <span className="text-[10px] text-slate-400 mt-1">تشتت العينة</span>
                    </div>

                    <div className="p-4 bg-white rounded-2xl border border-slate-200 shadow-xs flex flex-col justify-between">
                      <span className="text-[11px] font-bold text-slate-500">الوسيط (Median)</span>
                      <div className="text-xl font-black font-mono-numbers text-slate-900 mt-2">
                        {testResult.descriptiveMetrics?.median || testResult.statistics.secondaryStatValue || '-'}
                      </div>
                      <span className="text-[10px] text-slate-400 mt-1">النقطة المركزية</span>
                    </div>

                    <div className="p-4 bg-white rounded-2xl border border-slate-200 shadow-xs flex flex-col justify-between">
                      <span className="text-[11px] font-bold text-slate-500">المدى الربيعي (IQR)</span>
                      <div className="text-xl font-black font-mono-numbers text-slate-800 mt-2">
                        {testResult.descriptiveMetrics?.iqr || '-'}
                      </div>
                      <span className="text-[10px] text-slate-400 mt-1">
                        القيم الشاذة: {testResult.descriptiveMetrics?.outliersCount ?? 0}
                      </span>
                    </div>
                  </>
                ) : (
                  <>
                    <div className="p-4 bg-white rounded-2xl border border-slate-200 shadow-xs flex flex-col justify-between">
                      <span className="text-[11px] font-bold text-slate-500">{testResult.statistics.primaryStatName}</span>
                      <div className="text-xl font-black font-mono-numbers text-slate-900 mt-2">
                        {testResult.statistics.primaryStatValue}
                      </div>
                      <span className="text-[10px] text-slate-400 mt-1">إحصائية الاختبار</span>
                    </div>

                    <div className="p-4 bg-white rounded-2xl border border-slate-200 shadow-xs flex flex-col justify-between">
                      <span className="text-[11px] font-bold text-slate-500">القيمة الاحتمالية (p-value)</span>
                      <div className="text-xl font-black font-mono-numbers text-indigo-700 mt-2">
                        {testResult.statistics.pValue !== undefined
                          ? (testResult.statistics.pValue < 0.001 ? '< 0.001' : testResult.statistics.pValue)
                          : 'غير متاح'}
                      </div>
                      <span className="text-[10px] text-slate-400 mt-1">مستوى المعنوية α = {testResult.alpha}</span>
                    </div>

                    <div className="p-4 bg-white rounded-2xl border border-slate-200 shadow-xs flex flex-col justify-between">
                      <span className="text-[11px] font-bold text-slate-500">النتيجة الإحصائية</span>
                      <div className="mt-2">
                        {testResult.statistics.isSignificant !== undefined ? (
                          <span className={`px-2.5 py-1 rounded-lg text-xs font-bold inline-block ${
                            testResult.statistics.isSignificant
                              ? 'bg-emerald-100 text-emerald-800 border border-emerald-200'
                              : 'bg-slate-100 text-slate-700 border border-slate-300'
                          }`}>
                            {testResult.statistics.isSignificant ? 'دلالة إحصائية مؤكدة' : 'الأدلة غير كافية لرفض H0'}
                          </span>
                        ) : (
                          <span className="text-xs text-slate-400">-</span>
                        )}
                      </div>
                      <span className="text-[10px] text-slate-400 mt-1">
                        {testResult.statistics.isSignificant !== undefined
                          ? (testResult.statistics.isSignificant ? 'رفض الفرضية الصفرية' : 'عدم كفاية الدلائل لرفض H0')
                          : '-'}
                      </span>
                    </div>

                    <div className="p-4 bg-white rounded-2xl border border-slate-200 shadow-xs flex flex-col justify-between">
                      <span className="text-[11px] font-bold text-slate-500">الصفوف المستخدمة / المستبعدة</span>
                      <div className="text-xl font-black font-mono-numbers text-slate-800 mt-2">
                        {testResult.usedRowsCount} <span className="text-xs font-normal text-slate-400">/ {testResult.excludedRowsCount}</span>
                      </div>
                      <span className="text-[10px] text-slate-400 mt-1">
                        من أصل {testResult.totalRowsMatchingFilter} سطر
                      </span>
                    </div>
                  </>
                )}
              </div>

              {/* Effect Size & Confidence Interval (if supported) */}
              {(testResult.statistics.effectSize || testResult.statistics.confidenceInterval) && (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                  {testResult.statistics.effectSize && (
                    <div className="p-3.5 bg-indigo-50/50 rounded-xl border border-indigo-100 flex items-center justify-between">
                      <div>
                        <span className="font-bold text-indigo-900 block">{testResult.statistics.effectSize.name}</span>
                        <span className="text-[11px] text-indigo-700">{testResult.statistics.effectSize.interpretation}</span>
                      </div>
                      <div className="text-lg font-bold font-mono text-indigo-900">
                        {testResult.statistics.effectSize.value}
                      </div>
                    </div>
                  )}

                  {testResult.statistics.confidenceInterval && (
                    <div className="p-3.5 bg-blue-50/50 rounded-xl border border-blue-100 flex items-center justify-between">
                      <div>
                        <span className="font-bold text-blue-900 block">{testResult.statistics.confidenceInterval.parameterName}</span>
                        <span className="text-[11px] text-blue-700">مستوى ثقة {testResult.statistics.confidenceInterval.level}%</span>
                      </div>
                      <div className="text-sm font-bold font-mono text-blue-950">
                        [{testResult.statistics.confidenceInterval.lower} إلى {testResult.statistics.confidenceInterval.upper}]
                      </div>
                    </div>
                  )}
                </div>
              )}

              {/* Scientific Accounting Explanation */}
              <div className="p-4 bg-slate-50 rounded-2xl border border-slate-200 space-y-2 leading-relaxed">
                <span className="font-bold text-slate-800 flex items-center gap-1.5">
                  <Sparkles className="w-4 h-4 text-indigo-600" />
                  <span>التفسير العلمي والمحاسبي للنتيجة:</span>
                </span>
                <p className="text-slate-700 text-xs">
                  {testResult.explanationAr}
                </p>
                {testType === 'correlation' && (
                  <p className="text-[11px] text-amber-800 bg-amber-50 p-2.5 rounded-lg border border-amber-200 mt-2 font-medium">
                    ⚠️ <strong>تنبيه علمي ورقابي:</strong> إثبات الارتباط الإحصائي بين المتغيرين يعني تزامناً عددياً ولا يعني بالضرورة وجود علاقة سببية مباشرة (الارتباط لا يعني السببية).
                  </p>
                )}
              </div>

              {/* Exclusion Breakdown */}
              {testResult.excludedRowsCount > 0 && (
                <div className="p-3.5 bg-slate-100/60 rounded-xl border border-slate-200 text-xs space-y-1.5">
                  <span className="font-bold text-slate-700 block">تفصيل أسباب استبعاد الصفوف ({testResult.excludedRowsCount} صفاً):</span>
                  <div className="flex flex-wrap gap-2 text-[11px]">
                    {Object.entries(testResult.excludedReasons || {}).map(([reason, count]) => (
                      <span key={reason} className="px-2.5 py-1 bg-white border border-slate-200 rounded-lg text-slate-700">
                        {reason}: <strong>{count}</strong>
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Modal Footer */}
        <div className="p-4 border-t border-slate-200 bg-slate-50 flex items-center justify-between text-xs">
          <span className="text-slate-400">
            تعتمد الاختبارات على معادلات توزيعات Gamma وBeta وStudent t وChi-Square بدقة عددية عالية.
          </span>
          <button
            type="button"
            onClick={onClose}
            className="px-5 py-2 bg-slate-200 hover:bg-slate-300 text-slate-800 rounded-xl font-bold cursor-pointer transition"
          >
            إغلاق
          </button>
        </div>
      </div>
    </div>
  );
};
