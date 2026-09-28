-- ============================================================
-- ATUALIZAÇÃO v28 — Aniversários 🎂
-- Data de nascimento no cadastro (atletas, diretoria e comissão)
-- Rode no Supabase → SQL Editor → Run (projeto pzodgfsekqpumvgigeii)
-- ============================================================

alter table public.perfis add column if not exists nascimento date;

-- Confirmação: deve mostrar 1 linha
select column_name from information_schema.columns
where table_schema='public' and table_name='perfis' and column_name='nascimento';
