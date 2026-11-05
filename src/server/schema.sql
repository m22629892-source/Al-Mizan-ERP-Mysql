-- Al-Mizan ERP — MySQL 8.0.28+ / InnoDB / utf8mb4
CREATE TABLE IF NOT EXISTS `companies` (
  `id` VARCHAR(191) PRIMARY KEY,
  `name_ar` VARCHAR(255) NOT NULL,
  `name_en` VARCHAR(255) NOT NULL,
  `legal_name` LONGTEXT NOT NULL,
  `commercial_registry` LONGTEXT NOT NULL,
  `tax_id` VARCHAR(191) NOT NULL,
  `vat_number` LONGTEXT,
  `activity_code` LONGTEXT,
  `address_ar` LONGTEXT NOT NULL,
  `address_en` LONGTEXT,
  `city` LONGTEXT NOT NULL,
  `country` VARCHAR(255) NOT NULL DEFAULT 'مصر',
  `postal_code` LONGTEXT,
  `phone` LONGTEXT,
  `email` LONGTEXT,
  `website` LONGTEXT,
  `logo_url` LONGTEXT,
  `currency_code` VARCHAR(191) NOT NULL DEFAULT 'EGP',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `branches` (
  `id` VARCHAR(191) PRIMARY KEY,
  `company_id` VARCHAR(191) NOT NULL,
  `code` VARCHAR(191) NOT NULL UNIQUE,
  `name_ar` VARCHAR(255) NOT NULL,
  `name_en` VARCHAR(255) NOT NULL,
  `address` LONGTEXT,
  `phone` LONGTEXT,
  `is_active` INTEGER NOT NULL DEFAULT 1,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_branches_company_id FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `fiscal_years` (
  `id` VARCHAR(191) PRIMARY KEY,
  `code` VARCHAR(191) NOT NULL UNIQUE,
  `name_ar` VARCHAR(255) NOT NULL,
  `name_en` VARCHAR(255) NOT NULL,
  `start_date` DATE NOT NULL,
  `end_date` DATE NOT NULL,
  `is_closed` INTEGER NOT NULL DEFAULT 0,
  `closed_at` DATETIME,
  `closed_by` LONGTEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `fiscal_periods` (
  `id` VARCHAR(191) PRIMARY KEY,
  `fiscal_year_id` VARCHAR(191) NOT NULL,
  `period_number` INTEGER NOT NULL,
  `name_ar` VARCHAR(255) NOT NULL,
  `name_en` VARCHAR(255) NOT NULL,
  `start_date` DATE NOT NULL,
  `end_date` DATE NOT NULL,
  `is_closed` INTEGER NOT NULL DEFAULT 0,
  `closed_at` DATETIME,
  `closed_by` LONGTEXT,
  UNIQUE(fiscal_year_id, period_number),
  CONSTRAINT fk_fiscal_periods_fiscal_year_id FOREIGN KEY (`fiscal_year_id`) REFERENCES `fiscal_years` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `currencies` (
  `code` VARCHAR(191) PRIMARY KEY,
  `name_ar` VARCHAR(255) NOT NULL,
  `name_en` VARCHAR(255) NOT NULL,
  `symbol` LONGTEXT NOT NULL,
  `decimal_places` INTEGER NOT NULL DEFAULT 2,
  `is_base` INTEGER NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `exchange_rates` (
  `id` VARCHAR(191) PRIMARY KEY,
  `currency_code` VARCHAR(191) NOT NULL,
  `rate` DECIMAL(24,8) NOT NULL,
  `rate_date` DATE NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(currency_code, rate_date),
  CONSTRAINT fk_exchange_rates_currency_code FOREIGN KEY (`currency_code`) REFERENCES `currencies` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `cost_centers` (
  `id` VARCHAR(191) PRIMARY KEY,
  `code` VARCHAR(191) NOT NULL UNIQUE,
  `name_ar` VARCHAR(255) NOT NULL,
  `name_en` VARCHAR(255) NOT NULL,
  `parent_id` VARCHAR(191),
  `is_active` INTEGER NOT NULL DEFAULT 1,
  CONSTRAINT fk_cost_centers_parent_id FOREIGN KEY (`parent_id`) REFERENCES `cost_centers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `accounts` (
  `id` VARCHAR(191) PRIMARY KEY,
  `code` VARCHAR(191) NOT NULL UNIQUE,
  `name_ar` VARCHAR(255) NOT NULL,
  `name_en` VARCHAR(255) NOT NULL,
  `parent_id` VARCHAR(191),
  `account_type` VARCHAR(255) NOT NULL,
  `nature` VARCHAR(255) NOT NULL,
  `is_group` INTEGER NOT NULL DEFAULT 0,
  `level` INTEGER NOT NULL DEFAULT 1,
  `currency_code` VARCHAR(191),
  `is_reconciliation` INTEGER NOT NULL DEFAULT 0,
  `is_active` INTEGER NOT NULL DEFAULT 1,
  `notes` LONGTEXT,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_accounts_parent` (parent_id),
  INDEX `idx_accounts_code` (code),
  CONSTRAINT fk_accounts_parent_id FOREIGN KEY (`parent_id`) REFERENCES `accounts` (`id`),
  CONSTRAINT fk_accounts_currency_code FOREIGN KEY (`currency_code`) REFERENCES `currencies` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `document_sequences` (
  `id` VARCHAR(191) PRIMARY KEY,
  `doc_type` VARCHAR(255) NOT NULL,
  `branch_id` VARCHAR(191) NOT NULL,
  `fiscal_year_id` VARCHAR(191) NOT NULL,
  `prefix` VARCHAR(255) NOT NULL,
  `next_number` INTEGER NOT NULL DEFAULT 1,
  UNIQUE(doc_type, branch_id, fiscal_year_id),
  CONSTRAINT fk_document_sequences_branch_id FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  CONSTRAINT fk_document_sequences_fiscal_year_id FOREIGN KEY (`fiscal_year_id`) REFERENCES `fiscal_years` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `parties` (
  `id` VARCHAR(191) PRIMARY KEY,
  `code` VARCHAR(191) NOT NULL UNIQUE,
  `type` VARCHAR(191) NOT NULL,
  `name_ar` VARCHAR(255) NOT NULL,
  `name_en` VARCHAR(255) NOT NULL,
  `tax_id` VARCHAR(191),
  `commercial_registry` LONGTEXT,
  `national_id` VARCHAR(191),
  `is_company` INTEGER NOT NULL DEFAULT 1,
  `phone` LONGTEXT,
  `mobile` LONGTEXT,
  `email` LONGTEXT,
  `address` LONGTEXT,
  `city` LONGTEXT,
  `governorate` LONGTEXT,
  `credit_limit` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `payment_terms_days` INTEGER NOT NULL DEFAULT 0,
  `currency_code` VARCHAR(191) NOT NULL DEFAULT 'EGP',
  `account_id` VARCHAR(191),
  `is_active` INTEGER NOT NULL DEFAULT 1,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_parties_currency_code FOREIGN KEY (`currency_code`) REFERENCES `currencies` (`code`),
  CONSTRAINT fk_parties_account_id FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `party_contacts` (
  `id` VARCHAR(191) PRIMARY KEY,
  `party_id` VARCHAR(191) NOT NULL,
  `contact_name` LONGTEXT NOT NULL,
  `job_title` LONGTEXT,
  `phone` LONGTEXT,
  `email` LONGTEXT,
  CONSTRAINT fk_party_contacts_party_id FOREIGN KEY (`party_id`) REFERENCES `parties` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `warehouses` (
  `id` VARCHAR(191) PRIMARY KEY,
  `branch_id` VARCHAR(191) NOT NULL,
  `code` VARCHAR(191) NOT NULL UNIQUE,
  `name_ar` VARCHAR(255) NOT NULL,
  `name_en` VARCHAR(255) NOT NULL,
  `address` LONGTEXT,
  `is_damaged_stock` INTEGER NOT NULL DEFAULT 0,
  `is_active` INTEGER NOT NULL DEFAULT 1,
  CONSTRAINT fk_warehouses_branch_id FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `journal_entries` (
  `id` VARCHAR(191) PRIMARY KEY,
  `entry_number` VARCHAR(255) NOT NULL UNIQUE,
  `doc_type` VARCHAR(255) NOT NULL,
  `doc_id` VARCHAR(191),
  `doc_number` LONGTEXT,
  `entry_date` DATE NOT NULL,
  `posting_date` DATE NOT NULL,
  `fiscal_period_id` VARCHAR(191) NOT NULL,
  `branch_id` VARCHAR(191) NOT NULL,
  `status` VARCHAR(255) NOT NULL DEFAULT 'posted',
  `description` LONGTEXT NOT NULL,
  `total_debit` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `total_credit` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `currency_code` VARCHAR(191) NOT NULL DEFAULT 'EGP',
  `exchange_rate` DECIMAL(24,8) NOT NULL DEFAULT 1.0,
  `reversed_entry_id` VARCHAR(191),
  `is_system_generated` INTEGER NOT NULL DEFAULT 0,
  `created_by` LONGTEXT NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `posted_by` LONGTEXT,
  `posted_at` DATETIME,
  INDEX `idx_je_date` (entry_date),
  INDEX `idx_je_status` (status),
  INDEX `idx_je_doc` (doc_type, doc_id),
  CONSTRAINT fk_journal_entries_fiscal_period_id FOREIGN KEY (`fiscal_period_id`) REFERENCES `fiscal_periods` (`id`),
  CONSTRAINT fk_journal_entries_branch_id FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  CONSTRAINT fk_journal_entries_currency_code FOREIGN KEY (`currency_code`) REFERENCES `currencies` (`code`),
  CONSTRAINT fk_journal_entries_reversed_entry_id FOREIGN KEY (`reversed_entry_id`) REFERENCES `journal_entries` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `journal_entry_lines` (
  `id` VARCHAR(191) PRIMARY KEY,
  `entry_id` VARCHAR(191) NOT NULL,
  `line_number` INTEGER NOT NULL,
  `account_id` VARCHAR(191) NOT NULL,
  `party_id` VARCHAR(191),
  `cost_center_id` VARCHAR(191),
  `debit` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `credit` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `description` LONGTEXT,
  `currency_code` VARCHAR(191) NOT NULL DEFAULT 'EGP',
  `exchange_rate` DECIMAL(24,8) NOT NULL DEFAULT 1.0,
  `amount_currency` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_jel_account` (account_id),
  INDEX `idx_jel_party` (party_id),
  INDEX `idx_jel_entry` (entry_id),
  CONSTRAINT fk_journal_entry_lines_entry_id FOREIGN KEY (`entry_id`) REFERENCES `journal_entries` (`id`) ON DELETE CASCADE,
  CONSTRAINT fk_journal_entry_lines_account_id FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`),
  CONSTRAINT fk_journal_entry_lines_party_id FOREIGN KEY (`party_id`) REFERENCES `parties` (`id`),
  CONSTRAINT fk_journal_entry_lines_cost_center_id FOREIGN KEY (`cost_center_id`) REFERENCES `cost_centers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `sales_invoices` (
  `id` VARCHAR(191) PRIMARY KEY,
  `invoice_number` VARCHAR(255) NOT NULL UNIQUE,
  `branch_id` VARCHAR(191) NOT NULL,
  `warehouse_id` VARCHAR(191) NOT NULL,
  `customer_id` VARCHAR(191) NOT NULL,
  `invoice_date` DATE NOT NULL,
  `due_date` DATE NOT NULL,
  `payment_type` VARCHAR(255) NOT NULL,
  `currency_code` VARCHAR(191) NOT NULL DEFAULT 'EGP',
  `exchange_rate` DECIMAL(24,8) NOT NULL DEFAULT 1.0,
  `subtotal` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `discount_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `taxable_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `tax_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `withholding_tax_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `total_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `paid_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `remaining_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `cogs_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `status` VARCHAR(255) NOT NULL DEFAULT 'posted',
  `notes` LONGTEXT,
  `journal_entry_id` VARCHAR(191),
  `eta_uuid` LONGTEXT,
  `eta_submission_id` VARCHAR(191),
  `eta_status` VARCHAR(255) DEFAULT 'NotSubmitted',
  `created_by` LONGTEXT NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_sales_invoices_branch_id FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  CONSTRAINT fk_sales_invoices_warehouse_id FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`),
  CONSTRAINT fk_sales_invoices_customer_id FOREIGN KEY (`customer_id`) REFERENCES `parties` (`id`),
  CONSTRAINT fk_sales_invoices_currency_code FOREIGN KEY (`currency_code`) REFERENCES `currencies` (`code`),
  CONSTRAINT fk_sales_invoices_journal_entry_id FOREIGN KEY (`journal_entry_id`) REFERENCES `journal_entries` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `sales_returns` (
  `id` VARCHAR(191) PRIMARY KEY,
  `return_number` VARCHAR(255) NOT NULL UNIQUE,
  `original_invoice_id` VARCHAR(191),
  `branch_id` VARCHAR(191) NOT NULL,
  `warehouse_id` VARCHAR(191) NOT NULL,
  `customer_id` VARCHAR(191) NOT NULL,
  `return_date` DATE NOT NULL,
  `refund_type` VARCHAR(255) NOT NULL,
  `subtotal` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `tax_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `withholding_tax_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `total_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `refunded_cash_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `cogs_reversed_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `journal_entry_id` VARCHAR(191),
  `status` VARCHAR(255) NOT NULL DEFAULT 'posted',
  `notes` LONGTEXT,
  `created_by` LONGTEXT NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_sales_returns_original_invoice_id FOREIGN KEY (`original_invoice_id`) REFERENCES `sales_invoices` (`id`),
  CONSTRAINT fk_sales_returns_branch_id FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  CONSTRAINT fk_sales_returns_warehouse_id FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`),
  CONSTRAINT fk_sales_returns_customer_id FOREIGN KEY (`customer_id`) REFERENCES `parties` (`id`),
  CONSTRAINT fk_sales_returns_journal_entry_id FOREIGN KEY (`journal_entry_id`) REFERENCES `journal_entries` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `purchase_invoices` (
  `id` VARCHAR(191) PRIMARY KEY,
  `invoice_number` VARCHAR(255) NOT NULL UNIQUE,
  `supplier_invoice_number` LONGTEXT,
  `branch_id` VARCHAR(191) NOT NULL,
  `warehouse_id` VARCHAR(191) NOT NULL,
  `supplier_id` VARCHAR(191) NOT NULL,
  `invoice_date` DATE NOT NULL,
  `due_date` DATE NOT NULL,
  `payment_type` VARCHAR(255) NOT NULL,
  `currency_code` VARCHAR(191) NOT NULL DEFAULT 'EGP',
  `exchange_rate` DECIMAL(24,8) NOT NULL DEFAULT 1.0,
  `subtotal` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `discount_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `taxable_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `tax_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `withholding_tax_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `additional_expenses` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `total_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `paid_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `remaining_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `status` VARCHAR(255) NOT NULL DEFAULT 'posted',
  `notes` LONGTEXT,
  `journal_entry_id` VARCHAR(191),
  `created_by` LONGTEXT NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_purchase_invoices_branch_id FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  CONSTRAINT fk_purchase_invoices_warehouse_id FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`),
  CONSTRAINT fk_purchase_invoices_supplier_id FOREIGN KEY (`supplier_id`) REFERENCES `parties` (`id`),
  CONSTRAINT fk_purchase_invoices_currency_code FOREIGN KEY (`currency_code`) REFERENCES `currencies` (`code`),
  CONSTRAINT fk_purchase_invoices_journal_entry_id FOREIGN KEY (`journal_entry_id`) REFERENCES `journal_entries` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `purchase_returns` (
  `id` VARCHAR(191) PRIMARY KEY,
  `return_number` VARCHAR(255) NOT NULL UNIQUE,
  `original_invoice_id` VARCHAR(191),
  `branch_id` VARCHAR(191) NOT NULL,
  `warehouse_id` VARCHAR(191) NOT NULL,
  `supplier_id` VARCHAR(191) NOT NULL,
  `return_date` DATE NOT NULL,
  `subtotal` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `tax_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `withholding_tax_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `total_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `journal_entry_id` VARCHAR(191),
  `status` VARCHAR(255) NOT NULL DEFAULT 'posted',
  `notes` LONGTEXT,
  `created_by` LONGTEXT NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_purchase_returns_original_invoice_id FOREIGN KEY (`original_invoice_id`) REFERENCES `purchase_invoices` (`id`),
  CONSTRAINT fk_purchase_returns_branch_id FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  CONSTRAINT fk_purchase_returns_warehouse_id FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`),
  CONSTRAINT fk_purchase_returns_supplier_id FOREIGN KEY (`supplier_id`) REFERENCES `parties` (`id`),
  CONSTRAINT fk_purchase_returns_journal_entry_id FOREIGN KEY (`journal_entry_id`) REFERENCES `journal_entries` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `cash_boxes` (
  `id` VARCHAR(191) PRIMARY KEY,
  `branch_id` VARCHAR(191) NOT NULL,
  `code` VARCHAR(191) NOT NULL UNIQUE,
  `name_ar` VARCHAR(255) NOT NULL,
  `name_en` VARCHAR(255) NOT NULL,
  `account_id` VARCHAR(191) NOT NULL,
  `currency_code` VARCHAR(191) NOT NULL DEFAULT 'EGP',
  `current_balance` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `is_active` INTEGER NOT NULL DEFAULT 1,
  CONSTRAINT fk_cash_boxes_branch_id FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  CONSTRAINT fk_cash_boxes_account_id FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`),
  CONSTRAINT fk_cash_boxes_currency_code FOREIGN KEY (`currency_code`) REFERENCES `currencies` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `bank_accounts` (
  `id` VARCHAR(191) PRIMARY KEY,
  `bank_name` LONGTEXT NOT NULL,
  `account_number` LONGTEXT NOT NULL,
  `iban` LONGTEXT,
  `swift_code` LONGTEXT,
  `branch_name` LONGTEXT,
  `account_id` VARCHAR(191) NOT NULL,
  `currency_code` VARCHAR(191) NOT NULL DEFAULT 'EGP',
  `current_balance` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `is_active` INTEGER NOT NULL DEFAULT 1,
  CONSTRAINT fk_bank_accounts_account_id FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`),
  CONSTRAINT fk_bank_accounts_currency_code FOREIGN KEY (`currency_code`) REFERENCES `currencies` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `payment_vouchers` (
  `id` VARCHAR(191) PRIMARY KEY,
  `voucher_number` VARCHAR(255) NOT NULL UNIQUE,
  `voucher_type` VARCHAR(255) NOT NULL,
  `branch_id` VARCHAR(191) NOT NULL,
  `payment_method` LONGTEXT NOT NULL,
  `cash_box_id` VARCHAR(191),
  `bank_account_id` VARCHAR(191),
  `party_id` VARCHAR(191),
  `direct_account_id` VARCHAR(191),
  `cost_center_id` VARCHAR(191),
  `voucher_date` DATE NOT NULL,
  `amount` DECIMAL(24,8) NOT NULL,
  `currency_code` VARCHAR(191) NOT NULL DEFAULT 'EGP',
  `exchange_rate` DECIMAL(24,8) NOT NULL DEFAULT 1.0,
  `allocated_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `unallocated_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `notes` LONGTEXT,
  `description` LONGTEXT NOT NULL,
  `journal_entry_id` VARCHAR(191),
  `status` VARCHAR(255) NOT NULL DEFAULT 'posted',
  `created_by` LONGTEXT NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_payment_vouchers_branch_id FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  CONSTRAINT fk_payment_vouchers_cash_box_id FOREIGN KEY (`cash_box_id`) REFERENCES `cash_boxes` (`id`),
  CONSTRAINT fk_payment_vouchers_bank_account_id FOREIGN KEY (`bank_account_id`) REFERENCES `bank_accounts` (`id`),
  CONSTRAINT fk_payment_vouchers_party_id FOREIGN KEY (`party_id`) REFERENCES `parties` (`id`),
  CONSTRAINT fk_payment_vouchers_direct_account_id FOREIGN KEY (`direct_account_id`) REFERENCES `accounts` (`id`),
  CONSTRAINT fk_payment_vouchers_cost_center_id FOREIGN KEY (`cost_center_id`) REFERENCES `cost_centers` (`id`),
  CONSTRAINT fk_payment_vouchers_currency_code FOREIGN KEY (`currency_code`) REFERENCES `currencies` (`code`),
  CONSTRAINT fk_payment_vouchers_journal_entry_id FOREIGN KEY (`journal_entry_id`) REFERENCES `journal_entries` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `voucher_allocations` (
  `id` VARCHAR(191) PRIMARY KEY,
  `voucher_id` VARCHAR(191) NOT NULL,
  `invoice_type` LONGTEXT NOT NULL,
  `invoice_id` VARCHAR(191) NOT NULL,
  `allocated_amount` DECIMAL(24,8) NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_voucher_allocations_voucher_id FOREIGN KEY (`voucher_id`) REFERENCES `payment_vouchers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `cheques` (
  `id` VARCHAR(191) PRIMARY KEY,
  `cheque_number` LONGTEXT NOT NULL,
  `cheque_type` VARCHAR(255) NOT NULL,
  `bank_name` LONGTEXT NOT NULL,
  `branch_id` VARCHAR(191) NOT NULL,
  `party_id` VARCHAR(191) NOT NULL,
  `amount` DECIMAL(24,8) NOT NULL,
  `due_date` DATE NOT NULL,
  `status` VARCHAR(255) NOT NULL DEFAULT 'in_portfolio',
  `deposit_bank_id` VARCHAR(191),
  `collection_date` DATE,
  `bounce_date` DATE,
  `bounce_reason` LONGTEXT,
  `journal_entry_id` VARCHAR(191),
  `notes` LONGTEXT,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_cheques_branch_id FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  CONSTRAINT fk_cheques_party_id FOREIGN KEY (`party_id`) REFERENCES `parties` (`id`),
  CONSTRAINT fk_cheques_deposit_bank_id FOREIGN KEY (`deposit_bank_id`) REFERENCES `bank_accounts` (`id`),
  CONSTRAINT fk_cheques_journal_entry_id FOREIGN KEY (`journal_entry_id`) REFERENCES `journal_entries` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `stock_transactions` (
  `id` VARCHAR(191) PRIMARY KEY,
  `trans_number` VARCHAR(255) NOT NULL UNIQUE,
  `trans_type` VARCHAR(255) NOT NULL,
  `branch_id` VARCHAR(191) NOT NULL,
  `from_warehouse_id` VARCHAR(191),
  `to_warehouse_id` VARCHAR(191),
  `trans_date` DATE NOT NULL,
  `notes` LONGTEXT,
  `journal_entry_id` VARCHAR(191),
  `status` VARCHAR(255) NOT NULL DEFAULT 'posted',
  `created_by` LONGTEXT NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_stock_transactions_branch_id FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  CONSTRAINT fk_stock_transactions_from_warehouse_id FOREIGN KEY (`from_warehouse_id`) REFERENCES `warehouses` (`id`),
  CONSTRAINT fk_stock_transactions_to_warehouse_id FOREIGN KEY (`to_warehouse_id`) REFERENCES `warehouses` (`id`),
  CONSTRAINT fk_stock_transactions_journal_entry_id FOREIGN KEY (`journal_entry_id`) REFERENCES `journal_entries` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `fixed_assets` (
  `id` VARCHAR(191) PRIMARY KEY,
  `code` VARCHAR(191) NOT NULL UNIQUE,
  `name_ar` VARCHAR(255) NOT NULL,
  `name_en` VARCHAR(255) NOT NULL,
  `branch_id` VARCHAR(191) NOT NULL,
  `cost_center_id` VARCHAR(191),
  `purchase_date` DATE NOT NULL,
  `operation_date` DATE NOT NULL,
  `purchase_cost` DECIMAL(24,8) NOT NULL,
  `scrap_value` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `useful_life_years` DECIMAL(24,8) NOT NULL,
  `depreciation_method` VARCHAR(255) NOT NULL DEFAULT 'straight_line',
  `annual_depreciation_rate` DECIMAL(24,8) NOT NULL,
  `accumulated_depreciation` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `book_value` DECIMAL(24,8) NOT NULL,
  `asset_account_id` VARCHAR(191) NOT NULL,
  `depreciation_expense_account_id` VARCHAR(191) NOT NULL,
  `accumulated_depreciation_account_id` VARCHAR(191) NOT NULL,
  `status` VARCHAR(255) NOT NULL DEFAULT 'active',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_fixed_assets_branch_id FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  CONSTRAINT fk_fixed_assets_cost_center_id FOREIGN KEY (`cost_center_id`) REFERENCES `cost_centers` (`id`),
  CONSTRAINT fk_fixed_assets_asset_account_id FOREIGN KEY (`asset_account_id`) REFERENCES `accounts` (`id`),
  CONSTRAINT fk_fixed_assets_depreciation_expense_acco FOREIGN KEY (`depreciation_expense_account_id`) REFERENCES `accounts` (`id`),
  CONSTRAINT fk_fixed_assets_accumulated_depreciation_ FOREIGN KEY (`accumulated_depreciation_account_id`) REFERENCES `accounts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `fixed_asset_depreciations` (
  `id` VARCHAR(191) PRIMARY KEY,
  `asset_id` VARCHAR(191) NOT NULL,
  `depreciation_date` DATE NOT NULL,
  `amount` DECIMAL(24,8) NOT NULL,
  `journal_entry_id` VARCHAR(191),
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(asset_id, depreciation_date),
  CONSTRAINT fk_fixed_asset_depreciations_asset_id FOREIGN KEY (`asset_id`) REFERENCES `fixed_assets` (`id`),
  CONSTRAINT fk_fixed_asset_depreciations_journal_entry_id FOREIGN KEY (`journal_entry_id`) REFERENCES `journal_entries` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `users` (
  `id` VARCHAR(191) PRIMARY KEY,
  `username` VARCHAR(255) NOT NULL UNIQUE,
  `password_hash` LONGTEXT NOT NULL,
  `display_name` LONGTEXT NOT NULL,
  `role` VARCHAR(255) NOT NULL,
  `is_active` INTEGER NOT NULL DEFAULT 1,
  `force_change_password` INTEGER NOT NULL DEFAULT 0,
  `allowed_branch_ids` LONGTEXT,
  `allowed_warehouse_ids` LONGTEXT,
  `allowed_cashbox_ids` LONGTEXT,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `user_permissions` (
  `id` VARCHAR(191) PRIMARY KEY,
  `role` VARCHAR(255) NOT NULL,
  `permission_key` VARCHAR(255) NOT NULL,
  UNIQUE(role, permission_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `audit_logs` (
  `id` VARCHAR(191) PRIMARY KEY,
  `user_id` VARCHAR(191) NOT NULL,
  `action` VARCHAR(255) NOT NULL,
  `entity_type` VARCHAR(255) NOT NULL,
  `entity_id` VARCHAR(191) NOT NULL,
  `details` LONGTEXT,
  `old_values` LONGTEXT,
  `new_values` LONGTEXT,
  `ip_address` LONGTEXT,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_audit_time` (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `eta_submissions` (
  `id` VARCHAR(191) PRIMARY KEY,
  `invoice_id` VARCHAR(191) NOT NULL,
  `submission_uuid` VARCHAR(255) NOT NULL UNIQUE,
  `eta_document_id` VARCHAR(191),
  `submission_date` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `status` VARCHAR(255) NOT NULL,
  `eta_code` LONGTEXT,
  `error_details` LONGTEXT,
  `hash_signature` LONGTEXT,
  `json_payload` LONGTEXT,
  CONSTRAINT fk_eta_submissions_invoice_id FOREIGN KEY (`invoice_id`) REFERENCES `sales_invoices` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `period_closings` (
  `id` VARCHAR(191) PRIMARY KEY,
  `period_id` VARCHAR(191) NOT NULL,
  `closed_by` LONGTEXT NOT NULL,
  `closed_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `notes` LONGTEXT,
  `summary_json` LONGTEXT NOT NULL,
  CONSTRAINT fk_period_closings_period_id FOREIGN KEY (`period_id`) REFERENCES `fiscal_periods` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `period_reopen_logs` (
  `id` VARCHAR(191) PRIMARY KEY,
  `period_id` VARCHAR(191) NOT NULL,
  `reopened_by` LONGTEXT NOT NULL,
  `reopened_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `reason` LONGTEXT NOT NULL,
  `previous_status` VARCHAR(255) NOT NULL DEFAULT 'closed',
  CONSTRAINT fk_period_reopen_logs_period_id FOREIGN KEY (`period_id`) REFERENCES `fiscal_periods` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `bank_statements` (
  `id` VARCHAR(191) PRIMARY KEY,
  `bank_account_id` VARCHAR(191) NOT NULL,
  `statement_date` DATE NOT NULL,
  `opening_balance` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `closing_balance` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `filename` LONGTEXT,
  `imported_by` LONGTEXT NOT NULL,
  `imported_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_bank_statements_bank_account_id FOREIGN KEY (`bank_account_id`) REFERENCES `bank_accounts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `bank_statement_lines` (
  `id` VARCHAR(191) PRIMARY KEY,
  `statement_id` VARCHAR(191) NOT NULL,
  `bank_account_id` VARCHAR(191) NOT NULL,
  `line_date` DATE NOT NULL,
  `reference` LONGTEXT,
  `description` LONGTEXT NOT NULL,
  `debit` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `credit` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `is_matched` INTEGER NOT NULL DEFAULT 0,
  `matched_voucher_id` VARCHAR(191),
  `matched_journal_line_id` VARCHAR(191),
  `matched_at` DATETIME,
  `matched_by` LONGTEXT,
  CONSTRAINT fk_bank_statement_lines_statement_id FOREIGN KEY (`statement_id`) REFERENCES `bank_statements` (`id`) ON DELETE CASCADE,
  CONSTRAINT fk_bank_statement_lines_bank_account_id FOREIGN KEY (`bank_account_id`) REFERENCES `bank_accounts` (`id`),
  CONSTRAINT fk_bank_statement_lines_matched_voucher_id FOREIGN KEY (`matched_voucher_id`) REFERENCES `payment_vouchers` (`id`),
  CONSTRAINT fk_bank_statement_lines_matched_journal_line_id FOREIGN KEY (`matched_journal_line_id`) REFERENCES `journal_entry_lines` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `bank_reconciliations` (
  `id` VARCHAR(191) PRIMARY KEY,
  `bank_account_id` VARCHAR(191) NOT NULL,
  `period_id` VARCHAR(191) NOT NULL,
  `reconciliation_date` DATE NOT NULL,
  `statement_balance` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `book_balance` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `adjusted_bank_balance` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `adjusted_book_balance` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `variance` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `status` VARCHAR(255) NOT NULL DEFAULT 'draft',
  `approved_by` LONGTEXT,
  `approved_at` DATETIME,
  `notes` LONGTEXT,
  `created_by` LONGTEXT NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_bank_reconciliations_bank_account_id FOREIGN KEY (`bank_account_id`) REFERENCES `bank_accounts` (`id`),
  CONSTRAINT fk_bank_reconciliations_period_id FOREIGN KEY (`period_id`) REFERENCES `fiscal_periods` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `inventory_counts` (
  `id` VARCHAR(191) PRIMARY KEY,
  `count_number` VARCHAR(255) NOT NULL UNIQUE,
  `branch_id` VARCHAR(191) NOT NULL,
  `warehouse_id` VARCHAR(191) NOT NULL,
  `count_date` DATE NOT NULL,
  `status` VARCHAR(255) NOT NULL DEFAULT 'draft',
  `notes` LONGTEXT,
  `journal_entry_id` VARCHAR(191),
  `stock_transaction_id` VARCHAR(191),
  `total_shortage_cost` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `total_surplus_cost` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `net_variance_cost` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `created_by` LONGTEXT NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `posted_by` LONGTEXT,
  `posted_at` DATETIME,
  CONSTRAINT fk_inventory_counts_branch_id FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  CONSTRAINT fk_inventory_counts_warehouse_id FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`),
  CONSTRAINT fk_inventory_counts_journal_entry_id FOREIGN KEY (`journal_entry_id`) REFERENCES `journal_entries` (`id`),
  CONSTRAINT fk_inventory_counts_stock_transaction_id FOREIGN KEY (`stock_transaction_id`) REFERENCES `stock_transactions` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `excel_imports_log` (
  `id` VARCHAR(191) PRIMARY KEY,
  `import_type` VARCHAR(255) NOT NULL,
  `filename` LONGTEXT NOT NULL,
  `total_rows` INTEGER NOT NULL DEFAULT 0,
  `valid_rows` INTEGER NOT NULL DEFAULT 0,
  `error_rows` INTEGER NOT NULL DEFAULT 0,
  `status` VARCHAR(255) NOT NULL,
  `details_json` LONGTEXT,
  `imported_by` LONGTEXT NOT NULL,
  `imported_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `system_backups` (
  `id` VARCHAR(191) PRIMARY KEY,
  `filename` LONGTEXT NOT NULL,
  `file_path` LONGTEXT NOT NULL,
  `file_size` BIGINT NOT NULL DEFAULT 0,
  `schema_version` VARCHAR(255) NOT NULL DEFAULT '1.0',
  `integrity_status` VARCHAR(255) NOT NULL DEFAULT 'OK',
  `record_counts_json` LONGTEXT NOT NULL,
  `created_by` LONGTEXT NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `individual_permissions` (
  `user_id` VARCHAR(191) PRIMARY KEY,
  `permission_keys` LONGTEXT NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_individual_permissions_user_id FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `user_sessions` (
  `token` VARCHAR(191) PRIMARY KEY,
  `user_id` VARCHAR(191) NOT NULL,
  `expires_at` DATETIME NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_user_sessions_user_id FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `idempotency_keys` (
  `key` VARCHAR(191) PRIMARY KEY,
  `user_id` VARCHAR(191) NOT NULL,
  `endpoint` LONGTEXT NOT NULL,
  `request_hash` LONGTEXT,
  `response_code` INTEGER,
  `response_body` LONGTEXT,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `login_attempts` (
  `ip_or_user` VARCHAR(191) PRIMARY KEY,
  `attempts` INTEGER DEFAULT 0,
  `last_attempt` DATETIME,
  `locked_until` DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `system_settings` (
  `setting_key` VARCHAR(191) PRIMARY KEY,
  `setting_value` LONGTEXT NOT NULL,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `item_categories` (
  `id` VARCHAR(191) PRIMARY KEY,
  `code` VARCHAR(191) NOT NULL UNIQUE,
  `name_ar` VARCHAR(255) NOT NULL,
  `name_en` VARCHAR(255),
  `parent_id` VARCHAR(191),
  `is_active` INTEGER NOT NULL DEFAULT 1,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_item_categories_parent_id FOREIGN KEY (`parent_id`) REFERENCES `item_categories` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `party_sequences` (
  `type` VARCHAR(191) PRIMARY KEY,
  `last_number` INTEGER NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `account_sequences` (
  `sequence_key` VARCHAR(191) PRIMARY KEY,
  `last_number` INTEGER NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `items` (
  `id` VARCHAR(191) PRIMARY KEY,
  `code` VARCHAR(191) NOT NULL UNIQUE,
  `barcode` LONGTEXT,
  `name_ar` VARCHAR(255) NOT NULL,
  `name_en` VARCHAR(255) NOT NULL,
  `item_type` VARCHAR(255) NOT NULL,
  `category` VARCHAR(255) NOT NULL DEFAULT 'عام',
  `base_unit` VARCHAR(255) NOT NULL DEFAULT 'قطعة',
  `cost_price` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `sale_price` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `min_stock_level` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `moving_avg_cost` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `tax_rate` DECIMAL(24,8) NOT NULL DEFAULT 14.0,
  `eta_item_code` LONGTEXT,
  `eta_code_type` VARCHAR(255) DEFAULT 'EGS',
  `is_active` INTEGER NOT NULL DEFAULT 1,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `category_id` VARCHAR(191),
  CONSTRAINT fk_items_category_id FOREIGN KEY (`category_id`) REFERENCES `item_categories` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `item_units` (
  `id` VARCHAR(191) PRIMARY KEY,
  `item_id` VARCHAR(191) NOT NULL,
  `unit_name` VARCHAR(255) NOT NULL,
  `conversion_factor` DECIMAL(24,8) NOT NULL DEFAULT 1.0,
  `sale_price` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `barcode` LONGTEXT,
  `is_base` INTEGER NOT NULL DEFAULT 0,
  UNIQUE(item_id, unit_name),
  CONSTRAINT fk_item_units_item_id FOREIGN KEY (`item_id`) REFERENCES `items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `warehouse_stock` (
  `warehouse_id` VARCHAR(191) NOT NULL,
  `item_id` VARCHAR(191) NOT NULL,
  `quantity` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `reserved_qty` DECIMAL(24,8) NOT NULL DEFAULT 0,
  PRIMARY KEY(warehouse_id, item_id),
  CONSTRAINT fk_warehouse_stock_warehouse_id FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`),
  CONSTRAINT fk_warehouse_stock_item_id FOREIGN KEY (`item_id`) REFERENCES `items` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `sales_invoice_items` (
  `id` VARCHAR(191) PRIMARY KEY,
  `invoice_id` VARCHAR(191) NOT NULL,
  `item_id` VARCHAR(191) NOT NULL,
  `unit_name` VARCHAR(255) NOT NULL,
  `unit_factor` DECIMAL(24,8) NOT NULL DEFAULT 1.0,
  `quantity` DECIMAL(24,8) NOT NULL,
  `returned_quantity` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `unit_price` DECIMAL(24,8) NOT NULL,
  `cost_price` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `discount_percent` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `discount_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `tax_rate` DECIMAL(24,8) NOT NULL DEFAULT 14.0,
  `tax_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `total_amount` DECIMAL(24,8) NOT NULL,
  CONSTRAINT fk_sales_invoice_items_invoice_id FOREIGN KEY (`invoice_id`) REFERENCES `sales_invoices` (`id`) ON DELETE CASCADE,
  CONSTRAINT fk_sales_invoice_items_item_id FOREIGN KEY (`item_id`) REFERENCES `items` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `sales_return_items` (
  `id` VARCHAR(191) PRIMARY KEY,
  `return_id` VARCHAR(191) NOT NULL,
  `original_invoice_item_id` VARCHAR(191),
  `item_id` VARCHAR(191) NOT NULL,
  `unit_name` VARCHAR(255) NOT NULL,
  `unit_factor` DECIMAL(24,8) NOT NULL DEFAULT 1.0,
  `quantity` DECIMAL(24,8) NOT NULL,
  `unit_price` DECIMAL(24,8) NOT NULL,
  `unit_cost` DECIMAL(24,8) NOT NULL,
  `tax_rate` DECIMAL(24,8) NOT NULL DEFAULT 14.0,
  `tax_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `total_amount` DECIMAL(24,8) NOT NULL,
  CONSTRAINT fk_sales_return_items_return_id FOREIGN KEY (`return_id`) REFERENCES `sales_returns` (`id`) ON DELETE CASCADE,
  CONSTRAINT fk_sales_return_items_original_invoice_item_id FOREIGN KEY (`original_invoice_item_id`) REFERENCES `sales_invoice_items` (`id`),
  CONSTRAINT fk_sales_return_items_item_id FOREIGN KEY (`item_id`) REFERENCES `items` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `purchase_invoice_items` (
  `id` VARCHAR(191) PRIMARY KEY,
  `invoice_id` VARCHAR(191) NOT NULL,
  `item_id` VARCHAR(191) NOT NULL,
  `unit_name` VARCHAR(255) NOT NULL,
  `unit_factor` DECIMAL(24,8) NOT NULL DEFAULT 1.0,
  `quantity` DECIMAL(24,8) NOT NULL,
  `returned_quantity` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `unit_price` DECIMAL(24,8) NOT NULL,
  `discount_percent` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `discount_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `tax_rate` DECIMAL(24,8) NOT NULL DEFAULT 14.0,
  `tax_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `total_amount` DECIMAL(24,8) NOT NULL,
  CONSTRAINT fk_purchase_invoice_items_invoice_id FOREIGN KEY (`invoice_id`) REFERENCES `purchase_invoices` (`id`) ON DELETE CASCADE,
  CONSTRAINT fk_purchase_invoice_items_item_id FOREIGN KEY (`item_id`) REFERENCES `items` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `purchase_return_items` (
  `id` VARCHAR(191) PRIMARY KEY,
  `return_id` VARCHAR(191) NOT NULL,
  `item_id` VARCHAR(191) NOT NULL,
  `quantity` DECIMAL(24,8) NOT NULL,
  `unit_price` DECIMAL(24,8) NOT NULL,
  `tax_rate` DECIMAL(24,8) NOT NULL DEFAULT 14.0,
  `tax_amount` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `total_amount` DECIMAL(24,8) NOT NULL,
  `original_invoice_item_id` VARCHAR(191),
  CONSTRAINT fk_purchase_return_items_return_id FOREIGN KEY (`return_id`) REFERENCES `purchase_returns` (`id`) ON DELETE CASCADE,
  CONSTRAINT fk_purchase_return_items_item_id FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  CONSTRAINT fk_purchase_return_items_original_invoice_item_id FOREIGN KEY (`original_invoice_item_id`) REFERENCES `purchase_invoice_items` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `stock_transaction_items` (
  `id` VARCHAR(191) PRIMARY KEY,
  `transaction_id` VARCHAR(191) NOT NULL,
  `item_id` VARCHAR(191) NOT NULL,
  `quantity` DECIMAL(24,8) NOT NULL,
  `unit_cost` DECIMAL(24,8) NOT NULL,
  `total_cost` DECIMAL(24,8) NOT NULL,
  `batch_number` LONGTEXT,
  `expiry_date` DATE,
  CONSTRAINT fk_stock_transaction_items_transaction_id FOREIGN KEY (`transaction_id`) REFERENCES `stock_transactions` (`id`) ON DELETE CASCADE,
  CONSTRAINT fk_stock_transaction_items_item_id FOREIGN KEY (`item_id`) REFERENCES `items` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `inventory_count_items` (
  `id` VARCHAR(191) PRIMARY KEY,
  `count_id` VARCHAR(191) NOT NULL,
  `item_id` VARCHAR(191) NOT NULL,
  `system_quantity` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `counted_quantity` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `diff_quantity` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `unit_cost` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `total_diff_cost` DECIMAL(24,8) NOT NULL DEFAULT 0,
  `notes` LONGTEXT,
  CONSTRAINT fk_inventory_count_items_count_id FOREIGN KEY (`count_id`) REFERENCES `inventory_counts` (`id`) ON DELETE CASCADE,
  CONSTRAINT fk_inventory_count_items_item_id FOREIGN KEY (`item_id`) REFERENCES `items` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
