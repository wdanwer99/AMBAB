class SupabaseConfig {
  // Replace these with your actual Supabase credentials
  static const String url = 'https://fmeikacvaozjqbzzpedx.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZtZWlrYWN2YW96anFienpwZWR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDEzNzU1MTAsImV4cCI6MjA1Njk1MTUxMH0.BLlauk1N68O9rEUmcnTzyvyBdzpr6iacCMsrz5rPKTM';
  
  // Database table names
  static const String usersTable = 'users';
  static const String vendorsTable = 'vendors';
  static const String productsTable = 'products';
  static const String ordersTable = 'orders';
  static const String savedProductsTable = 'saved_products';
  
  // Storage bucket names
  static const String productImagesBucket = 'product-images';
  static const String vendorImagesBucket = 'vendor-images';
}

/*
SUPABASE SETUP INSTRUCTIONS:

1. Create a Supabase project at https://supabase.com
2. Get your project URL and anon key from Settings > API
3. Replace the values in this file

4. Create the following tables in your Supabase database:

USERS TABLE:
CREATE TABLE users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  location TEXT NOT NULL,
  phone INTEGER NOT NULL,
  role TEXT NOT NULL DEFAULT 'user',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

VENDORS TABLE:
CREATE TABLE vendors (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  location TEXT NOT NULL,
  phone INTEGER NOT NULL,
  store_name TEXT,
  store_description TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  rating DECIMAL DEFAULT 0.0,
  total_products INTEGER DEFAULT 0,
  total_sales INTEGER DEFAULT 0
);

PRODUCTS TABLE:
CREATE TABLE products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  price DECIMAL NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  image TEXT NOT NULL,
  category TEXT NOT NULL,
  vendor_id UUID REFERENCES vendors(id),
  vendor_name TEXT NOT NULL,
  vendor_store_name TEXT,
  is_available BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  rating DECIMAL DEFAULT 0.0,
  total_sold INTEGER DEFAULT 0
);

ORDERS TABLE:
CREATE TABLE orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  customer_id UUID REFERENCES users(id),
  customer_name TEXT NOT NULL,
  products JSONB NOT NULL,
  total DECIMAL NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  vendor_id UUID REFERENCES vendors(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

SAVED_PRODUCTS TABLE:
CREATE TABLE saved_products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  product_id TEXT NOT NULL,
  product_data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

5. Create storage buckets:
   - product-images (for product images)
   - vendor-images (for vendor/store images)

6. Set up Row Level Security (RLS) policies as needed

7. Update the main.dart file with your actual credentials
*/ 