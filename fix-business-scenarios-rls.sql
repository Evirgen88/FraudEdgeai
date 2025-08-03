-- Fix business_scenarios table RLS policies
-- Run this in Supabase SQL Editor

-- Enable RLS on business_scenarios table
ALTER TABLE business_scenarios ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can view own business scenarios" ON business_scenarios;
DROP POLICY IF EXISTS "Users can insert own business scenarios" ON business_scenarios;
DROP POLICY IF EXISTS "Users can update own business scenarios" ON business_scenarios;
DROP POLICY IF EXISTS "Users can delete own business scenarios" ON business_scenarios;

-- Create RLS policies for business_scenarios

-- Policy for SELECT (viewing own scenarios)
CREATE POLICY "Users can view own business scenarios" ON business_scenarios
    FOR SELECT USING (auth.uid() = user_id);

-- Policy for INSERT (creating new scenarios)
CREATE POLICY "Users can insert own business scenarios" ON business_scenarios
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy for UPDATE (updating own scenarios)
CREATE POLICY "Users can update own business scenarios" ON business_scenarios
    FOR UPDATE USING (auth.uid() = user_id);

-- Policy for DELETE (deleting own scenarios)
CREATE POLICY "Users can delete own business scenarios" ON business_scenarios
    FOR DELETE USING (auth.uid() = user_id);

-- Optional: Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_business_scenarios_user_id ON business_scenarios(user_id);
CREATE INDEX IF NOT EXISTS idx_business_scenarios_created_at ON business_scenarios(created_at);

-- Verify the policies are created
SELECT schemaname, tablename, policyname, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'business_scenarios';