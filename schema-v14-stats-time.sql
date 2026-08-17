-- ============================================================
-- ATUALIZAÇÃO v14 — Estatísticas do jogo (time todo)
-- Rode no Supabase → SQL Editor → Run (projeto pzodgfsekqpumvgigeii)
-- ============================================================

alter table public.eventos add column if not exists stats_time jsonb not null default '{}';

-- Confirmação: deve mostrar 1 linha
select column_name from information_schema.columns
where table_schema='public' and table_name='eventos' and column_name='stats_time';
