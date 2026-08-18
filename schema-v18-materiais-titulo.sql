-- ============================================================
-- ATUALIZAÇÃO v18 — Título e descrição nos materiais táticos
-- Rode no Supabase → SQL Editor → Run (projeto pzodgfsekqpumvgigeii)
-- ============================================================

alter table public.documentos add column if not exists titulo text not null default '';
alter table public.documentos add column if not exists descricao text not null default '';

-- Confirmação: deve mostrar 2 linhas
select column_name from information_schema.columns
where table_schema='public' and table_name='documentos'
  and column_name in ('titulo','descricao');
