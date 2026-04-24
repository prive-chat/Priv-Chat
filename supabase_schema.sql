-- ===============================================================
-- ESQUEMA MAESTRO DE SEGURIDAD Y ESTRUCTURA EMPRESARIAL (SUPABASE)
-- ===============================================================
-- Versión: 2.0 (Passion Red Edition)
-- Descripción: Configuración completa de tablas, seguridad RLS, 
--              almacenamiento (Storage) y automatización de notificaciones.
-- ===============================================================

-- 1. EXTENSIONES NECESARIAS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. CONFIGURACIÓN DE STORAGE (BÚCKETS)
-- Esto soluciona el error "Bucket not found"
INSERT INTO storage.buckets (id, name, public) 
VALUES ('media', 'media', true) 
ON CONFLICT (id) DO NOTHING;

-- 3. TABLA DE PERFILES (PROFILES)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  username TEXT UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  cover_url TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  is_private BOOLEAN DEFAULT FALSE,
  role TEXT DEFAULT 'user' CHECK (role IN ('user', 'super_admin')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Asegurar que todas las columnas necesarias existen (Migración)
DO $$ 
BEGIN 
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'email') THEN
    ALTER TABLE public.profiles ADD COLUMN email TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'username') THEN
    ALTER TABLE public.profiles ADD COLUMN username TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'full_name') THEN
    ALTER TABLE public.profiles ADD COLUMN full_name TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'avatar_url') THEN
    ALTER TABLE public.profiles ADD COLUMN avatar_url TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'cover_url') THEN
    ALTER TABLE public.profiles ADD COLUMN cover_url TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'is_verified') THEN
    ALTER TABLE public.profiles ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'is_private') THEN
    ALTER TABLE public.profiles ADD COLUMN is_private BOOLEAN DEFAULT FALSE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'role') THEN
    ALTER TABLE public.profiles ADD COLUMN role TEXT DEFAULT 'user';
  END IF;
END $$;

-- 4. TABLA DE MEDIOS (MEDIA)
CREATE TABLE IF NOT EXISTS public.media (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  url TEXT NOT NULL,
  type TEXT CHECK (type IN ('image', 'video')) NOT NULL,
  caption TEXT,
  shares_count BIGINT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Migración: Asegurar columna shares_count
DO $$ 
BEGIN 
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'media' AND column_name = 'shares_count') THEN
    ALTER TABLE public.media ADD COLUMN shares_count BIGINT DEFAULT 0;
  END IF;
END $$;

-- 5. TABLA DE MENSAJES (MESSAGES)
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  receiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  media_url TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP WITH TIME ZONE,
  is_delivered BOOLEAN DEFAULT FALSE,
  delivered_at TIMESTAMP WITH TIME ZONE,
  deleted_by_sender BOOLEAN DEFAULT FALSE,
  deleted_by_receiver BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 6. TABLA DE NOTIFICACIONES
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT CHECK (type IN ('message', 'verification', 'system', 'like', 'follow_request', 'follow_accept')) NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  link TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 7. TABLA DE LIKES
CREATE TABLE IF NOT EXISTS public.likes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  media_id UUID REFERENCES public.media(id) ON DELETE CASCADE NOT NULL,
  type TEXT DEFAULT 'heart',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  UNIQUE(user_id, media_id)
);

-- Migración: Asegurar columna type
DO $$ 
BEGIN 
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'likes' AND column_name = 'type') THEN
    ALTER TABLE public.likes ADD COLUMN type TEXT DEFAULT 'heart';
  END IF;
END $$;

