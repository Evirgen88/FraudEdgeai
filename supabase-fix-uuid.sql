-- UUID kolonu eksik hatası için düzeltme scripti
-- Bu SQL kodlarını Supabase Dashboard > SQL Editor'da çalıştır

-- 1. ADIM: users tablosuna uuid kolonu ekle (eğer yoksa)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS uuid UUID DEFAULT gen_random_uuid();

-- 2. ADIM: uuid kolonu için UNIQUE constraint ekle
ALTER TABLE users 
ADD CONSTRAINT users_uuid_unique UNIQUE(uuid);

-- 3. ADIM: Mevcut kullanıcılar için UUID generate et (eğer NULL ise)
UPDATE users 
SET uuid = gen_random_uuid() 
WHERE uuid IS NULL;

-- 4. ADIM: uuid kolonunu NOT NULL yap
ALTER TABLE users 
ALTER COLUMN uuid SET NOT NULL;

-- 5. ADIM: Şimdi user_progress foreign key'ini düzelt
ALTER TABLE user_progress 
DROP CONSTRAINT IF EXISTS user_progress_user_id_fkey;

ALTER TABLE user_progress 
ADD CONSTRAINT user_progress_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES users(uuid) ON DELETE CASCADE;

-- 6. ADIM: Performance için index ekle
CREATE INDEX IF NOT EXISTS idx_users_uuid ON users(uuid);

-- 7. ADIM: Test sorgusu - kullanıcıları kontrol et
-- SELECT id, uuid, first_name, last_name FROM users LIMIT 5;