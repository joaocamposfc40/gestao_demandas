-- ════════════════════════════════════════════════════════════════════
-- GESTÃO DE DEMANDAS — Blindagem de RLS (acesso de UM único usuário)
-- Projeto: xtpirxyjmqwcvjlcajsz
-- Executar no SQL Editor do Supabase DEPOIS do setup_demandas_supabase.sql
--
-- Resultado: somente o usuário autenticado cujo e-mail for o definido
-- abaixo consegue ler/criar/editar/excluir. A chave publishable exposta
-- no HTML público deixa de dar qualquer acesso aos dados.
-- ════════════════════════════════════════════════════════════════════

-- >>> Defina aqui o e-mail da SUA conta (a mesma que você criará no Auth) <<<
--     Se mudar o e-mail, troque nas 6 policies abaixo.
--     E-mail atual: joao.campos@ferreiracosta.com.br

-- ── 1) Garante RLS ligado nas duas tabelas ──────────────────────────
alter table public.demandas     enable row level security;
alter table public.demandas_log enable row level security;

-- ── 2) Remove TODAS as policies antigas (inclusive as permissivas) ──
do $$
declare r record;
begin
  for r in
    select policyname, tablename
    from pg_policies
    where schemaname = 'public'
      and tablename in ('demandas', 'demandas_log')
  loop
    execute format('drop policy if exists %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;

-- ── 3) Policies restritas ao SEU e-mail — tabela demandas ───────────
create policy "owner_select_demandas" on public.demandas
  for select to authenticated
  using (auth.jwt() ->> 'email' = 'joao.campos@ferreiracosta.com.br');

create policy "owner_insert_demandas" on public.demandas
  for insert to authenticated
  with check (auth.jwt() ->> 'email' = 'joao.campos@ferreiracosta.com.br');

create policy "owner_update_demandas" on public.demandas
  for update to authenticated
  using      (auth.jwt() ->> 'email' = 'joao.campos@ferreiracosta.com.br')
  with check (auth.jwt() ->> 'email' = 'joao.campos@ferreiracosta.com.br');

create policy "owner_delete_demandas" on public.demandas
  for delete to authenticated
  using (auth.jwt() ->> 'email' = 'joao.campos@ferreiracosta.com.br');

-- ── 4) Policies restritas ao SEU e-mail — tabela demandas_log ───────
create policy "owner_select_log" on public.demandas_log
  for select to authenticated
  using (auth.jwt() ->> 'email' = 'joao.campos@ferreiracosta.com.br');

create policy "owner_insert_log" on public.demandas_log
  for insert to authenticated
  with check (auth.jwt() ->> 'email' = 'joao.campos@ferreiracosta.com.br');

-- ════════════════════════════════════════════════════════════════════
-- PASSOS COMPLEMENTARES NO PAINEL DO SUPABASE (importantes!)
--
-- 1. Authentication → Providers → Email: deixe HABILITADO.
-- 2. Authentication → Providers → Email → "Allow new users to sign up":
--    DESLIGUE. Assim ninguém cria conta pela tela de login.
-- 3. Authentication → Users → "Add user" → crie a SUA conta:
--       e-mail: joao.campos@ferreiracosta.com.br
--       senha:  (defina uma senha forte)
--    Marque "Auto Confirm User" para não precisar confirmar por e-mail.
-- 4. (Opcional) Authentication → Providers → Email: desligue
--    "Confirm email" se quiser entrar direto sem etapa de confirmação.
-- ════════════════════════════════════════════════════════════════════