-- Función para compartir media
CREATE OR REPLACE FUNCTION public.increment_media_share(p_media_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.media SET shares_count = shares_count + 1 WHERE id = p_media_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Función para reaccionar a media
CREATE OR REPLACE FUNCTION public.toggle_media_reaction(p_user_id UUID, p_media_id UUID, p_reaction_type TEXT)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.likes (user_id, media_id, type)
  VALUES (p_user_id, p_media_id, p_reaction_type)
  ON CONFLICT (user_id, media_id) 
  DO UPDATE SET type = EXCLUDED.type;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 8. TABLA DE SEGUIDORES (FOLLOWS)
CREATE TABLE IF NOT EXISTS public.follows (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  follower_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  following_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  UNIQUE(follower_id, following_id)
);

-- 9. TABLA DE ESTADO DE CHATS (USER_CHATS)
-- Controla si un chat está oculto (Eliminar) o cuándo fue vaciado
CREATE TABLE IF NOT EXISTS public.user_chats (
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  target_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  is_hidden BOOLEAN DEFAULT FALSE,
  last_cleared_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  PRIMARY KEY (user_id, target_user_id)
);

-- 10. ACTIVAR SEGURIDAD DE NIVEL DE FILA (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_chats ENABLE ROW LEVEL SECURITY;

-- 11. FUNCIONES DE AYUDA PARA RLS
-- Rompe la recursión de seguridad consultando UNICAMENTE el JWT
-- Esto garantiza que no haya NINGÚN SELECT a la tabla profiles durante la validación
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
  -- PRIORIDAD ÚNICA: Verificar email maestro directamente en el JWT.
  -- Esto es instantáneo y es físicamente imposible que entre en bucle.
  RETURN (auth.jwt() ->> 'email' = 'privechat.vip@gmail.com');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 11. POLÍTICAS DE SEGURIDAD (RLS)

-- PERFILES: Solo el dueño puede editar su información.
DROP POLICY IF EXISTS "Perfiles visibles por usuarios" ON public.profiles;
CREATE POLICY "Perfiles visibles por usuarios" ON public.profiles FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Usuarios editan su info básica" ON public.profiles;
CREATE POLICY "Usuarios editan su info básica" ON public.profiles FOR UPDATE 
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id AND 
  (CASE WHEN auth.jwt() ->> 'email' = 'privechat.vip@gmail.com' THEN TRUE ELSE role = 'user' END)
);

-- MEDIOS: Solo usuarios autenticados ven medios. Solo dueños o admins borran.
DROP POLICY IF EXISTS "Medios visibles por usuarios" ON public.media;
CREATE POLICY "Medios visibles por usuarios" ON public.media FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Usuarios suben sus medios" ON public.media;
CREATE POLICY "Usuarios suben sus medios" ON public.media FOR INSERT WITH CHECK (
  auth.uid() = user_id AND 
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_verified = TRUE)
);

DROP POLICY IF EXISTS "Dueño o Admin eliminan medios" ON public.media;
CREATE POLICY "Dueño o Admin eliminan medios" ON public.media FOR DELETE USING (auth.uid() = user_id OR public.is_super_admin());

-- MENSAJES: Estricta privacidad entre participantes.
DROP POLICY IF EXISTS "Participantes leen mensajes" ON public.messages;
CREATE POLICY "Participantes leen mensajes" ON public.messages FOR SELECT USING (
  auth.uid() = sender_id OR 
  auth.uid() = receiver_id OR 
  public.is_super_admin()
);

DROP POLICY IF EXISTS "Usuarios envían mensajes" ON public.messages;
CREATE POLICY "Usuarios envían mensajes" ON public.messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

DROP POLICY IF EXISTS "Usuarios marcan como leido" ON public.messages;
CREATE POLICY "Usuarios marcan como leido" ON public.messages FOR UPDATE USING (auth.uid() = receiver_id)
WITH CHECK (
  (content = content) AND (sender_id = sender_id) AND (receiver_id = receiver_id) -- Solo permitir cambiar is_read
);

-- AUDIT LOGS: Solo admins.
DROP POLICY IF EXISTS "Solo Admins ven logs" ON public.audit_logs;
CREATE POLICY "Solo Admins ven logs" ON public.audit_logs FOR SELECT USING (public.is_super_admin());

-- ADS: Gestión solo por Admin.
DROP POLICY IF EXISTS "Anuncios visibles por todos" ON public.ads;
CREATE POLICY "Anuncios visibles por todos" ON public.ads FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Solo Admins gestionan anuncios" ON public.ads;
CREATE POLICY "Solo Admins gestionan anuncios" ON public.ads FOR ALL USING (public.is_super_admin());

