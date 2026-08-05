-- ============================================================
-- OAB/PA MASTER — Atualização v3 de Táticas
-- (confrontos adversários, histórico com placar, reutilização)
-- Cole tudo no SQL Editor e clique RUN
-- ============================================================

-- 1) Expandir taticas_esquemas para suportar adversários
alter table public.taticas_esquemas add column if not exists adversario jsonb;
-- Estrutura: { "nome": "nome do time", "posicoes": [...] }

alter table public.taticas_esquemas add column if not exists placar jsonb;
-- Estrutura: { "time": 2, "adversario": 1 }

alter table public.taticas_esquemas add column if not exists data_jogo date;
alter table public.taticas_esquemas add column if not exists performance text default '';
-- Ex: "vitória", "derrota", "empate", "não realizado"

alter table public.taticas_esquemas add column if not exists descricao_jogo text default '';
-- Observações sobre como foi o jogo, o que funcionou bem, etc

-- 2) Tabela de histórico de confrontos (para referência rápida)
create table if not exists public.taticas_confrontos (
  id uuid primary key default gen_random_uuid(),
  nome_escalacao text not null, -- referência ao nome da escalação
  adversario_nome text not null, -- nome do time adversário
  placar_time int not null default 0,
  placar_adversario int not null default 0,
  data_jogo date,
  formacao text not null, -- 'fut7', 'futsal', 'campo'
  posicoes_time jsonb, -- backup das posições do time
  posicoes_adversario jsonb, -- backup das posições do adversário
  performance text not null default '', -- 'vitória', 'derrota', 'empate'
  notas text default '', -- notas do que funcionou bem, o que melhorar
  tags text default '', -- tags tipo "defesa fraca", "ataque rápido", etc
  autor text not null default '',
  quando timestamptz not null default now()
);

alter table public.taticas_confrontos enable row level security;
drop policy if exists confrontos_all on public.taticas_confrontos;
create policy confrontos_all on public.taticas_confrontos for all
  using (public.sou_gestor()) with check (public.sou_gestor());
drop policy if exists confrontos_sel on public.taticas_confrontos;
create policy confrontos_sel on public.taticas_confrontos for select using (true);

select 'Atualização v3 de Táticas aplicada com sucesso! ⚽' as resultado;
