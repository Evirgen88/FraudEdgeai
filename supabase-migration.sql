-- Mevcut users ve user_progress tablolarını güncelleme scripti
-- Bu SQL kodlarını Supabase Dashboard > SQL Editor'da çalıştır

-- 1. ADIM: Mevcut users tablosuna yeni kolonları ekle
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS subscription_type TEXT DEFAULT 'free',
ADD COLUMN IF NOT EXISTS subscription_start DATE,
ADD COLUMN IF NOT EXISTS subscription_end DATE,
ADD COLUMN IF NOT EXISTS daily_scenario_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS monthly_scenario_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_daily_reset DATE DEFAULT CURRENT_DATE,
ADD COLUMN IF NOT EXISTS last_monthly_reset DATE DEFAULT DATE_TRUNC('month', CURRENT_DATE);

-- 2. ADIM: subscription_type için constraint ekle
ALTER TABLE users 
ADD CONSTRAINT check_subscription_type 
CHECK (subscription_type IN ('free', 'premium_monthly', 'premium_yearly'));

-- 3. ADIM: Mevcut kullanıcıları 'free' olarak ayarla (eğer NULL ise)
UPDATE users 
SET subscription_type = 'free' 
WHERE subscription_type IS NULL;

UPDATE users 
SET daily_scenario_count = 0 
WHERE daily_scenario_count IS NULL;

UPDATE users 
SET monthly_scenario_count = 0 
WHERE monthly_scenario_count IS NULL;

UPDATE users 
SET last_daily_reset = CURRENT_DATE 
WHERE last_daily_reset IS NULL;

UPDATE users 
SET last_monthly_reset = DATE_TRUNC('month', CURRENT_DATE) 
WHERE last_monthly_reset IS NULL;

-- 4. ADIM: Performance için indexler ekle
CREATE INDEX IF NOT EXISTS idx_users_subscription_type ON users(subscription_type);
CREATE INDEX IF NOT EXISTS idx_users_daily_reset ON users(last_daily_reset);
CREATE INDEX IF NOT EXISTS idx_users_monthly_reset ON users(last_monthly_reset);

-- 5. ADIM: Pricing system fonksiyonları
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

-- 6. ADIM: Test için örnek sorgular
-- Tüm kullanıcıları göster
-- SELECT id, first_name, last_name, subscription_type, daily_scenario_count, monthly_scenario_count FROM users;

-- Bir kullanıcının limitlerini kontrol et
-- SELECT * FROM check_user_limits('YOUR_USER_UUID_HERE');

-- Scenario sayacını artır
-- SELECT increment_scenario_count('YOUR_USER_UUID_HERE');

-- Günlük sayaçları manuel sıfırla
-- SELECT reset_daily_counters();

-- Aylık sayaçları manuel sıfırla  
-- SELECT reset_monthly_counters();