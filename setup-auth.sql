-- Supabase Authentication Setup
-- Run this in Supabase SQL Editor

-- Enable Google OAuth in Dashboard > Authentication > Providers > Google

-- Update users table to work with Supabase Auth
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_id uuid REFERENCES auth.users(id);
CREATE INDEX IF NOT EXISTS idx_users_auth_id ON users(auth_id);

-- Create trigger to auto-create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (
    auth_id,
    first_name,
    last_name,
    referral_source,
    description,
    subscription_type
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'referral_source', 'direct'),
    COALESCE(NEW.raw_user_meta_data->>'description', ''),
    'free'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Update RLS policies for auth users
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile" ON users;
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = auth_id);

DROP POLICY IF EXISTS "Users can update own profile" ON users;  
CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = auth_id);

-- Guest users policy (for anonymous access)
DROP POLICY IF EXISTS "Allow anonymous users" ON users;
CREATE POLICY "Allow anonymous users" ON users
  FOR ALL USING (auth.uid() IS NULL OR auth.uid() = auth_id);