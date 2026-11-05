import React, { useState, useEffect } from 'react';
import {
  Sliders,
  X,
  Check,
  RotateCcw,
  Sparkles,
  Info,
  DollarSign,
  Coins,
  Receipt,
  FileText,
  Calendar,
  Layers
} from 'lucide-react';
import { SheetAnalysis, SheetColumnMapping, ColumnMeta } from '../types';

interface ColumnMappingModalProps {
  isOpen: boolean;
  onClose: () => void;
  activeSheetName: string;
  sheetAnalysis: SheetAnalysis | null;
  onSaveMapping: (newMapping: SheetColumnMapping) => Promise<void>;
}

export const ColumnMappingModal: React.FC<ColumnMappingModalProps> = ({
  isOpen,
  onClose,
  activeSheetName,
  sheetAnalysis,
  onSaveMapping
}) => {
  const [formMapping, setFormMapping] = useState<SheetColumnMapping>({
    amountColumn: '',
    currencyColumn: '',
    typeColumn: '',
    invoiceColumn: '',
    dateColumn: '',
    dataLevel: 'line_item'
  });
  const [saving, setSaving] = useState(false);

  // Compute auto-detected suggestions from columns
  const detectedAmountCol = sheetAnalysis?.columns.find(c => /إجمالي|صافي|مبلغ|قيمة|total|net|amount|price/i.test(c.name))?.name || '';
  const detectedCurrencyCol = sheetAnalysis?.columns.find(c => /عملة|currency/i.test(c.name))?.name || '';
  const detectedTypeCol = sheetAnalysis?.columns.find(c => /نوع_الحركة|نوع الفاتورة|البيان|مرتجع|نوع|type/i.test(c.name))?.name || '';
  const detectedInvoiceCol = sheetAnalysis?.columns.find(c => /رقم_الفاتورة|رقم الفاتورة|الفاتورة|invoice/i.test(c.name))?.name || '';
  const detectedDateCol = sheetAnalysis?.columns.find(c => /تاريخ|date/i.test(c.name))?.name || '';

  useEffect(() => {
    if (sheetAnalysis?.columnMapping) {
      setFormMapping({
        amountColumn: sheetAnalysis.columnMapping.amountColumn || detectedAmountCol,
        currencyColumn: sheetAnalysis.columnMapping.currencyColumn || detectedCurrencyCol,
        typeColumn: sheetAnalysis.columnMapping.typeColumn || detectedTypeCol,
        invoiceColumn: sheetAnalysis.columnMapping.invoiceColumn || detectedInvoiceCol,
        dateColumn: sheetAnalysis.columnMapping.dateColumn || detectedDateCol,
        dataLevel: sheetAnalysis.columnMapping.dataLevel || 'line_item'
      });
    } else {
      setFormMapping({
        amountColumn: detectedAmountCol,
        currencyColumn: detectedCurrencyCol,
        typeColumn: detectedTypeCol,
        invoiceColumn: detectedInvoiceCol,
        dateColumn: detectedDateCol,
        dataLevel: 'line_item'
      });
    }
  }, [sheetAnalysis, activeSheetName]);

  if (!isOpen) return null;

  const handleResetToAuto = () => {
    setFormMapping({
      amountColumn: detectedAmountCol,
      currencyColumn: detectedCurrencyCol,
      typeColumn: detectedTypeCol,
      invoiceColumn: detectedInvoiceCol,
      dateColumn: detectedDateCol,
      dataLevel: 'line_item'
    });
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      await onSaveMapping(formMapping);
      onClose();
    } finally {
      setSaving(false);
    }
  };

  const allColumns = sheetAnalysis?.columns || [];

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-xs">
      <div className="bg-white rounded-2xl border border-slate-200 shadow-2xl w-full max-w-2xl max-h-[90vh] flex flex-col overflow-hidden">
        {/* Header */}
        <div className="p-5 border-b border-slate-200 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-emerald-600 text-white flex items-center justify-center shadow-xs">
              <Sliders className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-sm sm:text-base font-bold text-slate-900">
                إعداد وتعيين الأعمدة المحاسبية للتحليل
              </h3>
              <p className="text-xs text-slate-500 mt-0.5">
                ورقة العمل: <span className="font-bold text-slate-700 font-mono">{activeSheetName}</span> • يمكنك مراجعة الاكتشاف التلقائي واختيار الأعمدة المعتمدة في الحسابات.
              </p>
            </div>
          </div>
          <button onClick={onClose} className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg cursor-pointer">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-5 overflow-y-auto space-y-5 text-xs">
          <div className="p-3 bg-emerald-50/80 border border-emerald-200/90 rounded-xl text-emerald-900 flex items-start gap-2.5">
            <Info className="w-4 h-4 text-emerald-700 shrink-0 mt-0.5" />
            <div className="leading-relaxed font-medium">
              يقوم محرك الميزان باكتشاف نوع البيانات واقتراح الأعمدة تلقائياً. تعيينك اليدوي هنا يُعتمد كمرجع أعلى في الجمع، المتوسط، الوسيط، صافي المبيعات، وفصل العملات التام.
            </div>
          </div>

          <div className="space-y-4">
            {/* 1. Amount Column */}
            <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200 space-y-2">
              <div className="flex items-center justify-between">
                <label className="font-bold text-slate-800 flex items-center gap-2">
                  <DollarSign className="w-4 h-4 text-emerald-600" />
                  <span>عمود المبالغ / القيمة المالية (Amount Column)</span>
                </label>
                {detectedAmountCol && (
                  <span className="text-[11px] text-slate-500 flex items-center gap-1">
                    <Sparkles className="w-3 h-3 text-amber-500" />
                    <span>مقترح: <strong>{detectedAmountCol}</strong></span>
                  </span>
                )}
              </div>
              <select
                value={formMapping.amountColumn || ''}
                onChange={e => setFormMapping({ ...formMapping, amountColumn: e.target.value })}
                className="w-full bg-white border border-slate-300 rounded-lg px-3 py-2 text-slate-800 font-bold outline-none cursor-pointer"
              >
                <option value="">-- اختر عمود المبالغ --</option>
                {allColumns.map((c: ColumnMeta) => (
                  <option key={c.name} value={c.name}>
                    {c.name} ({c.userType || c.inferredType})
                  </option>
                ))}
              </select>
            </div>

            {/* 2. Currency Column */}
            <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200 space-y-2">
              <div className="flex items-center justify-between">
                <label className="font-bold text-slate-800 flex items-center gap-2">
                  <Coins className="w-4 h-4 text-emerald-600" />
                  <span>عمود العملة (Currency Column)</span>
                </label>
                {detectedCurrencyCol && (
                  <span className="text-[11px] text-slate-500 flex items-center gap-1">
                    <Sparkles className="w-3 h-3 text-amber-500" />
                    <span>مقترح: <strong>{detectedCurrencyCol}</strong></span>
                  </span>
                )}
              </div>
              <select
                value={formMapping.currencyColumn || ''}
                onChange={e => setFormMapping({ ...formMapping, currencyColumn: e.target.value })}
                className="w-full bg-white border border-slate-300 rounded-lg px-3 py-2 text-slate-800 font-bold outline-none cursor-pointer"
              >
                <option value="">-- لا يوجد عمود عملة مستقل (استخلاص تلقائي من محتوى الخلية) --</option>
                {allColumns.map((c: ColumnMeta) => (
                  <option key={c.name} value={c.name}>
                    {c.name} ({c.userType || c.inferredType})
                  </option>
                ))}
              </select>
              <p className="text-[10px] text-slate-400">
                في حال غياب عمود العملة وعدم وجود رمز عملة بالخلية، يُصنف الصف كـ <strong>(عملة غير محددة)</strong> ولا يُفترض الجنيه افتراضياً منعاً للخلط المالي.
              </p>
            </div>

            {/* 3. Movement Type Column */}
            <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200 space-y-2">
              <div className="flex items-center justify-between">
                <label className="font-bold text-slate-800 flex items-center gap-2">
                  <Receipt className="w-4 h-4 text-emerald-600" />
                  <span>عمود نوع الحركة [مبيعات / مرتجع] (Movement Type)</span>
                </label>
                {detectedTypeCol && (
                  <span className="text-[11px] text-slate-500 flex items-center gap-1">
                    <Sparkles className="w-3 h-3 text-amber-500" />
                    <span>مقترح: <strong>{detectedTypeCol}</strong></span>
                  </span>
                )}
              </div>
              <select
                value={formMapping.typeColumn || ''}
                onChange={e => setFormMapping({ ...formMapping, typeColumn: e.target.value })}
                className="w-full bg-white border border-slate-300 rounded-lg px-3 py-2 text-slate-800 font-bold outline-none cursor-pointer"
              >
                <option value="">-- غير محدد (القيم الموجبة مبيعات والقيم السالبة مرتجع) --</option>
                {allColumns.map((c: ColumnMeta) => (
                  <option key={c.name} value={c.name}>
                    {c.name} ({c.userType || c.inferredType})
                  </option>
                ))}
              </select>
            </div>

            {/* 4. Invoice Column */}
            <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200 space-y-2">
              <div className="flex items-center justify-between">
                <label className="font-bold text-slate-800 flex items-center gap-2">
                  <FileText className="w-4 h-4 text-emerald-600" />
                  <span>عمود رقم الفاتورة / السند (Invoice Number)</span>
                </label>
                {detectedInvoiceCol && (
                  <span className="text-[11px] text-slate-500 flex items-center gap-1">
                    <Sparkles className="w-3 h-3 text-amber-500" />
                    <span>مقترح: <strong>{detectedInvoiceCol}</strong></span>
                  </span>
                )}
              </div>
              <select
                value={formMapping.invoiceColumn || ''}
                onChange={e => setFormMapping({ ...formMapping, invoiceColumn: e.target.value })}
                className="w-full bg-white border border-slate-300 rounded-lg px-3 py-2 text-slate-800 font-bold outline-none cursor-pointer"
              >
                <option value="">-- غير محدد --</option>
                {allColumns.map((c: ColumnMeta) => (
                  <option key={c.name} value={c.name}>
                    {c.name} ({c.userType || c.inferredType})
                  </option>
                ))}
              </select>
            </div>

            {/* 5. Date Column */}
            <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200 space-y-2">
              <div className="flex items-center justify-between">
                <label className="font-bold text-slate-800 flex items-center gap-2">
                  <Calendar className="w-4 h-4 text-emerald-600" />
                  <span>عمود التاريخ (Date Column)</span>
                </label>
                {detectedDateCol && (
                  <span className="text-[11px] text-slate-500 flex items-center gap-1">
                    <Sparkles className="w-3 h-3 text-amber-500" />
                    <span>مقترح: <strong>{detectedDateCol}</strong></span>
                  </span>
                )}
              </div>
              <select
                value={formMapping.dateColumn || ''}
                onChange={e => setFormMapping({ ...formMapping, dateColumn: e.target.value })}
                className="w-full bg-white border border-slate-300 rounded-lg px-3 py-2 text-slate-800 font-bold outline-none cursor-pointer"
              >
                <option value="">-- غير محدد --</option>
                {allColumns.map((c: ColumnMeta) => (
                  <option key={c.name} value={c.name}>
                    {c.name} ({c.userType || c.inferredType})
                  </option>
                ))}
              </select>
            </div>

            {/* 6. Data Level Setting */}
            <div className="p-3.5 bg-slate-50 rounded-xl border border-slate-200 space-y-2">
              <label className="font-bold text-slate-800 flex items-center gap-2">
                <Layers className="w-4 h-4 text-emerald-600" />
                <span>مستوى البيانات عند حساب إجمالي وصافي المبيعات (Data Level)</span>
              </label>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 pt-1">
                <label
                  className={`flex items-start gap-2.5 p-3 rounded-xl border cursor-pointer transition ${
                    formMapping.dataLevel === 'line_item'
                      ? 'bg-emerald-50 border-emerald-300 text-emerald-900 font-bold'
                      : 'bg-white border-slate-200 text-slate-700'
                  }`}
                >
                  <input
                    type="radio"
                    name="dataLevel"
                    value="line_item"
                    checked={formMapping.dataLevel !== 'invoice'}
                    onChange={() => setFormMapping({ ...formMapping, dataLevel: 'line_item' })}
                    className="mt-0.5 text-emerald-600 focus:ring-emerald-500"
                  />
                  <div>
                    <span className="block text-xs">على مستوى بند الفاتورة (Line Item)</span>
                    <span className="block text-[10px] text-slate-500 font-normal mt-0.5">
                      كل سطر يمثل صنفاً وبنداً مستقلاً؛ يُجمع المبلغ لكل البنود بصورة اعتيادية.
                    </span>
                  </div>
                </label>

                <label
                  className={`flex items-start gap-2.5 p-3 rounded-xl border cursor-pointer transition ${
                    formMapping.dataLevel === 'invoice'
                      ? 'bg-emerald-50 border-emerald-300 text-emerald-900 font-bold'
                      : 'bg-white border-slate-200 text-slate-700'
                  }`}
                >
                  <input
                    type="radio"
                    name="dataLevel"
                    value="invoice"
                    checked={formMapping.dataLevel === 'invoice'}
                    onChange={() => setFormMapping({ ...formMapping, dataLevel: 'invoice' })}
                    className="mt-0.5 text-emerald-600 focus:ring-emerald-500"
                  />
                  <div>
                    <span className="block text-xs">على مستوى إجمالي الفاتورة (Invoice Total)</span>
                    <span className="block text-[10px] text-slate-500 font-normal mt-0.5">
                      يُحتسب إجمالي الفاتورة مرة واحدة فقط برقم الفاتورة لمنع تكرار الإجمالي مع كل بند.
                    </span>
                  </div>
                </label>
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-slate-200 bg-slate-50 flex items-center justify-between gap-3 text-xs">
          <button
            type="button"
            onClick={handleResetToAuto}
            className="flex items-center gap-1.5 px-3 py-2 text-slate-600 hover:text-slate-900 hover:bg-slate-200/70 rounded-xl font-medium transition cursor-pointer"
          >
            <RotateCcw className="w-3.5 h-3.5" />
            <span>استعادة الاقتراحات التلقائية</span>
          </button>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 bg-slate-200 hover:bg-slate-300 text-slate-700 rounded-xl font-bold cursor-pointer"
            >
              إلغاء
            </button>
            <button
              type="button"
              onClick={handleSave}
              disabled={saving}
              className="flex items-center gap-1.5 px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl font-bold transition shadow-xs cursor-pointer"
            >
              <Check className="w-4 h-4" />
              <span>{saving ? 'جارٍ الحفظ والتحديث...' : 'حفظ وتحديث الحسابات'}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
