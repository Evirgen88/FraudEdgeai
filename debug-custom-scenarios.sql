-- Debug custom_scenarios table
-- Bu SQL kodlarını tek tek çalıştır

-- 1. Önce tabloyu tamamen sil
DROP TABLE IF EXISTS custom_scenarios CASCADE;

-- 2. Basit bir tablo oluştur (sadece temel column'lar)
CREATE TABLE custom_scenarios (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT DEFAULT 'custom'
);

-- 3. Kontrol et
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'custom_scenarios' 
ORDER BY ordinal_position;