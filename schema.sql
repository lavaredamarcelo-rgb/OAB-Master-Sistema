-- ============================================================
-- SISTEMA OAB/PA MASTER — Banco de dados (Supabase/Postgres)
-- Cole este arquivo inteiro no SQL Editor do Supabase e clique RUN
-- ============================================================
create extension if not exists pgcrypto;

-- ===================== PERFIS =====================
create table if not exists public.perfis (
  id uuid primary key references auth.users(id) on delete cascade,
  nome text not null,
  fone text not null default '',
  email text not null default '',
  oab text not null default '',
  posicao text not null default '',
  role text not null default 'atleta' check (role in ('diretoria','treinador','preparador','atleta')),
  aprovado boolean not null default false,
  ativo boolean not null default true,
  consent_status text not null default 'pendente' check (consent_status in ('pendente','aceito','recusado','revogado')),
  consent_quando timestamptz,
  consent_versao text,
  criado_em timestamptz not null default now()
);
alter table public.perfis enable row level security;

-- Funções auxiliares (verificam papel do usuário logado)
create or replace function public.meu_papel() returns text
language sql stable security definer set search_path=public as
$$ select role from perfis where id = auth.uid() and aprovado and ativo $$;

create or replace function public.sou_diretoria() returns boolean
language sql stable security definer set search_path=public as
$$ select coalesce(public.meu_papel() = 'diretoria', false) $$;

create or replace function public.sou_gestor() returns boolean
language sql stable security definer set search_path=public as
$$ select coalesce(public.meu_papel() in ('diretoria','treinador'), false) $$;

create or replace function public.sou_comissao() returns boolean
language sql stable security definer set search_path=public as
$$ select coalesce(public.meu_papel() in ('diretoria','treinador','preparador'), false) $$;

create or replace function public.sou_membro() returns boolean
language sql stable security definer set search_path=public as
$$ select public.meu_papel() is not null $$;

-- Políticas de perfis
drop policy if exists perfis_sel on public.perfis;
create policy perfis_sel on public.perfis for select
  using (id = auth.uid() or public.sou_membro());
drop policy if exists perfis_upd_self on public.perfis;
create policy perfis_upd_self on public.perfis for update
  using (id = auth.uid());
drop policy if exists perfis_upd_dir on public.perfis;
create policy perfis_upd_dir on public.perfis for update
  using (public.sou_diretoria());
drop policy if exists perfis_del_dir on public.perfis;
create policy perfis_del_dir on public.perfis for delete
  using (public.sou_diretoria() and id <> auth.uid());

-- Trava: só diretoria altera papel/aprovação/ativo
create or replace function public.guarda_perfis() returns trigger
language plpgsql as $$
begin
  if not public.sou_diretoria() then
    if new.role is distinct from old.role
       or new.aprovado is distinct from old.aprovado
       or new.ativo is distinct from old.ativo then
      raise exception 'Somente a diretoria pode alterar papel, aprovação ou situação';
    end if;
  end if;
  return new;
end $$;
drop trigger if exists tg_guarda_perfis on public.perfis;
create trigger tg_guarda_perfis before update on public.perfis
  for each row execute function public.guarda_perfis();

-- ===================== CONFIGURAÇÃO DO CLUBE =====================
create table if not exists public.config (
  id int primary key default 1 check (id = 1),
  time_nome text not null default 'OAB/PA Master',
  pix text not null default '',
  grupo text not null default '',
  limite_faltas int not null default 3,
  encarregado text not null default '',
  enc_contato text not null default '',
  codigo_time text not null default 'MASTER2026'
);
alter table public.config enable row level security;
insert into public.config (id) values (1) on conflict do nothing;
drop policy if exists config_sel on public.config;
create policy config_sel on public.config for select using (public.sou_membro());
drop policy if exists config_upd on public.config;
create policy config_upd on public.config for update using (public.sou_diretoria());

-- ===================== CADASTRO (com código do time) =====================
create or replace function public.solicitar_cadastro(codigo text, p_nome text, p_fone text, p_oab text, p_posicao text)
returns text language plpgsql security definer set search_path=public as $$
declare fundador boolean; c text; em text;
begin
  if auth.uid() is null then raise exception 'Sessão inválida — faça login novamente'; end if;
  select codigo_time into c from config where id = 1;
  if lower(trim(codigo)) <> lower(trim(c)) then
    raise exception 'Código do time incorreto. Peça o código à diretoria.';
  end if;
  if exists (select 1 from perfis where id = auth.uid()) then return 'ja_existe'; end if;
  fundador := not exists (select 1 from perfis where role = 'diretoria' and aprovado);
  select coalesce(email,'') into em from auth.users where id = auth.uid();
  insert into perfis (id, nome, fone, oab, posicao, email, role, aprovado, consent_status)
  values (auth.uid(), p_nome, p_fone, p_oab, p_posicao, em,
          case when fundador then 'diretoria' else 'atleta' end,
          fundador,
          case when fundador then 'aceito' else 'pendente' end);
  insert into logs (tipo, texto, quem) values ('cadastro',
    case when fundador then 'Conta fundadora (diretoria) criada: ' || p_nome
         else 'Solicitação de cadastro recebida: ' || p_nome || ' — aguardando aprovação' end, p_nome);
  return case when fundador then 'fundador' else 'pendente' end;
