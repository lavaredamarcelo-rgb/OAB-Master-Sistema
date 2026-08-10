-- ============================================================
-- ATUALIZAÇÃO v7 — Atletas podem VISUALIZAR a relação de materiais
-- Rode no Supabase → SQL Editor → Run (pode rodar mais de uma vez)
-- ============================================================

-- Hoje só a diretoria enxerga o inventário; esta política libera a
-- LEITURA para todos os membros aprovados (editar continua só diretoria)
drop policy if exists inv_sel_membros on public.inventario;
create policy inv_sel_membros on public.inventario for select
  using (public.sou_membro());
