-- ============================================================
-- ATUALIZAÇÃO v23 — Convocações para campeonatos
-- Área de convocações: montador por posição, confirmação de
-- presença pelo atleta (via função segura) e histórico.
-- Rode no Supabase → SQL Editor → Run (projeto pzodgfsekqpumvgigeii)
-- ============================================================

create table if not exists public.convocacoes (
  id uuid primary key default gen_random_uuid(),
  titulo text not null,
  evento_id uuid references public.eventos(id) on delete set null,
  data date,
  hora text default '',
  local text default '',
  concentracao text default '',
  uniforme text default '',
  obs text default '',
  convocados jsonb not null default '[]',
  confirmacoes jsonb not null default '{}',
  status text not null default 'rascunho' check (status in ('rascunho','publicada','encerrada')),
  criado_por text default '',
  quando timestamptz default now()
);
alter table public.convocacoes enable row level security;

drop policy if exists conv_sel on public.convocacoes;
create policy conv_sel on public.convocacoes for select
  using (public.sou_gestor() or (public.sou_membro() and status <> 'rascunho'));

drop policy if exists conv_mod on public.convocacoes;
create policy conv_mod on public.convocacoes for all
  using (public.sou_gestor()) with check (public.sou_gestor());

-- Confirmação de presença pelo próprio convocado (função segura)
create or replace function public.confirmar_convocacao(conv uuid, ok boolean, motivo text default '')
returns void language sql security definer set search_path=public as
$$
  update convocacoes
  set confirmacoes = confirmacoes || jsonb_build_object(
    auth.uid()::text,
    jsonb_build_object('ok', ok, 'motivo', coalesce(motivo,''), 'quando', now()))
  where id = conv
    and status = 'publicada'
    and public.sou_membro()
    and exists (select 1 from jsonb_array_elements(convocacoes.convocados) e
                where e->>'atletaId' = auth.uid()::text);
$$;

-- Confirmação: deve mostrar 2 linhas (tabela + função)
select 'tabela convocacoes' as item from information_schema.tables
where table_schema='public' and table_name='convocacoes'
union all
select 'função confirmar_convocacao' from information_schema.routines
where routine_schema='public' and routine_name='confirmar_convocacao';
