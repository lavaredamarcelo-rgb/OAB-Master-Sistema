-- ============================================================
-- ATUALIZAÇÃO v20 — Testes de impulsão (3 saltos), força e resistência
-- Rode no Supabase → SQL Editor → Run (projeto pzodgfsekqpumvgigeii)
-- ============================================================

alter table public.avaliacoes add column if not exists salto1 text not null default '';
alter table public.avaliacoes add column if not exists salto2 text not null default '';
alter table public.avaliacoes add column if not exists salto3 text not null default '';
alter table public.avaliacoes add column if not exists forca text not null default '';
alter table public.avaliacoes add column if not exists resistencia text not null default '';

-- Confirmação: deve mostrar 5 linhas
select column_name from information_schema.columns
where table_schema='public' and table_name='avaliacoes'
  and column_name in ('salto1','salto2','salto3','forca','resistencia');
