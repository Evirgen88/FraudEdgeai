-- Fix Custom Scenarios Foreign Key Issue
-- Bu SQL kodlarını Supabase Dashboard > SQL Editor'da çalıştır

-- 1. Önce mevcut tabloları kontrol et
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM 
    information_schema.columns 
WHERE 
    table_name IN ('users', 'custom_scenarios', 'custom_scenario_steps', 'custom_scenario_questions')
    AND table_schema = 'public'
ORDER BY 
    table_name, ordinal_position;

-- 2. Users tablosunun yapısını kontrol et
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'users' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Foreign key constraint'leri kontrol et
SELECT
    conname AS constraint_name,
    conrelid::regclass AS table_name,
    a.attname AS column_name,
    confrelid::regclass AS foreign_table_name,
    af.attname AS foreign_column_name
FROM
    pg_constraint AS c
    JOIN pg_attribute AS a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
    JOIN pg_attribute AS af ON af.attrelid = c.confrelid AND af.attnum = ANY(c.confkey)
WHERE
    c.contype = 'f'
    AND conrelid::regclass::text LIKE '%custom_scenarios%';

-- 4. Eğer custom_scenarios tablosu yoksa veya yanlış yapıdaysa, yeniden oluştur
DROP TABLE IF EXISTS custom_scenario_test_answers CASCADE;
DROP TABLE IF EXISTS custom_scenario_questions CASCADE;
DROP TABLE IF EXISTS custom_scenario_steps CASCADE;
DROP TABLE IF EXISTS custom_scenarios CASCADE;

-- 5. Custom scenarios table - kullanıcı tarafından oluşturulan senaryolar
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

-- 6. Custom scenario steps table - scenario adımları
CREATE TABLE custom_scenario_steps (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  scenario_id UUID REFERENCES custom_scenarios(id) ON DELETE CASCADE,
  step_order INTEGER NOT NULL,
  timestamp TEXT,
  level TEXT DEFAULT 'info', -- info, warning, error, success
  message TEXT NOT NULL,
  is_critical BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Custom scenario questions table - sorular ve cevaplar
CREATE TABLE custom_scenario_questions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  scenario_id UUID REFERENCES custom_scenarios(id) ON DELETE CASCADE,
  question_order INTEGER NOT NULL,
  question_text TEXT NOT NULL,
  points INTEGER DEFAULT 10,
  keywords JSONB, -- Expected keywords for grading
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. Test answers table - test cevapları (optional, for tracking test results)
CREATE TABLE custom_scenario_test_answers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  scenario_id UUID REFERENCES custom_scenarios(id) ON DELETE CASCADE,
  question_id UUID REFERENCES custom_scenario_questions(id) ON DELETE CASCADE,
  user_answer TEXT NOT NULL,
  ai_feedback TEXT,
  score INTEGER DEFAULT 0,
  test_session_id UUID, -- To group answers from same test session
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. Indexes for better performance
CREATE INDEX idx_custom_scenarios_user_id ON custom_scenarios(user_id);
CREATE INDEX idx_custom_scenarios_test_status ON custom_scenarios(test_status);
CREATE INDEX idx_custom_scenario_steps_scenario_id ON custom_scenario_steps(scenario_id);
CREATE INDEX idx_custom_scenario_questions_scenario_id ON custom_scenario_questions(scenario_id);
CREATE INDEX idx_custom_scenario_test_answers_scenario_id ON custom_scenario_test_answers(scenario_id);

-- 10. RLS (Row Level Security) policies - herkese izin ver (development için)
ALTER TABLE custom_scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_scenario_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_scenario_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_scenario_test_answers ENABLE ROW LEVEL SECURITY;

-- Geliştirme aşaması için tüm işlemlere izin ver
CREATE POLICY "Allow all operations on custom_scenarios" ON custom_scenarios FOR ALL USING (true);
CREATE POLICY "Allow all operations on custom_scenario_steps" ON custom_scenario_steps FOR ALL USING (true);
CREATE POLICY "Allow all operations on custom_scenario_questions" ON custom_scenario_questions FOR ALL USING (true);
CREATE POLICY "Allow all operations on custom_scenario_test_answers" ON custom_scenario_test_answers FOR ALL USING (true);

-- 11. Updated_at trigger for custom_scenarios
CREATE TRIGGER update_custom_scenarios_updated_at
    BEFORE UPDATE ON custom_scenarios
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 12. Test etmek için örnek veri ekle (isteğe bağlı)
-- INSERT INTO custom_scenarios (user_id, title, description, file_name, file_size, raw_content)
-- SELECT id, 'Test Scenario', 'Test description', 'test.log', 1024, 'test log content'
-- FROM users LIMIT 1;

-- 13. Test sorguları
SELECT 'Tables created successfully' as status;
SELECT COUNT(*) as custom_scenarios_count FROM custom_scenarios;
SELECT COUNT(*) as users_count FROM users;