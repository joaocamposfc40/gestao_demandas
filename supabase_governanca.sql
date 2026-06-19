-- ════════════════════════════════════════════════════════════════════
-- GESTÃO DE DEMANDAS — Governança: perfis, hierarquia, aprovações,
-- notificações e RLS por hierarquia.
-- Projeto: xtpirxyjmqwcvjlcajsz
--
-- PRÉ-REQUISITO: as 15 contas de usuário já devem existir em Auth → Users
--   (mesmos e-mails da tabela abaixo, com "Auto Confirm User" marcado).
--   Admin (mat. 0) usa e-mail sintético: admin@demandas.ferreiracosta.com.br
--
-- Execute este arquivo INTEIRO no SQL Editor do Supabase.
-- É idempotente: pode rodar de novo sem quebrar.
-- ════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════
-- 1) TABELA profiles (quadro de usuários + hierarquia)
-- ════════════════════════════════════════════════════════════════════
create table if not exists public.profiles (
  id               uuid primary key references auth.users(id) on delete cascade,
  matricula        text unique not null,
  nome             text not null,
  cargo            text,
  email            text,
  perfil           text not null default 'usuario'
                     check (perfil in ('desenvolvedor','gestor_master','gestor','usuario')),
  gestor_matricula text,           -- matrícula do gestor imediato (null = topo)
  created_at       timestamptz default now()
);

-- ════════════════════════════════════════════════════════════════════
-- 2) SEED do profiles — casa o quadro com as contas já criadas em auth.users
--    (faz join por e-mail; quem ainda não tiver conta não recebe profile)
-- ════════════════════════════════════════════════════════════════════
insert into public.profiles (id, matricula, nome, cargo, email, perfil, gestor_matricula)
select u.id, v.matricula, v.nome, v.cargo, v.email, v.perfil, v.gestor_matricula
from (values
  ('0',     'Admin',             'Desenvolvedor do Sistema',              'admin@demandas.ferreiracosta.com.br', 'desenvolvedor', null),
  ('15712', 'Jurandir Pereira',  'Diretor de Auditoria Corporativa',      'jurandir.pereira@ferreiracosta.com.br', 'gestor_master', null),
  ('18242', 'Emerson Cardoso',   'Gerente de Auditoria Interna',          'emerson.cardoso@ferreiracosta.com.br',  'gestor',        '15712'),
  ('15406', 'Isabela de Freitas','Gerente de CI, Riscos & Compliance',    'isabela.freitas@ferreiracosta.com.br',  'gestor',        '15712'),
  ('30785', 'Rilma Saraiva',     'Coordenadora de ESG',                   'rilma.saraiva@ferreiracosta.com.br',    'gestor',        '15712'),
  ('25963', 'João Campos',       'Auditor de Dados',                      'joao.campos@ferreiracosta.com.br',      'usuario',       '15712'),
  ('11692', 'Marcelo Castim',    'DPO',                                   'marcelo.castim@ferreiracosta.com.br',   'usuario',       '15712'),
  ('30855', 'Ângelo Constâncio', 'Analista de CI',                        'angelo.constancio@ferreiracosta.com.br','usuario',       '15406'),
  ('27884', 'Layanne Santos',    'Analista de CI',                        'layanne.santos@ferreiracosta.com.br',   'usuario',       '15406'),
  ('29446', 'Bianca Bione',      'Analista de Compliance',                'bianca.bione@ferreiracosta.com.br',     'usuario',       '15406'),
  ('30188', 'Rayssa Santos',     'Aprendiz',                              'rayssa.santos@ferreiracosta.com.br',    'usuario',       '15406'),
  ('30805', 'Alexia Botelho',    'Auxiliar Administrativo',               'alexia.botelho@ferreiracosta.com.br',   'usuario',       '15406'),
  ('12549', 'Tatiane Bandeira',  'Analista ESG',                          'tatiane.carvalho@ferreiracosta.com.br', 'usuario',       '30785'),
  ('23741', 'Suzane Sena',       'Analista ESG',                          'suzane.sena@ferreiracosta.com.br',      'usuario',       '30785'),
  ('25884', 'Pedro Eugenio',     'Auxiliar Administrativo',               'pedro.eugenio@ferreiracosta.com.br',    'usuario',       '30785')
) as v(matricula, nome, cargo, email, perfil, gestor_matricula)
join auth.users u on lower(u.email) = lower(v.email)
on conflict (matricula) do update set
  id               = excluded.id,
  nome             = excluded.nome,
  cargo            = excluded.cargo,
  email            = excluded.email,
  perfil           = excluded.perfil,
  gestor_matricula = excluded.gestor_matricula;

