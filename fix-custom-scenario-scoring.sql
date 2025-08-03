-- Fix custom scenario scoring - add completion tracking
-- Bu script custom scenario tamamlama skorlarını düzeltir

-- 1. custom_scenarios tablosuna total_score alanını ekle (eğer yoksa)
ALTER TABLE custom_scenarios 
ADD COLUMN IF NOT EXISTS total_score INTEGER DEFAULT 0;

-- 2. Önce mevcut tabloyu kontrol et
DO $$
BEGIN
  -- Eğer tablo varsa ama yanlış referans varsa, düzelt
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'custom_scenario_completions') THEN
    -- Mevcut foreign key'i düzelt
    ALTER TABLE custom_scenario_completions DROP CONSTRAINT IF EXISTS custom_scenario_completions_user_id_fkey;
    ALTER TABLE custom_scenario_completions ADD CONSTRAINT custom_scenario_completions_user_id_fkey 
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    
    -- Average score alanını ekle
    ALTER TABLE custom_scenario_completions ADD COLUMN IF NOT EXISTS average_score INTEGER DEFAULT 0;
  ELSE
    -- Tablo yoksa oluştur
    CREATE TABLE custom_scenario_completions (
      id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
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

-- 3. İndeksleri ekle
CREATE INDEX IF NOT EXISTS idx_custom_scenario_completions_scenario ON custom_scenario_completions(scenario_id);
CREATE INDEX IF NOT EXISTS idx_custom_scenario_completions_user ON custom_scenario_completions(user_id);
CREATE INDEX IF NOT EXISTS idx_custom_scenario_completions_completed ON custom_scenario_completions(completed_at);

-- 4. RLS politikalarını ekle (eğer RLS aktifse)
ALTER TABLE custom_scenario_completions ENABLE ROW LEVEL SECURITY;

-- Kullanıcılar kendi completion'larını görebilir
CREATE POLICY IF NOT EXISTS "Users can view own completions" ON custom_scenario_completions
  FOR SELECT USING (auth.uid() = user_id);

-- Kullanıcılar kendi completion'larını ekleyebilir  
CREATE POLICY IF NOT EXISTS "Users can insert own completions" ON custom_scenario_completions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Kullanıcılar kendi completion'larını güncelleyebilir
CREATE POLICY IF NOT EXISTS "Users can update own completions" ON custom_scenario_completions
  FOR UPDATE USING (auth.uid() = user_id);

-- 5. Test için örnek data ekle (opsiyonel - kaldırılabilir)
-- Bu kısım test amaçlıdır, production'da kaldırılmalı
/*
DO $$
BEGIN
  -- Test completion'ı ekle (eğer test user'ı varsa)
  IF EXISTS (SELECT 1 FROM users LIMIT 1) AND EXISTS (SELECT 1 FROM custom_scenarios LIMIT 1) THEN
    INSERT INTO custom_scenario_completions (scenario_id, user_id, answers, total_score, average_score)
    SELECT 
      (SELECT id FROM custom_scenarios LIMIT 1),
      (SELECT id FROM users LIMIT 1),
      '{"question1": "test answer", "question2": "test answer 2"}',
      75,
      75
    ON CONFLICT (scenario_id, user_id) DO NOTHING;
  END IF;
END $$;
*/

COMMIT;