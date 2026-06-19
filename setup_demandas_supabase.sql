-- ════════════════════════════════════════════════════════════════════
-- GESTÃO DE DEMANDAS — Auditoria de Dados
-- Tabelas: demandas + demandas_log
-- Executar no SQL Editor do Supabase (projeto nkijyuartfyxrawkivmm)
-- ════════════════════════════════════════════════════════════════════

-- 1) Tabela principal de demandas
create table if not exists public.demandas (
  id          uuid primary key default gen_random_uuid(),
  code        text unique,                          -- DEM-001, DEM-002...
  titulo      text not null,
  descricao   text,
  setor       text not null,
  solicitante text not null,
  tipo        text not null default 'principal'
              check (tipo in ('principal','paralela','oportunidade')),
  prioridade  text not null default 'media'
              check (prioridade in ('alta','media','baixa')),
  prazo       date,
  status      text not null default 'backlog'
              check (status in ('backlog','andamento','aguardando','concluido')),
  progresso   int not null default 0 check (progresso between 0 and 100),
  criada_em   date default current_date,
  concluida_em date,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- updated_at automático
create or replace function public.tg_demandas_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists demandas_updated_at on public.demandas;
create trigger demandas_updated_at
  before update on public.demandas
  for each row execute function public.tg_demandas_updated_at();

-- 2) Histórico de movimentações
create table if not exists public.demandas_log (
  id           bigint generated always as identity primary key,
  demanda_code text,
  titulo       text not null,
  acao         text not null,                       -- criada / status / progresso / editada / excluída
  de           text,
  para         text,
  created_at   timestamptz not null default now()
);

-- Índices
create index if not exists idx_demandas_status on public.demandas (status);
create index if not exists idx_demandas_prazo  on public.demandas (prazo);
create index if not exists idx_log_created     on public.demandas_log (created_at desc);

-- 3) RLS — acesso via chave publishable (anon)
alter table public.demandas     enable row level security;
alter table public.demandas_log enable row level security;

drop policy if exists "demandas_select" on public.demandas;
drop policy if exists "demandas_insert" on public.demandas;
drop policy if exists "demandas_update" on public.demandas;
drop policy if exists "demandas_delete" on public.demandas;
create policy "demandas_select" on public.demandas for select using (true);
create policy "demandas_insert" on public.demandas for insert with check (true);
create policy "demandas_update" on public.demandas for update using (true);
create policy "demandas_delete" on public.demandas for delete using (true);

drop policy if exists "log_select" on public.demandas_log;
drop policy if exists "log_insert" on public.demandas_log;
create policy "log_select" on public.demandas_log for select using (true);
create policy "log_insert" on public.demandas_log for insert with check (true);