-- ════════════════════════════════════════════════════════════════════
-- 3) Campos de APROVAÇÃO na tabela demandas
-- ════════════════════════════════════════════════════════════════════
alter table public.demandas
  add column if not exists aprovacao     text not null default 'none'
                            check (aprovacao in ('none','pendente','aprovada','reprovada')),
  add column if not exists aprovador_id  uuid references auth.users(id),
  add column if not exists aprovado_por  uuid references auth.users(id),
  add column if not exists aprovado_em   timestamptz,
  add column if not exists aprovacao_obs text;

-- garante user_id (caso ainda não exista — vem da migration_multi_user.sql)
alter table public.demandas
  add column if not exists user_id uuid default auth.uid();
alter table public.demandas_log
  add column if not exists user_id uuid default auth.uid();

-- ════════════════════════════════════════════════════════════════════
-- 4) TABELA notificacoes (log que alimenta o sino)
-- ════════════════════════════════════════════════════════════════════
create table if not exists public.notificacoes (
  id           bigint generated always as identity primary key,
  user_id      uuid not null references auth.users(id) on delete cascade,
  tipo         text not null,   -- enviada | aprovacao_solicitada | aprovada | reprovada | info
  mensagem     text not null,
  demanda_code text,
  lida         boolean not null default false,
  created_at   timestamptz default now()
);
create index if not exists idx_notif_user on public.notificacoes (user_id, created_at desc);

-- ════════════════════════════════════════════════════════════════════
-- 5) FUNÇÕES auxiliares (SECURITY DEFINER → evitam recursão de RLS)
-- ════════════════════════════════════════════════════════════════════
create or replace function public.current_perfil()
returns text language sql stable security definer set search_path = public as $$
  select perfil from public.profiles where id = auth.uid();
$$;

create or replace function public.current_matricula()
returns text language sql stable security definer set search_path = public as $$
  select matricula from public.profiles where id = auth.uid();
$$;

-- pode o usuário logado ver/gerir a demanda de 'target'?
create or replace function public.can_view_user(target uuid)
returns boolean language plpgsql stable security definer set search_path = public as $$
declare v_perfil text; v_mat text; v_target_gestor text;
begin
  select perfil, matricula into v_perfil, v_mat from public.profiles where id = auth.uid();
  if v_perfil in ('desenvolvedor','gestor_master') then return true; end if;  -- veem tudo
  if target = auth.uid() then return true; end if;                            -- o próprio
  select gestor_matricula into v_target_gestor from public.profiles where id = target;
  if v_target_gestor is not null and v_target_gestor = v_mat then             -- gestor direto
    return true;
  end if;
  return false;
end; $$;

-- ════════════════════════════════════════════════════════════════════
-- 6) RPC: solicitar aprovação (dono → gestor imediato)
-- ════════════════════════════════════════════════════════════════════
create or replace function public.solicitar_aprovacao(p_demanda uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_owner uuid; v_owner_nome text; v_gestor_mat text; v_gestor_id uuid;
  v_titulo text; v_code text;
begin
  select user_id, titulo, code into v_owner, v_titulo, v_code
  from public.demandas where id = p_demanda;
  if v_owner is null then raise exception 'Demanda não encontrada'; end if;
  if v_owner <> auth.uid() then raise exception 'Apenas o dono da demanda pode solicitar aprovação'; end if;

  select nome, gestor_matricula into v_owner_nome, v_gestor_mat
  from public.profiles where id = v_owner;
  if v_gestor_mat is null then raise exception 'Você não possui gestor imediato para aprovar esta demanda'; end if;

  select id into v_gestor_id from public.profiles where matricula = v_gestor_mat;
  if v_gestor_id is null then raise exception 'Gestor imediato sem conta cadastrada'; end if;

  update public.demandas
    set aprovacao = 'pendente', aprovador_id = v_gestor_id,
        aprovado_por = null, aprovado_em = null, aprovacao_obs = null
    where id = p_demanda;

  -- notifica o gestor (aprovador)
  insert into public.notificacoes (user_id, tipo, mensagem, demanda_code)
  values (v_gestor_id, 'aprovacao_solicitada',
          format('%s solicitou sua aprovação — %s', v_owner_nome,
                 coalesce(v_code || ' · ', '') || v_titulo),
          v_code);

  -- notifica o próprio solicitante
  insert into public.notificacoes (user_id, tipo, mensagem, demanda_code)
  values (v_owner, 'enviada',
          format('Sua solicitação de aprovação (%s) foi enviada e está pendente.',
                 coalesce(v_code, v_titulo)),
          v_code);
end; $$;

-- ════════════════════════════════════════════════════════════════════
-- 7) RPC: decidir aprovação (gestor aprova/reprova)
-- ════════════════════════════════════════════════════════════════════
create or replace function public.decidir_aprovacao(p_demanda uuid, p_aprovar boolean, p_obs text default null)
returns void language plpgsql security definer set search_path = public as $$
declare v_owner uuid; v_aprovador uuid; v_code text; v_titulo text;
begin
  select user_id, aprovador_id, code, titulo
  into v_owner, v_aprovador, v_code, v_titulo
  from public.demandas where id = p_demanda;
  if v_aprovador is null then raise exception 'Demanda sem aprovador definido'; end if;
  if v_aprovador <> auth.uid() then raise exception 'Apenas o aprovador designado pode decidir'; end if;

  if p_aprovar then
    update public.demandas
      set aprovacao = 'aprovada', aprovado_por = auth.uid(), aprovado_em = now(), aprovacao_obs = p_obs
      where id = p_demanda;
    insert into public.notificacoes (user_id, tipo, mensagem, demanda_code)
    values (v_owner, 'aprovada',
            format('✓ Sua solicitação (%s) foi APROVADA.', coalesce(v_code, v_titulo)), v_code);
  else
    update public.demandas
      set aprovacao = 'reprovada', aprovado_por = auth.uid(), aprovado_em = now(), aprovacao_obs = p_obs
      where id = p_demanda;
    insert into public.notificacoes (user_id, tipo, mensagem, demanda_code)
    values (v_owner, 'reprovada',
            format('✗ Sua solicitação (%s) foi REPROVADA.%s', coalesce(v_code, v_titulo),
                   case when coalesce(p_obs,'') <> '' then ' Motivo: ' || p_obs else '' end), v_code);
  end if;
