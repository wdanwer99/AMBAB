-- Fix Vendor RLS Policies for Admin Access
-- This script ensures admins can properly view and manage vendor requests

-- Drop existing policies that might be causing issues
DROP POLICY IF EXISTS "Admins can view all vendors" ON vendors;
DROP POLICY IF EXISTS "Admins can update all vendors" ON vendors;
DROP POLICY IF EXISTS "Admins can insert vendors" ON vendors;

-- Create a more permissive policy for admins to view all vendors
CREATE POLICY "Admins can view all vendors" ON vendors
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() AND users.role = 'admin'
        )
    );

-- Create a more permissive policy for admins to update all vendors
CREATE POLICY "Admins can update all vendors" ON vendors
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() AND users.role = 'admin'
        )
    );

-- Create a more permissive policy for admins to insert vendors
CREATE POLICY "Admins can insert vendors" ON vendors
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() AND users.role = 'admin'
        )
    );

-- Also create a policy for authenticated users to insert their own vendor record
CREATE POLICY "Users can insert their own vendor record" ON vendors
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Create a policy for vendors to view their own data
CREATE POLICY "Vendors can view their own data" ON vendors
    FOR SELECT USING (auth.uid() = id);

-- Create a policy for vendors to update their own data (except approval fields)
CREATE POLICY "Vendors can update their own data" ON vendors
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (
        auth.uid() = id AND 
        approval_status = OLD.approval_status AND 
        is_approved = OLD.is_approved
    );

-- Grant necessary permissions
GRANT SELECT, UPDATE, INSERT ON vendors TO authenticated;

-- Test query to check if policies are working
-- This should return all vendors for admin users
-- SELECT * FROM vendors WHERE approval_status = 'pending'; 