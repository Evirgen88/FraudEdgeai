-- Pricing system fonksiyonlarını oluştur
-- Bu SQL kodlarını Supabase Dashboard > SQL Editor'da çalıştır

-- 1. Daily counter reset fonksiyonu
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

-- 2. Monthly counter reset fonksiyonu
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

-- 3. User limits kontrol fonksiyonu
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

-- 4. Scenario count increment fonksiyonu
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

-- 5. Test fonksiyonları
SELECT 'Fonksiyonlar oluşturuldu!' as message;

-- 6. Örnek test
-- SELECT * FROM check_user_limits('6a41a505-6c6f-4536-bcdc-5bfd0e332dc2');