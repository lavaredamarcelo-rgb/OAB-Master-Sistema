-- ============================================================
-- ATUALIZAÇÃO v18.1 — Permissão de EDIÇÃO nos documentos
-- (faltava a regra de update: título/descrição não gravavam)
-- Rode no Supabase → SQL Editor → Run (projeto pzodgfsekqpumvgigeii)
-- ============================================================

drop policy if exists doc_upd on public.documentos;
create policy doc_upd on public.documentos for update
  using (
    public.sou_diretoria()
    or atleta_id = auth.uid()
    or (escopo = 'tatica' and public.sou_gestor())
  )
  with check (
    public.sou_diretoria()
    or atleta_id = auth.uid()
    or (escopo = 'tatica' and public.sou_gestor())
  );

-- Confirmação: deve mostrar 1 linha (doc_upd)
select policyname from pg_policies
where schemaname='public' and tablename='documentos' and policyname='doc_upd';
