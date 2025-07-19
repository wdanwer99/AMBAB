-- Order Cancellation Setup for Supabase
-- This script sets up proper RLS policies for order cancellation

-- Enable RLS on orders table if not already enabled
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Policy for customers to view their own orders
CREATE POLICY "Customers can view their own orders" ON orders
    FOR SELECT USING (auth.uid() = customer_id);

-- Policy for customers to update their own orders (for cancellation)
CREATE POLICY "Customers can update their own orders" ON orders
    FOR UPDATE USING (auth.uid() = customer_id);

-- Policy for vendors to view orders containing their products
CREATE POLICY "Vendors can view orders with their products" ON orders
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM jsonb_array_elements(items) AS item
            WHERE (item->>'vendor_id')::text = auth.uid()::text
        )
    );

-- Policy for vendors to update orders containing their products
CREATE POLICY "Vendors can update orders with their products" ON orders
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM jsonb_array_elements(items) AS item
            WHERE (item->>'vendor_id')::text = auth.uid()::text
        )
    );

-- Policy for admins to view all orders
CREATE POLICY "Admins can view all orders" ON orders
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() AND users.role = 'admin'
        )
    );

-- Policy for admins to update all orders
CREATE POLICY "Admins can update all orders" ON orders
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() AND users.role = 'admin'
        )
    );

-- Add a trigger to prevent status changes on cancelled orders (optional)
CREATE OR REPLACE FUNCTION prevent_cancelled_order_updates()
RETURNS TRIGGER AS $$
BEGIN
    -- If the order is already cancelled, prevent further status changes
    IF OLD.status = 'Cancelled' AND NEW.status != 'Cancelled' THEN
        RAISE EXCEPTION 'Cannot change status of a cancelled order';
    END IF;
    
    -- If trying to cancel an order that's not pending, prevent it
    IF NEW.status = 'Cancelled' AND OLD.status != 'Pending' THEN
        RAISE EXCEPTION 'Only pending orders can be cancelled';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER prevent_cancelled_order_updates_trigger
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION prevent_cancelled_order_updates();

-- Add an index on customer_id for better performance
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);

-- Add an index on status for better filtering performance
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);

-- Add an index on created_at for better sorting performance
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- Grant necessary permissions
GRANT SELECT, UPDATE ON orders TO authenticated;
GRANT USAGE ON SEQUENCE orders_id_seq TO authenticated;

-- Comments for documentation
COMMENT ON TABLE orders IS 'Orders table with cancellation support';
COMMENT ON COLUMN orders.status IS 'Order status: Pending, Confirmed, Shipped, Delivered, Cancelled';
COMMENT ON COLUMN orders.updated_at IS 'Timestamp when order was last updated (for cancellation tracking)'; 