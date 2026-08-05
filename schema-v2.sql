-- ============================================================
-- OAB/PA MASTER — Atualização v2 do banco
-- (peças de uniforme, cargos/tarefas da diretoria, fundador,
--  LGPD para todos, notificações push)
-- Cole tudo no SQL Editor e clique RUN
-- ============================================================

-- 1) Uniformes por peças
alter table public.uniformes add column if not exists pecas jsonb not null
  default '{"camisa":"estoque","short":"estoque","meiao":"estoque"}'::jsonb;

-- 2) Cargos da diretoria + papel de Fundador
alter table public.perfis add column if not exists cargo text not null default '';
alter table public.perfis add column if not exists fundador boolean not null default false;
update public.perfis set fundador = true
 where id = (select id from public.perfis where role='diretoria' and aprovado order by criado_em asc limit 1)
   and not exists (select 1 from public.perfis where fundador);

create or replace function public.sou_fundador() returns boolean
language sql stable security definer set search_path=public as
$$ select coalesce((select fundador from perfis where id=auth.uid() and aprovado and ativo), false) $$;

-- 3) Todos precisam aceitar o termo LGPD (reapresenta a quem foi aceito automaticamente)
update public.perfis set consent_status='pendente' where role <> 'atleta' and consent_status='aceito';

create or replace function public.solicitar_cadastro(codigo text, p_nome text, p_fone text, p_oab text, p_posicao text)
returns text language plpgsql security definer set search_path=public as $$
declare fundador_novo boolean; c text; em text;
begin
  if auth.uid() is null then raise exception 'Sessão inválida — faça login novamente'; end if;
  select codigo_time into c from config where id = 1;
  if lower(trim(codigo)) <> lower(trim(c)) then
    raise exception 'Código do time incorreto. Peça o código à diretoria.';
  end if;
  if exists (select 1 from perfis where id = auth.uid()) then return 'ja_existe'; end if;
  fundador_novo := not exists (select 1 from perfis where role = 'diretoria' and aprovado);
  select coalesce(email,'') into em from auth.users where id = auth.uid();
  insert into perfis (id, nome, fone, oab, posicao, email, role, aprovado, fundador, consent_status)
  values (auth.uid(), p_nome, p_fone, p_oab, p_posicao, em,
          case when fundador_novo then 'diretoria' else 'atleta' end,
          fundador_novo, fundador_novo, 'pendente');
  insert into logs (tipo, texto, quem) values ('cadastro',
    case when fundador_novo then 'Conta fundadora (diretoria) criada: ' || p_nome
         else 'Solicitação de cadastro recebida: ' || p_nome || ' — aguardando aprovação' end, p_nome);
  return case when fundador_novo then 'fundador' else 'pendente' end;
end $$;

-- 4) Travas do Fundador
create or replace function public.guarda_perfis() returns trigger
language plpgsql as $$
begin
  if new.fundador is distinct from old.fundador then
    raise exception 'O papel de fundador não pode ser transferido pelo sistema';
  end if;
  if not public.sou_diretoria() then
    if new.role is distinct from old.role or new.aprovado is distinct from old.aprovado
       or new.ativo is distinct from old.ativo or new.cargo is distinct from old.cargo then
      raise exception 'Somente a diretoria pode alterar papel, cargo, aprovação ou situação';
    end if;
  end if;
  if (old.role='diretoria' or new.role='diretoria') and not public.sou_fundador() then
    if new.role is distinct from old.role or new.ativo is distinct from old.ativo then
      raise exception 'Somente o fundador pode promover, rebaixar ou desativar membros da diretoria';
    end if;
  end if;
  return new;
end $$;

drop policy if exists perfis_del_dir on public.perfis;
create policy perfis_del_dir on public.perfis for delete
  using (public.sou_diretoria() and id <> auth.uid() and (role <> 'diretoria' or public.sou_fundador()));

create or replace function public.guarda_config() returns trigger
language plpgsql as $$
begin
  if not public.sou_fundador() then
    if new.codigo_time is distinct from old.codigo_time or new.time_nome is distinct from old.time_nome then
      raise exception 'Somente o fundador pode alterar o nome do clube e o código do time';
    end if;
  end if;
  return new;
end $$;
drop trigger if exists tg_guarda_config on public.config;
create trigger tg_guarda_config before update on public.config
  for each row execute function public.guarda_config();

drop policy if exists logs_sel on public.logs;
create policy logs_sel on public.logs for select using (public.sou_fundador());

-- 5) Tarefas da diretoria
create table if not exists public.tarefas (
  id uuid primary key default gen_random_uuid(),
  titulo text not null, descricao text not null default '',
  responsavel_id uuid references public.perfis(id) on delete cascade,
  prazo date,
  status text not null default 'aberta' check (status in ('aberta','concluida')),
  criado_por text not null default '',
  quando timestamptz not null default now()
);
alter table public.tarefas enable row level security;
drop policy if exists tarefas_all on public.tarefas;
create policy tarefas_all on public.tarefas for all
  using (public.sou_diretoria()) with check (public.sou_diretoria());
drop policy if exists tarefas_own on public.tarefas;
create policy tarefas_own on public.tarefas for select using (responsavel_id = auth.uid());

-- 6) Notificações push
create table if not exists public.push_subs (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid references public.perfis(id) on delete cascade,
  sub jsonb not null,
  quando timestamptz not null default now()
);
alter table public.push_subs enable row level security;
drop policy if exists ps_ins on public.push_subs;
create policy ps_ins on public.push_subs for insert with check (atleta_id = auth.uid());
drop policy if exists ps_sel on public.push_subs;
create policy ps_sel on public.push_subs for select using (atleta_id = auth.uid());
drop policy if exists ps_del on public.push_subs;
create policy ps_del on public.push_subs for delete using (atleta_id = auth.uid());

select 'Atualização v2 aplicada com sucesso! ⚽' as resultado;
