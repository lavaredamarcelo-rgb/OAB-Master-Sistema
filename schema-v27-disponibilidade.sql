-- ============================================================
-- ATUALIZAÇÃO v27 — Disponibilidade para jogos ("🙋 Quem vai?")
-- Atletas se colocam disponíveis para os próximos jogos;
-- o treinador convoca em cima de quem respondeu.
-- Rode no Supabase → SQL Editor → Run (projeto pzodgfsekqpumvgigeii)
-- ============================================================

create table if not exists public.disponibilidades (
  id uuid primary key default gen_random_uuid(),
  evento_id uuid not null references public.eventos(id) on delete cascade,
  atleta_id uuid not null references public.perfis(id) on delete cascade,
  ok boolean not null,
  motivo text default '',
  quando timestamptz default now(),
  unique(evento_id, atleta_id)
);
alter table public.disponibilidades enable row level security;

drop policy if exists disp_sel on public.disponibilidades;
create policy disp_sel on public.disponibilidades for select using (public.sou_membro());
drop policy if exists disp_ins on public.disponibilidades;
create policy disp_ins on public.disponibilidades for insert with check (public.sou_membro() and (atleta_id = auth.uid() or public.sou_diretoria()));
drop policy if exists disp_upd on public.disponibilidades;
create policy disp_upd on public.disponibilidades for update using (atleta_id = auth.uid() or public.sou_diretoria()) with check (atleta_id = auth.uid() or public.sou_diretoria());
drop policy if exists disp_del on public.disponibilidades;
create policy disp_del on public.disponibilidades for delete using (atleta_id = auth.uid() or public.sou_diretoria());

-- Confirmação: deve mostrar 1 linha
select table_name from information_schema.tables
where table_schema='public' and table_name='disponibilidades';