-- Notificaciones
DROP POLICY IF EXISTS "Usuarios ven sus notificaciones" ON public.notifications;
CREATE POLICY "Usuarios ven sus notificaciones" ON public.notifications FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuarios gestionan sus notificaciones" ON public.notifications;
CREATE POLICY "Usuarios gestionan sus notificaciones" ON public.notifications FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Sistema crea notificaciones" ON public.notifications;
CREATE POLICY "Sistema crea notificaciones" ON public.notifications FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Likes
DROP POLICY IF EXISTS "Likes visibles por todos" ON public.likes;
CREATE POLICY "Likes visibles por todos" ON public.likes FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Usuarios gestionan sus likes" ON public.likes;
CREATE POLICY "Usuarios gestionan sus likes" ON public.likes FOR ALL USING (auth.uid() = user_id);

-- Follows
DROP POLICY IF EXISTS "Follows visibles por involucrados" ON public.follows;
CREATE POLICY "Follows visibles por involucrados" ON public.follows FOR SELECT USING (auth.uid() = follower_id OR auth.uid() = following_id);

DROP POLICY IF EXISTS "Usuarios gestionan sus follows" ON public.follows;
CREATE POLICY "Usuarios gestionan sus follows" ON public.follows FOR ALL USING (auth.uid() = follower_id OR auth.uid() = following_id);

-- User Chats
DROP POLICY IF EXISTS "Usuarios ven sus chats" ON public.user_chats;
CREATE POLICY "Usuarios ven sus chats" ON public.user_chats FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuarios gestionan sus chats" ON public.user_chats;
CREATE POLICY "Usuarios gestionan sus chats" ON public.user_chats FOR ALL USING (auth.uid() = user_id);

-- 12. POLÍTICAS DE STORAGE (MEDIA BUCKET)
DROP POLICY IF EXISTS "Acceso público a medios" ON storage.objects;
CREATE POLICY "Acceso público a medios" ON storage.objects FOR SELECT USING (bucket_id = 'media');

DROP POLICY IF EXISTS "Usuarios suben a media" ON storage.objects;
CREATE POLICY "Usuarios suben a media" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'media' AND 
  auth.role() = 'authenticated' AND
  (SELECT is_verified FROM public.profiles WHERE id = auth.uid()) = TRUE
);

DROP POLICY IF EXISTS "Usuarios eliminan sus objetos" ON storage.objects;
CREATE POLICY "Usuarios eliminan sus objetos" ON storage.objects FOR DELETE USING (
  bucket_id = 'media' AND 
  (auth.uid() = owner OR public.is_super_admin())
);
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  v_username TEXT;
  v_full_name TEXT;
