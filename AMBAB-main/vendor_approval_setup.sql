-- Vendor Approval System Setup for Supabase
-- This script sets up the database structure for vendor approval workflow

-- Step 1: Add approval columns to vendors table if they don't exist
ALTER TABLE vendors 
ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS approval_status TEXT DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Add is_disabled column to vendors table if it doesn't exist
ALTER TABLE vendors 
ADD COLUMN IF NOT EXISTS is_disabled BOOLEAN DEFAULT FALSE;

-- Step 2: Add updated_at column to users table if it doesn't exist
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Step 3: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_vendors_approval_status ON vendors(approval_status);
CREATE INDEX IF NOT EXISTS idx_vendors_is_approved ON vendors(is_approved);
CREATE INDEX IF NOT EXISTS idx_vendors_created_at ON vendors(created_at DESC);

-- Step 4: Enable RLS on vendors table
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;

-- Step 5: Drop existing policies that might be causing issues
DROP POLICY IF EXISTS "Admins can view all vendors" ON vendors;
DROP POLICY IF EXISTS "Admins can update all vendors" ON vendors;
DROP POLICY IF EXISTS "Admins can insert vendors" ON vendors;
DROP POLICY IF EXISTS "Vendors can view their own data" ON vendors;
DROP POLICY IF EXISTS "Vendors can update their own data" ON vendors;
DROP POLICY IF EXISTS "Users can insert their own vendor record" ON vendors;

-- Step 6: Create RLS policies

-- Policy for admins to view all vendors
CREATE POLICY "Admins can view all vendors" ON vendors
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() AND users.role = 'admin'
        )
    );

-- Policy for admins to update all vendors
CREATE POLICY "Admins can update all vendors" ON vendors
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() AND users.role = 'admin'
        )
    );

-- Policy for admins to insert vendors
CREATE POLICY "Admins can insert vendors" ON vendors
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() AND users.role = 'admin'
        )
    );

-- Policy for users to insert their own vendor record
CREATE POLICY "Users can insert their own vendor record" ON vendors
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Policy for vendors to view their own data
CREATE POLICY "Vendors can view their own data" ON vendors
    FOR SELECT USING (auth.uid() = id);

-- Policy for vendors to update their own data (except approval fields)
CREATE POLICY "Vendors can update their own data" ON vendors
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (
        auth.uid() = id AND 
        approval_status = OLD.approval_status AND 
        is_approved = OLD.is_approved
    );

-- Step 7: Grant necessary permissions
GRANT SELECT, UPDATE, INSERT ON vendors TO authenticated;

-- Step 8: Test queries to verify setup
-- Check if columns exist
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'vendors' 
AND column_name IN ('is_approved', 'approval_status', 'approved_at', 'rejected_at', 'rejection_reason');

-- Check if policies exist
SELECT schemaname, tablename, policyname, permissive, roles, cmd 
FROM pg_policies 
WHERE tablename = 'vendors';

-- Test admin access (this should work for admin users)
-- SELECT * FROM vendors WHERE approval_status = 'pending'; 