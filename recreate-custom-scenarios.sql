-- Recreate custom_scenarios table with all columns
-- Bu SQL kodlarını Supabase Dashboard > SQL Editor'da çalıştır

-- Önce mevcut tabloyu düşür (eğer test verisi varsa backup al!)
DROP TABLE IF EXISTS custom_scenarios CASCADE;

-- Yeni tabloyu tüm column'larla oluştur
CREATE TABLE custom_scenarios (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT DEFAULT 'custom',
  difficulty INTEGER DEFAULT 1 CHECK (difficulty IN (1, 2, 3)),
  raw_content TEXT, -- Original log file content
  file_name TEXT,
  file_size INTEGER,
  test_status TEXT DEFAULT 'draft' CHECK (test_status IN ('draft', 'tested')),
  test_score INTEGER, -- Average score from test (if tested)
  test_completed_at TIMESTAMP WITH TIME ZONE, -- When test was completed
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index'leri oluştur
CREATE INDEX IF NOT EXISTS idx_custom_scenarios_user_id ON custom_scenarios(user_id);
CREATE INDEX IF NOT EXISTS idx_custom_scenarios_test_status ON custom_scenarios(test_status);

-- RLS (Row Level Security) enable et
ALTER TABLE custom_scenarios ENABLE ROW LEVEL SECURITY;

-- Policy oluştur
CREATE POLICY "Users can manage their own custom scenarios" ON custom_scenarios FOR ALL USING (true);

-- Updated_at trigger ekle
CREATE TRIGGER update_custom_scenarios_updated_at
    BEFORE UPDATE ON custom_scenarios
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Tabloyu kontrol et
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'custom_scenarios' 
AND table_schema = 'public'
ORDER BY ordinal_position;