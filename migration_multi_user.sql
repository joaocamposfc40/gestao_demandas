-- ════════════════════════════════════════════════════════════════════
-- GESTÃO DE DEMANDAS — Migration: Multi-usuário (user_id + RLS por UID)
-- Projeto: xtpirxyjmqwcvjlcajsz
-- Executar no SQL Editor do Supabase
--
-- ATENÇÃO: executar ETAPA POR ETAPA. Não pule nenhuma.
-- Após concluir, habilitar signup no painel Auth do Supabase.
-- ════════════════════════════════════════════════════════════════════

-- ── ETAPA 1: Adicionar coluna user_id ────────────────────────────
-- (NULL por enquanto para permitir o backfill antes de tornar NOT NULL)

ALTER TABLE public.demandas
  ADD COLUMN IF NOT EXISTS user_id UUID;

ALTER TABLE public.demandas_log
  ADD COLUMN IF NOT EXISTS user_id UUID;

-- ── ETAPA 2: Backfill — associar registros existentes ao dono ────
-- Descobre o UUID de João e aplica em todos os registros existentes.

UPDATE public.demandas
  SET user_id = (
    SELECT id FROM auth.users
    WHERE email = 'joao.campos@ferreiracosta.com.br'
    LIMIT 1
  )
  WHERE user_id IS NULL;

UPDATE public.demandas_log
  SET user_id = (
    SELECT id FROM auth.users
    WHERE email = 'joao.campos@ferreiracosta.com.br'
    LIMIT 1
  )
  WHERE user_id IS NULL;

-- Verificação: confirme que não sobrou nenhum NULL antes de continuar
-- SELECT COUNT(*) FROM public.demandas WHERE user_id IS NULL;
-- Se retornar 0, prossiga. Caso contrário investigue antes de avançar.

-- ── ETAPA 3: Tornar NOT NULL com DEFAULT auth.uid() ───────────────

ALTER TABLE public.demandas
  ALTER COLUMN user_id SET DEFAULT auth.uid(),
  ALTER COLUMN user_id SET NOT NULL;

ALTER TABLE public.demandas_log
  ALTER COLUMN user_id SET DEFAULT auth.uid();
  -- demandas_log pode ficar NULL se não houver usuário autenticado no contexto

-- ── ETAPA 4: Remover policies antigas (baseadas em e-mail) ────────

DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT policyname, tablename
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('demandas', 'demandas_log')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', r.policyname, r.tablename);
  END LOOP;
END $$;

-- ── ETAPA 5: Criar novas policies por auth.uid() ──────────────────
-- Cada usuário vê e manipula SOMENTE seus próprios dados.

-- demandas
CREATE POLICY "uid_select_demandas" ON public.demandas
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "uid_insert_demandas" ON public.demandas
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "uid_update_demandas" ON public.demandas
  FOR UPDATE TO authenticated
  USING      (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "uid_delete_demandas" ON public.demandas
  FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- demandas_log
CREATE POLICY "uid_select_log" ON public.demandas_log
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "uid_insert_log" ON public.demandas_log
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- ════════════════════════════════════════════════════════════════════
-- PASSOS COMPLEMENTARES NO PAINEL DO SUPABASE
--
-- 1. Authentication → Providers → Email
--    "Allow new users to sign up": LIGUE (para permitir novos cadastros)
--
-- 2. (Recomendado) Authentication → URL Configuration
--    Adicione o domínio GitHub Pages como "Redirect URL" para que os
--    links de confirmação de e-mail funcionem após o deploy.
--    Ex.: https://<usuario>.github.io/gestao-demandas/app.html
--
-- 3. (Opcional) Para exigir confirmação de e-mail antes do 1º acesso:
--    Authentication → Email → "Confirm email": LIGUE
--
-- 4. Restrição de domínio @ferreiracosta.com.br:
--    O app valida o domínio no lado cliente. Para uma restrição server-side
--    mais segura, utilize um Database Hook "before user creation" no Supabase
--    ou uma Edge Function que rejeite e-mails fora do domínio.
--
-- NOTA: A chave publishable do Supabase continua segura de ficar
-- exposta no HTML — a proteção real são as RLS policies acima.
-- ════════════════════════════════════════════════════════════════════
