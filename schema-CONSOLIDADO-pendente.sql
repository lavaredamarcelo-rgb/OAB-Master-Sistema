-- ================================================================
-- SQL CONSOLIDADO — tudo que ainda falta no banco do OAB/PA Master
-- (v7 + v8 + v9 + correção do Diamante, em um arquivo só)
--
-- ⚠️ IMPORTANTE: confira no topo do painel do Supabase se o projeto
-- aberto é o do TIME (ref: pzodgfsekqpumvgigeii) — não o da gráfica!
--
-- Rode TUDO de uma vez: SQL Editor → colar → Run
-- Pode rodar mais de uma vez sem problema.
-- ================================================================

-- ---------- v7: atletas podem VER a relação de materiais ----------
drop policy if exists inv_sel_membros on public.inventario;
create policy inv_sel_membros on public.inventario for select
  using (public.sou_membro());

-- ---------- v8: foto do card do jogador ----------
alter table public.perfis add column if not exists foto_url text;
drop policy if exists fotos_atletas_upload on storage.objects;
create policy fotos_atletas_upload on storage.objects for insert to authenticated
  with check (bucket_id = 'publico' and name like 'atletas/%');

-- ---------- v9: campeonato com período + local do patrocinador ----------
alter table public.eventos add column if not exists data_fim date;
alter table public.patrocinadores add column if not exists local text not null default '';

-- ---------- Correção do Diamante: coluna tier vira texto livre ----------
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

-- ---------- Confirmação final ----------
-- Deve mostrar 3 linhas: foto_url, data_fim e local
select table_name, column_name
from information_schema.columns
where table_schema='public'
  and ((table_name='perfis' and column_name='foto_url')
    or (table_name='eventos' and column_name='data_fim')
    or (table_name='patrocinadores' and column_name='local'));