BEGIN
  -- Generar un username temporal basado en el email si no existe
  v_username := coalesce(
    new.raw_user_meta_data->>'username', 
    split_part(new.email, '@', 1) || '_' || substr(new.id::text, 1, 4)
  );
  
  -- Generar un full_name si no existe
  v_full_name := coalesce(
    new.raw_user_meta_data->>'full_name', 
    split_part(new.email, '@', 1)
  );

  INSERT INTO public.profiles (id, email, full_name, avatar_url, cover_url, username, role, is_verified)
  VALUES (
    new.id, 
    new.email, 
    v_full_name, 
    new.raw_user_meta_data->>'avatar_url',
    new.raw_user_meta_data->>'cover_url',
    v_username,
    'user',
    false
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = coalesce(profiles.full_name, EXCLUDED.full_name),
    username = coalesce(profiles.username, EXCLUDED.username);
    
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 14. AUTOMATIZACIÓN: NOTIFICACIONES AUTOMÁTICAS

-- Notificación de Mensaje Nuevo
CREATE OR REPLACE FUNCTION public.notify_new_message()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.notifications (user_id, sender_id, type, title, content, link)
  VALUES (
    new.receiver_id,
    new.sender_id,
    'message',
    'Nuevo mensaje',
    'Has recibido un nuevo mensaje privado.',
    '/messages'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_new_message ON public.messages;
CREATE TRIGGER on_new_message AFTER INSERT ON public.messages FOR EACH ROW EXECUTE PROCEDURE public.notify_new_message();

-- Notificación de Like
CREATE OR REPLACE FUNCTION public.notify_new_like()
RETURNS trigger AS $$
DECLARE
  v_media_owner UUID;
BEGIN
  SELECT user_id INTO v_media_owner FROM public.media WHERE id = new.media_id;
  
  IF v_media_owner != new.user_id THEN
    INSERT INTO public.notifications (user_id, sender_id, type, title, content, link)
    VALUES (
      v_media_owner,
      new.user_id,
      'like',
      'Nuevo Like',
      'A alguien le ha gustado tu publicación.',
      '/post/' || new.media_id
    );
  END IF;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_new_like ON public.likes;
CREATE TRIGGER on_new_like AFTER INSERT ON public.likes FOR EACH ROW EXECUTE PROCEDURE public.notify_new_like();

-- 15. OPTIMIZACIONES DE RENDIMIENTO (ÍNDICES)
CREATE INDEX IF NOT EXISTS idx_messages_participants ON public.messages (sender_id, receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications (user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_media_user_id ON public.media (user_id);

-- 16. CONFIGURACIÓN DE REALTIME
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        CREATE PUBLICATION supabase_realtime;
    END IF;
    
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications, public.messages, public.profiles, public.media;
EXCEPTION
    WHEN others THEN NULL;
END $$;

-- 17. SISTEMA DE AUDITORÍA (ENTERPRISE GRADE)
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  table_name TEXT NOT NULL,
  record_id UUID,
  old_data JSONB,
  new_data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Solo Admins ven logs" ON public.audit_logs;
CREATE POLICY "Solo Admins ven logs" ON public.audit_logs FOR SELECT USING (public.is_super_admin());

-- Función para registrar auditoría automáticamente
CREATE OR REPLACE FUNCTION public.process_audit_log() RETURNS trigger AS $$
BEGIN
  IF (TG_OP = 'DELETE') THEN
    INSERT INTO public.audit_logs (user_id, action, table_name, record_id, old_data)
    VALUES (auth.uid(), TG_OP, TG_TABLE_NAME, old.id, to_jsonb(old));
    RETURN old;
  ELSIF (TG_OP = 'UPDATE') THEN
    INSERT INTO public.audit_logs (user_id, action, table_name, record_id, old_data, new_data)
    VALUES (auth.uid(), TG_OP, TG_TABLE_NAME, new.id, to_jsonb(old), to_jsonb(new));
    RETURN new;
  ELSIF (TG_OP = 'INSERT') THEN
    INSERT INTO public.audit_logs (user_id, action, table_name, record_id, new_data)
    VALUES (auth.uid(), TG_OP, TG_TABLE_NAME, new.id, to_jsonb(new));
    RETURN new;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Aplicar auditoría a tablas críticas
DROP TRIGGER IF EXISTS tr_audit_profiles ON public.profiles;
CREATE TRIGGER tr_audit_profiles AFTER INSERT OR UPDATE OR DELETE ON public.profiles FOR EACH ROW EXECUTE PROCEDURE public.process_audit_log();

DROP TRIGGER IF EXISTS tr_audit_media ON public.media;
CREATE TRIGGER tr_audit_media AFTER INSERT OR UPDATE OR DELETE ON public.media FOR EACH ROW EXECUTE PROCEDURE public.process_audit_log();

-- 18. BÚSQUEDA DE TEXTO COMPLETO (FULL-TEXT SEARCH)
-- Optimiza la búsqueda de usuarios por nombre o username
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS search_vector tsvector;
CREATE INDEX IF NOT EXISTS idx_profiles_search ON public.profiles USING GIN (search_vector);

CREATE OR REPLACE FUNCTION public.profiles_search_trigger() RETURNS trigger AS $$
BEGIN
  new.search_vector :=
    setweight(to_tsvector('spanish', coalesce(new.username, '')), 'A') ||
    setweight(to_tsvector('spanish', coalesce(new.full_name, '')), 'B');
  RETURN new;
END
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_profiles_search ON public.profiles;
CREATE TRIGGER tr_profiles_search BEFORE INSERT OR UPDATE ON public.profiles
FOR EACH ROW EXECUTE PROCEDURE public.profiles_search_trigger();

-- 20. SISTEMA DE PUBLICIDAD (AD MANAGER)
CREATE TABLE IF NOT EXISTS public.ads (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  cta_text TEXT DEFAULT 'Saber más',
  image_url TEXT NOT NULL,
  link_url TEXT,
  type TEXT CHECK (type IN ('image', 'video')) DEFAULT 'image',
  placement TEXT CHECK (placement IN ('feed', 'sidebar', 'interstitial')) DEFAULT 'feed',
  status TEXT CHECK (status IN ('active', 'paused', 'scheduled')) DEFAULT 'active',
  impressions BIGINT DEFAULT 0,
  clicks BIGINT DEFAULT 0,
  cost_per_click DECIMAL(10, 2) DEFAULT 0,
  cost_per_impression DECIMAL(10, 2) DEFAULT 0,
  total_budget DECIMAL(10, 2) DEFAULT 0,
  spent_budget DECIMAL(10, 2) DEFAULT 0,
  priority INTEGER DEFAULT 0,
  shares_count BIGINT DEFAULT 0,
  starts_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ends_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Asegurar que todas las columnas necesarias existen (Para bases de datos ya creadas)
DO $$ 
BEGIN 
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ads' AND column_name = 'shares_count') THEN
    ALTER TABLE public.ads ADD COLUMN shares_count BIGINT DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ads' AND column_name = 'starts_at') THEN
    ALTER TABLE public.ads ADD COLUMN starts_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ads' AND column_name = 'ends_at') THEN
    ALTER TABLE public.ads ADD COLUMN ends_at TIMESTAMP WITH TIME ZONE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ads' AND column_name = 'priority') THEN
    ALTER TABLE public.ads ADD COLUMN priority INTEGER DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ads' AND column_name = 'cta_text') THEN
    ALTER TABLE public.ads ADD COLUMN cta_text TEXT DEFAULT 'Saber más';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ads' AND column_name = 'cost_per_click') THEN
    ALTER TABLE public.ads ADD COLUMN cost_per_click DECIMAL(10, 2) DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ads' AND column_name = 'cost_per_impression') THEN
    ALTER TABLE public.ads ADD COLUMN cost_per_impression DECIMAL(10, 2) DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ads' AND column_name = 'total_budget') THEN
    ALTER TABLE public.ads ADD COLUMN total_budget DECIMAL(10, 2) DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ads' AND column_name = 'spent_budget') THEN
    ALTER TABLE public.ads ADD COLUMN spent_budget DECIMAL(10, 2) DEFAULT 0;
  END IF;
END $$;

ALTER TABLE public.ads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anuncios visibles por todos" ON public.ads;
CREATE POLICY "Anuncios visibles por todos" ON public.ads FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Solo Admins gestionan anuncios" ON public.ads;
CREATE POLICY "Solo Admins gestionan anuncios" ON public.ads FOR ALL USING (public.is_super_admin());

-- Función para incrementar métricas de anuncios de forma segura
CREATE OR REPLACE FUNCTION public.increment_ad_metric(ad_id UUID, metric_type TEXT)
RETURNS VOID AS $$
BEGIN
  IF metric_type = 'impression' THEN
    UPDATE public.ads SET impressions = impressions + 1 WHERE id = ad_id;
  ELSIF metric_type = 'click' THEN
    UPDATE public.ads SET clicks = clicks + 1 WHERE id = ad_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
CREATE OR REPLACE FUNCTION public.get_user_conversations(p_user_id UUID)
RETURNS TABLE (
    other_user_id UUID,
    last_message TEXT,
    last_message_at TIMESTAMP WITH TIME ZONE,
    unread_count BIGINT,
    profile JSONB
) AS $$
BEGIN
    RETURN QUERY
    WITH latest_messages AS (
        SELECT DISTINCT ON (
            CASE WHEN sender_id < receiver_id THEN sender_id ELSE receiver_id END,
            CASE WHEN sender_id < receiver_id THEN receiver_id ELSE sender_id END
        )
        sender_id, receiver_id, content, created_at
        FROM public.messages
        WHERE (sender_id = p_user_id AND deleted_by_sender = FALSE) 
           OR (receiver_id = p_user_id AND deleted_by_receiver = FALSE)
        ORDER BY 
            CASE WHEN sender_id < receiver_id THEN sender_id ELSE receiver_id END,
            CASE WHEN sender_id < receiver_id THEN receiver_id ELSE sender_id END,
            created_at DESC
    ),
    active_chats AS (
        -- Combinamos usuarios con mensajes recientes y usuarios con chats marcados como visibles (Vaciar chat)
        SELECT 
            uc.target_user_id as other_id,
            NULL::text as msg_content,
            uc.updated_at as msg_at
        FROM public.user_chats uc
        WHERE uc.user_id = p_user_id AND uc.is_hidden = FALSE
        
        UNION
        
        SELECT 
            (CASE WHEN lm.sender_id = p_user_id THEN lm.receiver_id ELSE lm.sender_id END) as other_id,
            lm.content as msg_content,
            lm.created_at as msg_at
        FROM latest_messages lm
    ),
    final_conversations AS (
        SELECT DISTINCT ON (other_id)
            other_id,
            msg_content,
            msg_at
        FROM active_chats
        ORDER BY other_id, msg_at DESC
    )
    SELECT 
        fc.other_id as other_user_id,
        fc.msg_content as last_message,
        fc.msg_at as last_message_at,
        (
            SELECT count(*) 
            FROM public.notifications n 
            WHERE n.user_id = p_user_id 
            AND n.sender_id = fc.other_id
            AND n.is_read = FALSE
            AND n.type = 'message'
        ) as unread_count,
        to_jsonb(p) as profile
    FROM final_conversations fc
    JOIN public.profiles p ON p.id = fc.other_id
    ORDER BY fc.msg_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 21. BROADCAST GLOBAL (ESCALABILIDAD EMPRESARIAL)
-- Procesa el envío de notificaciones en el servidor para evitar colapsar el cliente
CREATE OR REPLACE FUNCTION public.broadcast_global_message(
  p_title TEXT,
  p_content TEXT,
  p_sender_id UUID
)
RETURNS VOID AS $$
BEGIN
  -- Insertar notificaciones para todos los usuarios existentes
  INSERT INTO public.notifications (user_id, sender_id, type, title, content, link)
  SELECT id, p_sender_id, 'system', p_title, p_content, '/'
  FROM public.profiles;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 22. FUNCIÓN PARA ELIMINAR CUENTA (RPC)
CREATE OR REPLACE FUNCTION public.delete_own_user()
RETURNS void AS $$
BEGIN
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 23. PERMISOS FINALES Y BACKFILL
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_ad_metric(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_ad_metric(UUID, TEXT) TO anon;

-- 21. REACCIONES A ANUNCIOS (AD_LIKES)
CREATE TABLE IF NOT EXISTS public.ad_likes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  ad_id UUID REFERENCES public.ads(id) ON DELETE CASCADE NOT NULL,
  type TEXT DEFAULT 'heart',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  UNIQUE(user_id, ad_id)
);

ALTER TABLE public.ad_likes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Reacciones anuncios visibles por todos" ON public.ad_likes;
CREATE POLICY "Reacciones anuncios visibles por todos" ON public.ad_likes FOR SELECT USING (auth.role() = 'authenticated');
DROP POLICY IF EXISTS "Usuarios reaccionan a anuncios" ON public.ad_likes;
CREATE POLICY "Usuarios reaccionan a anuncios" ON public.ad_likes FOR ALL USING (auth.uid() = user_id);

-- Función para compartir anuncio
CREATE OR REPLACE FUNCTION public.increment_ad_share(p_ad_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.ads SET shares_count = shares_count + 1 WHERE id = p_ad_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Función para reaccionar a anuncio
CREATE OR REPLACE FUNCTION public.toggle_ad_reaction(p_user_id UUID, p_ad_id UUID, p_reaction_type TEXT)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.ad_likes (user_id, ad_id, type)
  VALUES (p_user_id, p_ad_id, p_reaction_type)
  ON CONFLICT (user_id, ad_id) 
  DO UPDATE SET type = EXCLUDED.type;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.increment_ad_share(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_ad_share(UUID) TO anon;
GRANT EXECUTE ON FUNCTION public.toggle_ad_reaction(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_ad_metric(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_ad_metric(UUID, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.toggle_ad_reaction(UUID, UUID, TEXT) TO authenticated;

-- Backfill: Asegurar que todos los usuarios de auth.users tengan un perfil
INSERT INTO public.profiles (id, email, full_name, username, role)
SELECT 
    id, 
    email, 
    coalesce(raw_user_meta_data->>'full_name', split_part(email, '@', 1)),
    coalesce(raw_user_meta_data->>'username', split_part(email, '@', 1) || '_' || substr(id::text, 1, 4)),
    'user'
FROM auth.users
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = coalesce(profiles.full_name, EXCLUDED.full_name),
    username = coalesce(profiles.username, EXCLUDED.username);
