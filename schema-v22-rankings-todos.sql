-- ============================================================
-- ATUALIZAÇÃO v22 — Rankings visíveis para todos os membros
-- Libera a LEITURA das avaliações físicas para todo o elenco
-- (ranking das metas do preparador e overall do card para todos).
-- Escrita continua só com a comissão técnica.
-- Rode no Supabase → SQL Editor → Run (projeto pzodgfsekqpumvgigeii)
-- ============================================================

drop policy if exists aval_sel on public.avaliacoes;
create policy aval_sel on public.avaliacoes for select
  using (public.sou_membro());

-- Confirmação: deve mostrar 1 linha com "sou_membro"
select policyname, qual from pg_policies
where schemaname='public' and tablename='avaliacoes' and policyname='aval_sel';
