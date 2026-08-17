-- ============================================================
-- ATUALIZAÇÃO v16 — Mais estatísticas negativas
-- (chutes errados, gols sofridos, pênaltis, gol contra)
-- Rode no Supabase → SQL Editor → Run (projeto pzodgfsekqpumvgigeii)
-- ============================================================

alter table public.stats add column if not exists chutes_errados int not null default 0;
alter table public.stats add column if not exists gols_sofridos int not null default 0;
alter table public.stats add column if not exists penaltis_perdidos int not null default 0;
alter table public.stats add column if not exists penaltis_cometidos int not null default 0;
alter table public.stats add column if not exists gols_contra int not null default 0;

-- Confirmação: deve mostrar 5 linhas
select column_name from information_schema.columns
where table_schema='public' and table_name='stats'
  and column_name in ('chutes_errados','gols_sofridos','penaltis_perdidos','penaltis_cometidos','gols_contra');
