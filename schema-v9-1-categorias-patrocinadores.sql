-- ============================================================
-- ATUALIZAÇÃO v9.1 — Libera as novas categorias de patrocinador
-- (Diamante, Prata, Bronze)
-- Rode no Supabase → SQL Editor → Run (pode rodar mais de uma vez)
-- ============================================================

-- Remove QUALQUER regra de verificação antiga da tabela de
-- patrocinadores (a trava da coluna tier, independentemente do nome)
do $$
declare r record;
begin
  for r in
    select conname from pg_constraint
    where conrelid = 'public.patrocinadores'::regclass and contype = 'c'
  loop
    execute format('alter table public.patrocinadores drop constraint %I', r.conname);
  end loop;
end $$;

-- Garante também as colunas da v9, caso ainda não tenha rodado
alter table public.eventos add column if not exists data_fim date;
alter table public.patrocinadores add column if not exists local text not null default '';
