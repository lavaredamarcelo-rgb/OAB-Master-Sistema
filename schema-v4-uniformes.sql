-- ============================================================
-- OAB/PA MASTER — Atualização v4 de Uniformes
-- (CRUD Completo + Numeração Flexível)
-- Cole tudo no SQL Editor e clique RUN
-- ============================================================

-- 1) Expandir uniformes com campos de detalhamento
alter table public.uniformes add column if not exists detalhes text default '';
alter table public.uniformes add column if not exists editavel boolean not null default true;
alter table public.uniformes add column if not exists numeracao jsonb default '[]'::jsonb;
-- estrutura de numeracao: [{num: "1", status: "estoque", com: null, desde: null}, ...]

-- 2) Tabela de histórico de números (para rastreamento)
create table if not exists public.uniforme_numeros_historico (
  id uuid primary key default gen_random_uuid(),
  uniforme_id uuid references public.uniformes(id) on delete cascade,
  numero text not null,
  acao text not null check (acao in ('criado','entregue','devolvido','extraviado','removido')),
  atleta_id uuid references public.perfis(id) on delete set null,
  nome_convidado text, -- se foi entregue a convidado
  data date not null default now()::date,
  notas text default '',
  quem text not null default '',
  quando timestamptz not null default now()
);
alter table public.uniforme_numeros_historico enable row level security;
drop policy if exists unh_all on public.uniforme_numeros_historico;
create policy unh_all on public.uniforme_numeros_historico for all
  using (public.sou_gestor()) with check (public.sou_gestor());

-- 3) Índices
create index if not exists idx_uniforme_editavel on public.uniformes(editavel);
create index if not exists idx_unh_uniforme on public.uniforme_numeros_historico(uniforme_id);
create index if not exists idx_unh_numero on public.uniforme_numeros_historico(numero);

-- 4) Função para adicionar números (faixa ou solto)
create or replace function public.adiciona_numeros_uniforme(
  p_uniforme_id uuid,
  p_especificacao text  -- ex: "1-10" ou "15" ou "20-25,33,42"
)
returns void language plpgsql security definer set search_path=public as $$
declare
  v_partes text[];
  v_parte text;
  v_inicio int;
  v_fim int;
  v_num int;
  v_numeracao jsonb;
  v_uniforme record;
begin
  select * into v_uniforme from uniformes where id = p_uniforme_id;
  if v_uniforme is null then raise exception 'Uniforme não encontrado'; end if;

  v_numeracao := coalesce(v_uniforme.numeracao, '[]'::jsonb);

  -- Parse da especificação: "1-10,15,20-25,33"
  v_partes := string_to_array(p_especificacao, ',');

  foreach v_parte in array v_partes
  loop
    v_parte := trim(v_parte);

    if v_parte like '%-%' then
      -- É uma faixa (ex: "1-10")
      v_inicio := (string_to_array(v_parte, '-'))[1]::int;
      v_fim := (string_to_array(v_parte, '-'))[2]::int;
      for v_num in v_inicio..v_fim
      loop
        -- Adiciona se não existir
        if not exists (select 1 from jsonb_array_elements(v_numeracao) as x where x->>'num' = v_num::text) then
          v_numeracao := v_numeracao || jsonb_build_object('num', v_num::text, 'status', 'estoque', 'com', null, 'desde', null);
        end if;
      end loop;
    else
      -- É um número solto
      if not exists (select 1 from jsonb_array_elements(v_numeracao) as x where x->>'num' = v_parte) then
        v_numeracao := v_numeracao || jsonb_build_object('num', v_parte, 'status', 'estoque', 'com', null, 'desde', null);
      end if;
    end if;
  end loop;

  -- Atualiza
  update uniformes set numeracao = v_numeracao where id = p_uniforme_id;

  -- Registra no histórico
  foreach v_parte in array v_partes
  loop
    insert into uniforme_numeros_historico (uniforme_id, numero, acao, quem)
    values (p_uniforme_id, v_parte, 'criado', auth.jwt() ->> 'user_metadata'->>'name');
  end loop;
end $$;

-- 5) Função para remover número
create or replace function public.remove_numero_uniforme(
  p_uniforme_id uuid,
  p_numero text
)
returns void language plpgsql security definer set search_path=public as $$
declare
  v_uniforme record;
  v_numeracao jsonb;
begin
  select * into v_uniforme from uniformes where id = p_uniforme_id;
  if v_uniforme is null then raise exception 'Uniforme não encontrado'; end if;

  v_numeracao := v_uniforme.numeracao;
  v_numeracao := v_numeracao - (select pos from jsonb_array_elements(v_numeracao) with ordinality as x(val, pos) where val->>'num' = p_numero);

  update uniformes set numeracao = v_numeracao where id = p_uniforme_id;

  insert into uniforme_numeros_historico (uniforme_id, numero, acao, quem)
  values (p_uniforme_id, p_numero, 'removido', auth.jwt() ->> 'user_metadata'->>'name');
end $$;

-- 6) Função para marcar número como entregue
create or replace function public.entrega_numero_uniforme(
  p_uniforme_id uuid,
  p_numero text,
  p_atleta_id uuid,
  p_nome_convidado text default null
)
returns void language plpgsql security definer set search_path=public as $$
begin
  -- Atualiza numeração
  update uniformes
  set numeracao = jsonb_set(
    numeracao,
    (select array[pos-1] from jsonb_array_elements(numeracao) with ordinality x(val, pos) where val->>'num' = p_numero),
    jsonb_build_object('num', p_numero, 'status', 'atleta', 'com', p_atleta_id::text, 'desde', now()::date)
  )
  where id = p_uniforme_id;

  -- Registra histórico
  insert into uniforme_numeros_historico (uniforme_id, numero, acao, atleta_id, nome_convidado, quem)
  values (p_uniforme_id, p_numero, 'entregue', p_atleta_id, p_nome_convidado, auth.jwt() ->> 'user_metadata'->>'name');
end $$;

-- 7) Função para devolver número
create or replace function public.devolve_numero_uniforme(
  p_uniforme_id uuid,
  p_numero text,
  p_motivo text default 'devolução'
)
returns void language plpgsql security definer set search_path=public as $$
begin
  update uniformes
  set numeracao = jsonb_set(
    numeracao,
    (select array[pos-1] from jsonb_array_elements(numeracao) with ordinality x(val, pos) where val->>'num' = p_numero),
    jsonb_build_object('num', p_numero, 'status', 'estoque', 'com', null, 'desde', null)
  )
  where id = p_uniforme_id;

  insert into uniforme_numeros_historico (uniforme_id, numero, acao, notas, quem)
  values (p_uniforme_id, p_numero, 'devolvido', p_motivo, auth.jwt() ->> 'user_metadata'->>'name');
end $$;

select 'Atualização v4 de Uniformes aplicada com sucesso! 👕' as resultado;
