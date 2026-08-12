-- ============================================================
-- ATUALIZAÇÃO v10 — Placar dos jogos e retrospecto por adversário
-- Rode no Supabase → SQL Editor → Run (pode rodar mais de uma vez)
-- ⚠️ Confira se está no projeto do TIME (pzodgfsekqpumvgigeii)
-- ============================================================

alter table public.eventos add column if not exists adversario text not null default '';
alter table public.eventos add column if not exists placar_nos int;
alter table public.eventos add column if not exists placar_deles int;

-- Confirmação: deve mostrar 3 linhas
select column_name from information_schema.columns
where table_schema='public' and table_name='eventos'
  and column_name in ('adversario','placar_nos','placar_deles');
