-- Temiz başlangıç için tüm test verilerini sil ve yapıyı düzelt
-- Bu SQL kodlarını Supabase Dashboard > SQL Editor'da çalıştır

-- 1. ADIM: Tüm test verilerini sil
DELETE FROM user_progress;
DELETE FROM users;

-- 2. ADIM: Sequence'ları sıfırla (id sıfırdan başlasın)
ALTER SEQUENCE users_id_seq RESTART WITH 1;

-- 3. ADIM: users tablosuna uuid kolonu ekle (eğer henüz eklenmemişse)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS uuid UUID DEFAULT gen_random_uuid();

-- 4. ADIM: users tablosuna pricing kolonları ekle
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS subscription_type TEXT DEFAULT 'free',
ADD COLUMN IF NOT EXISTS subscription_start DATE,
ADD COLUMN IF NOT EXISTS subscription_end DATE,
ADD COLUMN IF NOT EXISTS daily_scenario_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS monthly_scenario_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_daily_reset DATE DEFAULT CURRENT_DATE,
ADD COLUMN IF NOT EXISTS last_monthly_reset DATE DEFAULT DATE_TRUNC('month', CURRENT_DATE),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 5. ADIM: Constraints ekle
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

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'users_uuid_unique'
    ) THEN
        ALTER TABLE users 
        ADD CONSTRAINT users_uuid_unique UNIQUE(uuid);
    END IF;
END $$;

-- 6. ADIM: uuid kolonunu NOT NULL yap
ALTER TABLE users 
ALTER COLUMN uuid SET NOT NULL;

-- 7. ADIM: Foreign key constraint'ini ekle
ALTER TABLE user_progress 
DROP CONSTRAINT IF EXISTS user_progress_user_id_fkey;

ALTER TABLE user_progress 
ADD CONSTRAINT user_progress_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES users(uuid) ON DELETE CASCADE;

-- 8. ADIM: Performance indexleri ekle
CREATE INDEX IF NOT EXISTS idx_users_uuid ON users(uuid);
CREATE INDEX IF NOT EXISTS idx_users_subscription_type ON users(subscription_type);
CREATE INDEX IF NOT EXISTS idx_users_daily_reset ON users(last_daily_reset);
CREATE INDEX IF NOT EXISTS idx_users_monthly_reset ON users(last_monthly_reset);

-- 9. ADIM: Updated_at trigger
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

-- 10. ADIM: Pricing system fonksiyonları
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

-- 11. ADIM: Test için örnek kullanıcı ekle
INSERT INTO users (first_name, last_name, referral_source, description) 
VALUES ('Test', 'User', 'development', 'Test kullanıcısı');

-- 12. ADIM: Kontrol sorguları
SELECT 'users tablosu', COUNT(*) FROM users;
SELECT 'user_progress tablosu', COUNT(*) FROM user_progress;

-- Test kullanıcısının bilgilerini göster
SELECT id, uuid, first_name, last_name, subscription_type, daily_scenario_count, monthly_scenario_count FROM users;