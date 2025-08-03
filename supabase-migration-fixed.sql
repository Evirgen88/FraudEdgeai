-- Mevcut users ve user_progress tablolarını güncelleme scripti (SERIAL ID + UUID yapısı için)
-- Bu SQL kodlarını Supabase Dashboard > SQL Editor'da çalıştır

-- 1. ADIM: Mevcut users tablosuna pricing kolonları ekle
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS subscription_type TEXT DEFAULT 'free',
ADD COLUMN IF NOT EXISTS subscription_start DATE,
ADD COLUMN IF NOT EXISTS subscription_end DATE,
ADD COLUMN IF NOT EXISTS daily_scenario_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS monthly_scenario_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_daily_reset DATE DEFAULT CURRENT_DATE,
ADD COLUMN IF NOT EXISTS last_monthly_reset DATE DEFAULT DATE_TRUNC('month', CURRENT_DATE),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 2. ADIM: subscription_type için constraint ekle
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'check_subscription_type'
    ) THEN
        ALTER TABLE users 
        ADD CONSTRAINT check_subscription_type 
        CHECK (subscription_type IN ('free', 'premium_monthly', 'premium_yearly'));
    END IF;
END $$;

-- 3. ADIM: Mevcut kullanıcıları 'free' olarak ayarla
UPDATE users 
SET 
    subscription_type = COALESCE(subscription_type, 'free'),
    daily_scenario_count = COALESCE(daily_scenario_count, 0),
    monthly_scenario_count = COALESCE(monthly_scenario_count, 0),
    last_daily_reset = COALESCE(last_daily_reset, CURRENT_DATE),
    last_monthly_reset = COALESCE(last_monthly_reset, DATE_TRUNC('month', CURRENT_DATE)),
    updated_at = COALESCE(updated_at, NOW());

-- 4. ADIM: user_progress tablosunu kontrol et ve gerekirse güncelle
-- user_progress tablosunun user_id kolonunu users tablosunun uuid kolonu ile eşleştirmek için
ALTER TABLE user_progress 
DROP CONSTRAINT IF EXISTS user_progress_user_id_fkey;

ALTER TABLE user_progress 
ADD CONSTRAINT user_progress_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES users(uuid) ON DELETE CASCADE;

-- 5. ADIM: Performance için indexler ekle
CREATE INDEX IF NOT EXISTS idx_users_uuid ON users(uuid);
CREATE INDEX IF NOT EXISTS idx_users_subscription_type ON users(subscription_type);
CREATE INDEX IF NOT EXISTS idx_users_daily_reset ON users(last_daily_reset);
CREATE INDEX IF NOT EXISTS idx_users_monthly_reset ON users(last_monthly_reset);
CREATE INDEX IF NOT EXISTS idx_user_progress_user_uuid ON user_progress(user_id);

-- 6. ADIM: Updated_at trigger function ve trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 7. ADIM: Pricing system fonksiyonları (UUID kolonu kullanarak)

-- Function to reset daily counters
CREATE OR REPLACE FUNCTION reset_daily_counters()
RETURNS void AS $$
BEGIN
  UPDATE users 
  SET daily_scenario_count = 0,
      last_daily_reset = CURRENT_DATE,
      updated_at = NOW()
  WHERE last_daily_reset < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- Function to reset monthly counters  
CREATE OR REPLACE FUNCTION reset_monthly_counters()
RETURNS void AS $$
BEGIN
  UPDATE users 
  SET monthly_scenario_count = 0,
      last_monthly_reset = DATE_TRUNC('month', CURRENT_DATE),
      updated_at = NOW()
  WHERE last_monthly_reset < DATE_TRUNC('month', CURRENT_DATE);
END;
$$ LANGUAGE plpgsql;

-- Function to check user limits (UUID kullanarak)
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
  
  -- Get user data using uuid column
  SELECT * INTO user_record FROM users WHERE uuid = user_uuid;
  
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

-- Function to increment scenario count (UUID kullanarak)
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
  
  -- Increment counters using uuid
  UPDATE users 
  SET daily_scenario_count = daily_scenario_count + 1,
      monthly_scenario_count = monthly_scenario_count + 1,
      updated_at = NOW()
  WHERE uuid = user_uuid;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to get user by uuid (helper function)
CREATE OR REPLACE FUNCTION get_user_by_uuid(user_uuid UUID)
RETURNS TABLE(
  id INTEGER,
  uuid UUID,
  first_name TEXT,
  last_name TEXT,
  subscription_type TEXT,
  daily_count INTEGER,
  monthly_count INTEGER
) AS $$
BEGIN
  RETURN QUERY 
    SELECT 
      u.id,
      u.uuid,
      u.first_name,
      u.last_name,
      u.subscription_type,
      u.daily_scenario_count,
      u.monthly_scenario_count
    FROM users u 
    WHERE u.uuid = user_uuid;
END;
$$ LANGUAGE plpgsql;

-- 8. ADIM: Test sorguları
-- SELECT * FROM users LIMIT 5;
-- SELECT * FROM user_progress LIMIT 5;

-- Test user limits (replace with actual UUID)
-- SELECT * FROM check_user_limits('your-actual-uuid-here');

-- Test increment (replace with actual UUID)  
-- SELECT increment_scenario_count('your-actual-uuid-here');

-- Get user info (replace with actual UUID)
-- SELECT * FROM get_user_by_uuid('your-actual-uuid-here');