-- ============================================================
-- ATUALIZAÇÃO v12 — Forma de pagamento e pagamentos parciais
-- Rode no Supabase → SQL Editor → Run (projeto pzodgfsekqpumvgigeii)
-- ============================================================

alter table public.cobrancas add column if not exists forma_pagamento text not null default '';
alter table public.cobrancas add column if not exists pagamentos jsonb not null default '[]';

-- Confirmação: deve mostrar 2 linhas
select column_name from information_schema.columns
where table_schema='public' and table_name='cobrancas'
  and column_name in ('forma_pagamento','pagamentos');
