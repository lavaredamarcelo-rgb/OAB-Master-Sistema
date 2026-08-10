-- ============================================================
-- ATUALIZAÇÃO v5 — Cadastro manual de atletas, isenção de
-- mensalidade (goleiros) e presença de convidados
-- Rode este arquivo INTEIRO no Supabase → SQL Editor → Run
-- Pode rodar mais de uma vez sem problema (idempotente)
-- ============================================================

-- 1) Colunas novas
alter table public.perfis add column if not exists cadastro_manual boolean not null default false;
alter table public.perfis add column if not exists isento_mensalidade boolean not null default false;
alter table public.presencas add column if not exists convidado text;

-- 2) Perfis manuais não têm conta de login: id ganha valor próprio
--    e deixa de exigir vínculo com auth.users
alter table public.perfis alter column id set default gen_random_uuid();
alter table public.perfis drop constraint if exists perfis_id_fkey;

-- 3) Presenças de convidados: a chave primária antiga exigia atleta;
--    troca por restrição única que aceita convidados (atleta_id nulo)
alter table public.presencas drop constraint if exists presencas_pkey;
alter table public.presencas alter column atleta_id drop not null;
do $$ begin
  alter table public.presencas add constraint presencas_evento_atleta_uniq unique (evento_id, atleta_id);
exception when duplicate_table or duplicate_object then null; end $$;

-- 4) Cadastro manual de atleta (só diretoria)
create or replace function public.cadastrar_atleta_manual(
  p_nome text, p_fone text, p_oab text, p_posicao text,
  p_role text default 'atleta', p_isento boolean default false)
returns uuid language plpgsql security definer set search_path=public as $$
declare novo_id uuid;
begin
  if not public.sou_diretoria() then
    raise exception 'Apenas a diretoria pode cadastrar atletas manualmente';
  end if;
  insert into perfis (nome, fone, email, oab, posicao, role, aprovado, ativo,
                      cadastro_manual, isento_mensalidade, consent_status)
  values (p_nome, coalesce(p_fone,''), '', coalesce(p_oab,''), coalesce(p_posicao,''),
          coalesce(nullif(p_role,''),'atleta'), true, true, true,
          coalesce(p_isento,false), 'pendente')
  returning id into novo_id;
  return novo_id;
end $$;

-- 5) Vincular cadastro manual ao perfil real: transfere presenças,
--    estatísticas, cobranças, avaliações, metas, uniformes, saúde e
--    documentos, completa dados do perfil e apaga o cadastro manual
create or replace function public.vincular_cadastro_manual(p_manual uuid, p_real uuid)
returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.sou_diretoria() then
    raise exception 'Apenas a diretoria pode vincular cadastros';
  end if;
  if not exists (select 1 from perfis where id=p_manual and cadastro_manual) then
    raise exception 'Cadastro manual não encontrado';
  end if;

  -- presenças: move as que o perfil real ainda não tem; descarta duplicadas
  update presencas set atleta_id=p_real where atleta_id=p_manual
    and not exists (select 1 from presencas p2 where p2.evento_id=presencas.evento_id and p2.atleta_id=p_real);
  delete from presencas where atleta_id=p_manual;

  update stats      set atleta_id=p_real where atleta_id=p_manual;
  update cobrancas  set atleta_id=p_real where atleta_id=p_manual;
  update avaliacoes set atleta_id=p_real where atleta_id=p_manual;
  update metas      set atleta_id=p_real where atleta_id=p_manual;
  update uniformes  set atleta_id=p_real where atleta_id=p_manual;
  begin
    update documentos set atleta_id=p_real where atleta_id=p_manual;
  exception when undefined_table then null; end;
  begin
    update saude set atleta_id=p_real where atleta_id=p_manual
      and not exists (select 1 from saude s2 where s2.atleta_id=p_real);
    delete from saude where atleta_id=p_manual;
  exception when undefined_table then null; end;

  -- completa dados em branco do perfil real com os do cadastro manual
  update perfis set
    fone   = coalesce(nullif(perfis.fone,''), m.fone),
    oab    = coalesce(nullif(perfis.oab,''),  m.oab),
    posicao= coalesce(nullif(perfis.posicao,''), m.posicao),
    isento_mensalidade = m.isento_mensalidade
  from (select fone, oab, posicao, isento_mensalidade from perfis where id=p_manual) m
  where perfis.id = p_real;

  delete from perfis where id = p_manual;
end $$;

-- 6) Geração automática de mensalidades: pula isentos (goleiros)
create or replace function public.gera_mensalidades()
returns int language plpgsql security definer set search_path=public as $$
declare cfg record; descr text; venc date; n int;
begin
  select * into cfg from config where id=1;
  if cfg.mensalidade_auto is distinct from true then return 0; end if;
  descr := 'Mensalidade ' || to_char(current_date,'MM/YYYY');
  venc  := date_trunc('month',current_date)::date + (least(coalesce(cfg.mensalidade_dia,10),28) - 1);
  insert into cobrancas (atleta_id, descricao, valor, venc)
  select p.id, descr, coalesce(cfg.mensalidade_valor,130), venc
  from perfis p
  where p.ativo and p.aprovado
    and p.role in ('atleta','diretoria')
    and coalesce(p.isento_mensalidade,false) = false
    and not exists (select 1 from cobrancas c where c.atleta_id=p.id and c.descricao=descr);
  get diagnostics n = row_count;
  return n;
end $$;
