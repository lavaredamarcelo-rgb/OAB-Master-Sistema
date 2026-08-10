-- ============================================================
-- ATUALIZAÇÃO v6 — Hora de fim nos compromissos da Agenda
-- Rode no Supabase → SQL Editor → Run (pode rodar mais de uma vez)
-- ============================================================

alter table public.eventos add column if not exists hora_fim text;
