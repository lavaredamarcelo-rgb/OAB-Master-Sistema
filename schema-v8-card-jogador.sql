-- ============================================================
-- ATUALIZAÇÃO v8 — Card do jogador com foto
-- Rode no Supabase → SQL Editor → Run (pode rodar mais de uma vez)
-- ============================================================

-- 1) Coluna da foto no perfil
alter table public.perfis add column if not exists foto_url text;

-- 2) Permite que membros logados enviem fotos para a pasta atletas/
--    do bucket público (mesmo bucket das logos dos patrocinadores)
drop policy if exists fotos_atletas_upload on storage.objects;
create policy fotos_atletas_upload on storage.objects for insert to authenticated
  with check (bucket_id = 'publico' and name like 'atletas/%');
