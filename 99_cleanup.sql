
-- ============================================================
-- SUSPEND SCHEDULED TASKS
-- ============================================================
--
-- Suspend tasks before dropping them.
-- Skip if no task was created.
--

ALTER TASK IF EXISTS DAILY_ORDERS_LOAD SUSPEND;

DROP TASK IF EXISTS DAILY_ORDERS_LOAD;

-- ============================================================
-- DROP EXTERNAL STAGES 
-- ============================================================

DROP STAGE IF EXISTS ECOMMERCE_S3_KEY_STAGE;

-- ============================================================
-- DROP CSV FILE FORMATS
-- ============================================================

DROP FILE FORMAT IF EXISTS ECOMMERCE_CSV_FORMAT;

DROP FILE FORMAT IF EXISTS ECOMMERCE_CSV_INFER_FORMAT;

DROP FILE FORMAT IF EXISTS ECOMMERCE_CSV_LOAD_FORMAT;

-- ============================================================
-- DROP TABLES/DATABASE/WAREHOUSE
-- ============================================================

DROP TABLE IF EXISTS ORDERS;

DROP TABLE IF EXISTS PRODUCTS;

DROP WAREHOUSE IF EXISTS DEV_WH;


DROP SCHEMA IF EXISTS ECOMMERCE_DB.RAW;

DROP DATABASE IF EXISTS ECOMMERCE_DB;

-- ============================================================
-- VERIFY CLEANUP
-- ============================================================
--
-- Run these commands while the database still exists.
-- If you dropped the entire database, skip the object
-- checks that reference it.
--

SHOW Databases;

SHOW STAGES;

SHOW FILE FORMATS ;

SHOW TASKS;

SHOW WAREHOUSES;


