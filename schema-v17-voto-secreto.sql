-- ============================================================
-- ATUALIZAÇÃO v17 — Voto secreto no Craque do Jogo
-- Cada pessoa só enxerga o PRÓPRIO voto; a contagem sai
-- agregada por uma função do banco (ninguém vê voto alheio)
-- Rode no Supabase → SQL Editor → Run (projeto pzodgfsekqpumvgigeii)
-- ============================================================

-- 1) Leitura restrita: só o próprio voto
drop policy if exists craque_sel on public.craque_votos;
drop policy if exists craque_sel_proprio on public.craque_votos;
create policy craque_sel_proprio on public.craque_votos for select
  using (votante_id = auth.uid());

-- 2) Contagem agregada e sigilosa (para o placar de votos)
create or replace function public.contagem_craque_todos()
returns table(evento_id uuid, voto_id uuid, votos bigint)
language sql stable security definer set search_path=public as
$$
  select cv.evento_id, cv.voto_id, count(*)::bigint
  from craque_votos cv
  where public.sou_membro()
  group by cv.evento_id, cv.voto_id
$$;

-- Confirmação: deve mostrar 1 linha (a função criada)
select routine_name from information_schema.routines
where routine_schema='public' and routine_name='contagem_craque_todos';
