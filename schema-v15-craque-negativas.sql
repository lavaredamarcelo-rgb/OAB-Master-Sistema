-- ============================================================
-- ATUALIZAÇÃO v15 — Estatísticas negativas + votação Craque do Jogo
-- Rode no Supabase → SQL Editor → Run (projeto pzodgfsekqpumvgigeii)
-- ============================================================

-- 1) Novas estatísticas negativas
alter table public.stats add column if not exists duelos_perdidos int not null default 0;
alter table public.stats add column if not exists bolas_perdidas int not null default 0;
alter table public.stats add column if not exists faltas_cometidas int not null default 0;

-- 2) Votação do Craque do Jogo (1 voto por pessoa por jogo, pode trocar)
create table if not exists public.craque_votos (
  id uuid primary key default gen_random_uuid(),
  evento_id uuid not null references public.eventos(id) on delete cascade,
  votante_id uuid not null references public.perfis(id) on delete cascade,
  voto_id uuid not null references public.perfis(id) on delete cascade,
  quando timestamptz not null default now(),
  unique (evento_id, votante_id)
);
alter table public.craque_votos enable row level security;

drop policy if exists craque_sel on public.craque_votos;
create policy craque_sel on public.craque_votos for select using (public.sou_membro());

drop policy if exists craque_ins on public.craque_votos;
create policy craque_ins on public.craque_votos for insert
  with check (votante_id = auth.uid() and public.sou_membro());

drop policy if exists craque_upd on public.craque_votos;
create policy craque_upd on public.craque_votos for update
  using (votante_id = auth.uid()) with check (votante_id = auth.uid());

drop policy if exists craque_del on public.craque_votos;
create policy craque_del on public.craque_votos for delete using (votante_id = auth.uid());

-- Confirmação: deve mostrar 3 colunas novas + a tabela
select 'stats.'||column_name as item from information_schema.columns
where table_schema='public' and table_name='stats'
  and column_name in ('duelos_perdidos','bolas_perdidas','faltas_cometidas')
union all
select 'tabela craque_votos' from information_schema.tables
where table_schema='public' and table_name='craque_votos';