end; $$;

grant execute on function public.solicitar_aprovacao(uuid) to authenticated;
grant execute on function public.decidir_aprovacao(uuid, boolean, text) to authenticated;
grant execute on function public.can_view_user(uuid) to authenticated;
grant execute on function public.current_perfil() to authenticated;
grant execute on function public.current_matricula() to authenticated;

-- ════════════════════════════════════════════════════════════════════
-- 8) RLS
-- ════════════════════════════════════════════════════════════════════
alter table public.profiles      enable row level security;
alter table public.demandas      enable row level security;
alter table public.demandas_log  enable row level security;
alter table public.notificacoes  enable row level security;

-- remove policies antigas de demandas/demandas_log (e-mail fixo / auth.uid simples)
do $$
declare r record;
begin
  for r in
    select policyname, tablename from pg_policies
    where schemaname = 'public'
      and tablename in ('demandas','demandas_log','profiles','notificacoes')
  loop
    execute format('drop policy if exists %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;

-- profiles: diretório visível a todos os autenticados; escrita só via seed (owner do SQL)
create policy "profiles_select_all" on public.profiles
  for select to authenticated using (true);

-- demandas: visão/gestão por hierarquia
create policy "dem_select" on public.demandas
  for select to authenticated using (can_view_user(user_id));
create policy "dem_insert" on public.demandas
  for insert to authenticated with check (user_id = auth.uid());
create policy "dem_update" on public.demandas
  for update to authenticated using (can_view_user(user_id)) with check (can_view_user(user_id));
create policy "dem_delete" on public.demandas
  for delete to authenticated using (can_view_user(user_id));

-- demandas_log: leitura por hierarquia; inserção do próprio ator
create policy "log_select" on public.demandas_log
  for select to authenticated using (user_id is null or can_view_user(user_id));
create policy "log_insert" on public.demandas_log
  for insert to authenticated with check (user_id = auth.uid() or user_id is null);

-- notificacoes: cada um vê e marca como lida apenas as suas (inserção é via RPC definer)
create policy "notif_select" on public.notificacoes
  for select to authenticated using (user_id = auth.uid());
create policy "notif_update" on public.notificacoes
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ════════════════════════════════════════════════════════════════════
-- PASSOS NO PAINEL DO SUPABASE
--  1. Authentication → Users → criar as 15 contas (e-mails da tabela +
--     admin@demandas.ferreiracosta.com.br), marcando "Auto Confirm User".
--  2. Authentication → Providers → Email → "Allow new users to sign up": DESLIGAR
--     (quadro é fixo; cadastro é manual).
--  3. Rodar este arquivo. Conferir: select matricula, nome, perfil from profiles order by matricula;
-- ════════════════════════════════════════════════════════════════════
