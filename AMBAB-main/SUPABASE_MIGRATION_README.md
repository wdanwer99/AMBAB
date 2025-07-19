# Firebase to Supabase Migration

This app has been successfully migrated from Firebase to Supabase. Here's what you need to do to complete the setup:

## 🚀 Quick Setup

### 1. **Create Supabase Project**
1. Go to [supabase.com](https://supabase.com)
2. Create a new project
3. Note your project URL and anon key

### 2. **Update Configuration**
1. Open `lib/config/supabase_config.dart`
2. Replace `YOUR_SUPABASE_URL` with your actual Supabase URL
3. Replace `YOUR_SUPABASE_ANON_KEY` with your actual anon key

### 3. **Install Dependencies**
```bash
flutter pub get
```

## 🗄️ Database Setup

### Create Tables
Run these SQL commands in your Supabase SQL editor:

```sql
-- Users table
CREATE TABLE users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  location TEXT NOT NULL,
  phone INTEGER NOT NULL,
  role TEXT NOT NULL DEFAULT 'user',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Vendors table
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

-- Products table
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

-- Orders table
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

-- Saved products table
CREATE TABLE saved_products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  product_id TEXT NOT NULL,
  product_data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 4. **Storage Setup**
1. Go to Storage in your Supabase dashboard
2. Create two buckets:
   - `product-images` (for product images)
   - `vendor-images` (for vendor/store images)
3. Set bucket policies to allow authenticated users to upload

### 5. **Row Level Security (RLS)**
Enable RLS on all tables and create appropriate policies:

```sql
-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_products ENABLE ROW LEVEL SECURITY;

-- Example policies (adjust as needed)
CREATE POLICY "Users can view their own data" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Vendors can view their own data" ON vendors
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Anyone can view available products" ON products
  FOR SELECT USING (is_available = true);

CREATE POLICY "Vendors can manage their products" ON products
  FOR ALL USING (auth.uid() = vendor_id);
```

## 🔄 Migration Changes

### **Authentication**
- ✅ Firebase Auth → Supabase Auth
- ✅ User registration and login
- ✅ Role-based access control

### **Database**
- ✅ Firestore → Supabase PostgreSQL
- ✅ Real-time subscriptions
- ✅ Complex queries and relationships

### **Storage**
- ✅ Firebase Storage → Supabase Storage
- ✅ Image upload and management
- ✅ Public URL generation

### **Features Maintained**
- ✅ Multi-vendor system
- ✅ Product management
- ✅ Order processing
- ✅ User profiles
- ✅ Saved products

## 🎯 Benefits of Supabase

1. **Open Source**: Full control over your data
2. **PostgreSQL**: Powerful SQL database
3. **Real-time**: Built-in subscriptions
4. **Edge Functions**: Serverless functions
5. **Better Pricing**: More generous free tier
6. **Type Safety**: Better TypeScript/Flutter integration

## 🚨 Important Notes

1. **Data Migration**: If you have existing Firebase data, you'll need to export and import it manually
2. **Environment Variables**: Consider using environment variables for production
3. **Testing**: Test all features thoroughly after migration
4. **Backup**: Always backup your data before making changes

## 🔧 Troubleshooting

### Common Issues:
1. **Connection Errors**: Check your Supabase URL and anon key
2. **Permission Errors**: Verify RLS policies are set correctly
3. **Image Upload Issues**: Check storage bucket permissions
4. **Authentication Errors**: Ensure auth is properly configured

### Support:
- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Discord](https://discord.supabase.com)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)

---

**Your multi-vendor agriculture app is now powered by Supabase! 🚀** 