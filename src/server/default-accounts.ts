// Shared account identifiers are required by the accounting engine. No opening balances.
export const defaultAccountsData = [
      // Level 1: Main Headings
      { id: 'acc_1', code: '1', name_ar: 'الأصول', name_en: 'Assets', parent: null, type: 'asset', nature: 'debit', is_group: 1, level: 1 },
      { id: 'acc_2', code: '2', name_ar: 'الالتزامات', name_en: 'Liabilities', parent: null, type: 'liability', nature: 'credit', is_group: 1, level: 1 },
      { id: 'acc_3', code: '3', name_ar: 'حقوق الملكية', name_en: 'Equity', parent: null, type: 'equity', nature: 'credit', is_group: 1, level: 1 },
      { id: 'acc_4', code: '4', name_ar: 'الإيرادات', name_en: 'Revenues', parent: null, type: 'revenue', nature: 'credit', is_group: 1, level: 1 },
      { id: 'acc_5', code: '5', name_ar: 'تكلفة المبيعات', name_en: 'Cost of Goods Sold', parent: null, type: 'cogs', nature: 'debit', is_group: 1, level: 1 },
      { id: 'acc_6', code: '6', name_ar: 'المصروفات التشغيلية والإدارية', name_en: 'Operating Expenses', parent: null, type: 'expense', nature: 'debit', is_group: 1, level: 1 },

      // Level 2 & 3: Assets
      { id: 'acc_11', code: '11', name_ar: 'الأصول المتداولة', name_en: 'Current Assets', parent: 'acc_1', type: 'asset', nature: 'debit', is_group: 1, level: 2 },
      { id: 'acc_111', code: '111', name_ar: 'النقدية وما في حكمها', name_en: 'Cash and Cash Equivalents', parent: 'acc_11', type: 'asset', nature: 'debit', is_group: 1, level: 3 },
      { id: 'acc_1111', code: '1111', name_ar: 'خزينة المركز الرئيسي - القاهرة', name_en: 'Cairo Main Cash Box', parent: 'acc_111', type: 'asset', nature: 'debit', is_group: 0, level: 4 },
      { id: 'acc_1112', code: '1112', name_ar: 'خزينة فرع الإسكندرية', name_en: 'Alexandria Cash Box', parent: 'acc_111', type: 'asset', nature: 'debit', is_group: 0, level: 4 },
      { id: 'acc_1113', code: '1113', name_ar: 'البنك الأهلي المصري (حساب جاري بالجنيه)', name_en: 'National Bank of Egypt (EGP)', parent: 'acc_111', type: 'asset', nature: 'debit', is_group: 0, level: 4 },
      { id: 'acc_1114', code: '1114', name_ar: 'بنك مصر (حساب جاري بالدولار)', name_en: 'Banque Misr (USD)', parent: 'acc_111', type: 'asset', nature: 'debit', is_group: 0, level: 4 },

      { id: 'acc_112', code: '112', name_ar: 'العملاء والمدينون', name_en: 'Accounts Receivable', parent: 'acc_11', type: 'asset', nature: 'debit', is_group: 1, level: 3 },
      { id: 'acc_1121', code: '1121', name_ar: 'العملاء التجاريون (حساب الرقابة العام)', name_en: 'Trade Debtors Control Account', parent: 'acc_112', type: 'asset', nature: 'debit', is_group: 0, level: 4, is_reconciliation: 1 },
      { id: 'acc_1122', code: '1122', name_ar: 'عملاء التوزيع والتجزئة', name_en: 'Retail Debtors', parent: 'acc_112', type: 'asset', nature: 'debit', is_group: 0, level: 4 },

      { id: 'acc_113', code: '113', name_ar: 'أوراق القبض', name_en: 'Notes Receivable', parent: 'acc_11', type: 'asset', nature: 'debit', is_group: 1, level: 3 },
      { id: 'acc_1131', code: '1131', name_ar: 'شيكات برسم التحصيل بالخزينة', name_en: 'Cheques in Hand', parent: 'acc_113', type: 'asset', nature: 'debit', is_group: 0, level: 4 },
      { id: 'acc_1132', code: '1132', name_ar: 'شيكات مودعة بالبنك للتحصيل', name_en: 'Cheques under Collection', parent: 'acc_113', type: 'asset', nature: 'debit', is_group: 0, level: 4 },

      { id: 'acc_114', code: '114', name_ar: 'المخزون السلعي', name_en: 'Inventory Asset', parent: 'acc_11', type: 'asset', nature: 'debit', is_group: 1, level: 3 },
      { id: 'acc_1141', code: '1141', name_ar: 'مخزون بضاعة بغرض البيع (المخزن الرئيسي)', name_en: 'Finished Goods Inventory - Cairo', parent: 'acc_114', type: 'asset', nature: 'debit', is_group: 0, level: 4 },
      { id: 'acc_1142', code: '1142', name_ar: 'مخزون فرع الإسكندرية', name_en: 'Inventory - Alexandria', parent: 'acc_114', type: 'asset', nature: 'debit', is_group: 0, level: 4 },
      { id: 'acc_1143', code: '1143', name_ar: 'مخزون بضاعة تالفة ومرتجعات فحص', name_en: 'Damaged & Inspection Stock', parent: 'acc_114', type: 'asset', nature: 'debit', is_group: 0, level: 4 },

      { id: 'acc_115', code: '115', name_ar: 'أرصدة مدينة لدى مصلحة الضرائب', name_en: 'Tax Authority Debit Balances', parent: 'acc_11', type: 'asset', nature: 'debit', is_group: 1, level: 3 },
      { id: 'acc_1151', code: '1151', name_ar: 'مصلحة الضرائب - ضريبة القيمة المضافة (مدخلات قابلة للخصم)', name_en: 'Input VAT Recoverable (14%)', parent: 'acc_115', type: 'asset', nature: 'debit', is_group: 0, level: 4 },
      { id: 'acc_1152', code: '1152', name_ar: 'مصلحة الضرائب - خصم وتحصيل مستقطع من العملاء (1%)', name_en: 'Withholding Tax Deducted by Customers', parent: 'acc_115', type: 'asset', nature: 'debit', is_group: 0, level: 4 },

      // Non-Current Assets
      { id: 'acc_12', code: '12', name_ar: 'الأصول غير المتداولة (الثابتة)', name_en: 'Non-Current Assets', parent: 'acc_1', type: 'asset', nature: 'debit', is_group: 1, level: 2 },
      { id: 'acc_1211', code: '1211', name_ar: 'أجهزة حاسب آلي ومعدات شبكات', name_en: 'Computers & IT Equipment', parent: 'acc_12', type: 'asset', nature: 'debit', is_group: 0, level: 3 },
      { id: 'acc_1212', code: '1212', name_ar: 'أثاث ومفروشات وتجهيزات مكتبية', name_en: 'Office Furniture & Fixtures', parent: 'acc_12', type: 'asset', nature: 'debit', is_group: 0, level: 3 },
      { id: 'acc_1213', code: '1213', name_ar: 'سيارات نقل وتوزيع', name_en: 'Vehicles & Delivery Trucks', parent: 'acc_12', type: 'asset', nature: 'debit', is_group: 0, level: 3 },
      { id: 'acc_1221', code: '1221', name_ar: 'مجمع إهلاك أجهزة حاسب آلي', name_en: 'Accum. Deprec. - Computers', parent: 'acc_12', type: 'asset', nature: 'credit', is_group: 0, level: 3 },
      { id: 'acc_1222', code: '1222', name_ar: 'مجمع إهلاك أثاث وتجهيزات', name_en: 'Accum. Deprec. - Furniture', parent: 'acc_12', type: 'asset', nature: 'credit', is_group: 0, level: 3 },
      { id: 'acc_1223', code: '1223', name_ar: 'مجمع إهلاك سيارات', name_en: 'Accum. Deprec. - Vehicles', parent: 'acc_12', type: 'asset', nature: 'credit', is_group: 0, level: 3 },

      // Liabilities
      { id: 'acc_21', code: '21', name_ar: 'الالتزامات المتداولة', name_en: 'Current Liabilities', parent: 'acc_2', type: 'liability', nature: 'credit', is_group: 1, level: 2 },
      { id: 'acc_211', code: '211', name_ar: 'الموردون والدائنون التجاريون', name_en: 'Accounts Payable', parent: 'acc_21', type: 'liability', nature: 'credit', is_group: 1, level: 3 },
      { id: 'acc_2111', code: '2111', name_ar: 'الموردون التجاريون (حساب الرقابة العام)', name_en: 'Trade Creditors Control Account', parent: 'acc_211', type: 'liability', nature: 'credit', is_group: 0, level: 4, is_reconciliation: 1 },
      { id: 'acc_2121', code: '2121', name_ar: 'أوراق الدفع (شيكات صادرة للموردين)', name_en: 'Notes Payable (Issued Cheques)', parent: 'acc_21', type: 'liability', nature: 'credit', is_group: 0, level: 3 },
      
      { id: 'acc_213', code: '213', name_ar: 'الالتزامات الضريبية (مصلحة الضرائب المصرية)', name_en: 'Tax Liabilities (ETA)', parent: 'acc_21', type: 'liability', nature: 'credit', is_group: 1, level: 3 },
      { id: 'acc_2131', code: '2131', name_ar: 'مصلحة الضرائب - ضريبة القيمة المضافة (مخرجات مستحقة 14%)', name_en: 'Output VAT Payable (14%)', parent: 'acc_213', type: 'liability', nature: 'credit', is_group: 0, level: 4 },
      { id: 'acc_2132', code: '2132', name_ar: 'مصلحة الضرائب - ضرائب الخصم والتحصيل أمانات (مستقطعة من الموردين)', name_en: 'Withholding Tax Payable (1%/3%)', parent: 'acc_213', type: 'liability', nature: 'credit', is_group: 0, level: 4 },
      { id: 'acc_2133', code: '2133', name_ar: 'مصلحة الضرائب - ضريبة كسب العمل', name_en: 'Payroll Tax Payable', parent: 'acc_213', type: 'liability', nature: 'credit', is_group: 0, level: 4 },
      { id: 'acc_2141', code: '2141', name_ar: 'مصروفات مستحقة وأرصدة دائنة أخرى', name_en: 'Accrued Expenses & Other Payables', parent: 'acc_21', type: 'liability', nature: 'credit', is_group: 0, level: 3 },

      // Equity
      { id: 'acc_31', code: '31', name_ar: 'رأس المال والاحتياطيات', name_en: 'Capital & Reserves', parent: 'acc_3', type: 'equity', nature: 'credit', is_group: 1, level: 2 },
      { id: 'acc_3111', code: '3111', name_ar: 'رأس المال المدفوع', name_en: 'Paid-in Capital', parent: 'acc_31', type: 'equity', nature: 'credit', is_group: 0, level: 3 },
      { id: 'acc_3211', code: '3211', name_ar: 'الاحتياطي القانوني', name_en: 'Legal Reserve', parent: 'acc_31', type: 'equity', nature: 'credit', is_group: 0, level: 3 },
      { id: 'acc_3311', code: '3311', name_ar: 'الأرباح المحتجزة / المرحلة', name_en: 'Retained Earnings', parent: 'acc_31', type: 'equity', nature: 'credit', is_group: 0, level: 3 },
      { id: 'acc_3411', code: '3411', name_ar: 'أرباح وخسائر العام الحالي', name_en: 'Current Year Profit/Loss', parent: 'acc_31', type: 'equity', nature: 'credit', is_group: 0, level: 3 },

      // Revenues
      { id: 'acc_41', code: '41', name_ar: 'إيرادات النشاط الرئيسي', name_en: 'Operating Revenues', parent: 'acc_4', type: 'revenue', nature: 'credit', is_group: 1, level: 2 },
      { id: 'acc_4111', code: '4111', name_ar: 'إيرادات مبيعات أجهزة وإلكترونيات', name_en: 'Sales Revenue - Electronics', parent: 'acc_41', type: 'revenue', nature: 'credit', is_group: 0, level: 3 },
      { id: 'acc_4112', code: '4112', name_ar: 'إيرادات مبيعات مستلزمات وإكسسوارات', name_en: 'Sales Revenue - Accessories', parent: 'acc_41', type: 'revenue', nature: 'credit', is_group: 0, level: 3 },
      { id: 'acc_4113', code: '4113', name_ar: 'إيرادات خدمات صيانة ودعم فني', name_en: 'Maintenance & Service Revenue', parent: 'acc_41', type: 'revenue', nature: 'credit', is_group: 0, level: 3 },
      { id: 'acc_4211', code: '4211', name_ar: 'مردودات ومسموحات المبيعات', name_en: 'Sales Returns & Allowances', parent: 'acc_41', type: 'revenue', nature: 'debit', is_group: 0, level: 3 },
      { id: 'acc_4311', code: '4311', name_ar: 'الخصم المسموح به للعملاء', name_en: 'Sales Discounts Allowed', parent: 'acc_41', type: 'revenue', nature: 'debit', is_group: 0, level: 3 },
      { id: 'acc_4511', code: '4511', name_ar: 'إيرادات متنوعة وأرباح فروق عملة', name_en: 'Other Income & Forex Gain', parent: 'acc_4', type: 'revenue', nature: 'credit', is_group: 0, level: 2 },

      // Cost of Goods Sold
      { id: 'acc_51', code: '51', name_ar: 'تكلفة النشاط والمبيعات', name_en: 'Cost of Sales', parent: 'acc_5', type: 'cogs', nature: 'debit', is_group: 1, level: 2 },
      { id: 'acc_5111', code: '5111', name_ar: 'تكلفة البضاعة المباعة (أجهزة وإلكترونيات)', name_en: 'COGS - Electronics', parent: 'acc_51', type: 'cogs', nature: 'debit', is_group: 0, level: 3 },
      { id: 'acc_5112', code: '5112', name_ar: 'تكلفة البضاعة المباعة (إكسسوارات)', name_en: 'COGS - Accessories', parent: 'acc_51', type: 'cogs', nature: 'debit', is_group: 0, level: 3 },
      { id: 'acc_5211', code: '5211', name_ar: 'عجز وتسويات المخزون السلعي والهالك', name_en: 'Inventory Shrinkage & Loss', parent: 'acc_51', type: 'cogs', nature: 'debit', is_group: 0, level: 3 },

      // Operating Expenses
      { id: 'acc_61', code: '61', name_ar: 'المصروفات البيعية والعمومية', name_en: 'Selling & Admin Expenses', parent: 'acc_6', type: 'expense', nature: 'debit', is_group: 1, level: 2 },
      { id: 'acc_6111', code: '6111', name_ar: 'الأجور والمرتبات والمكافآت', name_en: 'Salaries, Wages & Bonuses', parent: 'acc_61', type: 'expense', nature: 'debit', is_group: 0, level: 3 },
      { id: 'acc_6211', code: '6211', name_ar: 'إيجار المقرات والمعارض والمخازن', name_en: 'Rent Expense', parent: 'acc_61', type: 'expense', nature: 'debit', is_group: 0, level: 3 },
      { id: 'acc_6311', code: '6311', name_ar: 'إهلاك الأصول الثابتة', name_en: 'Depreciation Expense', parent: 'acc_61', type: 'expense', nature: 'debit', is_group: 0, level: 3 },
      { id: 'acc_6411', code: '6411', name_ar: 'كهرباء ومياه وغاز ومرافق', name_en: 'Utilities Expense', parent: 'acc_61', type: 'expense', nature: 'debit', is_group: 0, level: 3 },
      { id: 'acc_6412', code: '6412', name_ar: 'اتصالات وإنترنت وموقع إلكتروني', name_en: 'Telecommunications & Internet', parent: 'acc_61', type: 'expense', nature: 'debit', is_group: 0, level: 3 },
      { id: 'acc_6511', code: '6511', name_ar: 'مصاريف بنكية وعمولات تحصيل', name_en: 'Bank Charges & Commissions', parent: 'acc_61', type: 'expense', nature: 'debit', is_group: 0, level: 3 },
      { id: 'acc_6611', code: '6611', name_ar: 'خسائر فروق تقييم العملة الأجنبية', name_en: 'Foreign Exchange Losses', parent: 'acc_61', type: 'expense', nature: 'debit', is_group: 0, level: 3 }
    ];
