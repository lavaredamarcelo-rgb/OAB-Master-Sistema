# 🔄 Guia: Lançamentos Recorrentes (Despesas e Receitas)

## 📋 Resumo

Agora você pode criar **despesas e receitas que se repetem todos os meses** (janeiro a dezembro). Cada mês aparece com status **"Pendente"**, e você marca como **"Pago"** quando a transação acontecer.

**No Balanço**, a receita/despesa só aparece no cálculo quando estiver marcada como **"Pago"**.

---

## 🚀 Instalação

1. Abra o **SQL Editor** do seu projeto Supabase
2. Cole o conteúdo completo do arquivo: `schema-v4-recorrencias.sql`
3. Clique **RUN**

Isso vai adicionar:
- Coluna `status` (pendente, pago, atrasado, cancelado)
- Coluna `tipo_recorrencia` (unica, mensal, anual)
- Campos de referência mensal/anual
- Funções para marcar como pago

**⏱️ Tempo**: ~20 segundos

---

## 💸 Criar Despesa Recorrente

**Quando usar:** Treinador, aluguel, seguro — despesas que se repetem todo mês

**Acesso:**
- Aba **Financeiro → Balanço → Despesas**
- Botão amarelo **"🔄 Recorrente"**

**O que preencher:**
```
📝 Item: Treinador
🏷️ Categoria: Pessoal / Operacional / Aluguel
💵 Valor mensal: 5.000,00
👤 Fornecedor: João Silva (opcional)
📅 Vencimento: 10 (dia do mês)
📌 Obs: Serviço de treinamento (opcional)

[✓ Criar (12 meses)]
```

**Resultado:**
- Cria 12 linhas (jan/2025 a dez/2025)
- Cada linha começa como **"Pendente"**
- Você marca cada mês como "Pago" quando pagar
- No Balanço, só aparece no cálculo quando "Pago"

**Exemplo:**
```
Treinador - jan/25: PENDENTE → [clique] → PAGO
Treinador - fev/25: PENDENTE → [clique] → PAGO
...
```

---

## 💰 Criar Receita Recorrente

**Quando usar:** Mensalidades, patrocínios, contribuições — receitas que se repetem todo mês

**Acesso:**
- Aba **Financeiro → Balanço → Receitas**
- Botão amarelo **"🔄 Recorrente"**

**O que preencher:**
```
📝 Descrição: Mensalidade João Silva
💰 Tipo: Mensalidade atleta / Atleta avulso / Patrocínio / etc
💵 Valor mensal: 150,00
📌 Obs: Período 2025 (opcional)

[✓ Criar (12 meses)]
```

**Resultado:**
- Cria 12 linhas (jan/2025 a dez/2025)
- Cada linha começa como **"Pendente"**
- Você marca cada mês como "Pago" quando receber
- No Balanço, só aparece no cálculo quando "Pago"

**Exemplo:**
```
Mensalidade João - jan/25: PENDENTE → [clique] → PAGO
Mensalidade João - fev/25: PENDENTE → [clique] → PAGO
...
```

---

## 📊 Como Usar no Balanço

### Visualizar Pendências

**Financeiro → Balanço → Despesas**

Vai mostrar:
- ❌ Contas a pagar (PENDENTE)
- ✅ Despesas pagas (PAGO)
- 🔴 Atrasadas (ATRASADO — se passou da data)

### Marcar como Pago

**Clique na linha → Marca como "PAGO"**

A despesa **desaparece da aba "Contas a Pagar"** e aparece no **Balanço Geral** com o valor já contabilizado.

### Balanço Geral

**Financeiro → Balanço**

Mostra:
- 💵 **Total de Receitas** — só soma itens marcados como "PAGO"
- 💸 **Total de Despesas** — só soma itens marcados como "PAGO"
- 📊 **Saldo Líquido** = Receitas - Despesas

---

## 🎯 Exemplo Completo

### Janeiro:
1. Cria despesa recorrente: "Treinador - R$ 5.000 (jan-dez)"
   → Sistema cria 12 linhas (jan, fev, mar, ... dez)

2. Cria receita recorrente: "Mensalidade João - R$ 150 (jan-dez)"
   → Sistema cria 12 linhas (jan, fev, mar, ... dez)

3. Você vai ao banco e paga o treinador em 10/01
   → Marca "Despesa Treinador - jan/25" como PAGO
   → Aparece no Balanço Geral

4. Você recebe de João em 15/01
   → Marca "Receita Mensalidade João - jan/25" como PAGO
   → Aparece no Balanço Geral

### Balanço de Janeiro:
```
💰 Receitas: R$ 150 (João pago)
💸 Despesas: R$ 5.000 (Treinador pago)
📊 Saldo: -R$ 4.850
```

### Em Fevereiro:
- Mesmas 12 linhas continuam
- "Treinador - fev/25: PENDENTE"
- "Mensalidade João - fev/25: PENDENTE"
- Você marca cada uma quando pagar/receber

---

## 🔍 Status Disponíveis

| Status | Significado | Aparece no Balanço? |
|--------|-----------|-------------------|
| **PENDENTE** | Não pagou/recebeu ainda | ❌ Não |
| **PAGO** | Já pagou/recebeu | ✅ Sim |
| **ATRASADO** | Passou do vencimento e ainda não pagou | ⚠️ Apenas em relatórios |
| **CANCELADO** | Não vai pagar/receber | ❌ Não |

---

## 💡 Dicas

1. **Use a data de vencimento** (ex: 10) para organizar quando deve pagar
2. **Marque assim que pagar** — não deixe acumular pendências
3. **Crie uma receita recorrente POR PESSOA** (uma para João, uma para Maria, etc)
4. **No final do ano**, você terá 12 linhas de cada despesa/receita, todas marcadas como pagas
5. **Use "Cancelado"** se alguma receita/despesa não acontecer mais naquele mês

---

## 🆘 Problemas?

### "Não vejo o botão 🔄 Recorrente"
- Verifique se rodou o `schema-v4-recorrencias.sql` no Supabase
- Recarregue a página (F5)

### "Criei 12 meses mas não aparece nada"
- Recarregue a página (F5)
- Procure pela seção de "Contas a Pagar" em Balanço → Despesas

### "Não consegui marcar como pago"
- O botão ainda está em desenvolvimento
- Use: Financeiro → Balanço → [clique na linha]

---

## 📞 Próximos Passos (Planejado)

- 🎯 Interface para marcar como pago diretamente da lista
- 🎯 Filtro por mês/ano
- 🎯 Gerar recorrências para 2026 antes de dezembro
- 🎯 Editar valor de uma despesa/receita específica
- 🎯 Relatório de "Contas a Pagar" por mês

---

**Versão:** 1.0  
**Data:** janeiro 2026  
**Autor:** Sistema OAB/PA Master
