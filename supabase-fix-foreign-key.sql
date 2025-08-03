-- Foreign key constraint hatası için düzeltme scripti
-- Bu SQL kodlarını Supabase Dashboard > SQL Editor'da çalıştır

-- 1. ADIM: Önce mevcut durumu kontrol edelim
-- SELECT 'users tablosu', COUNT(*) FROM users;
-- SELECT 'user_progress tablosu', COUNT(*) FROM user_progress;

-- 2. ADIM: user_progress'deki orphan kayıtları bul
-- SELECT DISTINCT up.user_id 
-- FROM user_progress up 
-- LEFT JOIN users u ON up.user_id = u.uuid 
-- WHERE u.uuid IS NULL;

-- 3. ADIM: Constraint'i kaldır (zaten var)
ALTER TABLE user_progress DROP CONSTRAINT IF EXISTS user_progress_user_id_fkey;

-- 4. ADIM: İki seçenek var, birini seç:

-- SEÇENEK A: Orphan kayıtları sil (güvenli ama veri kaybı)
-- DELETE FROM user_progress 
-- WHERE user_id NOT IN (SELECT uuid FROM users WHERE uuid IS NOT NULL);

-- SEÇENEK B: Orphan kayıtları mevcut bir user'a bağla (veri korunur)
-- Önce bir test user'ın UUID'sini al
DO $$
DECLARE
    first_user_uuid UUID;
BEGIN
    -- İlk kullanıcının UUID'sini al
    SELECT uuid INTO first_user_uuid FROM users ORDER BY id LIMIT 1;
    
    -- Eğer hiç kullanıcı yoksa, varsayılan bir UUID oluştur
    IF first_user_uuid IS NULL THEN
        INSERT INTO users (first_name, last_name, referral_source, uuid) 
        VALUES ('Default', 'User', 'system', gen_random_uuid())
        RETURNING uuid INTO first_user_uuid;
    END IF;
    
    -- Orphan kayıtları bu kullanıcıya bağla
    UPDATE user_progress 
    SET user_id = first_user_uuid
    WHERE user_id NOT IN (SELECT uuid FROM users WHERE uuid IS NOT NULL);
    
    RAISE NOTICE 'Orphan records updated to user UUID: %', first_user_uuid;
END $$;

-- 5. ADIM: Şimdi foreign key constraint'ini ekle
ALTER TABLE user_progress 
ADD CONSTRAINT user_progress_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES users(uuid) ON DELETE CASCADE;

-- 6. ADIM: Kontrol sorguları
-- Tüm kayıtların eşleştiğini kontrol et
SELECT 
    'Toplam user_progress kayıtları' as description, 
    COUNT(*) as count 
FROM user_progress
UNION ALL
SELECT 
    'Eşleşen kayıtlar', 
    COUNT(*) 
FROM user_progress up 
JOIN users u ON up.user_id = u.uuid
UNION ALL
SELECT 
    'Eşleşmeyen kayıtlar', 
    COUNT(*) 
FROM user_progress up 
LEFT JOIN users u ON up.user_id = u.uuid 
WHERE u.uuid IS NULL;