end $$;
grant execute on function public.solicitar_cadastro to authenticated;

-- ===================== TABELAS DO CLUBE =====================
create table if not exists public.saude (
  atleta_id uuid primary key references public.perfis(id) on delete cascade,
  sangue text default '', plano text default '', alergias text default '',
  medicamentos text default '', condicoes text default '', emergencia text default '',
  lesoes text default '', obs text default '',
  atualizado_em timestamptz default now()
);
alter table public.saude enable row level security;
drop policy if exists saude_all on public.saude;
create policy saude_all on public.saude for all
  using (public.sou_comissao() or atleta_id = auth.uid())
  with check (public.sou_comissao() or atleta_id = auth.uid());

create table if not exists public.eventos (
  id uuid primary key default gen_random_uuid(),
  tipo text not null default 'treino', titulo text not null,
  data date not null, hora text not null default '19:00',
  local text not null default '', obs text not null default ''
);
alter table public.eventos enable row level security;
drop policy if exists eventos_sel on public.eventos;
create policy eventos_sel on public.eventos for select using (public.sou_membro());
drop policy if exists eventos_mod on public.eventos;
create policy eventos_mod on public.eventos for all
  using (public.sou_gestor()) with check (public.sou_gestor());

create table if not exists public.presencas (
  evento_id uuid references public.eventos(id) on delete cascade,
  atleta_id uuid references public.perfis(id) on delete cascade,
  status text not null check (status in ('presente','atraso','falta','justificada')),
  primary key (evento_id, atleta_id)
);
alter table public.presencas enable row level security;
drop policy if exists pres_sel on public.presencas;
create policy pres_sel on public.presencas for select using (public.sou_membro());
drop policy if exists pres_mod on public.presencas;
create policy pres_mod on public.presencas for all
  using (public.sou_gestor()) with check (public.sou_gestor());

create table if not exists public.cobrancas (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid references public.perfis(id) on delete cascade,
  descricao text not null, valor numeric not null default 0,
  venc date not null, status text not null default 'pendente' check (status in ('pendente','pago')),
  pago_em date
);
alter table public.cobrancas enable row level security;
drop policy if exists cob_sel on public.cobrancas;
create policy cob_sel on public.cobrancas for select
  using (public.sou_diretoria() or atleta_id = auth.uid());
drop policy if exists cob_mod on public.cobrancas;
create policy cob_mod on public.cobrancas for all
  using (public.sou_diretoria()) with check (public.sou_diretoria());

create table if not exists public.avaliacoes (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid references public.perfis(id) on delete cascade,
  data date not null, peso text default '', altura text default '',
  gordura text default '', vo2 text default '', notas text default ''
);
alter table public.avaliacoes enable row level security;
drop policy if exists aval_sel on public.avaliacoes;
create policy aval_sel on public.avaliacoes for select
  using (public.sou_comissao() or atleta_id = auth.uid());
drop policy if exists aval_mod on public.avaliacoes;
create policy aval_mod on public.avaliacoes for all
  using (public.sou_comissao()) with check (public.sou_comissao());

create table if not exists public.metas (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid references public.perfis(id) on delete cascade,
  descricao text not null, prazo date,
  status text not null default 'andamento' check (status in ('andamento','atingida'))
);
alter table public.metas enable row level security;
drop policy if exists metas_sel on public.metas;
create policy metas_sel on public.metas for select
  using (public.sou_comissao() or atleta_id = auth.uid());
drop policy if exists metas_mod on public.metas;
create policy metas_mod on public.metas for all
  using (public.sou_comissao()) with check (public.sou_comissao());

create table if not exists public.stats (
  id uuid primary key default gen_random_uuid(),
  evento_id uuid references public.eventos(id) on delete cascade,
  atleta_id uuid references public.perfis(id) on delete cascade,
  minutos int, gols int default 0, assist int default 0, amarelos int default 0,
  vermelho boolean default false, desarmes int default 0, duelos int default 0,
  passes int default 0, nota numeric, obs text default '',
  unique (evento_id, atleta_id)
);
alter table public.stats enable row level security;
drop policy if exists stats_sel on public.stats;
create policy stats_sel on public.stats for select using (public.sou_membro());
drop policy if exists stats_mod on public.stats;
create policy stats_mod on public.stats for all
  using (public.sou_gestor()) with check (public.sou_gestor());

create table if not exists public.uniformes (
  id uuid primary key default gen_random_uuid(),
  descricao text not null, numero text default '', tamanho text default 'M',
  status text not null default 'estoque' check (status in ('estoque','pendente','com_atleta')),
  atleta_id uuid references public.perfis(id) on delete set null,
  entregue_em text default '', aceito_em text default ''
);
alter table public.uniformes enable row level security;
drop policy if exists uni_sel on public.uniformes;
create policy uni_sel on public.uniformes for select
  using (public.sou_diretoria() or atleta_id = auth.uid());
