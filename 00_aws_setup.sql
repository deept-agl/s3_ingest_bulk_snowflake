
-- ============================================================
-- AWS S3 TO SNOWFLAKE BULK DATA INGESTION
-- METHOD : ACCESS KEY BASED AUTHENTICATION
-- ============================================================
--
-- Signup for a Snowflake Account here https://signup.snowflake.com/

-- Signup for AWS Free Trial Account here https://signin.aws.amazon.com/signup?request_type=builderId&trk=fbdf98be-fd82-4f85-ba7f-1fec88374081&sc_channel=ps
-- ============================================================
-- STEP 1: CREATE AWS S3 BUCKET
-- ============================================================
--
-- 1. Log in to AWS Management Console.
-- 2. Navigate to S3 -> General purpose buckets.
-- 3. Click Create bucket.
-- 4. Enter bucket name:
--      retail-s3-to-snowflake-ingestion
-- 5. Select AWS Region: ap-southeast-2 (Sydney).
-- 6. Keep ACLs disabled (Bucket owner enforced).
-- 7. Keep Block all public access enabled.
-- 8. Keep default encryption as SSE-S3.
-- 9. Click Create bucket.
--
-- Note: S3 bucket names must be globally unique.
-- Use a different name if this name is unavailable.
--
--
-- ============================================================
-- STEP 2: CREATE S3 FOLDERS AND UPLOAD DATA
-- ============================================================
--
-- 1. Open the newly created S3 bucket.
-- 2. Create the following folder structure:
--
--    retail-s3-to-snowflake-ingestion/
--       ecommerce/
--          orders/
--             orders_2026-10-15.csv
--             orders_2026-10-16.csv
--          products/
--             products.csv
--
-- 3. Upload only Products CSV file for now to check connection.
-- 4. Ensure CSV files have headers.
--
-- NOTE:
-- Orders files can arrive daily with new filenames suffixed with date.
-- Products files can be loaded separately.
--
--
-- ============================================================
-- STEP 3: CREATE AWS IAM USER
-- ============================================================
--
-- 1. Navigate to AWS IAM -> Users -> Create user.
-- 2. Username: snowflake-s3-ingestion-user
-- 3. Do not enable AWS Management Console access.
-- 4. Create the user.
--
--
-- ============================================================
-- STEP 4: CREATE S3 READ-ONLY IAM POLICY
-- ============================================================
--
-- 1. Navigate to IAM -> Policies -> Create policy.
-- 2. Select JSON.
-- 3. Paste the following policy JSON.
-- 4. Name it: SnowflakeEcommerceS3ReadOnly
-- 5. Click Create policy.

