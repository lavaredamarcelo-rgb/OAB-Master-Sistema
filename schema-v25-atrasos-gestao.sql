-- ============================================================
-- ATUALIZAÇÃO v25 — Resumo de atrasos para a comissão técnica
-- Treinador e auxiliar veem, APENAS como resumo (quantidade e
-- valor total em atraso por atleta), a situação financeira ao
-- montar convocações. Nenhum detalhe de cobrança é exposto.
-- Rode no Supabase → SQL Editor → Run (projeto pzodgfsekqpumvgigeii)
-- ============================================================

create or replace function public.atrasos_por_atleta()
returns table(atleta_id uuid, qtd bigint, total numeric)
language sql stable security definer set search_path=public as
$$
  select c.atleta_id, count(*)::bigint,
    sum( greatest(0,
      (case when c.descricao ~* 'mensalidade' and c.status <> 'pago'
            then coalesce((select mensalidade_valor_apos from config where id=1), c.valor)
            else c.valor end)
      - coalesce((select sum((pp->>'valor')::numeric)
                  from jsonb_array_elements(coalesce(c.pagamentos,'[]'::jsonb)) pp),0)
    ))::numeric
  from cobrancas c
  where public.sou_gestor()
    and c.atleta_id is not null
    and c.status <> 'pago'
    and c.venc < current_date
  group by c.atleta_id
$$;

-- Confirmação: deve mostrar 1 linha
select routine_name from information_schema.routines
where routine_schema='public' and routine_name='atrasos_por_atleta';
