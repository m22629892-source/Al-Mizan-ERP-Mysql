-- Al-Mizan ERP DEMO ONLY. Run on a NEW database. Demo owner: owner / admin123.
-- No real customer data is included.
CREATE DATABASE IF NOT EXISTS almizan CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE almizan;
SET NAMES utf8mb4;
SET time_zone = '+00:00';

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

START TRANSACTION;
INSERT INTO `companies` (`id`,`name_ar`,`name_en`,`legal_name`,`commercial_registry`,`tax_id`,`vat_number`,`activity_code`,`address_ar`,`address_en`,`city`,`country`,`postal_code`,`phone`,`email`,`website`,`logo_url`,`currency_code`,`created_at`,`updated_at`) VALUES ('comp_al_mizan','شركة الميزان للتجارة والتوريدات ش.م.م','Al-Mizan Commercial Trading S.A.E','شركة الميزان للتجارة والتوريدات المساهمة المصرية','189452','458-921-364','EG458921364','4690','15 شارع مكرم عبيد، المنطقة السادسة، مدينة نصر، القاهرة','15 Makram Ebeid St, 6th District, Nasr City, Cairo','القاهرة','مصر','11765','+20 2 22718900','info@almizan-erp.eg','https://almizan-erp.eg',NULL,'EGP','2026-11-05 20:40:18','2026-11-05 20:40:18');
INSERT INTO `branches` (`id`,`company_id`,`code`,`name_ar`,`name_en`,`address`,`phone`,`is_active`,`created_at`) VALUES ('br_alex','comp_al_mizan','ALX','فرع الإسكندرية (سموحة)','Alexandria Branch','شارع فوزي معاذ، سموحة، الإسكندرية','+20 3 4298100',1,'2026-11-05 20:40:18');
INSERT INTO `branches` (`id`,`company_id`,`code`,`name_ar`,`name_en`,`address`,`phone`,`is_active`,`created_at`) VALUES ('br_cairo','comp_al_mizan','CAI','الفرع الرئيسي - القاهرة (مدينة نصر)','Cairo Main Branch','15 شارع مكرم عبيد، مدينة نصر','+20 2 22718901',1,'2026-11-05 20:40:18');
INSERT INTO `fiscal_years` (`id`,`code`,`name_ar`,`name_en`,`start_date`,`end_date`,`is_closed`,`closed_at`,`closed_by`) VALUES ('fy_2026','2026','السنة المالية 2026','Fiscal Year 2026','2026-01-01','2026-12-31',0,NULL,NULL);
INSERT INTO `fiscal_periods` (`id`,`fiscal_year_id`,`period_number`,`name_ar`,`name_en`,`start_date`,`end_date`,`is_closed`,`closed_at`,`closed_by`) VALUES ('fp_2026_01','fy_2026',1,'فترة يناير 2026','Period January 2026','2026-01-01','2026-01-31',0,NULL,NULL);
INSERT INTO `fiscal_periods` (`id`,`fiscal_year_id`,`period_number`,`name_ar`,`name_en`,`start_date`,`end_date`,`is_closed`,`closed_at`,`closed_by`) VALUES ('fp_2026_02','fy_2026',2,'فترة فبراير 2026','Period February 2026','2026-02-01','2026-02-28',0,NULL,NULL);
INSERT INTO `fiscal_periods` (`id`,`fiscal_year_id`,`period_number`,`name_ar`,`name_en`,`start_date`,`end_date`,`is_closed`,`closed_at`,`closed_by`) VALUES ('fp_2026_03','fy_2026',3,'فترة مارس 2026','Period March 2026','2026-03-01','2026-03-31',0,NULL,NULL);
INSERT INTO `fiscal_periods` (`id`,`fiscal_year_id`,`period_number`,`name_ar`,`name_en`,`start_date`,`end_date`,`is_closed`,`closed_at`,`closed_by`) VALUES ('fp_2026_04','fy_2026',4,'فترة أبريل 2026','Period April 2026','2026-04-01','2026-04-30',0,NULL,NULL);
INSERT INTO `fiscal_periods` (`id`,`fiscal_year_id`,`period_number`,`name_ar`,`name_en`,`start_date`,`end_date`,`is_closed`,`closed_at`,`closed_by`) VALUES ('fp_2026_05','fy_2026',5,'فترة مايو 2026','Period May 2026','2026-05-01','2026-05-31',0,NULL,NULL);
INSERT INTO `fiscal_periods` (`id`,`fiscal_year_id`,`period_number`,`name_ar`,`name_en`,`start_date`,`end_date`,`is_closed`,`closed_at`,`closed_by`) VALUES ('fp_2026_06','fy_2026',6,'فترة يونيو 2026','Period June 2026','2026-06-01','2026-06-30',0,NULL,NULL);
INSERT INTO `fiscal_periods` (`id`,`fiscal_year_id`,`period_number`,`name_ar`,`name_en`,`start_date`,`end_date`,`is_closed`,`closed_at`,`closed_by`) VALUES ('fp_2026_07','fy_2026',7,'فترة يوليو 2026','Period July 2026','2026-07-01','2026-07-31',0,NULL,NULL);
INSERT INTO `fiscal_periods` (`id`,`fiscal_year_id`,`period_number`,`name_ar`,`name_en`,`start_date`,`end_date`,`is_closed`,`closed_at`,`closed_by`) VALUES ('fp_2026_08','fy_2026',8,'فترة أغسطس 2026','Period August 2026','2026-08-01','2026-08-31',0,NULL,NULL);
INSERT INTO `fiscal_periods` (`id`,`fiscal_year_id`,`period_number`,`name_ar`,`name_en`,`start_date`,`end_date`,`is_closed`,`closed_at`,`closed_by`) VALUES ('fp_2026_09','fy_2026',9,'فترة سبتمبر 2026','Period September 2026','2026-09-01','2026-09-30',0,NULL,NULL);
INSERT INTO `fiscal_periods` (`id`,`fiscal_year_id`,`period_number`,`name_ar`,`name_en`,`start_date`,`end_date`,`is_closed`,`closed_at`,`closed_by`) VALUES ('fp_2026_10','fy_2026',10,'فترة أكتوبر 2026','Period October 2026','2026-10-01','2026-10-31',0,NULL,NULL);
INSERT INTO `fiscal_periods` (`id`,`fiscal_year_id`,`period_number`,`name_ar`,`name_en`,`start_date`,`end_date`,`is_closed`,`closed_at`,`closed_by`) VALUES ('fp_2026_11','fy_2026',11,'فترة نوفمبر 2026','Period November 2026','2026-11-01','2026-11-30',0,NULL,NULL);
INSERT INTO `fiscal_periods` (`id`,`fiscal_year_id`,`period_number`,`name_ar`,`name_en`,`start_date`,`end_date`,`is_closed`,`closed_at`,`closed_by`) VALUES ('fp_2026_12','fy_2026',12,'فترة ديسمبر 2026','Period December 2026','2026-12-01','2026-12-31',0,NULL,NULL);
INSERT INTO `currencies` (`code`,`name_ar`,`name_en`,`symbol`,`decimal_places`,`is_base`) VALUES ('EGP','الجنيه المصري','Egyptian Pound','ج.م',2,1);
INSERT INTO `currencies` (`code`,`name_ar`,`name_en`,`symbol`,`decimal_places`,`is_base`) VALUES ('EUR','اليورو الأوروبي','Euro','€',2,0);
INSERT INTO `currencies` (`code`,`name_ar`,`name_en`,`symbol`,`decimal_places`,`is_base`) VALUES ('SAR','الريال السعودي','Saudi Riyal','ر.س',2,0);
INSERT INTO `currencies` (`code`,`name_ar`,`name_en`,`symbol`,`decimal_places`,`is_base`) VALUES ('USD','الدولار الأمريكي','US Dollar','$',2,0);
INSERT INTO `exchange_rates` (`id`,`currency_code`,`rate`,`rate_date`,`created_at`) VALUES ('rate_eur_2026','EUR',52.2,'2026-01-01','2026-11-05 20:40:18');
INSERT INTO `exchange_rates` (`id`,`currency_code`,`rate`,`rate_date`,`created_at`) VALUES ('rate_sar_2026','SAR',12.92,'2026-01-01','2026-11-05 20:40:18');
INSERT INTO `exchange_rates` (`id`,`currency_code`,`rate`,`rate_date`,`created_at`) VALUES ('rate_usd_2026','USD',48.5,'2026-01-01','2026-11-05 20:40:18');
INSERT INTO `cost_centers` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`is_active`) VALUES ('cc_admin','CC-101','الإدارة العامة والمكتب التنفيذي','General Administration',NULL,1);
INSERT INTO `cost_centers` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`is_active`) VALUES ('cc_sales','CC-201','قطاع المبيعات والتسويق','Sales & Marketing',NULL,1);
INSERT INTO `cost_centers` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`is_active`) VALUES ('cc_tech','CC-401','إدارة تقنية المعلومات والدعم الفني','IT & Support',NULL,1);
INSERT INTO `cost_centers` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`is_active`) VALUES ('cc_warehouses','CC-301','إدارة المخازن واللوجستيات','Warehousing & Logistics',NULL,1);
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_1','1','الأصول','Assets',NULL,'asset','debit',1,1,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_11','11','الأصول المتداولة','Current Assets','acc_1','asset','debit',1,2,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_111','111','النقدية وما في حكمها','Cash and Cash Equivalents','acc_11','asset','debit',1,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_1111','1111','خزينة المركز الرئيسي - القاهرة','Cairo Main Cash Box','acc_111','asset','debit',0,4,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_1112','1112','خزينة فرع الإسكندرية','Alexandria Cash Box','acc_111','asset','debit',0,4,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_1113','1113','البنك الأهلي المصري (حساب جاري بالجنيه)','National Bank of Egypt (EGP)','acc_111','asset','debit',0,4,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_1114','1114','بنك مصر (حساب جاري بالدولار)','Banque Misr (USD)','acc_111','asset','debit',0,4,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_112','112','العملاء والمدينون','Accounts Receivable','acc_11','asset','debit',1,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_1121','1121','العملاء التجاريون (حساب الرقابة العام)','Trade Debtors Control Account','acc_112','asset','debit',0,4,NULL,1,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_1122','1122','عملاء التوزيع والتجزئة','Retail Debtors','acc_112','asset','debit',0,4,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_113','113','أوراق القبض','Notes Receivable','acc_11','asset','debit',1,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_1131','1131','شيكات برسم التحصيل بالخزينة','Cheques in Hand','acc_113','asset','debit',0,4,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_1132','1132','شيكات مودعة بالبنك للتحصيل','Cheques under Collection','acc_113','asset','debit',0,4,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_114','114','المخزون السلعي','Inventory Asset','acc_11','asset','debit',1,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_1141','1141','مخزون بضاعة بغرض البيع (المخزن الرئيسي)','Finished Goods Inventory - Cairo','acc_114','asset','debit',0,4,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_1142','1142','مخزون فرع الإسكندرية','Inventory - Alexandria','acc_114','asset','debit',0,4,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_1143','1143','مخزون بضاعة تالفة ومرتجعات فحص','Damaged & Inspection Stock','acc_114','asset','debit',0,4,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_115','115','أرصدة مدينة لدى مصلحة الضرائب','Tax Authority Debit Balances','acc_11','asset','debit',1,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_1151','1151','مصلحة الضرائب - ضريبة القيمة المضافة (مدخلات قابلة للخصم)','Input VAT Recoverable (14%)','acc_115','asset','debit',0,4,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_1152','1152','مصلحة الضرائب - خصم وتحصيل مستقطع من العملاء (1%)','Withholding Tax Deducted by Customers','acc_115','asset','debit',0,4,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_12','12','الأصول غير المتداولة (الثابتة)','Non-Current Assets','acc_1','asset','debit',1,2,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_1211','1211','أجهزة حاسب آلي ومعدات شبكات','Computers & IT Equipment','acc_12','asset','debit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_1212','1212','أثاث ومفروشات وتجهيزات مكتبية','Office Furniture & Fixtures','acc_12','asset','debit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_1213','1213','سيارات نقل وتوزيع','Vehicles & Delivery Trucks','acc_12','asset','debit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_1221','1221','مجمع إهلاك أجهزة حاسب آلي','Accum. Deprec. - Computers','acc_12','asset','credit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_1222','1222','مجمع إهلاك أثاث وتجهيزات','Accum. Deprec. - Furniture','acc_12','asset','credit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_1223','1223','مجمع إهلاك سيارات','Accum. Deprec. - Vehicles','acc_12','asset','credit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_2','2','الالتزامات','Liabilities',NULL,'liability','credit',1,1,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_21','21','الالتزامات المتداولة','Current Liabilities','acc_2','liability','credit',1,2,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_211','211','الموردون والدائنون التجاريون','Accounts Payable','acc_21','liability','credit',1,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_2111','2111','الموردون التجاريون (حساب الرقابة العام)','Trade Creditors Control Account','acc_211','liability','credit',0,4,NULL,1,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_2121','2121','أوراق الدفع (شيكات صادرة للموردين)','Notes Payable (Issued Cheques)','acc_21','liability','credit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_213','213','الالتزامات الضريبية (مصلحة الضرائب المصرية)','Tax Liabilities (ETA)','acc_21','liability','credit',1,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_2131','2131','مصلحة الضرائب - ضريبة القيمة المضافة (مخرجات مستحقة 14%)','Output VAT Payable (14%)','acc_213','liability','credit',0,4,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_2132','2132','مصلحة الضرائب - ضرائب الخصم والتحصيل أمانات (مستقطعة من الموردين)','Withholding Tax Payable (1%/3%)','acc_213','liability','credit',0,4,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_2133','2133','مصلحة الضرائب - ضريبة كسب العمل','Payroll Tax Payable','acc_213','liability','credit',0,4,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_2141','2141','مصروفات مستحقة وأرصدة دائنة أخرى','Accrued Expenses & Other Payables','acc_21','liability','credit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_3','3','حقوق الملكية','Equity',NULL,'equity','credit',1,1,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_31','31','رأس المال والاحتياطيات','Capital & Reserves','acc_3','equity','credit',1,2,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_3111','3111','رأس المال المدفوع','Paid-in Capital','acc_31','equity','credit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_3211','3211','الاحتياطي القانوني','Legal Reserve','acc_31','equity','credit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_3311','3311','الأرباح المحتجزة / المرحلة','Retained Earnings','acc_31','equity','credit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_3411','3411','أرباح وخسائر العام الحالي','Current Year Profit/Loss','acc_31','equity','credit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_4','4','الإيرادات','Revenues',NULL,'revenue','credit',1,1,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_41','41','إيرادات النشاط الرئيسي','Operating Revenues','acc_4','revenue','credit',1,2,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_4111','4111','إيرادات مبيعات أجهزة وإلكترونيات','Sales Revenue - Electronics','acc_41','revenue','credit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_4112','4112','إيرادات مبيعات مستلزمات وإكسسوارات','Sales Revenue - Accessories','acc_41','revenue','credit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_4113','4113','إيرادات خدمات صيانة ودعم فني','Maintenance & Service Revenue','acc_41','revenue','credit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_4211','4211','مردودات ومسموحات المبيعات','Sales Returns & Allowances','acc_41','revenue','debit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_4311','4311','الخصم المسموح به للعملاء','Sales Discounts Allowed','acc_41','revenue','debit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_4511','4511','إيرادات متنوعة وأرباح فروق عملة','Other Income & Forex Gain','acc_4','revenue','credit',0,2,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_5','5','تكلفة المبيعات','Cost of Goods Sold',NULL,'cogs','debit',1,1,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_51','51','تكلفة النشاط والمبيعات','Cost of Sales','acc_5','cogs','debit',1,2,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_5111','5111','تكلفة البضاعة المباعة (أجهزة وإلكترونيات)','COGS - Electronics','acc_51','cogs','debit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_5112','5112','تكلفة البضاعة المباعة (إكسسوارات)','COGS - Accessories','acc_51','cogs','debit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_5211','5211','عجز وتسويات المخزون السلعي والهالك','Inventory Shrinkage & Loss','acc_51','cogs','debit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_6','6','المصروفات التشغيلية والإدارية','Operating Expenses',NULL,'expense','debit',1,1,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_61','61','المصروفات البيعية والعمومية','Selling & Admin Expenses','acc_6','expense','debit',1,2,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_6111','6111','الأجور والمرتبات والمكافآت','Salaries, Wages & Bonuses','acc_61','expense','debit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_6211','6211','إيجار المقرات والمعارض والمخازن','Rent Expense','acc_61','expense','debit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_6311','6311','إهلاك الأصول الثابتة','Depreciation Expense','acc_61','expense','debit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_6411','6411','كهرباء ومياه وغاز ومرافق','Utilities Expense','acc_61','expense','debit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_6412','6412','اتصالات وإنترنت وموقع إلكتروني','Telecommunications & Internet','acc_61','expense','debit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_6511','6511','مصاريف بنكية وعمولات تحصيل','Bank Charges & Commissions','acc_61','expense','debit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `accounts` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`account_type`,`nature`,`is_group`,`level`,`currency_code`,`is_reconciliation`,`is_active`,`notes`,`created_at`) VALUES ('acc_6611','6611','خسائر فروق تقييم العملة الأجنبية','Foreign Exchange Losses','acc_61','expense','debit',0,3,NULL,0,1,NULL,'2026-11-05 20:40:18');
INSERT INTO `document_sequences` (`id`,`doc_type`,`branch_id`,`fiscal_year_id`,`prefix`,`next_number`) VALUES ('seq_1793911218397_swj8v','JV','br_cairo','fy_2026','JV-2026-CAI',10);
INSERT INTO `document_sequences` (`id`,`doc_type`,`branch_id`,`fiscal_year_id`,`prefix`,`next_number`) VALUES ('seq_1793911218425_lpvlf','JV','br_alex','fy_2026','JV-2026-ALX',2);
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_cust_001','CUST-0001','customer','شركة النيل للتوكيلات التجارية ش.م.م','Customer 1','210-458-791','109230',NULL,1,'+20 2 2710000',NULL,NULL,'شارع التجارة الرئيسي، القاهرة','القاهرة',NULL,500000,45,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_cust_002','CUST-0002','customer','مؤسسة الأهرام للتوزيع والتجهيزات','Customer 2','104-589-322','84920',NULL,1,'+20 2 2720000',NULL,NULL,'شارع التجارة الرئيسي، الجيزة','الجيزة',NULL,750000,60,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_cust_003','CUST-0003','customer','شركة الدلتا للتجارة والتوزيع','Customer 3','315-782-901','92314',NULL,1,'+20 2 2730000',NULL,NULL,'شارع التجارة الرئيسي، طنطا','طنطا',NULL,300000,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_cust_004','CUST-0004','customer','مكتبة وموزع الشروق الحديثة','Customer 4','402-911-344','71203',NULL,1,'+20 2 2740000',NULL,NULL,'شارع التجارة الرئيسي، القاهرة','القاهرة',NULL,150000,15,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_cust_005','CUST-0005','customer','شركة الإسكندرية لتكنولوجيا المعلومات','Customer 5','501-239-880','45812',NULL,1,'+20 2 2750000',NULL,NULL,'شارع التجارة الرئيسي، الإسكندرية','الإسكندرية',NULL,400000,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_cust_006','CUST-0006','customer','مؤسسة المستقبل للأنظمة الرقمية','Customer 6','620-114-599','63201',NULL,1,'+20 2 2760000',NULL,NULL,'شارع التجارة الرئيسي، المنصورة','المنصورة',NULL,250000,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_cust_007','CUST-0007','customer','شركة الصعيد للمقاولات والتوريدات','Customer 7','719-402-188','39410',NULL,1,'+20 2 2770000',NULL,NULL,'شارع التجارة الرئيسي، أسيوط','أسيوط',NULL,350000,45,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_cust_008','CUST-0008','customer','مؤسسة الفراعنة للإلكترونيات','Customer 8','810-993-211','81290',NULL,1,'+20 2 2780000',NULL,NULL,'شارع التجارة الرئيسي، القاهرة','القاهرة',NULL,600000,45,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_cust_009','CUST-0009','customer','شركة طيبة للتجهيزات الفندقية','Customer 9','904-182-377','52891',NULL,1,'+20 2 2790000',NULL,NULL,'شارع التجارة الرئيسي، الغردقة','الغردقة',NULL,450000,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_cust_010','CUST-0010','customer','شركة البحر الأحمر للتسويق','Customer 10','118-294-601','67412',NULL,1,'+20 2 27100000',NULL,NULL,'شارع التجارة الرئيسي، شرم الشيخ','شرم الشيخ',NULL,200000,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_cust_011','CUST-0011','customer','مؤسسة الصفوة للأجهزة الذكية','Customer 11','229-385-712','99201',NULL,1,'+20 2 27110000',NULL,NULL,'شارع التجارة الرئيسي، القاهرة','القاهرة',NULL,300000,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_cust_012','CUST-0012','customer','شركة السويس للخدمات اللوجستية','Customer 12','330-496-823','34190',NULL,1,'+20 2 27120000',NULL,NULL,'شارع التجارة الرئيسي، السويس','السويس',NULL,180000,15,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_cust_013','CUST-0013','customer','مؤسسة النور للأدوات والمعدات','Customer 13','441-507-934','87214',NULL,1,'+20 2 27130000',NULL,NULL,'شارع التجارة الرئيسي، الزقازيق','الزقازيق',NULL,220000,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_cust_014','CUST-0014','customer','شركة بورسعيد التجارية الحرة','Customer 14','552-618-045','18492',NULL,1,'+20 2 27140000',NULL,NULL,'شارع التجارة الرئيسي، بورسعيد','بورسعيد',NULL,500000,45,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_cust_015','CUST-0015','customer','مؤسسة المنار للإلكترونيات','Customer 15','663-729-156','92410',NULL,1,'+20 2 27150000',NULL,NULL,'شارع التجارة الرئيسي، بنها','بنها',NULL,150000,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_cust_016','CUST-0016','customer','شركة المهندسين لتجهيز المكاتب','Customer 16','774-830-267','64819',NULL,1,'+20 2 27160000',NULL,NULL,'شارع التجارة الرئيسي، الجيزة','الجيزة',NULL,280000,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_cust_017','CUST-0017','customer','مؤسسة مصر للحلول المتكاملة','Customer 17','885-941-378','49201',NULL,1,'+20 2 27170000',NULL,NULL,'شارع التجارة الرئيسي، القاهرة','القاهرة',NULL,400000,45,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_cust_018','CUST-0018','customer','شركة الوادي للتجارة والتوكيلات','Customer 18','996-052-489','78290',NULL,1,'+20 2 27180000',NULL,NULL,'شارع التجارة الرئيسي، سوهاج','سوهاج',NULL,320000,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_cust_019','CUST-0019','customer','مؤسسة العروبة للتجارة العامة','Customer 19','107-163-590','81029',NULL,1,'+20 2 27190000',NULL,NULL,'شارع التجارة الرئيسي، الإسماعيلية','الإسماعيلية',NULL,200000,15,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_cust_020','CUST-0020','customer','شركة الأندلس للأنظمة المكتبية','Customer 20','218-274-601','95412',NULL,1,'+20 2 27200000',NULL,NULL,'شارع التجارة الرئيسي، الإسكندرية','الإسكندرية',NULL,350000,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_supp_001','SUPP-0001','supplier','شركة سامسونج مصر للإلكترونيات ش.م.م','Supplier 1','100-200-301','48201',NULL,1,'+20 2 3310000',NULL,NULL,'المنطقة الصناعية، بني سويف','بني سويف',NULL,0,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_supp_002','SUPP-0002','supplier','شركة العربي للتجارة والصناعة (توشيبا)','Supplier 2','200-300-402','18204',NULL,1,'+20 2 3320000',NULL,NULL,'المنطقة الصناعية، القاهرة','القاهرة',NULL,0,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_supp_003','SUPP-0003','supplier','شركة إتش بي مصر للحواسب (HP Egypt)','Supplier 3','300-400-503','93810',NULL,1,'+20 2 3330000',NULL,NULL,'المنطقة الصناعية، القرية الذكية، الجيزة','القرية الذكية، الجيزة',NULL,0,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_supp_004','SUPP-0004','supplier','شركة ديل تكنولوجيز مصر (Dell Technologies)','Supplier 4','400-500-604','84912',NULL,1,'+20 2 3340000',NULL,NULL,'المنطقة الصناعية، القاهرة الجديدة','القاهرة الجديدة',NULL,0,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_supp_005','SUPP-0005','supplier','شركة كانون الشرق الأوسط - مكتب مصر','Supplier 5','500-600-705','39201',NULL,1,'+20 2 3350000',NULL,NULL,'المنطقة الصناعية، القاهرة','القاهرة',NULL,0,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_supp_006','SUPP-0006','supplier','شركة راية للتوزيع ش.م.م','Supplier 6','600-700-806','72910',NULL,1,'+20 2 3360000',NULL,NULL,'المنطقة الصناعية، مدينة 6 أكتوبر','مدينة 6 أكتوبر',NULL,0,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_supp_007','SUPP-0007','supplier','شركة بي تك للتجارة والتوزيع (B.TECH)','Supplier 7','700-800-907','61928',NULL,1,'+20 2 3370000',NULL,NULL,'المنطقة الصناعية، المقطم، القاهرة','المقطم، القاهرة',NULL,0,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_supp_008','SUPP-0008','supplier','شركة مانتراك مصر للمعدات والحلول','Supplier 8','800-900-018','51920',NULL,1,'+20 2 3380000',NULL,NULL,'المنطقة الصناعية، الإسكندرية','الإسكندرية',NULL,0,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_supp_009','SUPP-0009','supplier','الشركة المصرية الدولية للتوريدات المكتبية','Supplier 9','900-010-129','49201',NULL,1,'+20 2 3390000',NULL,NULL,'المنطقة الصناعية، القاهرة','القاهرة',NULL,0,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_supp_010','SUPP-0010','supplier','مؤسسة البشير للمستلزمات التقنية','Supplier 10','110-220-330','88201',NULL,1,'+20 2 33100000',NULL,NULL,'المنطقة الصناعية، الجيزة','الجيزة',NULL,0,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_supp_011','SUPP-0011','supplier','شركة لوجيتك للملحقات الرقمية','Supplier 11','220-330-441','39401',NULL,1,'+20 2 33110000',NULL,NULL,'المنطقة الصناعية، القاهرة','القاهرة',NULL,0,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_supp_012','SUPP-0012','supplier','شركة شنايدر إليكتريك مصر (Schneider Electric)','Supplier 12','330-440-552','91823',NULL,1,'+20 2 33120000',NULL,NULL,'المنطقة الصناعية، التجمع الخامس','التجمع الخامس',NULL,0,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_supp_013','SUPP-0013','supplier','الشركة العربية لتصنيع الشاشات','Supplier 13','440-550-663','74819',NULL,1,'+20 2 33130000',NULL,NULL,'المنطقة الصناعية، العاشر من رمضان','العاشر من رمضان',NULL,0,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_supp_014','SUPP-0014','supplier','مؤسسة الهلال للتجهيزات المكتبية المتطورة','Supplier 14','550-660-774','83910',NULL,1,'+20 2 33140000',NULL,NULL,'المنطقة الصناعية، طنطا','طنطا',NULL,0,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `parties` (`id`,`code`,`type`,`name_ar`,`name_en`,`tax_id`,`commercial_registry`,`national_id`,`is_company`,`phone`,`mobile`,`email`,`address`,`city`,`governorate`,`credit_limit`,`payment_terms_days`,`currency_code`,`account_id`,`is_active`,`created_at`) VALUES ('party_supp_015','SUPP-0015','supplier','شركة إيديال للحلول الرقمية والأثاث المكتبي','Supplier 15','660-770-885','29481',NULL,1,'+20 2 33150000',NULL,NULL,'المنطقة الصناعية، حلوان','حلوان',NULL,0,30,'EGP',NULL,1,'2026-11-05 20:40:18');
INSERT INTO `warehouses` (`id`,`branch_id`,`code`,`name_ar`,`name_en`,`address`,`is_damaged_stock`,`is_active`) VALUES ('wh_alex','br_alex','WH-ALX-01','مخزن فرع الإسكندرية (سموحة)','Alexandria Regional Warehouse','المنطقة الصناعية، سموحة',0,1);
INSERT INTO `warehouses` (`id`,`branch_id`,`code`,`name_ar`,`name_en`,`address`,`is_damaged_stock`,`is_active`) VALUES ('wh_damaged','br_cairo','WH-DMG-01','مخزن البضاعة المرتجعة والتالفة','Damaged & Inspection Warehouse','ملحق المخزن الرئيسي، القاهرة',1,1);
INSERT INTO `warehouses` (`id`,`branch_id`,`code`,`name_ar`,`name_en`,`address`,`is_damaged_stock`,`is_active`) VALUES ('wh_main','br_cairo','WH-CAI-01','المخزن الرئيسي - القاهرة (مصر الجديدة)','Cairo Central Warehouse','منطقة شيراتون، مصر الجديدة',0,1);
INSERT INTO `journal_entries` (`id`,`entry_number`,`doc_type`,`doc_id`,`doc_number`,`entry_date`,`posting_date`,`fiscal_period_id`,`branch_id`,`status`,`description`,`total_debit`,`total_credit`,`currency_code`,`exchange_rate`,`reversed_entry_id`,`is_system_generated`,`created_by`,`created_at`,`posted_by`,`posted_at`) VALUES ('je_1793911218393_c0drh','JV-2026-CAI-000001','MANUAL','OPENING_2026','OPN-2026-001','2026-01-01','2026-01-01','fp_2026_01','br_cairo','posted','قيد الأرصدة الافتتاحية المعتمدة للسنة المالية 2026',4027500,4027500,'EGP',1,NULL,1,'usr_fin_mgr','2026-11-05 20:40:18','usr_fin_mgr','2026-11-05 20:40:18');
INSERT INTO `journal_entries` (`id`,`entry_number`,`doc_type`,`doc_id`,`doc_number`,`entry_date`,`posting_date`,`fiscal_period_id`,`branch_id`,`status`,`description`,`total_debit`,`total_credit`,`currency_code`,`exchange_rate`,`reversed_entry_id`,`is_system_generated`,`created_by`,`created_at`,`posted_by`,`posted_at`) VALUES ('je_1793911218407_dnrnl','JV-2026-CAI-000002','SALES_INV','inv_INV-2026-CAI-000001','INV-2026-CAI-000001','2026-01-15','2026-01-15','fp_2026_01','br_cairo','posted','فاتورة مبيعات رقم INV-2026-CAI-000001',87160,87160,'EGP',1,NULL,1,'usr_sales','2026-11-05 20:40:18','usr_sales','2026-11-05 20:40:18');
INSERT INTO `journal_entries` (`id`,`entry_number`,`doc_type`,`doc_id`,`doc_number`,`entry_date`,`posting_date`,`fiscal_period_id`,`branch_id`,`status`,`description`,`total_debit`,`total_credit`,`currency_code`,`exchange_rate`,`reversed_entry_id`,`is_system_generated`,`created_by`,`created_at`,`posted_by`,`posted_at`) VALUES ('je_1793911218415_ijmaf','JV-2026-CAI-000003','SALES_INV','inv_INV-2026-CAI-000002','INV-2026-CAI-000002','2026-01-22','2026-01-22','fp_2026_01','br_cairo','posted','فاتورة مبيعات رقم INV-2026-CAI-000002',224132,224132,'EGP',1,NULL,1,'usr_sales','2026-11-05 20:40:18','usr_sales','2026-11-05 20:40:18');
INSERT INTO `journal_entries` (`id`,`entry_number`,`doc_type`,`doc_id`,`doc_number`,`entry_date`,`posting_date`,`fiscal_period_id`,`branch_id`,`status`,`description`,`total_debit`,`total_credit`,`currency_code`,`exchange_rate`,`reversed_entry_id`,`is_system_generated`,`created_by`,`created_at`,`posted_by`,`posted_at`) VALUES ('je_1793911218423_6t3v4','JV-2026-ALX-000001','SALES_INV','inv_INV-2026-ALX-000003','INV-2026-ALX-000003','2026-02-05','2026-02-05','fp_2026_02','br_alex','posted','فاتورة مبيعات رقم INV-2026-ALX-000003',113980,113980,'EGP',1,NULL,1,'usr_sales','2026-11-05 20:40:18','usr_sales','2026-11-05 20:40:18');
INSERT INTO `journal_entries` (`id`,`entry_number`,`doc_type`,`doc_id`,`doc_number`,`entry_date`,`posting_date`,`fiscal_period_id`,`branch_id`,`status`,`description`,`total_debit`,`total_credit`,`currency_code`,`exchange_rate`,`reversed_entry_id`,`is_system_generated`,`created_by`,`created_at`,`posted_by`,`posted_at`) VALUES ('je_1793911218430_w88vn','JV-2026-CAI-000004','SALES_INV','inv_INV-2026-CAI-000004','INV-2026-CAI-000004','2026-02-18','2026-02-18','fp_2026_02','br_cairo','posted','فاتورة مبيعات رقم INV-2026-CAI-000004',47416,47416,'EGP',1,NULL,1,'usr_sales','2026-11-05 20:40:18','usr_sales','2026-11-05 20:40:18');
INSERT INTO `journal_entries` (`id`,`entry_number`,`doc_type`,`doc_id`,`doc_number`,`entry_date`,`posting_date`,`fiscal_period_id`,`branch_id`,`status`,`description`,`total_debit`,`total_credit`,`currency_code`,`exchange_rate`,`reversed_entry_id`,`is_system_generated`,`created_by`,`created_at`,`posted_by`,`posted_at`) VALUES ('je_1793911218436_iwhiz','JV-2026-CAI-000005','RCPT','rcpt_INV-2026-CAI-000004','RC-INV-2026-CAI-000004','2026-02-18','2026-02-18','fp_2026_02','br_cairo','posted','سند تحصيل نقدي فوري للفاتورة INV-2026-CAI-000004',27572,27572,'EGP',1,NULL,1,'usr_cashier','2026-11-05 20:40:18','usr_cashier','2026-11-05 20:40:18');
INSERT INTO `journal_entries` (`id`,`entry_number`,`doc_type`,`doc_id`,`doc_number`,`entry_date`,`posting_date`,`fiscal_period_id`,`branch_id`,`status`,`description`,`total_debit`,`total_credit`,`currency_code`,`exchange_rate`,`reversed_entry_id`,`is_system_generated`,`created_by`,`created_at`,`posted_by`,`posted_at`) VALUES ('je_1793911218442_oidsg','JV-2026-CAI-000006','SALES_INV','inv_INV-2026-CAI-000005','INV-2026-CAI-000005','2026-03-02','2026-03-02','fp_2026_03','br_cairo','posted','فاتورة مبيعات رقم INV-2026-CAI-000005',53350,53350,'EGP',1,NULL,1,'usr_sales','2026-11-05 20:40:18','usr_sales','2026-11-05 20:40:18');
INSERT INTO `journal_entries` (`id`,`entry_number`,`doc_type`,`doc_id`,`doc_number`,`entry_date`,`posting_date`,`fiscal_period_id`,`branch_id`,`status`,`description`,`total_debit`,`total_credit`,`currency_code`,`exchange_rate`,`reversed_entry_id`,`is_system_generated`,`created_by`,`created_at`,`posted_by`,`posted_at`) VALUES ('je_1793911218452_do0m7','JV-2026-CAI-000007','PUR_INV','pur_PINV-2026-CAI-000001','PINV-2026-CAI-000001','2026-01-10','2026-01-10','fp_2026_01','br_cairo','posted','فاتورة مشتريات رقم PINV-2026-CAI-000001 من المورد',45600,45600,'EGP',1,NULL,1,'usr_procurement','2026-11-05 20:40:18','usr_procurement','2026-11-05 20:40:18');
INSERT INTO `journal_entries` (`id`,`entry_number`,`doc_type`,`doc_id`,`doc_number`,`entry_date`,`posting_date`,`fiscal_period_id`,`branch_id`,`status`,`description`,`total_debit`,`total_credit`,`currency_code`,`exchange_rate`,`reversed_entry_id`,`is_system_generated`,`created_by`,`created_at`,`posted_by`,`posted_at`) VALUES ('je_1793911218459_ah63q','JV-2026-CAI-000008','PUR_INV','pur_PINV-2026-CAI-000002','PINV-2026-CAI-000002','2026-02-01','2026-02-01','fp_2026_02','br_cairo','posted','فاتورة مشتريات رقم PINV-2026-CAI-000002 من المورد',54150,54150,'EGP',1,NULL,1,'usr_procurement','2026-11-05 20:40:18','usr_procurement','2026-11-05 20:40:18');
INSERT INTO `journal_entries` (`id`,`entry_number`,`doc_type`,`doc_id`,`doc_number`,`entry_date`,`posting_date`,`fiscal_period_id`,`branch_id`,`status`,`description`,`total_debit`,`total_credit`,`currency_code`,`exchange_rate`,`reversed_entry_id`,`is_system_generated`,`created_by`,`created_at`,`posted_by`,`posted_at`) VALUES ('je_1793911218466_tyu3l','JV-2026-CAI-000009','SALES_RET','ret_RET-2026-CAI-000001','RET-2026-CAI-000001','2026-01-20','2026-01-20','fp_2026_01','br_cairo','posted','مردود مبيعات جزئي للفاتورة INV-2026-CAI-000001',43580,43580,'EGP',1,NULL,1,'usr_sales','2026-11-05 20:40:18','usr_sales','2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218398_1_8xh','je_1793911218393_c0drh',1,'acc_1111',NULL,NULL,150000,0,'رصيد افتتاحي - خزينة القاهرة','EGP',1,150000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218399_2_g0p','je_1793911218393_c0drh',2,'acc_1112',NULL,NULL,75000,0,'رصيد افتتاحي - خزينة الإسكندرية','EGP',1,75000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218399_3_g8y','je_1793911218393_c0drh',3,'acc_1113',NULL,NULL,850000,0,'رصيد افتتاحي - البنك الأهلي المصري','EGP',1,850000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218399_4_tsu','je_1793911218393_c0drh',4,'acc_1114',NULL,NULL,1212500,0,'رصيد افتتاحي - بنك مصر دولار ($25,000 @ 48.5)','EGP',1,1212500,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218400_5_7jj','je_1793911218393_c0drh',5,'acc_1121',NULL,NULL,420000,0,'رصيد افتتاحي - حساب رقابة العملاء','EGP',1,420000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218400_6_x02','je_1793911218393_c0drh',6,'acc_1141',NULL,NULL,550000,0,'رصيد افتتاحي - مخزون البضائع بالقاهرة','EGP',1,550000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218400_7_egw','je_1793911218393_c0drh',7,'acc_1142',NULL,NULL,220000,0,'رصيد افتتاحي - مخزون البضائع بالإسكندرية','EGP',1,220000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218400_8_b0z','je_1793911218393_c0drh',8,'acc_1211',NULL,NULL,120000,0,'رصيد افتتاحي - أجهزة حاسب آلي','EGP',1,120000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218401_10_j79','je_1793911218393_c0drh',10,'acc_1213',NULL,NULL,350000,0,'رصيد افتتاحي - سيارات نقل','EGP',1,350000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218401_11_6hq','je_1793911218393_c0drh',11,'acc_1221',NULL,NULL,0,40000,'رصيد افتتاحي - مجمع إهلاك حواسب','EGP',1,40000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218401_12_hvn','je_1793911218393_c0drh',12,'acc_1222',NULL,NULL,0,16000,'رصيد افتتاحي - مجمع إهلاك أثاث','EGP',1,16000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218401_9_g4z','je_1793911218393_c0drh',9,'acc_1212',NULL,NULL,80000,0,'رصيد افتتاحي - أثاث ومفروشات','EGP',1,80000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218402_13_rbc','je_1793911218393_c0drh',13,'acc_1223',NULL,NULL,0,70000,'رصيد افتتاحي - مجمع إهلاك سيارات','EGP',1,70000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218402_14_tal','je_1793911218393_c0drh',14,'acc_2111',NULL,NULL,0,401500,'رصيد افتتاحي - حساب رقابة الموردين','EGP',1,401500,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218402_15_981','je_1793911218393_c0drh',15,'acc_3111',NULL,NULL,0,2000000,'رأس المال المصدر والمدفوع','EGP',1,2000000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218402_16_osg','je_1793911218393_c0drh',16,'acc_3211',NULL,NULL,0,300000,'الاحتياطي القانوني','EGP',1,300000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218403_17_rc7','je_1793911218393_c0drh',17,'acc_3311',NULL,NULL,0,1200000,'الأرباح المحتجزة من السنوات السابقة','EGP',1,1200000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218410_1_z01','je_1793911218407_dnrnl',1,'acc_1121','party_cust_001',NULL,49720,0,'استحقاق فاتورة مبيعات INV-2026-CAI-000001','EGP',1,49720,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218410_2_beq','je_1793911218407_dnrnl',2,'acc_1152',NULL,NULL,440,0,'ضريبة الخصم والتحصيل المستقطعة (1%) للفاتورة INV-2026-CAI-000001','EGP',1,440,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218410_3_p7b','je_1793911218407_dnrnl',3,'acc_4111',NULL,NULL,0,44000,'إيراد مبيعات فاتورة INV-2026-CAI-000001','EGP',1,44000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218410_4_alk','je_1793911218407_dnrnl',4,'acc_2131',NULL,NULL,0,6160,'ضريبة القيمة المضافة (14%) فاتورة INV-2026-CAI-000001','EGP',1,6160,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218411_5_l6a','je_1793911218407_dnrnl',5,'acc_5111',NULL,NULL,37000,0,'تكلفة البضاعة المباعة للفاتورة INV-2026-CAI-000001','EGP',1,37000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218411_6_ub1','je_1793911218407_dnrnl',6,'acc_1141',NULL,NULL,0,37000,'صرف مخزون للفاتورة INV-2026-CAI-000001','EGP',1,37000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218418_1_geu','je_1793911218415_ijmaf',1,'acc_1121','party_cust_002',NULL,128594,0,'استحقاق فاتورة مبيعات INV-2026-CAI-000002','EGP',1,128594,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218418_2_ph5','je_1793911218415_ijmaf',2,'acc_1152',NULL,NULL,1138,0,'ضريبة الخصم والتحصيل المستقطعة (1%) للفاتورة INV-2026-CAI-000002','EGP',1,1138,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218418_3_zay','je_1793911218415_ijmaf',3,'acc_4111',NULL,NULL,0,113800,'إيراد مبيعات فاتورة INV-2026-CAI-000002','EGP',1,113800,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218418_4_jps','je_1793911218415_ijmaf',4,'acc_2131',NULL,NULL,0,15932,'ضريبة القيمة المضافة (14%) فاتورة INV-2026-CAI-000002','EGP',1,15932,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218419_5_cfi','je_1793911218415_ijmaf',5,'acc_5111',NULL,NULL,94400,0,'تكلفة البضاعة المباعة للفاتورة INV-2026-CAI-000002','EGP',1,94400,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218419_6_arh','je_1793911218415_ijmaf',6,'acc_1141',NULL,NULL,0,94400,'صرف مخزون للفاتورة INV-2026-CAI-000002','EGP',1,94400,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218426_1_46n','je_1793911218423_6t3v4',1,'acc_1121','party_cust_005',NULL,64410,0,'استحقاق فاتورة مبيعات INV-2026-ALX-000003','EGP',1,64410,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218426_2_ktd','je_1793911218423_6t3v4',2,'acc_1152',NULL,NULL,570,0,'ضريبة الخصم والتحصيل المستقطعة (1%) للفاتورة INV-2026-ALX-000003','EGP',1,570,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218426_3_dx8','je_1793911218423_6t3v4',3,'acc_4111',NULL,NULL,0,57000,'إيراد مبيعات فاتورة INV-2026-ALX-000003','EGP',1,57000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218426_4_p0f','je_1793911218423_6t3v4',4,'acc_2131',NULL,NULL,0,7980,'ضريبة القيمة المضافة (14%) فاتورة INV-2026-ALX-000003','EGP',1,7980,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218427_5_c54','je_1793911218423_6t3v4',5,'acc_5111',NULL,NULL,49000,0,'تكلفة البضاعة المباعة للفاتورة INV-2026-ALX-000003','EGP',1,49000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218427_6_f6n','je_1793911218423_6t3v4',6,'acc_1142',NULL,NULL,0,49000,'صرف مخزون للفاتورة INV-2026-ALX-000003','EGP',1,49000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218433_1_z2l','je_1793911218430_w88vn',1,'acc_1121','party_cust_008',NULL,27572,0,'استحقاق فاتورة مبيعات INV-2026-CAI-000004','EGP',1,27572,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218433_2_2dd','je_1793911218430_w88vn',2,'acc_1152',NULL,NULL,244,0,'ضريبة الخصم والتحصيل المستقطعة (1%) للفاتورة INV-2026-CAI-000004','EGP',1,244,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218433_3_n8l','je_1793911218430_w88vn',3,'acc_4111',NULL,NULL,0,24400,'إيراد مبيعات فاتورة INV-2026-CAI-000004','EGP',1,24400,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218433_4_v00','je_1793911218430_w88vn',4,'acc_2131',NULL,NULL,0,3416,'ضريبة القيمة المضافة (14%) فاتورة INV-2026-CAI-000004','EGP',1,3416,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218434_5_5zc','je_1793911218430_w88vn',5,'acc_5111',NULL,NULL,19600,0,'تكلفة البضاعة المباعة للفاتورة INV-2026-CAI-000004','EGP',1,19600,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218434_6_0zq','je_1793911218430_w88vn',6,'acc_1141',NULL,NULL,0,19600,'صرف مخزون للفاتورة INV-2026-CAI-000004','EGP',1,19600,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218439_1_t3h','je_1793911218436_iwhiz',1,'acc_1111',NULL,NULL,27572,0,'تحصيل نقدي بالخزينة - فاتورة INV-2026-CAI-000004','EGP',1,27572,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218439_2_188','je_1793911218436_iwhiz',2,'acc_1121','party_cust_008',NULL,0,27572,'سداد قيمة الفاتورة INV-2026-CAI-000004','EGP',1,27572,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218445_1_qdl','je_1793911218442_oidsg',1,'acc_1121','party_cust_010',NULL,31075,0,'استحقاق فاتورة مبيعات INV-2026-CAI-000005','EGP',1,31075,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218445_2_34a','je_1793911218442_oidsg',2,'acc_1152',NULL,NULL,275,0,'ضريبة الخصم والتحصيل المستقطعة (1%) للفاتورة INV-2026-CAI-000005','EGP',1,275,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218445_3_fmv','je_1793911218442_oidsg',3,'acc_4111',NULL,NULL,0,27500,'إيراد مبيعات فاتورة INV-2026-CAI-000005','EGP',1,27500,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218445_4_txt','je_1793911218442_oidsg',4,'acc_2131',NULL,NULL,0,3850,'ضريبة القيمة المضافة (14%) فاتورة INV-2026-CAI-000005','EGP',1,3850,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218446_5_443','je_1793911218442_oidsg',5,'acc_5111',NULL,NULL,22000,0,'تكلفة البضاعة المباعة للفاتورة INV-2026-CAI-000005','EGP',1,22000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218446_6_zrr','je_1793911218442_oidsg',6,'acc_1141',NULL,NULL,0,22000,'صرف مخزون للفاتورة INV-2026-CAI-000005','EGP',1,22000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218454_1_a0g','je_1793911218452_do0m7',1,'acc_1141',NULL,NULL,40000,0,'إضافة مخزون مشتريات فاتورة PINV-2026-CAI-000001','EGP',1,40000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218454_2_i02','je_1793911218452_do0m7',2,'acc_1151',NULL,NULL,5600,0,'ضريبة مدخلات 14% فاتورة مشتريات PINV-2026-CAI-000001','EGP',1,5600,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218454_3_8ex','je_1793911218452_do0m7',3,'acc_2111','party_supp_001',NULL,0,45200,'استحقاق المورد عن فاتورة مشتريات PINV-2026-CAI-000001','EGP',1,45200,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218454_4_0tr','je_1793911218452_do0m7',4,'acc_2132',NULL,NULL,0,400,'أمانات خصم وتحصيل 1% فاتورة مشتريات PINV-2026-CAI-000001','EGP',1,400,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218461_1_62n','je_1793911218459_ah63q',1,'acc_1141',NULL,NULL,47500,0,'إضافة مخزون مشتريات فاتورة PINV-2026-CAI-000002','EGP',1,47500,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218461_2_rj2','je_1793911218459_ah63q',2,'acc_1151',NULL,NULL,6650,0,'ضريبة مدخلات 14% فاتورة مشتريات PINV-2026-CAI-000002','EGP',1,6650,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218461_3_2bk','je_1793911218459_ah63q',3,'acc_1111',NULL,NULL,0,53675,'استحقاق المورد عن فاتورة مشتريات PINV-2026-CAI-000002','EGP',1,53675,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218462_4_0ku','je_1793911218459_ah63q',4,'acc_2132',NULL,NULL,0,475,'أمانات خصم وتحصيل 1% فاتورة مشتريات PINV-2026-CAI-000002','EGP',1,475,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218469_1_2xk','je_1793911218466_tyu3l',1,'acc_4211',NULL,NULL,22000,0,'مردودات مبيعات RET-2026-CAI-000001','EGP',1,22000,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218469_2_ta0','je_1793911218466_tyu3l',2,'acc_2131',NULL,NULL,3080,0,'عكس ضريبة مبيعات RET-2026-CAI-000001','EGP',1,3080,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218469_3_zth','je_1793911218466_tyu3l',3,'acc_1121','party_cust_001',NULL,0,24860,'تخفيض مديونية العميل عن مردود RET-2026-CAI-000001','EGP',1,24860,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218469_4_795','je_1793911218466_tyu3l',4,'acc_1152',NULL,NULL,0,220,'عكس خصم وتحصيل RET-2026-CAI-000001','EGP',1,220,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218469_5_0ab','je_1793911218466_tyu3l',5,'acc_1141',NULL,NULL,18500,0,'إعادة مخزون بضاعة مرتجعة RET-2026-CAI-000001','EGP',1,18500,'2026-11-05 20:40:18');
INSERT INTO `journal_entry_lines` (`id`,`entry_id`,`line_number`,`account_id`,`party_id`,`cost_center_id`,`debit`,`credit`,`description`,`currency_code`,`exchange_rate`,`amount_currency`,`created_at`) VALUES ('jel_1793911218470_6_x0m','je_1793911218466_tyu3l',6,'acc_5111',NULL,NULL,0,18500,'عكس تكلفة مبيعات RET-2026-CAI-000001','EGP',1,18500,'2026-11-05 20:40:18');
INSERT INTO `sales_invoices` (`id`,`invoice_number`,`branch_id`,`warehouse_id`,`customer_id`,`invoice_date`,`due_date`,`payment_type`,`currency_code`,`exchange_rate`,`subtotal`,`discount_amount`,`taxable_amount`,`tax_amount`,`withholding_tax_amount`,`total_amount`,`paid_amount`,`remaining_amount`,`cogs_amount`,`status`,`notes`,`journal_entry_id`,`eta_uuid`,`eta_submission_id`,`eta_status`,`created_by`,`created_at`) VALUES ('inv_INV-2026-ALX-000003','INV-2026-ALX-000003','br_alex','wh_alex','party_cust_005','2026-02-05','2026-02-05','credit','EGP',1,57000,0,57000,7980,570,64410,0,64410,49000,'posted',NULL,'je_1793911218423_6t3v4',NULL,NULL,'SimulationAccepted','usr_sales','2026-11-05 20:40:18');
INSERT INTO `sales_invoices` (`id`,`invoice_number`,`branch_id`,`warehouse_id`,`customer_id`,`invoice_date`,`due_date`,`payment_type`,`currency_code`,`exchange_rate`,`subtotal`,`discount_amount`,`taxable_amount`,`tax_amount`,`withholding_tax_amount`,`total_amount`,`paid_amount`,`remaining_amount`,`cogs_amount`,`status`,`notes`,`journal_entry_id`,`eta_uuid`,`eta_submission_id`,`eta_status`,`created_by`,`created_at`) VALUES ('inv_INV-2026-CAI-000001','INV-2026-CAI-000001','br_cairo','wh_main','party_cust_001','2026-01-15','2026-01-15','credit','EGP',1,44000,0,44000,6160,440,49720,0,49720,37000,'posted',NULL,'je_1793911218407_dnrnl',NULL,NULL,'SimulationAccepted','usr_sales','2026-11-05 20:40:18');
INSERT INTO `sales_invoices` (`id`,`invoice_number`,`branch_id`,`warehouse_id`,`customer_id`,`invoice_date`,`due_date`,`payment_type`,`currency_code`,`exchange_rate`,`subtotal`,`discount_amount`,`taxable_amount`,`tax_amount`,`withholding_tax_amount`,`total_amount`,`paid_amount`,`remaining_amount`,`cogs_amount`,`status`,`notes`,`journal_entry_id`,`eta_uuid`,`eta_submission_id`,`eta_status`,`created_by`,`created_at`) VALUES ('inv_INV-2026-CAI-000002','INV-2026-CAI-000002','br_cairo','wh_main','party_cust_002','2026-01-22','2026-01-22','credit','EGP',1,113800,0,113800,15932,1138,128594,0,128594,94400,'posted',NULL,'je_1793911218415_ijmaf',NULL,NULL,'SimulationAccepted','usr_sales','2026-11-05 20:40:18');
INSERT INTO `sales_invoices` (`id`,`invoice_number`,`branch_id`,`warehouse_id`,`customer_id`,`invoice_date`,`due_date`,`payment_type`,`currency_code`,`exchange_rate`,`subtotal`,`discount_amount`,`taxable_amount`,`tax_amount`,`withholding_tax_amount`,`total_amount`,`paid_amount`,`remaining_amount`,`cogs_amount`,`status`,`notes`,`journal_entry_id`,`eta_uuid`,`eta_submission_id`,`eta_status`,`created_by`,`created_at`) VALUES ('inv_INV-2026-CAI-000004','INV-2026-CAI-000004','br_cairo','wh_main','party_cust_008','2026-02-18','2026-02-18','cash','EGP',1,24400,0,24400,3416,244,27572,27572,0,19600,'posted',NULL,'je_1793911218430_w88vn',NULL,NULL,'SimulationAccepted','usr_sales','2026-11-05 20:40:18');
INSERT INTO `sales_invoices` (`id`,`invoice_number`,`branch_id`,`warehouse_id`,`customer_id`,`invoice_date`,`due_date`,`payment_type`,`currency_code`,`exchange_rate`,`subtotal`,`discount_amount`,`taxable_amount`,`tax_amount`,`withholding_tax_amount`,`total_amount`,`paid_amount`,`remaining_amount`,`cogs_amount`,`status`,`notes`,`journal_entry_id`,`eta_uuid`,`eta_submission_id`,`eta_status`,`created_by`,`created_at`) VALUES ('inv_INV-2026-CAI-000005','INV-2026-CAI-000005','br_cairo','wh_main','party_cust_010','2026-03-02','2026-03-02','credit','EGP',1,27500,0,27500,3850,275,31075,0,31075,22000,'posted',NULL,'je_1793911218442_oidsg',NULL,NULL,'SimulationAccepted','usr_sales','2026-11-05 20:40:18');
INSERT INTO `sales_returns` (`id`,`return_number`,`original_invoice_id`,`branch_id`,`warehouse_id`,`customer_id`,`return_date`,`refund_type`,`subtotal`,`tax_amount`,`withholding_tax_amount`,`total_amount`,`refunded_cash_amount`,`cogs_reversed_amount`,`journal_entry_id`,`status`,`notes`,`created_by`,`created_at`) VALUES ('ret_RET-2026-CAI-000001','RET-2026-CAI-000001','inv_INV-2026-CAI-000001','br_cairo','wh_main','party_cust_001','2026-01-20','credit_note',22000,3080,220,24860,0,18500,'je_1793911218466_tyu3l','posted',NULL,'usr_sales','2026-11-05 20:40:18');
INSERT INTO `purchase_invoices` (`id`,`invoice_number`,`supplier_invoice_number`,`branch_id`,`warehouse_id`,`supplier_id`,`invoice_date`,`due_date`,`payment_type`,`currency_code`,`exchange_rate`,`subtotal`,`discount_amount`,`taxable_amount`,`tax_amount`,`withholding_tax_amount`,`additional_expenses`,`total_amount`,`paid_amount`,`remaining_amount`,`status`,`notes`,`journal_entry_id`,`created_by`,`created_at`) VALUES ('pur_PINV-2026-CAI-000001','PINV-2026-CAI-000001','SAMS-90214','br_cairo','wh_main','party_supp_001','2026-01-10','2026-01-10','credit','EGP',1,40000,0,40000,5600,400,0,45200,0,45200,'posted',NULL,'je_1793911218452_do0m7','usr_procurement','2026-11-05 20:40:18');
INSERT INTO `purchase_invoices` (`id`,`invoice_number`,`supplier_invoice_number`,`branch_id`,`warehouse_id`,`supplier_id`,`invoice_date`,`due_date`,`payment_type`,`currency_code`,`exchange_rate`,`subtotal`,`discount_amount`,`taxable_amount`,`tax_amount`,`withholding_tax_amount`,`additional_expenses`,`total_amount`,`paid_amount`,`remaining_amount`,`status`,`notes`,`journal_entry_id`,`created_by`,`created_at`) VALUES ('pur_PINV-2026-CAI-000002','PINV-2026-CAI-000002','HP-55410','br_cairo','wh_main','party_supp_003','2026-02-01','2026-02-01','cash','EGP',1,47500,0,47500,6650,475,0,53675,53675,0,'posted',NULL,'je_1793911218459_ah63q','usr_procurement','2026-11-05 20:40:18');
INSERT INTO `cash_boxes` (`id`,`branch_id`,`code`,`name_ar`,`name_en`,`account_id`,`currency_code`,`current_balance`,`is_active`) VALUES ('cash_alex','br_alex','CASH-02','خزينة فرع الإسكندرية','Alexandria Cash Box','acc_1112','EGP',75000,1);
INSERT INTO `cash_boxes` (`id`,`branch_id`,`code`,`name_ar`,`name_en`,`account_id`,`currency_code`,`current_balance`,`is_active`) VALUES ('cash_cairo','br_cairo','CASH-01','خزينة المركز الرئيسي - القاهرة','Cairo Main Cash Box','acc_1111','EGP',150000,1);
INSERT INTO `bank_accounts` (`id`,`bank_name`,`account_number`,`iban`,`swift_code`,`branch_name`,`account_id`,`currency_code`,`current_balance`,`is_active`) VALUES ('bank_misr','بنك مصر','200987114002','EG920002020098711400200000200','BMISEGCX','فرع سموحة','acc_1114','USD',25000,1);
INSERT INTO `bank_accounts` (`id`,`bank_name`,`account_number`,`iban`,`swift_code`,`branch_name`,`account_id`,`currency_code`,`current_balance`,`is_active`) VALUES ('bank_nbe','البنك الأهلي المصري','100458921001','EG380003010045892100100000100','NBEGEGCX','فرع مكرم عبيد','acc_1113','EGP',850000,1);
INSERT INTO `payment_vouchers` (`id`,`voucher_number`,`voucher_type`,`branch_id`,`payment_method`,`cash_box_id`,`bank_account_id`,`party_id`,`direct_account_id`,`cost_center_id`,`voucher_date`,`amount`,`currency_code`,`exchange_rate`,`allocated_amount`,`unallocated_amount`,`notes`,`description`,`journal_entry_id`,`status`,`created_by`,`created_at`) VALUES ('pv_INV-2026-CAI-000004','RV-2026-000004','receipt','br_cairo','cash','cash_cairo',NULL,'party_cust_008',NULL,NULL,'2026-02-18',27572,'EGP',1,27572,0,NULL,'تحصيل نقدي للفاتورة INV-2026-CAI-000004','je_1793911218436_iwhiz','posted','usr_cashier','2026-11-05 20:40:18');
INSERT INTO `fixed_assets` (`id`,`code`,`name_ar`,`name_en`,`branch_id`,`cost_center_id`,`purchase_date`,`operation_date`,`purchase_cost`,`scrap_value`,`useful_life_years`,`depreciation_method`,`annual_depreciation_rate`,`accumulated_depreciation`,`book_value`,`asset_account_id`,`depreciation_expense_account_id`,`accumulated_depreciation_account_id`,`status`,`created_at`) VALUES ('fa_01','AST-001','أجهزة كمبيوتر وخوادم الإدارة الرئيسية','HQ Core Servers & PCs','br_cairo','cc_tech','2025-01-01','2025-01-01',120000,10000,3,'straight_line',33.33,40000,80000,'acc_1211','acc_6311','acc_1221','active','2026-11-05 20:40:18');
INSERT INTO `fixed_assets` (`id`,`code`,`name_ar`,`name_en`,`branch_id`,`cost_center_id`,`purchase_date`,`operation_date`,`purchase_cost`,`scrap_value`,`useful_life_years`,`depreciation_method`,`annual_depreciation_rate`,`accumulated_depreciation`,`book_value`,`asset_account_id`,`depreciation_expense_account_id`,`accumulated_depreciation_account_id`,`status`,`created_at`) VALUES ('fa_02','AST-002','أثاث ومكاتب المقر الرئيسي وفرع الإسكندرية','Office Furniture & Desks','br_cairo','cc_admin','2025-01-01','2025-01-01',80000,5000,5,'straight_line',20,16000,64000,'acc_1212','acc_6311','acc_1222','active','2026-11-05 20:40:18');
INSERT INTO `fixed_assets` (`id`,`code`,`name_ar`,`name_en`,`branch_id`,`cost_center_id`,`purchase_date`,`operation_date`,`purchase_cost`,`scrap_value`,`useful_life_years`,`depreciation_method`,`annual_depreciation_rate`,`accumulated_depreciation`,`book_value`,`asset_account_id`,`depreciation_expense_account_id`,`accumulated_depreciation_account_id`,`status`,`created_at`) VALUES ('fa_03','AST-003','سيارة نقل وتوزيع شيفروليه جامبو','Chevrolet Jumbo Distribution Truck','br_cairo','cc_warehouses','2025-01-01','2025-01-01',350000,50000,5,'straight_line',20,70000,280000,'acc_1213','acc_6311','acc_1223','active','2026-11-05 20:40:18');
INSERT INTO `users` (`id`,`username`,`password_hash`,`display_name`,`role`,`is_active`,`force_change_password`,`allowed_branch_ids`,`allowed_warehouse_ids`,`allowed_cashbox_ids`,`created_at`) VALUES ('usr_accountant','accountant1','$2b$10$rSEpp8jfikyvOnBNW7MvruC8sZgySu14iAsYbhv5ceJ71pnnSPKyy','الأستاذة / مي حسن (محاسب عام)','accountant',1,0,'*','*','*','2026-11-05 20:40:18');
INSERT INTO `users` (`id`,`username`,`password_hash`,`display_name`,`role`,`is_active`,`force_change_password`,`allowed_branch_ids`,`allowed_warehouse_ids`,`allowed_cashbox_ids`,`created_at`) VALUES ('usr_admin','admin','$2b$10$rSEpp8jfikyvOnBNW7MvruC8sZgySu14iAsYbhv5ceJ71pnnSPKyy','الأستاذ / شريف فوزي (مدير النظام)','admin',1,0,'*','*','*','2026-11-05 20:40:18');
INSERT INTO `users` (`id`,`username`,`password_hash`,`display_name`,`role`,`is_active`,`force_change_password`,`allowed_branch_ids`,`allowed_warehouse_ids`,`allowed_cashbox_ids`,`created_at`) VALUES ('usr_auditor','auditor','$2b$10$rSEpp8jfikyvOnBNW7MvruC8sZgySu14iAsYbhv5ceJ71pnnSPKyy','مكتب مراجعة الحسابات (مراجع قراءة فقط)','auditor_readonly',1,0,'*','*','*','2026-11-05 20:40:18');
INSERT INTO `users` (`id`,`username`,`password_hash`,`display_name`,`role`,`is_active`,`force_change_password`,`allowed_branch_ids`,`allowed_warehouse_ids`,`allowed_cashbox_ids`,`created_at`) VALUES ('usr_cashier','cashier','$2b$10$rSEpp8jfikyvOnBNW7MvruC8sZgySu14iAsYbhv5ceJ71pnnSPKyy','الأستاذة / نورهان كمال (أمين الخزينة)','cashier',1,0,'*','*','*','2026-11-05 20:40:18');
INSERT INTO `users` (`id`,`username`,`password_hash`,`display_name`,`role`,`is_active`,`force_change_password`,`allowed_branch_ids`,`allowed_warehouse_ids`,`allowed_cashbox_ids`,`created_at`) VALUES ('usr_fin_mgr','financial_mgr','$2b$10$rSEpp8jfikyvOnBNW7MvruC8sZgySu14iAsYbhv5ceJ71pnnSPKyy','المحاسب القانوني / محمد عبد الرحمن (المدير المالي)','finance_manager',1,0,'*','*','*','2026-11-05 20:40:18');
INSERT INTO `users` (`id`,`username`,`password_hash`,`display_name`,`role`,`is_active`,`force_change_password`,`allowed_branch_ids`,`allowed_warehouse_ids`,`allowed_cashbox_ids`,`created_at`) VALUES ('usr_owner','owner','$2b$10$rSEpp8jfikyvOnBNW7MvruC8sZgySu14iAsYbhv5ceJ71pnnSPKyy','المهندس / أحمد البدري (المالك)','owner',1,0,'*','*','*','2026-11-05 20:40:18');
INSERT INTO `users` (`id`,`username`,`password_hash`,`display_name`,`role`,`is_active`,`force_change_password`,`allowed_branch_ids`,`allowed_warehouse_ids`,`allowed_cashbox_ids`,`created_at`) VALUES ('usr_procurement','procurement','$2b$10$rSEpp8jfikyvOnBNW7MvruC8sZgySu14iAsYbhv5ceJ71pnnSPKyy','الأستاذ / طارق جلال (مسؤول المشتريات)','purchase_officer',1,0,'*','*','*','2026-11-05 20:40:18');
INSERT INTO `users` (`id`,`username`,`password_hash`,`display_name`,`role`,`is_active`,`force_change_password`,`allowed_branch_ids`,`allowed_warehouse_ids`,`allowed_cashbox_ids`,`created_at`) VALUES ('usr_sales','sales_rep','$2b$10$rSEpp8jfikyvOnBNW7MvruC8sZgySu14iAsYbhv5ceJ71pnnSPKyy','الأستاذ / كريم سليم (مسؤول المبيعات)','sales_officer',1,0,'*','*','*','2026-11-05 20:40:18');
INSERT INTO `users` (`id`,`username`,`password_hash`,`display_name`,`role`,`is_active`,`force_change_password`,`allowed_branch_ids`,`allowed_warehouse_ids`,`allowed_cashbox_ids`,`created_at`) VALUES ('usr_storekeeper','storekeeper','$2b$10$rSEpp8jfikyvOnBNW7MvruC8sZgySu14iAsYbhv5ceJ71pnnSPKyy','العم / حسن رضوان (أمين المخزن الرئيسي)','storekeeper',1,0,'*','*','*','2026-11-05 20:40:18');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_accounts.create','accountant','accounts.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_accounts.edit','accountant','accounts.edit');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_accounts_view','accountant','accounts.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_add','accountant','add');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_aging_view','accountant','aging.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_bank_reconciliation_view','accountant','bank_reconciliation.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_bank_reconcile','accountant','bank.reconcile');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_dashboard_view','accountant','dashboard.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_delete_draft','accountant','delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_edit_draft','accountant','edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_eta_view','accountant','eta.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_excel_analytics_chat','accountant','excel_analytics.chat');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_excel_analytics_export','accountant','excel_analytics.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_excel_analytics_view','accountant','excel_analytics.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_excel_import_view','accountant','excel_import.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_export','accountant','export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_import_excel','accountant','import.excel');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_inventory_count_view','accountant','inventory_count.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_inventory_count','accountant','inventory.count');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_inventory_view','accountant','inventory.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_items_view','accountant','items.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_journal_create','accountant','journal.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_journal_delete_draft','accountant','journal.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_journal_edit_draft','accountant','journal.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_journal_export','accountant','journal.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_journal_post','accountant','journal.post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_journal_print','accountant','journal.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_journal_view','accountant','journal.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_month_close_view','accountant','month_close.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_parties_create','accountant','parties.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_parties_edit','accountant','parties.edit');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_parties_statement','accountant','parties.statement');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_parties_view','accountant','parties.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_period_review','accountant','period.review');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_post','accountant','post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_print','accountant','print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_purchase_returns_create','accountant','purchase_returns.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_purchase_returns_delete_draft','accountant','purchase_returns.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_purchase_returns_edit_draft','accountant','purchase_returns.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_purchase_returns_post','accountant','purchase_returns.post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_purchase_returns_print','accountant','purchase_returns.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_purchase_returns_view','accountant','purchase_returns.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_purchases_create','accountant','purchases.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_purchases_delete_draft','accountant','purchases.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_purchases_edit_draft','accountant','purchases.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_purchases_export','accountant','purchases.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_purchases_post','accountant','purchases.post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_purchases_print','accountant','purchases.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_purchases_view','accountant','purchases.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_reports_export','accountant','reports.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_reports_print','accountant','reports.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_reports_view','accountant','reports.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_sales_returns_create','accountant','sales_returns.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_sales_returns_delete_draft','accountant','sales_returns.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_sales_returns_edit_draft','accountant','sales_returns.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_sales_returns_post','accountant','sales_returns.post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_sales_returns_print','accountant','sales_returns.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_sales_returns_view','accountant','sales_returns.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_sales_create','accountant','sales.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_sales_delete_draft','accountant','sales.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_sales_edit_draft','accountant','sales.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_sales_export','accountant','sales.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_sales_post','accountant','sales.post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_sales_print','accountant','sales.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_sales_view','accountant','sales.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_treasury_payment','accountant','treasury.payment');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_treasury_payment_create','accountant','treasury.payment.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_treasury_print','accountant','treasury.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_treasury_receipt','accountant','treasury.receipt');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_treasury_receipt_create','accountant','treasury.receipt.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_treasury_view','accountant','treasury.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_view','accountant','view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_view_cost','accountant','view_cost');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_accountant_view_profit','accountant','view_profit');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_accounts_create','admin','accounts.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_accounts_delete','admin','accounts.delete');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_accounts_edit','admin','accounts.edit');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_accounts_manage','admin','accounts.manage');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_accounts_view','admin','accounts.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_add','admin','add');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_aging_view','admin','aging.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_approve','admin','approve');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_backup_create','admin','backup.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_backup_restore','admin','backup.restore');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_backup_view','admin','backup.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_bank_reconciliation_view','admin','bank_reconciliation.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_bank_reconcile','admin','bank.reconcile');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_dashboard_view','admin','dashboard.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_delete_draft','admin','delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_edit_draft','admin','edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_eta_send','admin','eta.send');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_eta_view','admin','eta.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_excel_analytics_chat','admin','excel_analytics.chat');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_excel_analytics_export','admin','excel_analytics.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_excel_analytics_view','admin','excel_analytics.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_excel_import_view','admin','excel_import.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_export','admin','export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_import_excel','admin','import.excel');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_inventory_count_view','admin','inventory_count.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_inventory_count','admin','inventory.count');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_inventory_view','admin','inventory.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_items_create','admin','items.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_items_delete','admin','items.delete');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_items_edit','admin','items.edit');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_items_manage','admin','items.manage');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_items_view','admin','items.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_journal_create','admin','journal.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_journal_delete_draft','admin','journal.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_journal_edit_draft','admin','journal.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_journal_export','admin','journal.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_journal_post','admin','journal.post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_journal_print','admin','journal.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_journal_reverse','admin','journal.reverse');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_journal_view','admin','journal.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_manage_settings','admin','manage_settings');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_month_close_view','admin','month_close.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_parties_create','admin','parties.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_parties_delete','admin','parties.delete');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_parties_edit','admin','parties.edit');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_parties_statement','admin','parties.statement');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_parties_view','admin','parties.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_period_close','admin','period.close');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_period_reopen','admin','period.reopen');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_period_review','admin','period.review');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_post','admin','post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_print','admin','print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_purchase_returns_create','admin','purchase_returns.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_purchase_returns_delete_draft','admin','purchase_returns.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_purchase_returns_edit_draft','admin','purchase_returns.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_purchase_returns_post','admin','purchase_returns.post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_purchase_returns_print','admin','purchase_returns.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_purchase_returns_reverse','admin','purchase_returns.reverse');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_purchase_returns_view','admin','purchase_returns.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_purchases_create','admin','purchases.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_purchases_delete_draft','admin','purchases.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_purchases_edit_draft','admin','purchases.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_purchases_export','admin','purchases.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_purchases_post','admin','purchases.post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_purchases_print','admin','purchases.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_purchases_reverse','admin','purchases.reverse');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_purchases_view','admin','purchases.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_reopen_period','admin','reopen_period');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_reports_export','admin','reports.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_reports_print','admin','reports.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_reports_view','admin','reports.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_reverse','admin','reverse');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_sales_returns_create','admin','sales_returns.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_sales_returns_delete_draft','admin','sales_returns.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_sales_returns_edit_draft','admin','sales_returns.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_sales_returns_post','admin','sales_returns.post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_sales_returns_print','admin','sales_returns.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_sales_returns_reverse','admin','sales_returns.reverse');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_sales_returns_view','admin','sales_returns.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_sales_create','admin','sales.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_sales_delete_draft','admin','sales.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_sales_edit_draft','admin','sales.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_sales_export','admin','sales.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_sales_post','admin','sales.post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_sales_print','admin','sales.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_sales_reverse','admin','sales.reverse');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_sales_view','admin','sales.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_tests_run','admin','tests.run');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_tests_view','admin','tests.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_treasury_payment','admin','treasury.payment');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_treasury_payment_create','admin','treasury.payment.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_treasury_print','admin','treasury.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_treasury_receipt','admin','treasury.receipt');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_treasury_receipt_create','admin','treasury.receipt.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_treasury_reverse','admin','treasury.reverse');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_treasury_view','admin','treasury.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_users_manage','admin','users.manage');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_users_view','admin','users.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_view','admin','view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_view_cost','admin','view_cost');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_admin_view_profit','admin','view_profit');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_accounts_view','auditor_readonly','accounts.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_aging_view','auditor_readonly','aging.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_bank_reconciliation_view','auditor_readonly','bank_reconciliation.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_dashboard_view','auditor_readonly','dashboard.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_eta.view','auditor_readonly','eta.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_excel_analytics_export','auditor_readonly','excel_analytics.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_excel_analytics_view','auditor_readonly','excel_analytics.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_export','auditor_readonly','export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_inventory_count_view','auditor_readonly','inventory_count.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_inventory_view','auditor_readonly','inventory.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_items_view','auditor_readonly','items.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_journal_view','auditor_readonly','journal.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_month_close_view','auditor_readonly','month_close.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_parties_view','auditor_readonly','parties.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_print','auditor_readonly','print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_purchase_returns_view','auditor_readonly','purchase_returns.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_purchases_view','auditor_readonly','purchases.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_reports_export','auditor_readonly','reports.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_reports_print','auditor_readonly','reports.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_reports_view','auditor_readonly','reports.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_sales_returns_view','auditor_readonly','sales_returns.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_sales_view','auditor_readonly','sales.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_treasury_view','auditor_readonly','treasury.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_view','auditor_readonly','view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_view_cost','auditor_readonly','view_cost');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_auditor_readonly_view_profit','auditor_readonly','view_profit');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_cashier_add','cashier','add');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_cashier_dashboard_view','cashier','dashboard.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_cashier_parties.view','cashier','parties.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_cashier_print','cashier','print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_cashier_sales.view','cashier','sales.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_cashier_treasury.payment','cashier','treasury.payment');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_cashier_treasury.payment.create','cashier','treasury.payment.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_cashier_treasury_print','cashier','treasury.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_cashier_treasury_receipt','cashier','treasury.receipt');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_cashier_treasury_receipt_create','cashier','treasury.receipt.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_cashier_treasury_view','cashier','treasury.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_cashier_view','cashier','view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_accounts_create','finance_manager','accounts.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_accounts_edit','finance_manager','accounts.edit');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_accounts_manage','finance_manager','accounts.manage');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_accounts_view','finance_manager','accounts.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_add','finance_manager','add');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_aging_view','finance_manager','aging.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_approve','finance_manager','approve');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_bank_reconciliation_view','finance_manager','bank_reconciliation.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_bank_reconcile','finance_manager','bank.reconcile');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_dashboard_view','finance_manager','dashboard.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_delete_draft','finance_manager','delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_edit_draft','finance_manager','edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_eta.send','finance_manager','eta.send');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_eta_view','finance_manager','eta.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_excel_analytics_chat','finance_manager','excel_analytics.chat');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_excel_analytics_export','finance_manager','excel_analytics.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_excel_analytics_view','finance_manager','excel_analytics.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_excel_import_view','finance_manager','excel_import.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_export','finance_manager','export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_import_excel','finance_manager','import.excel');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_inventory_count_view','finance_manager','inventory_count.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_inventory_count','finance_manager','inventory.count');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_inventory_view','finance_manager','inventory.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_items_view','finance_manager','items.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_journal_create','finance_manager','journal.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_journal_delete_draft','finance_manager','journal.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_journal_edit_draft','finance_manager','journal.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_journal_export','finance_manager','journal.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_journal_post','finance_manager','journal.post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_journal_print','finance_manager','journal.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_journal_reverse','finance_manager','journal.reverse');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_journal_view','finance_manager','journal.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_month_close_view','finance_manager','month_close.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_parties_create','finance_manager','parties.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_parties_edit','finance_manager','parties.edit');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_parties_statement','finance_manager','parties.statement');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_parties_view','finance_manager','parties.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_period_close','finance_manager','period.close');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_period_reopen','finance_manager','period.reopen');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_period_review','finance_manager','period.review');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_post','finance_manager','post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_print','finance_manager','print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_purchase_returns_create','finance_manager','purchase_returns.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_purchase_returns_delete_draft','finance_manager','purchase_returns.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_purchase_returns_edit_draft','finance_manager','purchase_returns.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_purchase_returns_post','finance_manager','purchase_returns.post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_purchase_returns_print','finance_manager','purchase_returns.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_purchase_returns_reverse','finance_manager','purchase_returns.reverse');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_purchase_returns_view','finance_manager','purchase_returns.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_purchases_create','finance_manager','purchases.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_purchases_delete_draft','finance_manager','purchases.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_purchases_edit_draft','finance_manager','purchases.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_purchases_export','finance_manager','purchases.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_purchases_post','finance_manager','purchases.post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_purchases_print','finance_manager','purchases.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_purchases_reverse','finance_manager','purchases.reverse');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_purchases_view','finance_manager','purchases.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_reopen_period','finance_manager','reopen_period');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_reports_export','finance_manager','reports.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_reports_print','finance_manager','reports.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_reports_view','finance_manager','reports.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_reverse','finance_manager','reverse');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_sales_returns_create','finance_manager','sales_returns.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_sales_returns_delete_draft','finance_manager','sales_returns.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_sales_returns_edit_draft','finance_manager','sales_returns.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_sales_returns_post','finance_manager','sales_returns.post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_sales_returns_print','finance_manager','sales_returns.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_sales_returns_reverse','finance_manager','sales_returns.reverse');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_sales_returns_view','finance_manager','sales_returns.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_sales_create','finance_manager','sales.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_sales_delete_draft','finance_manager','sales.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_sales_edit_draft','finance_manager','sales.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_sales_export','finance_manager','sales.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_sales_post','finance_manager','sales.post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_sales_print','finance_manager','sales.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_sales_reverse','finance_manager','sales.reverse');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_sales_view','finance_manager','sales.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_tests_view','finance_manager','tests.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_treasury_payment','finance_manager','treasury.payment');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_treasury_payment_create','finance_manager','treasury.payment.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_treasury_print','finance_manager','treasury.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_treasury_receipt','finance_manager','treasury.receipt');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_treasury_receipt_create','finance_manager','treasury.receipt.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_treasury_reverse','finance_manager','treasury.reverse');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_treasury_view','finance_manager','treasury.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_view','finance_manager','view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_view_cost','finance_manager','view_cost');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_finance_manager_view_profit','finance_manager','view_profit');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_*','owner','*');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_accounts.create','owner','accounts.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_accounts.delete','owner','accounts.delete');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_accounts.edit','owner','accounts.edit');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_accounts.manage','owner','accounts.manage');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_accounts.view','owner','accounts.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_add','owner','add');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_approve','owner','approve');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_dashboard.view','owner','dashboard.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_delete_draft','owner','delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_edit_draft','owner','edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_eta.send','owner','eta.send');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_eta.view','owner','eta.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_export','owner','export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_inventory.view','owner','inventory.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_items.create','owner','items.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_items.delete','owner','items.delete');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_items.edit','owner','items.edit');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_items.manage','owner','items.manage');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_items.view','owner','items.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_journal.create','owner','journal.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_journal.delete_draft','owner','journal.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_journal.edit_draft','owner','journal.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_journal.export','owner','journal.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_journal.post','owner','journal.post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_journal.print','owner','journal.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_journal.reverse','owner','journal.reverse');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_journal.view','owner','journal.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_manage_settings','owner','manage_settings');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_parties.create','owner','parties.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_parties.delete','owner','parties.delete');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_parties.edit','owner','parties.edit');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_parties.statement','owner','parties.statement');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_parties.view','owner','parties.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_post','owner','post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_print','owner','print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_purchase_returns.create','owner','purchase_returns.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_purchase_returns.delete_draft','owner','purchase_returns.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_purchase_returns.edit_draft','owner','purchase_returns.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_purchase_returns.post','owner','purchase_returns.post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_purchase_returns.print','owner','purchase_returns.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_purchase_returns.reverse','owner','purchase_returns.reverse');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_purchase_returns.view','owner','purchase_returns.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_purchases.create','owner','purchases.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_purchases.delete_draft','owner','purchases.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_purchases.edit_draft','owner','purchases.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_purchases.export','owner','purchases.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_purchases.post','owner','purchases.post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_purchases.print','owner','purchases.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_purchases.reverse','owner','purchases.reverse');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_purchases.view','owner','purchases.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_reopen_period','owner','reopen_period');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_reports.export','owner','reports.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_reports.print','owner','reports.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_reports.view','owner','reports.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_reverse','owner','reverse');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_sales_returns.create','owner','sales_returns.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_sales_returns.delete_draft','owner','sales_returns.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_sales_returns.edit_draft','owner','sales_returns.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_sales_returns.post','owner','sales_returns.post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_sales_returns.print','owner','sales_returns.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_sales_returns.reverse','owner','sales_returns.reverse');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_sales_returns.view','owner','sales_returns.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_sales.create','owner','sales.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_sales.delete_draft','owner','sales.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_sales.edit_draft','owner','sales.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_sales.export','owner','sales.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_sales.post','owner','sales.post');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_sales.print','owner','sales.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_sales.reverse','owner','sales.reverse');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_sales.view','owner','sales.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_tests.run','owner','tests.run');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_tests.view','owner','tests.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_treasury.payment','owner','treasury.payment');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_treasury.payment.create','owner','treasury.payment.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_treasury.print','owner','treasury.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_treasury.receipt','owner','treasury.receipt');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_treasury.receipt.create','owner','treasury.receipt.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_treasury.reverse','owner','treasury.reverse');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_treasury.view','owner','treasury.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_users.manage','owner','users.manage');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_users.view','owner','users.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_view','owner','view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_view_cost','owner','view_cost');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_owner_view_profit','owner','view_profit');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_add','purchase_officer','add');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_dashboard_view','purchase_officer','dashboard.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_delete_draft','purchase_officer','delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_edit_draft','purchase_officer','edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_inventory_view','purchase_officer','inventory.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_items_view','purchase_officer','items.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_parties_create','purchase_officer','parties.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_parties_edit','purchase_officer','parties.edit');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_parties_statement','purchase_officer','parties.statement');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_parties_view','purchase_officer','parties.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_print','purchase_officer','print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_purchase_returns_create','purchase_officer','purchase_returns.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_purchase_returns_delete_draft','purchase_officer','purchase_returns.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_purchase_returns_edit_draft','purchase_officer','purchase_returns.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_purchase_returns_print','purchase_officer','purchase_returns.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_purchase_returns_view','purchase_officer','purchase_returns.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_purchases_create','purchase_officer','purchases.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_purchases_delete_draft','purchase_officer','purchases.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_purchases_edit_draft','purchase_officer','purchases.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_purchases_export','purchase_officer','purchases.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_purchases_print','purchase_officer','purchases.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_purchases_view','purchase_officer','purchases.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_view','purchase_officer','view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_purchase_officer_view_cost','purchase_officer','view_cost');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_add','sales_officer','add');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_dashboard_view','sales_officer','dashboard.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_delete_draft','sales_officer','delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_edit_draft','sales_officer','edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_inventory_view','sales_officer','inventory.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_items_view','sales_officer','items.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_parties_create','sales_officer','parties.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_parties_edit','sales_officer','parties.edit');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_parties_statement','sales_officer','parties.statement');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_parties_view','sales_officer','parties.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_print','sales_officer','print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_sales_returns_create','sales_officer','sales_returns.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_sales_returns_delete_draft','sales_officer','sales_returns.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_sales_returns_edit_draft','sales_officer','sales_returns.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_sales_returns_print','sales_officer','sales_returns.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_sales_returns_view','sales_officer','sales_returns.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_sales_create','sales_officer','sales.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_sales_delete_draft','sales_officer','sales.delete_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_sales_edit_draft','sales_officer','sales.edit_draft');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_sales_export','sales_officer','sales.export');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_sales_print','sales_officer','sales.print');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_sales_view','sales_officer','sales.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_sales_officer_view','sales_officer','view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_storekeeper_inventory_count_view','storekeeper','inventory_count.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_storekeeper_inventory_count','storekeeper','inventory.count');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_storekeeper_inventory_view','storekeeper','inventory.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_storekeeper_items_create','storekeeper','items.create');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_storekeeper_items_edit','storekeeper','items.edit');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_storekeeper_items_manage','storekeeper','items.manage');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_storekeeper_items_view','storekeeper','items.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_storekeeper_purchases.view','storekeeper','purchases.view');
INSERT INTO `user_permissions` (`id`,`role`,`permission_key`) VALUES ('perm_storekeeper_sales.view','storekeeper','sales.view');
INSERT INTO `audit_logs` (`id`,`user_id`,`action`,`entity_type`,`entity_id`,`details`,`old_values`,`new_values`,`ip_address`,`created_at`) VALUES ('audit_1793911218403_ajecf','usr_fin_mgr','POST_JOURNAL','journal_entries','je_1793911218393_c0drh','ترحيل قيد يومية برقم JV-2026-CAI-000001',NULL,NULL,NULL,'2026-11-05 20:40:18');
INSERT INTO `audit_logs` (`id`,`user_id`,`action`,`entity_type`,`entity_id`,`details`,`old_values`,`new_values`,`ip_address`,`created_at`) VALUES ('audit_1793911218411_2qy90','usr_sales','POST_JOURNAL','journal_entries','je_1793911218407_dnrnl','ترحيل قيد يومية برقم JV-2026-CAI-000002',NULL,NULL,NULL,'2026-11-05 20:40:18');
INSERT INTO `audit_logs` (`id`,`user_id`,`action`,`entity_type`,`entity_id`,`details`,`old_values`,`new_values`,`ip_address`,`created_at`) VALUES ('audit_1793911218419_7syv5','usr_sales','POST_JOURNAL','journal_entries','je_1793911218415_ijmaf','ترحيل قيد يومية برقم JV-2026-CAI-000003',NULL,NULL,NULL,'2026-11-05 20:40:18');
INSERT INTO `audit_logs` (`id`,`user_id`,`action`,`entity_type`,`entity_id`,`details`,`old_values`,`new_values`,`ip_address`,`created_at`) VALUES ('audit_1793911218427_rljwx','usr_sales','POST_JOURNAL','journal_entries','je_1793911218423_6t3v4','ترحيل قيد يومية برقم JV-2026-ALX-000001',NULL,NULL,NULL,'2026-11-05 20:40:18');
INSERT INTO `audit_logs` (`id`,`user_id`,`action`,`entity_type`,`entity_id`,`details`,`old_values`,`new_values`,`ip_address`,`created_at`) VALUES ('audit_1793911218434_zgbx6','usr_sales','POST_JOURNAL','journal_entries','je_1793911218430_w88vn','ترحيل قيد يومية برقم JV-2026-CAI-000004',NULL,NULL,NULL,'2026-11-05 20:40:18');
INSERT INTO `audit_logs` (`id`,`user_id`,`action`,`entity_type`,`entity_id`,`details`,`old_values`,`new_values`,`ip_address`,`created_at`) VALUES ('audit_1793911218440_zgaqg','usr_cashier','POST_JOURNAL','journal_entries','je_1793911218436_iwhiz','ترحيل قيد يومية برقم JV-2026-CAI-000005',NULL,NULL,NULL,'2026-11-05 20:40:18');
INSERT INTO `audit_logs` (`id`,`user_id`,`action`,`entity_type`,`entity_id`,`details`,`old_values`,`new_values`,`ip_address`,`created_at`) VALUES ('audit_1793911218446_zbgtu','usr_sales','POST_JOURNAL','journal_entries','je_1793911218442_oidsg','ترحيل قيد يومية برقم JV-2026-CAI-000006',NULL,NULL,NULL,'2026-11-05 20:40:18');
INSERT INTO `audit_logs` (`id`,`user_id`,`action`,`entity_type`,`entity_id`,`details`,`old_values`,`new_values`,`ip_address`,`created_at`) VALUES ('audit_1793911218454_5q4of','usr_procurement','POST_JOURNAL','journal_entries','je_1793911218452_do0m7','ترحيل قيد يومية برقم JV-2026-CAI-000007',NULL,NULL,NULL,'2026-11-05 20:40:18');
INSERT INTO `audit_logs` (`id`,`user_id`,`action`,`entity_type`,`entity_id`,`details`,`old_values`,`new_values`,`ip_address`,`created_at`) VALUES ('audit_1793911218462_1p76m','usr_procurement','POST_JOURNAL','journal_entries','je_1793911218459_ah63q','ترحيل قيد يومية برقم JV-2026-CAI-000008',NULL,NULL,NULL,'2026-11-05 20:40:18');
INSERT INTO `audit_logs` (`id`,`user_id`,`action`,`entity_type`,`entity_id`,`details`,`old_values`,`new_values`,`ip_address`,`created_at`) VALUES ('audit_1793911218470_w44y5','usr_sales','POST_JOURNAL','journal_entries','je_1793911218466_tyu3l','ترحيل قيد يومية برقم JV-2026-CAI-000009',NULL,NULL,NULL,'2026-11-05 20:40:18');
INSERT INTO `system_settings` (`setting_key`,`setting_value`,`updated_at`) VALUES ('allow_negative_stock','false','2026-11-05 20:40:17');
INSERT INTO `item_categories` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`is_active`,`created_at`) VALUES ('cat_accessories','CAT-05','ملحقات وإكسسوارات','Accessories & Peripherals',NULL,1,'2026-11-05 20:40:17');
INSERT INTO `item_categories` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`is_active`,`created_at`) VALUES ('cat_display','CAT-02','شاشات وعرض','Monitors & Displays',NULL,1,'2026-11-05 20:40:17');
INSERT INTO `item_categories` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`is_active`,`created_at`) VALUES ('cat_hardware','CAT-01','أجهزة حاسب آلي','Computers & Laptops',NULL,1,'2026-11-05 20:40:17');
INSERT INTO `item_categories` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`is_active`,`created_at`) VALUES ('cat_network','CAT-04','شبكات واتصالات','Networking & Telecom',NULL,1,'2026-11-05 20:40:17');
INSERT INTO `item_categories` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`is_active`,`created_at`) VALUES ('cat_printers','CAT-03','طابعات وماسحات','Printers & Scanners',NULL,1,'2026-11-05 20:40:17');
INSERT INTO `item_categories` (`id`,`code`,`name_ar`,`name_en`,`parent_id`,`is_active`,`created_at`) VALUES ('cat_services','CAT-06','خدمات فنية','Technical Services',NULL,1,'2026-11-05 20:40:17');
INSERT INTO `party_sequences` (`type`,`last_number`) VALUES ('customer',20);
INSERT INTO `party_sequences` (`type`,`last_number`) VALUES ('supplier',15);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('parent_acc_1',2);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('parent_acc_11',5);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('parent_acc_111',4);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('parent_acc_112',2);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('parent_acc_113',2);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('parent_acc_114',3);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('parent_acc_115',2);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('parent_acc_12',23);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('parent_acc_2',1);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('parent_acc_21',41);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('parent_acc_211',1);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('parent_acc_213',3);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('parent_acc_3',1);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('parent_acc_31',11);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('parent_acc_4',511);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('parent_acc_41',13);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('parent_acc_5',1);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('parent_acc_51',12);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('parent_acc_6',1);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('parent_acc_61',11);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('root_asset',1);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('root_cogs',5);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('root_equity',3);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('root_expense',6);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('root_liability',2);
INSERT INTO `account_sequences` (`sequence_key`,`last_number`) VALUES ('root_revenue',4);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_001','ITM-0001','622100000001','لابتوب ديل فوسترو 3520 كور i5 رام 8 جيجا هارد 512 SSD','Dell Vostro 3520 Core i5 8GB 512GB SSD','stock','أجهزة حاسب آلي','قطعة',18500,22000,5,18500,14,'EG-458921364-IT01','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_002','ITM-0002','622100000002','لابتوب إتش بي 250 G9 كور i7 رام 16 جيجا هارد 1 تيرا SSD','HP 250 G9 Core i7 16GB 1TB SSD','stock','أجهزة حاسب آلي','قطعة',26000,31000,5,26000,14,'EG-458921364-IT02','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_003','ITM-0003','622100000003','لابتوب لينوفو ثينك باد E14 كور i5 الجيل 13','Lenovo ThinkPad E14 Gen 5 i5','stock','أجهزة حاسب آلي','قطعة',24500,28500,5,24500,14,'EG-458921364-IT03','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_004','ITM-0004','622100000004','كمبيوتر مكتبي ديل أوبتيبليكس 3000 ميني تاور','Dell OptiPlex 3000 MT Core i5','stock','أجهزة حاسب آلي','قطعة',16500,19500,5,16500,14,'EG-458921364-IT04','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_005','ITM-0005','622100000005','سيرفر إتش بي بروليانت ML30 الجيل العاشر','HPE ProLiant ML30 Gen10 Server','stock','أجهزة حاسب آلي','قطعة',65000,78000,5,65000,14,'EG-458921364-IT05','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_006','ITM-0006','622100000006','لابتوب أسوس زينبوك 14 شاشة أوليد كور i7','Asus ZenBook 14 OLED Core i7','stock','أجهزة حاسب آلي','قطعة',38000,44000,5,38000,14,'EG-458921364-IT06','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_007','ITM-0007','622100000007','جهاز أبل ماك بوك أير M2 شاشة 13.6 بوصة رام 8 جيجا','Apple MacBook Air M2 13.6 8GB 256GB','stock','أجهزة حاسب آلي','قطعة',42000,49500,5,42000,14,'EG-458921364-IT07','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_008','ITM-0008','622100000008','محطة عمل لينوفو ثينك ستيشن P3 تاور للمهندسين','Lenovo ThinkStation P3 Tower Workstation','stock','أجهزة حاسب آلي','قطعة',72000,86000,5,72000,14,'EG-458921364-IT08','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_009','ITM-0009','622100000009','كمبيوتر ديل أول إن ون شاشة 24 بوصة لمس','Dell Inspiron All-in-One 24 Touch','stock','أجهزة حاسب آلي','قطعة',25000,29500,5,25000,14,'EG-458921364-IT09','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_010','ITM-0010','622100000010','لابتوب إيسر أسباير 5 كور i5 بطاقة شاشة مستقلة','Acer Aspire 5 Core i5 Dedicated GPU','stock','أجهزة حاسب آلي','قطعة',19500,23200,5,19500,14,'EG-458921364-IT10','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_011','ITM-0011','622100000011','شاشة ديل 24 بوصة فل إتش دي IPS بدون حواف','Dell 24 FHD IPS Borderless Monitor E2423H','stock','شاشات وعرض','قطعة',4100,5200,5,4100,14,'EG-458921364-DIS01','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_012','ITM-0012','622100000012','شاشة سامسونج 27 بوصة منحنية 75 هرتز','Samsung 27 Curved Monitor Essential','stock','شاشات وعرض','قطعة',5600,6900,5,5600,14,'EG-458921364-DIS02','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_013','ITM-0013','622100000013','شاشة إتش بي 22 بوصة مضادة للتوهج للمكاتب','HP V22e 21.5 FHD Anti-Glare Monitor','stock','شاشات وعرض','قطعة',3200,3950,5,3200,14,'EG-458921364-DIS03','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_014','ITM-0014','622100000014','شاشة إل جي 32 بوصة 4K UHD للمصممين','LG 32 4K UHD Monitor HDR10','stock','شاشات وعرض','قطعة',14500,17800,5,14500,14,'EG-458921364-DIS04','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_015','ITM-0015','622100000015','شاشة بروجكتور عرض إبسون EB-E01 ساطعة 3300 لومن','Epson EB-E01 XGA 3300 Lumens Projector','stock','شاشات وعرض','قطعة',16500,19900,5,16500,14,'EG-458921364-DIS05','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_016','ITM-0016','622100000016','طابعة إتش بي ليزر جيت برو M404dn شبكة ودوبلكس','HP LaserJet Pro M404dn Duplex Network','stock','طابعات وماسحات','قطعة',9800,12200,5,9800,14,'EG-458921364-PRN01','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_017','ITM-0017','622100000017','طابعة إبسون إيكو تانك L3250 ألوان خزان حبر واي فاي','Epson EcoTank L3250 All-in-One Wi-Fi','stock','طابعات وماسحات','قطعة',7400,9100,5,7400,14,'EG-458921364-PRN02','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_018','ITM-0018','622100000018','طابعة كانون آي-سينسيس ليزر ألوان متعددة المهام','Canon i-SENSYS MF655Cdw Multifunction','stock','طابعات وماسحات','قطعة',18500,22800,5,18500,14,'EG-458921364-PRN03','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_019','ITM-0019','622100000019','ماسح ضوئي إبسون فاست فوت مكتبي سريع للوثائق','Epson WorkForce Document Scanner DS-530','stock','طابعات وماسحات','قطعة',13200,16000,5,13200,14,'EG-458921364-PRN04','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_020','ITM-0020','622100000020','طابعة باركود وإيصالات حرارية زيبرا ZD220','Zebra ZD220 Direct Thermal Barcode Printer','stock','طابعات وماسحات','قطعة',5800,7300,5,5800,14,'EG-458921364-PRN05','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_021','ITM-0021','622100000021','راوتر سيسكو 2911 للأعمال والشبكات الآمنة','Cisco 2911 Integrated Services Router','stock','شبكات واتصالات','قطعة',22000,27500,5,22000,14,'EG-458921364-NET01','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_022','ITM-0022','622100000022','سويتش شبكة تي بي لينك 24 بورت جيجابت معدني','TP-Link 24-Port Gigabit Rackmount Switch','stock','شبكات واتصالات','قطعة',3600,4500,5,3600,14,'EG-458921364-NET02','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_023','ITM-0023','622100000023','سويتش شبكة سيسكو كاتاليست 2960 بورت 48 مع PoE','Cisco Catalyst 2960 48-Port PoE Switch','stock','شبكات واتصالات','قطعة',34000,42000,5,34000,14,'EG-458921364-NET03','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_024','ITM-0024','622100000024','أكسس بوينت يوبيكويتي يونيفاي يو 6 برو واي فاي 6','Ubiquiti UniFi U6 Pro Access Point Wi-Fi 6','stock','شبكات واتصالات','قطعة',7100,8800,5,7100,14,'EG-458921364-NET04','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_025','ITM-0025','622100000025','جهاز يو بي إس شنايدر APC سمارت 1500 فولت أمبير','APC Smart-UPS 1500VA LCD 230V','stock','شبكات واتصالات','قطعة',18500,23000,5,18500,14,'EG-458921364-NET05','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_026','ITM-0026','622100000026','كيبورد وماوس لاسلكي لوجيتك MK270','Logitech MK270 Wireless Combo','stock','ملحقات وإكسسوارات','قطعة',950,1350,5,950,14,'EG-458921364-ACC01','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_027','ITM-0027','622100000027','ماوس ليزر بلوتوث لوجيتك MX ماستر 3S الفاخر','Logitech MX Master 3S Wireless Mouse','stock','ملحقات وإكسسوارات','قطعة',4200,5400,5,4200,14,'EG-458921364-ACC02','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_028','ITM-0028','622100000028','سماعة رأس مركز اتصالات جابرا إيفولف 20 يو إس بي','Jabra Evolve 20 Stereo USB Headset','stock','ملحقات وإكسسوارات','قطعة',1400,1900,5,1400,14,'EG-458921364-ACC03','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_029','ITM-0029','622100000029','كاميرا ويب لوجيتك C920 برو فل إتش دي 1080p','Logitech C920 HD Pro Webcam','stock','ملحقات وإكسسوارات','قطعة',3100,4100,5,3100,14,'EG-458921364-ACC04','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_030','ITM-0030','622100000030','هارد خارجي ويسترن ديجيتال 2 تيرا باسبورت USB 3.0','WD My Passport 2TB External HDD','stock','ملحقات وإكسسوارات','قطعة',2400,3150,5,2400,14,'EG-458921364-ACC05','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_031','ITM-0031','622100000031','وحدة تخزين سامسونج SSD خارجية T7 سعة 1 تيرا','Samsung T7 1TB Portable SSD USB 3.2','stock','ملحقات وإكسسوارات','قطعة',4900,6200,5,4900,14,'EG-458921364-ACC06','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_032','ITM-0032','622100000032','فلاشة كينجستون داتا ترافيلر 64 جيجا معدنية','Kingston 64GB DataTraveler USB 3.2','stock','ملحقات وإكسسوارات','قطعة',180,280,5,180,14,'EG-458921364-ACC07','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_033','ITM-0033','622100000033','كابل شبكة كات 6 بكرة 305 متر ماركة شنايدر','Schneider Actassi Cat6 UTP Cable 305m','stock','ملحقات وإكسسوارات','قطعة',3800,4900,5,3800,14,'EG-458921364-ACC08','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_034','ITM-0034','622100000034','خرطوشة حبر إتش بي ليزر أسود أصلية 58A','HP 58A Black Original LaserJet Toner','stock','ملحقات وإكسسوارات','قطعة',2900,3750,5,2900,14,'EG-458921364-ACC09','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_035','ITM-0035','622100000035','كرتونة ورق تصوير دبل إيه وزن 80 جرام 5 رزم (A4)','Double A Copy Paper A4 80gsm Box 5 Reams','stock','ملحقات وإكسسوارات','قطعة',780,990,5,780,14,'EG-458921364-ACC10','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_036','ITM-0036','622100000036','خدمة تركيب وتمديد شبكات محلية (لكل نقطة)','Network Cabling & Termination Service','service','خدمات فنية','خدمة',100,250,0,100,14,'EG-458921364-SRV01','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_037','ITM-0037','622100000037','عقد صيانة سنوي لأنظمة الحواسب والخوادم','Annual IT Infrastructure Maintenance Contract','service','خدمات فنية','خدمة',5000,12000,0,5000,14,'EG-458921364-SRV02','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_038','ITM-0038','622100000038','جلسة استشارات أمن سيبراني وضبط خوادم','Cybersecurity Audit & Server Hardening','service','خدمات فنية','خدمة',1500,4000,0,1500,14,'EG-458921364-SRV03','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_039','ITM-0039','622100000039','خدمة تركيب وضبط كاميرات المراقبة الرقمية','IP CCTV Installation & Configuration Service','service','خدمات فنية','خدمة',400,950,0,400,14,'EG-458921364-SRV04','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `items` (`id`,`code`,`barcode`,`name_ar`,`name_en`,`item_type`,`category`,`base_unit`,`cost_price`,`sale_price`,`min_stock_level`,`moving_avg_cost`,`tax_rate`,`eta_item_code`,`eta_code_type`,`is_active`,`created_at`,`category_id`) VALUES ('item_040','ITM-0040','622100000040','خدمة التدريب الفني وتسليم الأنظمة للعميل','On-site Technical Staff Training Service','service','خدمات فنية','خدمة',1000,2500,0,1000,14,'EG-458921364-SRV05','EGS',1,'2026-11-05 20:40:18',NULL);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_1','item_001','قطعة',1,22000,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_10','item_010','قطعة',1,23200,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_11','item_011','قطعة',1,5200,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_12','item_012','قطعة',1,6900,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_13','item_013','قطعة',1,3950,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_14','item_014','قطعة',1,17800,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_15','item_015','قطعة',1,19900,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_16','item_016','قطعة',1,12200,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_17','item_017','قطعة',1,9100,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_18','item_018','قطعة',1,22800,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_19','item_019','قطعة',1,16000,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_2','item_002','قطعة',1,31000,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_20','item_020','قطعة',1,7300,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_21','item_021','قطعة',1,27500,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_22','item_022','قطعة',1,4500,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_23','item_023','قطعة',1,42000,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_24','item_024','قطعة',1,8800,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_25','item_025','قطعة',1,23000,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_26','item_026','قطعة',1,1350,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_27','item_027','قطعة',1,5400,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_28','item_028','قطعة',1,1900,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_29','item_029','قطعة',1,4100,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_3','item_003','قطعة',1,28500,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_30','item_030','قطعة',1,3150,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_31','item_031','قطعة',1,6200,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_32','item_032','قطعة',1,280,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_33','item_033','قطعة',1,4900,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_34','item_034','قطعة',1,3750,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_35','item_035','قطعة',1,990,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_36','item_036','خدمة',1,250,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_37','item_037','خدمة',1,12000,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_38','item_038','خدمة',1,4000,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_39','item_039','خدمة',1,950,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_4','item_004','قطعة',1,19500,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_40','item_040','خدمة',1,2500,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_5','item_005','قطعة',1,78000,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_6','item_006','قطعة',1,44000,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_7','item_007','قطعة',1,49500,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_8','item_008','قطعة',1,86000,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_base_9','item_009','قطعة',1,29500,NULL,1);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_carton_26','item_026','كرتونة (10 قطع)',10,12825,NULL,0);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_carton_27','item_027','كرتونة (10 قطع)',10,51300,NULL,0);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_carton_28','item_028','كرتونة (10 قطع)',10,18050,NULL,0);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_carton_29','item_029','كرتونة (10 قطع)',10,38950,NULL,0);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_carton_30','item_030','كرتونة (10 قطع)',10,29925,NULL,0);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_carton_31','item_031','كرتونة (10 قطع)',10,58900,NULL,0);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_carton_32','item_032','كرتونة (10 قطع)',10,2660,NULL,0);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_carton_33','item_033','كرتونة (10 قطع)',10,46550,NULL,0);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_carton_34','item_034','كرتونة (10 قطع)',10,35625,NULL,0);
INSERT INTO `item_units` (`id`,`item_id`,`unit_name`,`conversion_factor`,`sale_price`,`barcode`,`is_base`) VALUES ('unit_carton_35','item_035','كرتونة (10 قطع)',10,9405,NULL,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_001',7,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_002',9,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_003',9,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_004',13,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_005',15,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_006',17,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_007',19,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_008',21,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_009',23,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_010',5,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_011',7,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_012',9,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_013',11,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_014',13,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_015',15,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_016',17,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_017',19,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_018',21,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_019',23,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_020',5,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_021',7,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_022',9,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_023',11,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_024',13,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_025',15,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_026',17,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_027',19,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_028',21,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_029',23,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_030',5,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_031',7,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_032',9,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_033',11,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_034',13,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_alex','item_035',15,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_001',17,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_002',18,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_003',24,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_004',27,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_005',30,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_006',33,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_007',36,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_008',39,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_009',42,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_010',45,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_011',54,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_012',51,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_013',54,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_014',57,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_015',60,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_016',66,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_017',66,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_018',69,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_019',72,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_020',15,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_021',17,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_022',21,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_023',24,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_024',27,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_025',30,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_026',33,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_027',36,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_028',39,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_029',42,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_030',45,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_031',48,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_032',51,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_033',54,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_034',57,0);
INSERT INTO `warehouse_stock` (`warehouse_id`,`item_id`,`quantity`,`reserved_qty`) VALUES ('wh_main','item_035',60,0);
INSERT INTO `sales_invoice_items` (`id`,`invoice_id`,`item_id`,`unit_name`,`unit_factor`,`quantity`,`returned_quantity`,`unit_price`,`cost_price`,`discount_percent`,`discount_amount`,`tax_rate`,`tax_amount`,`total_amount`) VALUES ('sii_INV-2026-ALX-000003_item_003','inv_INV-2026-ALX-000003','item_003','قطعة',1,2,0,28500,24500,0,0,14,7980,64980);
INSERT INTO `sales_invoice_items` (`id`,`invoice_id`,`item_id`,`unit_name`,`unit_factor`,`quantity`,`returned_quantity`,`unit_price`,`cost_price`,`discount_percent`,`discount_amount`,`tax_rate`,`tax_amount`,`total_amount`) VALUES ('sii_INV-2026-CAI-000001_item_001','inv_INV-2026-CAI-000001','item_001','قطعة',1,2,1,22000,18500,0,0,14,6160,50160);
INSERT INTO `sales_invoice_items` (`id`,`invoice_id`,`item_id`,`unit_name`,`unit_factor`,`quantity`,`returned_quantity`,`unit_price`,`cost_price`,`discount_percent`,`discount_amount`,`tax_rate`,`tax_amount`,`total_amount`) VALUES ('sii_INV-2026-CAI-000002_item_002','inv_INV-2026-CAI-000002','item_002','قطعة',1,3,0,31000,26000,0,0,14,13020,106020);
INSERT INTO `sales_invoice_items` (`id`,`invoice_id`,`item_id`,`unit_name`,`unit_factor`,`quantity`,`returned_quantity`,`unit_price`,`cost_price`,`discount_percent`,`discount_amount`,`tax_rate`,`tax_amount`,`total_amount`) VALUES ('sii_INV-2026-CAI-000002_item_011','inv_INV-2026-CAI-000002','item_011','قطعة',1,4,0,5200,4100,0,0,14,2912,23712);
INSERT INTO `sales_invoice_items` (`id`,`invoice_id`,`item_id`,`unit_name`,`unit_factor`,`quantity`,`returned_quantity`,`unit_price`,`cost_price`,`discount_percent`,`discount_amount`,`tax_rate`,`tax_amount`,`total_amount`) VALUES ('sii_INV-2026-CAI-000004_item_016','inv_INV-2026-CAI-000004','item_016','قطعة',1,2,0,12200,9800,0,0,14,3416,27816);
INSERT INTO `sales_invoice_items` (`id`,`invoice_id`,`item_id`,`unit_name`,`unit_factor`,`quantity`,`returned_quantity`,`unit_price`,`cost_price`,`discount_percent`,`discount_amount`,`tax_rate`,`tax_amount`,`total_amount`) VALUES ('sii_INV-2026-CAI-000005_item_021','inv_INV-2026-CAI-000005','item_021','قطعة',1,1,0,27500,22000,0,0,14,3850,31350);
INSERT INTO `sales_return_items` (`id`,`return_id`,`original_invoice_item_id`,`item_id`,`unit_name`,`unit_factor`,`quantity`,`unit_price`,`unit_cost`,`tax_rate`,`tax_amount`,`total_amount`) VALUES ('sri_RET-2026-CAI-000001_item001','ret_RET-2026-CAI-000001',NULL,'item_001','قطعة',1,1,22000,18500,14,3080,25080);
INSERT INTO `purchase_invoice_items` (`id`,`invoice_id`,`item_id`,`unit_name`,`unit_factor`,`quantity`,`returned_quantity`,`unit_price`,`discount_percent`,`discount_amount`,`tax_rate`,`tax_amount`,`total_amount`) VALUES ('pii_PINV-2026-CAI-000001_item_011','pur_PINV-2026-CAI-000001','item_011','قطعة',1,10,0,4000,0,0,14,5600,45600);
INSERT INTO `purchase_invoice_items` (`id`,`invoice_id`,`item_id`,`unit_name`,`unit_factor`,`quantity`,`returned_quantity`,`unit_price`,`discount_percent`,`discount_amount`,`tax_rate`,`tax_amount`,`total_amount`) VALUES ('pii_PINV-2026-CAI-000002_item_016','pur_PINV-2026-CAI-000002','item_016','قطعة',1,5,0,9500,0,0,14,6650,54150);
COMMIT;
SELECT 'Al-Mizan demo database ready' AS result;