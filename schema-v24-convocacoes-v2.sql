-- ============================================================
-- ATUALIZAÇÃO v24 — Convocações v2
-- Período do campeonato, nº máximo de convocados (compromisso
-- criado pela diretoria) e substituições registradas
-- Rode no Supabase → SQL Editor → Run (projeto pzodgfsekqpumvgigeii)
-- ============================================================

alter table public.convocacoes add column if not exists data_fim date;
alter table public.convocacoes add column if not exists max_atletas int;
alter table public.convocacoes add column if not exists substituicoes jsonb not null default '[]';

-- Confirmação: deve mostrar 3 linhas
select column_name from information_schema.columns
where table_schema='public' and table_name='convocacoes'
  and column_name in ('data_fim','max_atletas','substituicoes');