-- IMPORTANT:
-- If your bucket name differs, update the Resource ARNs.
--
-- IAM POLICY:
--
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GetBucketRegion",
      "Effect": "Allow",
      "Action": "s3:GetBucketLocation",
      "Resource": "arn:aws:s3:::retail-s3-to-snowflake-ingestion"
    },
    {
      "Sid": "ListEcommerceFiles",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::retail-s3-to-snowflake-ingestion",
      "Condition": {
        "StringLike": {
          "s3:prefix": [
            "ecommerce/",
            "ecommerce/*"
          ]
        }
      }
    },
    {
      "Sid": "ReadEcommerceFiles",
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::retail-s3-to-snowflake-ingestion/ecommerce/*"
    }
  ]
}
--
--
--
-- ============================================================
-- STEP 5: ATTACH IAM POLICY TO IAM USER
-- ============================================================
--
-- 1. Navigate to IAM -> Users.
-- 2. Open snowflake-s3-ingestion-user.
-- 3. Click Add permissions.
-- 4. Select Attach policies directly.
-- 5. Search for SnowflakeEcommerceS3ReadOnly.
-- 6. Select and attach the policy.
--
--
-- ============================================================
-- STEP 6: GENERATE AWS ACCESS KEYS
-- ============================================================
--
-- 1. Open the IAM user.
-- 2. Navigate to Security credentials.
-- 3. Click Create access key.
-- 4. Select Third-party service or Other.
-- 5. Create the access key.
-- 6. Securely save:
--      - Access Key ID
--      - Secret Access Key
--
-- IMPORTANT:
-- Never upload credentials to GitHub.
-- Never expose credentials in videos or screenshots.
-- Delete access keys when no longer required.
--
--
-- ============================================================
-- STEP 7: SET UP SNOWFLAKE OBJECTS
-- ============================================================

USE ROLE ACCOUNTADMIN;

CREATE DATABASE IF NOT EXISTS ECOMMERCE_DB;

CREATE SCHEMA IF NOT EXISTS ECOMMERCE_DB.RAW;

CREATE WAREHOUSE IF NOT EXISTS DEV_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

USE WAREHOUSE DEV_WH;
USE DATABASE ECOMMERCE_DB;
USE SCHEMA RAW;


-- ============================================================
-- STEP 8: CREATE EXTERNAL STAGE USING AWS ACCESS KEYS
-- ============================================================
--
-- This approach does not require STORAGE INTEGRATION.
-- AWS credentials are configured directly in the stage.
--
-- IMPORTANT:
-- Execute with real credentials only in a private worksheet.
-- Do not save actual credentials in a shared SQL script.
-- Replace the placeholders below before execution.
--

CREATE STAGE ECOMMERCE_S3_KEY_STAGE
    URL = 's3://retail-s3-to-snowflake-ingestion/ecommerce/'
    CREDENTIALS = (
        AWS_KEY_ID = '<YOUR_ACCESS_KEY_ID>'
        AWS_SECRET_KEY = '<YOUR_SECRET_ACCESS_KEY>'
    );


-- ============================================================
-- STEP 9: VERIFY S3 CONNECTION FROM SNOWFLAKE
-- ============================================================

LIST @ECOMMERCE_S3_KEY_STAGE;

-- Verify individual folder.

LIST @ECOMMERCE_S3_KEY_STAGE/products/;


-- ============================================================
-- STEP 10: CREATE CSV FILE FORMAT
-- ============================================================

CREATE FILE FORMAT IF NOT EXISTS ECOMMERCE_CSV_FORMAT
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    EMPTY_FIELD_AS_NULL = TRUE;


-- ============================================================
-- STEP 11: CREATE TARGET TABLES MANUALLY OR INFER SCHEMA TO CREATE BY TEMPLATE
-- ============================================================
--
-- Create ORDERS and PRODUCTS tables based on the exact
-- columns and data types present in your CSV files.
--
-- Example table structures are not included here because
-- they must match the actual generated datasets.
--
-- After table creation, continue to Step 12.
--
--
-- ============================================================
-- STEP 12: LOAD ORDERS DATA FROM S3
-- ============================================================

COPY INTO ECOMMERCE_DB.RAW.ORDERS
FROM @ECOMMERCE_S3_KEY_STAGE/orders/
FILE_FORMAT = (FORMAT_NAME = ECOMMERCE_CSV_FORMAT)
ON_ERROR = 'ABORT_STATEMENT';


-- ============================================================
-- STEP 13: LOAD PRODUCTS DATA FROM S3
-- ============================================================

COPY INTO ECOMMERCE_DB.RAW.PRODUCTS
FROM @ECOMMERCE_S3_KEY_STAGE/products/
FILE_FORMAT = (FORMAT_NAME = ECOMMERCE_CSV_FORMAT)
ON_ERROR = 'ABORT_STATEMENT';


-- ============================================================
-- STEP 14: VALIDATE DATA LOAD
-- ============================================================

SELECT COUNT(*) AS TOTAL_ORDERS
FROM ECOMMERCE_DB.RAW.ORDERS;

SELECT COUNT(*) AS TOTAL_PRODUCTS
FROM ECOMMERCE_DB.RAW.PRODUCTS;

SELECT *
FROM ECOMMERCE_DB.RAW.ORDERS
LIMIT 10;

SELECT *
FROM ECOMMERCE_DB.RAW.PRODUCTS
LIMIT 10;


-- ============================================================
-- STEP 15: CHECK COPY HISTORY
-- ============================================================

SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'ECOMMERCE_DB.RAW.ORDERS',
        START_TIME => DATEADD('DAY', -7, CURRENT_TIMESTAMP())
    )
);


-- ============================================================
-- STEP 16: CLEANUP AFTER DEMO
-- ============================================================
--
-- AWS CLEANUP:
-- 1. Deactivate/delete the IAM access keys.
-- 2. Delete the dedicated IAM user if no longer needed.
-- 3. Delete unused IAM policies.
-- 4. Delete S3 objects/bucket if no longer required.
--
-- SNOWFLAKE CLEANUP:
-- Uncomment only when cleanup is required.
--
-- DROP STAGE IF EXISTS ECOMMERCE_S3_KEY_STAGE;
-- DROP FILE FORMAT IF EXISTS ECOMMERCE_CSV_FORMAT;
-- DROP WAREHOUSE IF EXISTS DEV_WH;
--
-- ============================================================
-- END OF PROJECT
-- ============================================================
