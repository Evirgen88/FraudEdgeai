-- Disable email confirmation for easier user onboarding
-- Run this in Supabase SQL Editor

-- Update auth settings to disable email confirmation
UPDATE auth.config 
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'),
  '{enable_signup}',
  'true'
);

-- Alternative: Update the auth configuration directly
-- Go to Supabase Dashboard > Authentication > Settings
-- Turn OFF "Enable email confirmations"