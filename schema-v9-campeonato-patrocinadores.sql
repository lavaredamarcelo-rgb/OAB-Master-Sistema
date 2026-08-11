-- ============================================================
-- ATUALIZAÇÃO v9 — Agenda de campeonato (período) e melhorias
-- nos patrocinadores (local + novas categorias)
-- Rode no Supabase → SQL Editor → Run (pode rodar mais de uma vez)
-- ============================================================

-- 1) Campeonatos com período (data de início e término)
alter table public.eventos add column if not exists data_fim date;

-- 2) Local/endereço do patrocinador
alter table public.patrocinadores add column if not exists local text not null default '';

-- 3) Garante que as novas categorias (diamante, prata, bronze)
--    sejam aceitas, caso exista restrição antiga na coluna tier
alter table public.patrocinadores drop constraint if exists patrocinadores_tier_check;
