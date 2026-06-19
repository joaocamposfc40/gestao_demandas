-- ════════════════════════════════════════════════════════════════════
-- GESTÃO DE DEMANDAS — Migration: adicionar coluna relevancia
-- Projeto: xtpirxyjmqwcvjlcajsz
-- Executar no SQL Editor do Supabase
-- ════════════════════════════════════════════════════════════════════

-- Adiciona a coluna relevancia à tabela demandas
-- IF NOT EXISTS garante que não falha se já existir
ALTER TABLE public.demandas
  ADD COLUMN IF NOT EXISTS relevancia text NOT NULL DEFAULT 'normal'
  CHECK (relevancia IN ('normal', 'alta', 'critica'));

-- Normaliza registros existentes que possam ter valor nulo (por segurança)
UPDATE public.demandas SET relevancia = 'normal' WHERE relevancia IS NULL;
