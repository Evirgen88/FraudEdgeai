-- Safe fix for custom scenario scoring
-- Bu script PostgreSQL UUID extension'ını kontrol eder

-- 1. UUID extension'ını aktifleştir
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. custom_scenarios tablosuna total_score alanını ekle
ALTER TABLE custom_scenarios 
ADD COLUMN IF NOT EXISTS total_score INTEGER DEFAULT 0;

-- 3. custom_scenario_completions tablosunu düzelt/oluştur
DO $$
BEGIN
  -- Eğer tablo varsa
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'custom_scenario_completions') THEN
    -- Mevcut foreign key'i düzelt
    ALTER TABLE custom_scenario_completions DROP CONSTRAINT IF EXISTS custom_scenario_completions_user_id_fkey;
    ALTER TABLE custom_scenario_completions ADD CONSTRAINT custom_scenario_completions_user_id_fkey 
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    
    -- Average score alanını ekle
    ALTER TABLE custom_scenario_completions ADD COLUMN IF NOT EXISTS average_score INTEGER DEFAULT 0;
    
    -- Answers alanını JSONB yap (eğer değilse)
    ALTER TABLE custom_scenario_completions ALTER COLUMN answers TYPE JSONB USING answers::JSONB;
    ALTER TABLE custom_scenario_completions ALTER COLUMN answers SET DEFAULT '{}';
    
  ELSE
    -- Tablo yoksa oluştur (uuid_generate_v4() kullan)
    CREATE TABLE custom_scenario_completions (
      id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
      scenario_id UUID REFERENCES custom_scenarios(id) ON DELETE CASCADE,
      user_id UUID REFERENCES users(id) ON DELETE CASCADE,
      answers JSONB NOT NULL DEFAULT '{}',
      total_score INTEGER NOT NULL DEFAULT 0,
      average_score INTEGER NOT NULL DEFAULT 0,
      completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      UNIQUE(scenario_id, user_id)
    );
  END IF;
END $$;

-- 4. İndeksleri ekle
CREATE INDEX IF NOT EXISTS idx_custom_scenario_completions_scenario ON custom_scenario_completions(scenario_id);
CREATE INDEX IF NOT EXISTS idx_custom_scenario_completions_user ON custom_scenario_completions(user_id);
CREATE INDEX IF NOT EXISTS idx_custom_scenario_completions_completed ON custom_scenario_completions(completed_at);

-- 5. RLS politikalarını ekle
ALTER TABLE custom_scenario_completions ENABLE ROW LEVEL SECURITY;

-- Kullanıcılar kendi completion'larını görebilir
DROP POLICY IF EXISTS "Users can view own completions" ON custom_scenario_completions;
CREATE POLICY "Users can view own completions" ON custom_scenario_completions
  FOR SELECT USING (user_id = auth.uid()::uuid);

-- Kullanıcılar kendi completion'larını ekleyebilir  
DROP POLICY IF EXISTS "Users can insert own completions" ON custom_scenario_completions;
CREATE POLICY "Users can insert own completions" ON custom_scenario_completions
  FOR INSERT WITH CHECK (user_id = auth.uid()::uuid);

-- Kullanıcılar kendi completion'larını güncelleyebilir
DROP POLICY IF EXISTS "Users can update own completions" ON custom_scenario_completions;
CREATE POLICY "Users can update own completions" ON custom_scenario_completions
  FOR UPDATE USING (user_id = auth.uid()::uuid);

COMMIT;