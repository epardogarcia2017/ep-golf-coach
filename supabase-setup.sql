-- ============================================================
-- EP GOLF COACH - SUPABASE SCHEMA
-- Ejecutar en: Supabase → SQL Editor → New Query
-- ============================================================

-- PROFILES (extended user data)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  nombre TEXT,
  apellido TEXT,
  email TEXT,
  tel TEXT,
  nivel TEXT,
  origen TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- BOOKINGS
CREATE TABLE IF NOT EXISTS bookings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  user_email TEXT,
  user_name TEXT,
  modality TEXT NOT NULL,
  modality_name TEXT,
  date_key TEXT NOT NULL,
  date_iso TIMESTAMPTZ NOT NULL,
  date_display TEXT,
  slot INTEGER NOT NULL,
  slot_label TEXT,
  nivel TEXT,
  status TEXT DEFAULT 'confirmed',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- POSTS (community)
CREATE TABLE IF NOT EXISTS posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  author_id UUID REFERENCES auth.users(id),
  type TEXT DEFAULT 'tip',
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  likes INTEGER DEFAULT 0,
  liked_by UUID[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- NOTIFICATIONS
CREATE TABLE IF NOT EXISTS notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID,
  type TEXT,
  title TEXT,
  body TEXT,
  booking_id UUID,
  for_admin BOOLEAN DEFAULT FALSE,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- PROFILES: users see/edit only their own
CREATE POLICY "profiles_own" ON profiles FOR ALL USING (auth.uid() = id);

-- BOOKINGS: users see only their own; admin sees all
CREATE POLICY "bookings_own" ON bookings FOR SELECT USING (
  auth.uid() = user_id OR 
  auth.jwt()->> 'email' = 'epardogarcia2017@gmail.com'
);
CREATE POLICY "bookings_insert" ON bookings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "bookings_update" ON bookings FOR UPDATE USING (
  auth.uid() = user_id OR 
  auth.jwt()->>'email' = 'epardogarcia2017@gmail.com'
);

-- POSTS: everyone reads; only admin writes
CREATE POLICY "posts_read" ON posts FOR SELECT USING (TRUE);
CREATE POLICY "posts_write" ON posts FOR INSERT WITH CHECK (
  auth.jwt()->>'email' = 'epardogarcia2017@gmail.com'
);
CREATE POLICY "posts_update" ON posts FOR UPDATE USING (TRUE);

-- NOTIFICATIONS: admin sees all; users see own
CREATE POLICY "notif_read" ON notifications FOR SELECT USING (
  auth.uid() = user_id OR 
  for_admin = TRUE AND auth.jwt()->>'email' = 'epardogarcia2017@gmail.com'
);
CREATE POLICY "notif_insert" ON notifications FOR INSERT WITH CHECK (TRUE);

-- ============================================================
-- INITIAL POST
-- ============================================================
INSERT INTO posts (type, title, body) VALUES (
  'tip',
  'Bienvenidos a EP Golf Coach',
  'Este es el espacio de la comunidad. Acá voy a compartir tips técnicos, análisis de swing, resultados de torneos y novedades. ¡Bienvenidos a todos!'
);


-- COMMENTS (add this if not already created)
CREATE TABLE IF NOT EXISTS comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  author_name TEXT,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "comments_read" ON comments FOR SELECT USING (TRUE);
CREATE POLICY "comments_insert" ON comments FOR INSERT WITH CHECK (auth.uid() = user_id);

-- PUSH SUBSCRIPTIONS (for server-side push notifications)
CREATE TABLE IF NOT EXISTS push_subscriptions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  email TEXT,
  subscription JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE push_subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "push_own" ON push_subscriptions FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "push_admin_read" ON push_subscriptions FOR SELECT USING (TRUE);
