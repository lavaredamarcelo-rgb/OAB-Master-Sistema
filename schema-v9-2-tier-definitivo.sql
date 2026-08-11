-- ============================================================
-- ATUALIZAÇÃO v9.2 — Correção DEFINITIVA da categoria Diamante
-- Rode no Supabase → SQL Editor → Run (pode rodar mais de uma vez)
-- ============================================================

-- 1) Se a coluna tier for de tipo fechado (enum/domínio), converte
--    para texto livre — passa a aceitar qualquer categoria
do $$
declare tname text;
begin
  select udt_name into tname
  from information_schema.columns
  where table_schema='public' and table_name='patrocinadores' and column_name='tier';
  if tname is distinct from 'text' then
    execute 'alter table public.patrocinadores alter column tier drop default';
    execute 'alter table public.patrocinadores alter column tier type text using tier::text';
    execute $q$alter table public.patrocinadores alter column tier set default 'apoio'$q$;
  end if;
end $$;

-- 2) Remove qualquer regra de verificação da tabela (qualquer nome)
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

-- 3) Confirmação: mostra o tipo atual da coluna (deve aparecer "text")
select column_name, data_type, udt_name
from information_schema.columns
where table_schema='public' and table_name='patrocinadores' and column_name='tier';
