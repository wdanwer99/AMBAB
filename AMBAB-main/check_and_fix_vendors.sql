-- Check and Fix Vendors Table Structure
-- This script will diagnose the current table structure and add missing columns

-- Step 1: Check current vendors table structure
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'vendors' 
ORDER BY ordinal_position;

-- Step 2: Check if approval columns exist
SELECT 
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'vendors' AND column_name = 'approval_status'
    ) THEN 'approval_status column EXISTS' 
    ELSE 'approval_status column DOES NOT EXIST' 
    END as status_check;

-- Step 3: Add missing approval columns (run this if columns don't exist)
ALTER TABLE vendors 
ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS approval_status TEXT DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Step 4: Verify columns were added
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'vendors' 
AND column_name IN ('is_approved', 'approval_status', 'approved_at', 'rejected_at', 'rejection_reason')
ORDER BY column_name;

-- Step 5: Update existing vendors to have pending status (if any exist)
UPDATE vendors 
SET approval_status = 'pending', is_approved = false 
WHERE approval_status IS NULL;

-- Step 6: Test the query that was failing
SELECT COUNT(*) as total_vendors FROM vendors;
SELECT COUNT(*) as pending_vendors FROM vendors WHERE approval_status = 'pending';
SELECT * FROM vendors WHERE approval_status = 'pending' LIMIT 5; 