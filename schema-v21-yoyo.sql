-- ============================================================
-- ATUALIZAÇÃO v21 — Yo-yo test na avaliação física
-- (metas do preparador: % gordura 14%, Yo-yo, salto horizontal)
-- Rode no Supabase → SQL Editor → Run (projeto pzodgfsekqpumvgigeii)
-- ============================================================

alter table public.avaliacoes add column if not exists yoyo text not null default '';

-- Confirmação: deve mostrar 1 linha
select column_name from information_schema.columns
where table_schema='public' and table_name='avaliacoes' and column_name='yoyo';
