-- ============================================================
-- ATUALIZAÇÃO v19 — Composição corporal na avaliação física
-- (peso de gordura, peso magro e % de massa muscular)
-- Rode no Supabase → SQL Editor → Run (projeto pzodgfsekqpumvgigeii)
-- ============================================================

alter table public.avaliacoes add column if not exists peso_gordura text not null default '';
alter table public.avaliacoes add column if not exists peso_magro text not null default '';
alter table public.avaliacoes add column if not exists massa_muscular text not null default '';

-- Confirmação: deve mostrar 3 linhas
select column_name from information_schema.columns
where table_schema='public' and table_name='avaliacoes'
  and column_name in ('peso_gordura','peso_magro','massa_muscular');