drop policy if exists uni_dir on public.uniformes;
create policy uni_dir on public.uniformes for all
  using (public.sou_diretoria()) with check (public.sou_diretoria());
drop policy if exists uni_aceite on public.uniformes;
create policy uni_aceite on public.uniformes for update
  using (atleta_id = auth.uid());

create table if not exists public.inventario (
  id uuid primary key default gen_random_uuid(),
  nome text not null, cat text default 'Geral', qtd int not null default 1
);
alter table public.inventario enable row level security;
drop policy if exists inv_all on public.inventario;
create policy inv_all on public.inventario for all
  using (public.sou_diretoria()) with check (public.sou_diretoria());

create table if not exists public.taticas_notas (
  id uuid primary key default gen_random_uuid(),
  titulo text not null, texto text default '', autor text default '',
  quando timestamptz default now()
);
alter table public.taticas_notas enable row level security;
drop policy if exists tn_sel on public.taticas_notas;
create policy tn_sel on public.taticas_notas for select using (public.sou_membro());
drop policy if exists tn_mod on public.taticas_notas;
create policy tn_mod on public.taticas_notas for all
  using (public.sou_gestor()) with check (public.sou_gestor());

create table if not exists public.taticas_esquemas (
  id uuid primary key default gen_random_uuid(),
  nome text not null, formacao text not null, posicoes jsonb not null default '[]',
  obs text default '', quando timestamptz default now()
);
alter table public.taticas_esquemas enable row level security;
drop policy if exists te_sel on public.taticas_esquemas;
create policy te_sel on public.taticas_esquemas for select using (public.sou_membro());
drop policy if exists te_mod on public.taticas_esquemas;
create policy te_mod on public.taticas_esquemas for all
  using (public.sou_gestor()) with check (public.sou_gestor());

-- Documentos (metadados; arquivos ficam no Storage)
create table if not exists public.documentos (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid references public.perfis(id) on delete cascade,
  escopo text not null check (escopo in ('geral','saude','financeiro','tatica')),
  categoria text default 'Outro',
  nome text not null, path text not null, mime text default '', tam int default 0,
  quem text default '', quando timestamptz default now()
);
alter table public.documentos enable row level security;
drop policy if exists doc_sel on public.documentos;
create policy doc_sel on public.documentos for select using (
  public.sou_diretoria()
  or atleta_id = auth.uid()
  or (escopo = 'tatica' and public.sou_membro())
  or (escopo = 'saude' and public.sou_comissao())
);
drop policy if exists doc_ins on public.documentos;
create policy doc_ins on public.documentos for insert with check (
  public.sou_diretoria()
  or (atleta_id = auth.uid() and escopo in ('geral','saude'))
  or (escopo = 'tatica' and public.sou_gestor())
);
drop policy if exists doc_del on public.documentos;
create policy doc_del on public.documentos for delete using (
  public.sou_diretoria() or atleta_id = auth.uid() or (escopo = 'tatica' and public.sou_gestor())
);

create table if not exists public.logs (
  id uuid primary key default gen_random_uuid(),
  tipo text not null, texto text not null, quem text default '',
  quando timestamptz default now()
);
alter table public.logs enable row level security;
drop policy if exists logs_ins on public.logs;
create policy logs_ins on public.logs for insert with check (public.sou_membro());
drop policy if exists logs_sel on public.logs;
create policy logs_sel on public.logs for select using (public.sou_diretoria());

-- ===================== STORAGE (arquivos) =====================
insert into storage.buckets (id, name, public) values ('arquivos','arquivos', false)
on conflict (id) do nothing;

drop policy if exists arq_sel on storage.objects;
create policy arq_sel on storage.objects for select using (
  bucket_id = 'arquivos' and (
    public.sou_diretoria()
    or (storage.foldername(name))[1] = auth.uid()::text
    or ((storage.foldername(name))[1] = 'tatica' and public.sou_membro())
    or (public.sou_comissao() and (storage.foldername(name))[1] not in ('financeiro','tatica'))
  )
);
drop policy if exists arq_ins on storage.objects;
create policy arq_ins on storage.objects for insert with check (
  bucket_id = 'arquivos' and (
    public.sou_diretoria()
    or (storage.foldername(name))[1] = auth.uid()::text
    or ((storage.foldername(name))[1] = 'tatica' and public.sou_gestor())
  )
);
drop policy if exists arq_del on storage.objects;
create policy arq_del on storage.objects for delete using (
  bucket_id = 'arquivos' and (
    public.sou_diretoria()
    or (storage.foldername(name))[1] = auth.uid()::text
    or ((storage.foldername(name))[1] = 'tatica' and public.sou_gestor())
  )
);

-- ===================== PRONTO! =====================
select 'Banco do OAB/PA Master criado com sucesso! ⚽' as resultado;
