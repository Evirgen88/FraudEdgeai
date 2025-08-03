-- Custom Scenarios için database şeması
-- Bu SQL kodlarını Supabase Dashboard > SQL Editor'da çalıştır

-- 1. Custom scenarios ana tablosu
CREATE TABLE IF NOT EXISTS custom_scenarios (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(uuid) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT DEFAULT 'custom',
  difficulty INTEGER DEFAULT 1 CHECK (difficulty >= 1 AND difficulty <= 3), -- 1=Easy, 2=Medium, 3=Hard
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  is_public BOOLEAN DEFAULT false,
  original_file_name TEXT, -- Yüklenen dosyanın adı
  original_file_size INTEGER, -- Dosya boyutu (bytes)
  raw_logs JSONB, -- Ham log verileri
  processed_logs JSONB, -- AI ile işlenmiş log verileri
  ai_analysis JSONB, -- AI'ın analiz sonuçları
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Custom scenario steps (zaman çizelgesi)
CREATE TABLE IF NOT EXISTS custom_scenario_steps (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  scenario_id UUID REFERENCES custom_scenarios(id) ON DELETE CASCADE,
  step_order INTEGER NOT NULL,
  timestamp_text TEXT NOT NULL, -- "14:30:15" gibi
  level TEXT NOT NULL CHECK (level IN ('info', 'warning', 'error', 'success')),
  message TEXT NOT NULL,
  raw_data JSONB, -- Ham log satırı
  is_critical BOOLEAN DEFAULT false, -- Bu step kritik mi?
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Custom scenario questions
CREATE TABLE IF NOT EXISTS custom_scenario_questions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  scenario_id UUID REFERENCES custom_scenarios(id) ON DELETE CASCADE,
  question_order INTEGER NOT NULL,
  question_text TEXT NOT NULL,
  ai_generated BOOLEAN DEFAULT true, -- AI mi oluşturdu, manuel mi?
  expected_keywords JSONB, -- Beklenen anahtar kelimeler ["phishing", "credential theft"]
  sample_answer TEXT, -- Örnek doğru cevap
  points INTEGER DEFAULT 10, -- Bu sorunun puanı
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Custom scenario completions (kullanıcı tamamlamaları)
CREATE TABLE IF NOT EXISTS custom_scenario_completions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  scenario_id UUID REFERENCES custom_scenarios(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(uuid) ON DELETE CASCADE,
  answers JSONB NOT NULL, -- Kullanıcının cevapları
  total_score INTEGER NOT NULL,
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(scenario_id, user_id) -- Bir kullanıcı aynı scenarioyu birden fazla kez tamamlayabilir ama son skor tutulur
);

-- 5. Performance için indexler
CREATE INDEX IF NOT EXISTS idx_custom_scenarios_user_id ON custom_scenarios(user_id);
CREATE INDEX IF NOT EXISTS idx_custom_scenarios_status ON custom_scenarios(status);
CREATE INDEX IF NOT EXISTS idx_custom_scenarios_category ON custom_scenarios(category);
CREATE INDEX IF NOT EXISTS idx_custom_scenarios_public ON custom_scenarios(is_public);
CREATE INDEX IF NOT EXISTS idx_custom_scenario_steps_scenario_id ON custom_scenario_steps(scenario_id);
CREATE INDEX IF NOT EXISTS idx_custom_scenario_steps_order ON custom_scenario_steps(scenario_id, step_order);
CREATE INDEX IF NOT EXISTS idx_custom_scenario_questions_scenario_id ON custom_scenario_questions(scenario_id);
CREATE INDEX IF NOT EXISTS idx_custom_scenario_questions_order ON custom_scenario_questions(scenario_id, question_order);
CREATE INDEX IF NOT EXISTS idx_custom_scenario_completions_scenario ON custom_scenario_completions(scenario_id);
CREATE INDEX IF NOT EXISTS idx_custom_scenario_completions_user ON custom_scenario_completions(user_id);

-- 6. Updated_at trigger'ları
CREATE TRIGGER update_custom_scenarios_updated_at 
    BEFORE UPDATE ON custom_scenarios 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_custom_scenario_questions_updated_at 
    BEFORE UPDATE ON custom_scenario_questions 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 7. Helper functions

-- Get user's custom scenarios
CREATE OR REPLACE FUNCTION get_user_custom_scenarios(user_uuid UUID)
RETURNS TABLE(
  id UUID,
  title TEXT,
  description TEXT,
  category TEXT,
  difficulty INTEGER,
  status TEXT,
  created_at TIMESTAMPTZ,
  question_count BIGINT,
  completion_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
    SELECT 
      cs.id,
      cs.title,
      cs.description,
      cs.category,
      cs.difficulty,
      cs.status,
      cs.created_at,
      COUNT(DISTINCT csq.id) as question_count,
      COUNT(DISTINCT csc.id) as completion_count
    FROM custom_scenarios cs
    LEFT JOIN custom_scenario_questions csq ON cs.id = csq.scenario_id
    LEFT JOIN custom_scenario_completions csc ON cs.id = csc.scenario_id
    WHERE cs.user_id = user_uuid
    GROUP BY cs.id, cs.title, cs.description, cs.category, cs.difficulty, cs.status, cs.created_at
    ORDER BY cs.updated_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Get scenario with all details
CREATE OR REPLACE FUNCTION get_custom_scenario_details(scenario_uuid UUID)
RETURNS TABLE(
  scenario_id UUID,
  title TEXT,
  description TEXT,
  steps JSONB,
  questions JSONB
) AS $$
BEGIN
  RETURN QUERY
    SELECT 
      cs.id,
      cs.title,
      cs.description,
      COALESCE(
        json_agg(
          json_build_object(
            'id', css.id,
            'order', css.step_order,
            'timestamp', css.timestamp_text,
            'level', css.level,
            'message', css.message,
            'is_critical', css.is_critical
          ) ORDER BY css.step_order
        ) FILTER (WHERE css.id IS NOT NULL), 
        '[]'::json
      )::jsonb as steps,
      COALESCE(
        json_agg(
          json_build_object(
            'id', csq.id,
            'order', csq.question_order,
            'question', csq.question_text,
            'keywords', csq.expected_keywords,
            'sample_answer', csq.sample_answer,
            'points', csq.points
          ) ORDER BY csq.question_order
        ) FILTER (WHERE csq.id IS NOT NULL),
        '[]'::json
      )::jsonb as questions
    FROM custom_scenarios cs
    LEFT JOIN custom_scenario_steps css ON cs.id = css.scenario_id
    LEFT JOIN custom_scenario_questions csq ON cs.id = csq.scenario_id
    WHERE cs.id = scenario_uuid
    GROUP BY cs.id, cs.title, cs.description;
END;
$$ LANGUAGE plpgsql;

-- 8. Test data (optional)
-- INSERT INTO custom_scenarios (user_id, title, description, category) 
-- VALUES (
--   (SELECT uuid FROM users LIMIT 1),
--   'Test Custom Scenario',
--   'Bu bir test custom scenario',
--   'test'
-- );

-- Kontrol sorguları
-- SELECT * FROM custom_scenarios;
-- SELECT * FROM get_user_custom_scenarios((SELECT uuid FROM users LIMIT 1));