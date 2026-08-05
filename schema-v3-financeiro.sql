-- ============================================================
-- OAB/PA MASTER — Atualização v3 do Financeiro
-- (Sistema de Lotes de Importação, Lançador Rápido, Editor de Período)
-- Cole tudo no SQL Editor e clique RUN
-- ============================================================

-- 1) Tabela de Lotes de Importação
create table if not exists public.import_lotes (
  id uuid primary key default gen_random_uuid(),
  nome_arquivo text not null,
  versao int not null default 1,
  hash_arquivo text not null,
  data_import timestamptz not null default now(),
  data_atualizacao timestamptz,
  status text not null default 'ativo' check (status in ('ativo','substituido','erro')),
  total_cobracas int default 0,
  total_despesas int default 0,
  total_entrada numeric default 0,
  total_saida numeric default 0,
  notas text default '',
  autor text not null default '',
  lote_anterior_id uuid references public.import_lotes(id) on delete set null
);
alter table public.import_lotes enable row level security;
drop policy if exists lotes_all on public.import_lotes;
create policy lotes_all on public.import_lotes for all
  using (public.sou_gestor()) with check (public.sou_gestor());
drop policy if exists lotes_sel on public.import_lotes;
create policy lotes_sel on public.import_lotes for select using (true);

-- 2) Adicionar campos em cobrancas
alter table public.cobrancas add column if not exists import_lote_id uuid references public.import_lotes(id) on delete set null;
alter table public.cobrancas add column if not exists tipo_lancamento text not null default 'manual'
  check (tipo_lancamento in ('manual','automatica','avulso','importado','treino','historico'));

-- 3) Adicionar campos em despesas
alter table public.despesas add column if not exists import_lote_id uuid references public.import_lotes(id) on delete set null;
alter table public.despesas add column if not exists tipo_lancamento text not null default 'manual'
  check (tipo_lancamento in ('manual','automatica','importado','historico'));

-- 4) Indices para performance
create index if not exists idx_import_lotes_hash on public.import_lotes(hash_arquivo);
create index if not exists idx_import_lotes_status on public.import_lotes(status);
create index if not exists idx_cobrancas_lote on public.cobrancas(import_lote_id);
create index if not exists idx_despesas_lote on public.despesas(import_lote_id);

-- 5) Função para calcular hash da planilha (será chamada pelo JS)
create or replace function public.hash_planilha(arquivo_nome text, estrutura jsonb)
returns text language sql immutable as $$
  select encode(sha256(convert_to(arquivo_nome || jsonb_build_object('estrutura', estrutura)::text, 'utf8')), 'hex');
$$;

-- 6) Função para criar um lote de importação
create or replace function public.cria_lote_importacao(
  p_nome_arquivo text,
  p_hash_arquivo text,
  p_versao int default 1,
  p_notas text default ''
)
returns uuid language plpgsql security definer set search_path=public as $$
declare
  v_lote_id uuid;
  v_lote_anterior uuid;
begin
  -- Procura lote anterior com mesmo hash
  select id into v_lote_anterior from import_lotes
    where hash_arquivo = p_hash_arquivo and status = 'ativo'
    order by versao desc limit 1;

  -- Se existir anterior, marca como substituído
  if v_lote_anterior is not null then
    update import_lotes set status = 'substituido' where id = v_lote_anterior;
  end if;

  -- Cria novo lote
  insert into import_lotes (nome_arquivo, versao, hash_arquivo, notas, autor, lote_anterior_id)
  values (p_nome_arquivo, p_versao, p_hash_arquivo, p_notas, auth.jwt() ->> 'user_metadata'->>'name', v_lote_anterior)
  returning id into v_lote_id;

  return v_lote_id;
end $$;

-- 7) Função para atualizar totais do lote
create or replace function public.atualiza_totais_lote(p_lote_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare
  v_total_c int;
  v_total_d int;
  v_entrada numeric;
  v_saida numeric;
begin
  select count(*) into v_total_c from cobrancas where import_lote_id = p_lote_id;
  select count(*) into v_total_d from despesas where import_lote_id = p_lote_id;
  select coalesce(sum(valor), 0) into v_entrada from cobrancas where import_lote_id = p_lote_id and status = 'pago';
  select coalesce(sum(valor), 0) into v_saida from despesas where import_lote_id = p_lote_id;

  update import_lotes
  set total_cobracas = v_total_c,
      total_despesas = v_total_d,
      total_entrada = v_entrada,
      total_saida = v_saida,
      data_atualizacao = now()
  where id = p_lote_id;
end $$;

select 'Atualização v3 de Financeiro aplicada com sucesso! 💰' as resultado;
