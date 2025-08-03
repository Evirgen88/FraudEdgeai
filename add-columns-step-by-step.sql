-- custom_scenarios tablosuna column'ları tek tek ekle
-- Bu SQL'leri tek tek çalıştır - her birinin başarılı olduğunu kontrol et

-- 1. title column ekle
ALTER TABLE custom_scenarios 
ADD COLUMN title TEXT NOT NULL DEFAULT 'Untitled Scenario';

-- 2. description column ekle  
ALTER TABLE custom_scenarios 
ADD COLUMN description TEXT;

-- 3. category column ekle
ALTER TABLE custom_scenarios 
ADD COLUMN category TEXT DEFAULT 'custom';

-- 4. difficulty column ekle
ALTER TABLE custom_scenarios 
ADD COLUMN difficulty INTEGER DEFAULT 1;

-- 5. raw_content column ekle
ALTER TABLE custom_scenarios 
ADD COLUMN raw_content TEXT;

-- 6. file_name column ekle
ALTER TABLE custom_scenarios 
ADD COLUMN file_name TEXT;

-- 7. file_size column ekle
ALTER TABLE custom_scenarios 
ADD COLUMN file_size INTEGER;

-- 8. test_status column ekle
ALTER TABLE custom_scenarios 
ADD COLUMN test_status TEXT DEFAULT 'draft';

-- 9. test_score column ekle
ALTER TABLE custom_scenarios 
ADD COLUMN test_score INTEGER;

-- 10. test_completed_at column ekle
ALTER TABLE custom_scenarios 
ADD COLUMN test_completed_at TIMESTAMP WITH TIME ZONE;

-- 11. created_at column ekle
ALTER TABLE custom_scenarios 
ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 12. updated_at column ekle
ALTER TABLE custom_scenarios 
ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 13. Constraint'leri ekle
ALTER TABLE custom_scenarios 
ADD CONSTRAINT check_difficulty CHECK (difficulty IN (1, 2, 3));

ALTER TABLE custom_scenarios 
ADD CONSTRAINT check_test_status CHECK (test_status IN ('draft', 'tested'));

-- 14. Son kontrol - column'ları listele
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'custom_scenarios' 
AND table_schema = 'public'
ORDER BY ordinal_position;