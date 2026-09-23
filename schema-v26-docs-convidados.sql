-- ============================================================
-- ATUALIZAÇÃO v26 — Documentos de atletas convidados
-- (de fora do grupo, convocados para compor elenco)
-- Rode no Supabase → SQL Editor → Run (projeto pzodgfsekqpumvgigeii)
-- ============================================================

alter table public.documentos add column if not exists convidado text not null default '';

-- Confirmação: deve mostrar 1 linha
select column_name from information_schema.columns
where table_schema='public' and table_name='documentos' and column_name='convidado';
