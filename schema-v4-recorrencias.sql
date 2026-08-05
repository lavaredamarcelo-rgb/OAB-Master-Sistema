-- ============================================================
-- OAB/PA MASTER — Atualização v4 de Recorrências
-- (Despesas e Receitas Recorrentes com Status)
-- Cole tudo no SQL Editor e clique RUN
-- ============================================================

-- 1) Adicionar coluna de status em despesas
alter table public.despesas add column if not exists status text not null default 'pendente'
  check (status in ('pendente','pago','atrasado','cancelado'));
alter table public.despesas add column if not exists tipo_recorrencia text default null
  check (tipo_recorrencia is null or tipo_recorrencia in ('unica','mensal','anual'));
alter table public.despesas add column if not exists mes_referencia int;
alter table public.despesas add column if not exists ano_referencia int;
alter table public.despesas add column if not exists data_pagamento date;

-- 2) Adicionar coluna de status em balanco_receitas
alter table public.balanco_receitas add column if not exists status text not null default 'pendente'
  check (status in ('pendente','pago','cancelado'));
alter table public.balanco_receitas add column if not exists tipo_recorrencia text default null
  check (tipo_recorrencia is null or tipo_recorrencia in ('unica','mensal','anual'));
alter table public.balanco_receitas add column if not exists mes_referencia int;
alter table public.balanco_receitas add column if not exists ano_referencia int;
alter table public.balanco_receitas add column if not exists data_recebimento date;

-- 3) Índices para performance
create index if not exists idx_despesas_status on public.despesas(status);
create index if not exists idx_despesas_recorrencia on public.despesas(tipo_recorrencia);
create index if not exists idx_despesas_mes_ano on public.despesas(mes_referencia, ano_referencia);
create index if not exists idx_receitas_status on public.balanco_receitas(status);
create index if not exists idx_receitas_recorrencia on public.balanco_receitas(tipo_recorrencia);
create index if not exists idx_receitas_mes_ano on public.balanco_receitas(mes_referencia, ano_referencia);

-- 4) Função para marcar despesa como paga
create or replace function public.marca_despesa_paga(p_despesa_id uuid)
returns void language plpgsql security definer set search_path=public as $$
begin
  update despesas set status='pago', data_pagamento=now()::date where id=p_despesa_id;
end $$;

-- 5) Função para marcar receita como paga
create or replace function public.marca_receita_paga(p_receita_id uuid)
returns void language plpgsql security definer set search_path=public as $$
begin
  update balanco_receitas set status='pago', data_recebimento=now()::date where id=p_receita_id;
end $$;

-- 6) Função para marcar como pendente/cancelado
create or replace function public.marca_despesa_status(p_despesa_id uuid, p_status text)
returns void language plpgsql security definer set search_path=public as $$
begin
  if p_status not in ('pendente','pago','atrasado','cancelado') then
    raise exception 'Status inválido: %', p_status;
  end if;
  update despesas set status=p_status where id=p_despesa_id;
end $$;

create or replace function public.marca_receita_status(p_receita_id uuid, p_status text)
returns void language plpgsql security definer set search_path=public as $$
begin
  if p_status not in ('pendente','pago','cancelado') then
    raise exception 'Status inválido: %', p_status;
  end if;
  update balanco_receitas set status=p_status where id=p_receita_id;
end $$;

select 'Atualização v4 de Recorrências aplicada com sucesso! 🔄' as resultado;
