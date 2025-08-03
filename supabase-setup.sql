-- FintechEdge AI Supabase Table Setup
-- Bu SQL kodlarını Supabase Dashboard > SQL Editor'da çalıştır

-- Users table - kullanıcı profil bilgileri
CREATE TABLE IF NOT EXISTS users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  referral_source TEXT,
  description TEXT,
  subscription_type TEXT DEFAULT 'free' CHECK (subscription_type IN ('free', 'premium_monthly', 'premium_yearly')),
  subscription_start DATE,
  subscription_end DATE,
  daily_scenario_count INTEGER DEFAULT 0,
  monthly_scenario_count INTEGER DEFAULT 0,
  last_daily_reset DATE DEFAULT CURRENT_DATE,
  last_monthly_reset DATE DEFAULT DATE_TRUNC('month', CURRENT_DATE),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User progress table - senaryo tamamlama skorları
CREATE TABLE IF NOT EXISTS user_progress (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  scenario_id TEXT NOT NULL,
  scenario_name TEXT NOT NULL,
  score INTEGER NOT NULL CHECK (score >= 0 AND score <= 100),
  answers JSONB NOT NULL,
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_name ON users(first_name, last_name);
CREATE INDEX IF NOT EXISTS idx_user_progress_user_id ON user_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_scenario ON user_progress(scenario_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_completed ON user_progress(completed_at DESC);

-- RLS (Row Level Security) policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;

-- Allow all operations for now (daha sonra daha güvenli policies ekleyebiliriz)
CREATE POLICY "Allow all operations on users" ON users FOR ALL USING (true);
CREATE POLICY "Allow all operations on user_progress" ON user_progress FOR ALL USING (true);

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Updated_at trigger for users table
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Pricing system functions

-- Function to reset daily counters
CREATE OR REPLACE FUNCTION reset_daily_counters()
RETURNS void AS $$
BEGIN
  UPDATE users 
  SET daily_scenario_count = 0,
      last_daily_reset = CURRENT_DATE
  WHERE last_daily_reset < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- Function to reset monthly counters  
CREATE OR REPLACE FUNCTION reset_monthly_counters()
RETURNS void AS $$
BEGIN
  UPDATE users 
  SET monthly_scenario_count = 0,
      last_monthly_reset = DATE_TRUNC('month', CURRENT_DATE)
  WHERE last_monthly_reset < DATE_TRUNC('month', CURRENT_DATE);
END;
$$ LANGUAGE plpgsql;

-- Function to check user limits
CREATE OR REPLACE FUNCTION check_user_limits(user_uuid UUID)
RETURNS TABLE(
  can_use_scenario BOOLEAN,
  subscription_type TEXT,
  daily_count INTEGER,
  monthly_count INTEGER,
  daily_limit INTEGER,
  monthly_limit INTEGER
) AS $$
DECLARE
  user_record RECORD;
  d_limit INTEGER;
  m_limit INTEGER;
BEGIN
  -- First reset counters if needed
  PERFORM reset_daily_counters();
  PERFORM reset_monthly_counters();
  
  -- Get user data
  SELECT * INTO user_record FROM users WHERE id = user_uuid;
  
  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'not_found'::TEXT, 0, 0, 0, 0;
    RETURN;
  END IF;
  
  -- Set limits based on subscription
  CASE user_record.subscription_type
    WHEN 'free' THEN
      d_limit := 3;
      m_limit := 20;
    WHEN 'premium_monthly', 'premium_yearly' THEN
      d_limit := 999999;
      m_limit := 999999;
    ELSE
      d_limit := 3;
      m_limit := 20;
  END CASE;
  
  -- Check if user can use scenario
  RETURN QUERY SELECT 
    (user_record.daily_scenario_count < d_limit AND user_record.monthly_scenario_count < m_limit),
    user_record.subscription_type,
    user_record.daily_scenario_count,
    user_record.monthly_scenario_count,
    d_limit,
    m_limit;
END;
$$ LANGUAGE plpgsql;

-- Function to increment scenario count
CREATE OR REPLACE FUNCTION increment_scenario_count(user_uuid UUID)
RETURNS BOOLEAN AS $$
DECLARE
  limits_check RECORD;
BEGIN
  -- Check limits first
  SELECT * INTO limits_check FROM check_user_limits(user_uuid);
  
  IF NOT limits_check.can_use_scenario THEN
    RETURN FALSE;
  END IF;
  
  -- Increment counters
  UPDATE users 
  SET daily_scenario_count = daily_scenario_count + 1,
      monthly_scenario_count = monthly_scenario_count + 1
  WHERE id = user_uuid;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Example queries to test the setup:
-- SELECT * FROM users;
-- SELECT * FROM user_progress;
-- SELECT COUNT(*) as total_users FROM users;
-- SELECT COUNT(*) as total_completions FROM user_progress;
-- SELECT * FROM check_user_limits('YOUR_USER_UUID');
-- SELECT increment_scenario_count('YOUR_USER_UUID');