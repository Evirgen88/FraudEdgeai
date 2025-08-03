-- Enable signup and disable email confirmation
-- Run this in Supabase SQL Editor

-- Enable signup
UPDATE auth.config 
SET 
  enable_signup = true,
  enable_email_confirmations = false
WHERE true;

-- Alternative method if config table doesn't exist
-- Insert or update auth configuration
INSERT INTO auth.config (enable_signup, enable_email_confirmations)
VALUES (true, false)
ON CONFLICT DO UPDATE SET
  enable_signup = true,
  enable_email_confirmations = false;

-- Check current settings
SELECT enable_signup, enable_email_confirmations 
FROM auth.config;

-- If the above doesn't work, try this approach:
-- Update the auth schema settings directly
UPDATE pg_catalog.pg_settings 
SET setting = 'true' 
WHERE name = 'supabase_auth.enable_signup';

UPDATE pg_catalog.pg_settings 
SET setting = 'false' 
WHERE name = 'supabase_auth.enable_email_confirmations';