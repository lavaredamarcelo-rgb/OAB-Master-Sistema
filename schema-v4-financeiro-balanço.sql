-- ============================================================
-- OAB/PA MASTER — Atualização v4 do Financeiro
-- (Balanço com Consolidação de Cobranças + Receitas Gerais)
-- Cole tudo no SQL Editor e clique RUN
-- ============================================================

-- 1) Tabela de Receitas Gerais (Balanço)
create table if not exists public.balanco_receitas (
  id uuid primary key default gen_random_uuid(),
  data date not null default now()::date,
  tipo text not null check (tipo in ('mensalidade_atleta','atleta_avulso','patrocinio','auxilio','venda','doacao','outro')),
  descricao text not null,
  valor numeric not null,
  origem text default '', -- ex: "Consolidado de cobrança #xyz" ou "Lançamento manual"
  cobranca_id uuid references public.cobrancas(id) on delete set null, -- vincula se for consolidação
  autor text not null default '',
  quando timestamptz not null default now()
);
alter table public.balanco_receitas enable row level security;
drop policy if exists br_all on public.balanco_receitas;
create policy br_all on public.balanco_receitas for all
  using (public.sou_gestor()) with check (public.sou_gestor());
drop policy if exists br_sel on public.balanco_receitas;
create policy br_sel on public.balanco_receitas for select using (true);

-- 2) Adicionar coluna de consolidação em cobrancas
alter table public.cobrancas add column if not exists consolidado boolean not null default false;
alter table public.cobrancas add column if not exists consolidado_em date;
alter table public.cobrancas add column if not exists receita_id uuid references public.balanco_receitas(id) on delete set null;

-- 3) Índices
create index if not exists idx_br_tipo on public.balanco_receitas(tipo);
create index if not exists idx_br_data on public.balanco_receitas(data);
create index if not exists idx_cob_consolidado on public.cobrancas(consolidado);

-- 4) Função para consolidar uma cobrança paga no balanço
create or replace function public.consolida_cobranca(p_cobranca_id uuid)
returns uuid language plpgsql security definer set search_path=public as $$
declare
  v_cob record;
  v_receita_id uuid;
  v_tipo text;
  v_descricao text;
begin
  -- Busca cobrança
  select * into v_cob from cobrancas where id = p_cobranca_id;
  if v_cob is null then raise exception 'Cobrança não encontrada'; end if;
  if v_cob.status <> 'pago' then raise exception 'Cobrança não está paga'; end if;
  if v_cob.consolidado then raise exception 'Cobrança já foi consolidada'; end if;

  -- Determina tipo e descrição
  if v_cob.atletaId is not null then
    v_tipo := 'mensalidade_atleta';
    v_descricao := 'Mensalidade: ' || (select nome from perfis where id = v_cob.atletaId limit 1) || ' — ' || v_cob.descricao;
  else
    v_tipo := 'atleta_avulso';
    v_descricao := 'Avulso: ' || (v_cob.convidado || 'Convidado') || ' — ' || v_cob.descricao;
  end if;

  -- Cria receita
  insert into balanco_receitas (tipo, descricao, valor, origem, cobranca_id, autor)
  values (v_tipo, v_descricao, v_cob.valor, 'Consolidado de cobrança', p_cobranca_id, auth.jwt() ->> 'user_metadata'->>'name')
  returning id into v_receita_id;

  -- Marca cobrança como consolidada
  update cobrancas set consolidado = true, consolidado_em = now()::date, receita_id = v_receita_id
  where id = p_cobranca_id;

  return v_receita_id;
end $$;

-- 5) Função para desconsolidar (desfazer)
create or replace function public.desconsolida_cobranca(p_cobranca_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare
  v_receita_id uuid;
begin
  select receita_id into v_receita_id from cobrancas where id = p_cobranca_id;
  if v_receita_id is null then raise exception 'Cobrança não foi consolidada'; end if;

  delete from balanco_receitas where id = v_receita_id;
  update cobrancas set consolidado = false, consolidado_em = null, receita_id = null where id = p_cobranca_id;
end $$;

-- 6) Função para consolidar TODAS as cobranças pagas de uma vez
create or replace function public.consolida_todas_cobracas()
returns table(consolidadas int, puladas int) language plpgsql security definer set search_path=public as $$
declare
  v_consolidadas int := 0;
  v_puladas int := 0;
  v_cob record;
begin
  for v_cob in select id from cobrancas where status = 'pago' and not consolidado
  loop
    begin
      perform consolida_cobranca(v_cob.id);
      v_consolidadas := v_consolidadas + 1;
    exception when others then
      v_puladas := v_puladas + 1;
    end;
  end loop;
  return query select v_consolidadas, v_puladas;
end $$;

select 'Atualização v4 de Financeiro (Balanço) aplicada com sucesso! 💰' as resultado;
