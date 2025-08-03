-- Fix custom_scenarios table - eksik column'ları ekle
-- Bu SQL kodlarını Supabase Dashboard > SQL Editor'da çalıştır

-- Önce tabloyu kontrol et
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'custom_scenarios' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Eksik column'ları ekle
ALTER TABLE custom_scenarios 
ADD COLUMN IF NOT EXISTS test_status TEXT DEFAULT 'draft' CHECK (test_status IN ('draft', 'tested'));

ALTER TABLE custom_scenarios 
ADD COLUMN IF NOT EXISTS test_score INTEGER;

ALTER TABLE custom_scenarios 
ADD COLUMN IF NOT EXISTS test_completed_at TIMESTAMP WITH TIME ZONE;

-- Şimdi index'i oluştur
CREATE INDEX IF NOT EXISTS idx_custom_scenarios_test_status ON custom_scenarios(test_status);

-- Tabloyu tekrar kontrol et
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'custom_scenarios' 
AND table_schema = 'public'
ORDER BY ordinal_position;