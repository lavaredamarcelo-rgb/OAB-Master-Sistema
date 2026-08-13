-- ============================================================
-- ATUALIZAÇÃO v11 — Novos itens de avaliação no Desempenho
-- (antecipação, duelos aéreos, chutes no gol, defesas,
--  passes errados no lugar de passes certos)
-- Rode no Supabase → SQL Editor → Run (projeto pzodgfsekqpumvgigeii)
-- ============================================================

alter table public.stats add column if not exists antecipacao int not null default 0;
alter table public.stats add column if not exists duelos_aereos int not null default 0;
alter table public.stats add column if not exists chutes_gol int not null default 0;
alter table public.stats add column if not exists defesas int not null default 0;
alter table public.stats add column if not exists passes_errados int not null default 0;

-- Confirmação: deve mostrar 5 linhas
select column_name from information_schema.columns
where table_schema='public' and table_name='stats'
  and column_name in ('antecipacao','duelos_aereos','chutes_gol','defesas','passes_errados');
