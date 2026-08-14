-- ============================================================
-- ATUALIZAÇÃO v13 — "Como quer ser chamado" (apelido de exibição)
-- Rode no Supabase → SQL Editor → Run (projeto pzodgfsekqpumvgigeii)
-- ============================================================

alter table public.perfis add column if not exists apelido text not null default '';

-- Confirmação: deve mostrar 1 linha
select column_name from information_schema.columns
where table_schema='public' and table_name='perfis' and column_name='apelido';
