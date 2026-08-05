# 💰 Guia: Sistema Financeiro v3 — Lançador Rápido + Editor de Período + Gestor de Importações

## 🚀 Instalação (Obrigatório)

### Passo 1: Aplicar Schema no Supabase

1. Abra o **SQL Editor** do seu projeto Supabase
2. Cole o conteúdo completo do arquivo: `/OAB-Master-Sistema/schema-v3-financeiro.sql`
3. Clique **RUN**

Isso vai criar:
- Tabela `import_lotes` (para rastrear importações)
- Colunas em `cobrancas` e `despesas` (para vincular a lotes)
- Índices para performance

**⏱️ Tempo**: ~30 segundos

---

## 📋 As Três Funcionalidades

### 1️⃣ **Lançador Rápido** — ➕ Novo Lançamento Avulso

**Quando usar:** Para adicionar **uma ou poucas** entradas/cobranças de pessoas que não estão no sistema.

**Acesso:** 
- Aba **Financeiro → Cobranças**
- Botão amarelo **"➕ Lançamento avulso"**

**O que preencher:**
```
📅 Data: 15/01/2025 (quando é relativo ao período)
👤 Quem: João Silva (ex-atleta) / Fornecedor X / Convidado
🏷️ Tipo: Mensalidade 2025, Contribuição extra, Empréstimo devolvido, etc
💵 Valor: R$ 150,00
📱 WhatsApp: (91) 99999-9999 (opcional, bom para cobranças futuras)
✅ Status: Pago / Pendente
📝 Obs: Referente ao período anterior…

[✓ Salvar]
```

**Resultado:**
- Lançamento fica marcado como **"historico"** (tipo_lancamento)
- Aparece na lista de cobranças normalmente
- Rastreável: você vê que foi "Lançamento manual"

**Exemplo:** Você quer adicionar R$ 130 que João pagou em janeiro de 2025
1. Clica "➕ Lançamento avulso"
2. Data: 15/01/2025
3. Quem: João Silva
4. Tipo: **Mensalidade 2025**
5. Valor: 130
6. Status: ✅ Pago
7. Salva!

---

### 2️⃣ **Editor de Período** — 📊 Visualizar/Editar Intervalo

**Quando usar:** Para ver e registrar **múltiplos lançamentos de um período** (ex: todo o ano 2025).

**Acesso:**
- Aba **Financeiro → Cobranças**
- Botão cinza **"📊 Editor de período"**

**O que faz:**
1. Você escolhe um intervalo de datas (ex: 01/01/2025 a 31/12/2025)
2. Sistema mostra **entradas + saídas** daquele período em uma tabela
3. Você pode **adicionar novas linhas** manualmente
4. Calcula automaticamente:
   - Total entradas
   - Total saídas
   - Saldo líquido do período

**Exemplo:**
```
Período: 01/01/2025 a 31/12/2025
Marcar como: 📅 Período anterior (histórico)

┌──────────────────────────────────────┐
│ Data      │ Pessoa        │ Tipo  │ Valor  │
├──────────────────────────────────────┤
│ 01/01/25  │ João Silva    │ Mens. │ R$ 130 │
│ 05/01/25  │ Aluguel Arena │ Desp. │-R$ 800│
│ 10/01/25  │ Maria Costa   │ Mens. │ R$ 130 │
└──────────────────────────────────────┘

💰 Entradas: R$ 2.500
💸 Saídas: R$ 1.800
📊 Líquido: R$ 700

[✓ Confirmar]
```

**Resultado:**
- Todos os lançamentos ficam marcados como **"historico"**
- O saldo do período é calculado e pode virar **saldo_inicial do ano seguinte**

---

### 3️⃣ **Gestor de Importações** — 📦 Rastrear Lotes de Planilhas

**Quando usar:** Para ver o **histórico de todas as importações** e gerenciar atualizações.

**Acesso:**
- Aba **Financeiro → Cobranças**
- Botão cinza **"📦 Gestor de importações"**

**O que mostra:**

```
📦 LOTES DE IMPORTAÇÃO

✅ Lote #1 — "Financeiro 2025.xlsx" (v2 - ATUAL)
   ├─ 1ª import: 15 jan 2026
   ├─ Atualizado: 20 jan 2026 ✨ NOVA VERSÃO!
   ├─ Cobranças: 12 (11 atualizadas + 1 nova)
   ├─ Despesas: 5
   ├─ Total: +R$ 2.500 | -R$ 1.800
   └─ [👁️ Detalhes] [↩️ Desfazer]

⚠️ Lote #2 — "Receitas.xls" (v1 - SUBSTITUÍDO)
   ├─ Criado: 10 jan 2026
   ├─ Substituído por: Lote #1 v2
   └─ [📊 Ver diferenças]
```

**Como funciona a ATUALIZAÇÃO de planilha:**

**Cenário:**
- **Dia 1:** Você importa `Financeiro 2025.xlsx` com 10 lançamentos
- **Dia 5:** Você atualiza a planilha (corrige valores, adiciona novos)
- **Dia 5:** Você importa de novo a mesma planilha

**O que acontece:**
1. Sistema **detecta que é a mesma planilha** (por hash)
2. Compara: quais dados mudaram?
3. Propõe: "Deseja atualizar os dados desta importação?"
   - **Sim, atualizar:** Remove lançamentos antigos, adiciona novos
   - **Não, importar como novo:** Cria um novo lote (⚠️ cuidado com dúplices!)

**Resultado:**
- ✅ Sem lançamentos dúplices
- ✅ Histórico completo (v1, v2, v3 de cada planilha)
- ✅ Pode desfazer qualquer lote

---

## 🔄 Fluxo Completo: Migrando Dados de 2025

### Exemplo Passo-a-Passo

**Meta:** Trazer os dados financeiros de 2025 para o sistema.

**Opção A — Usar Lançador Rápido (poucos dados)**
```
1. Aba Financeiro → Cobranças
2. [➕ Lançamento avulso]
3. Data: 15/01/2025, Quem: João, Tipo: Mensalidade 2025, Valor: 130, Status: Pago
4. [✓ Salvar]
5. Repetir para cada lançamento...
```
⏱️ Bom para: **10-20 lançamentos**

---

**Opção B — Usar Editor de Período (muitos dados)**
```
1. Aba Financeiro → Cobranças
2. [📊 Editor de período]
3. Data inicial: 01/01/2025
4. Data final: 31/12/2025
5. Marcar como: 📅 Período anterior (histórico)
6. Clica [+ Nova linha] múltiplas vezes
7. Preenche cada linha:
   - Data | Pessoa | Tipo | Valor
8. [✓ Confirmar]
```
⏱️ Bom para: **Qualquer quantidade**

---

**Opção C — Usar Importador de Planilha (dados em Excel)**
```
1. Aba Financeiro → Cobranças
2. Botão [⬆ Importar planilha]
3. Escolha seu Excel (formato antigo do time)
4. Clica [Ler planilha]
5. Sistema faz preview
6. Clica [Aplicar]
7. Se for atualizar depois, sistema avisa que é v2 e oferece atualizar
```
⏱️ Bom para: **Grandes volumes já em Excel**

---

## ⚠️ Sobre Lançamentos Dúplices

### Cenário de Risco

```
❌ ERRADO:
Dia 1: Importa "Financeiro 2025.xlsx"
       └─ João: R$ 130 (mensalidade jan/2025)

Dia 5: Atualiza a planilha com novos dados
Dia 5: Importa de novo "Financeiro 2025.xlsx"
       
Resultado: João fica com R$ 130 + R$ 130 = R$ 260 ❌
```

### Como o Sistema Previne

```
✅ CORRETO:
Dia 1: Importa "Financeiro 2025.xlsx" v1
       └─ Cria LOTE #1 com hash ABC123

Dia 5: Importa de novo "Financeiro 2025.xlsx"
       └─ Sistema detecta: "Este arquivo já foi importado (LOTE #1)"
       └─ Pergunta: "Deseja atualizar LOTE #1?"
       
Se SIM:
  └─ Remove lançamentos da v1
  └─ Adiciona lançamentos da v2 (atualizados)
  └─ LOTE #1 vira v2

Resultado: João fica com R$ 150 (valor correto de jan/2025) ✅
```

---

## 📊 Rastreamento: Como Saber Origem do Lançamento

Cada lançamento tem um **tipo_lancamento**:

| Tipo | Significado | Onde vem |
|------|-----------|----------|
| `manual` | Lançamento manual avulso | Lançador Rápido ➕ |
| `historico` | Período anterior (2025, etc) | Editor de Período 📊 |
| `importado` | Veio de planilha | Importador ⬆ |
| `automatica` | Gerado automaticamente | Sistema (gera_mensalidades) |
| `avulso` | Treino avulso | Treino Avulso 🏃 |
| `treino` | (mesmo que avulso) | - |

**Como ver no sistema:**

Na tabela de Cobranças, cada linha mostra:
```
João Silva — Mensalidade 2025 | R$ 130 | Pago
📄 Importado em "Financeiro 2025.xlsx" v2 (15 jan)
```

Se clicar [Detalhes], vê:
```
Tipo de lançamento: historico
Origem: Lançador Rápido
Data de criação: 20 jan 2026
```

---

## 🎯 Checklist de Uso

- [ ] Rodei o `schema-v3-financeiro.sql` no Supabase
- [ ] Atualizei o sistema (F5 ou recarreguei)
- [ ] Vi os 3 novos botões em Financeiro → Cobranças
  - [ ] ➕ Lançamento avulso
  - [ ] 📊 Editor de período
  - [ ] 📦 Gestor de importações
- [ ] Testei o Lançador Rápido
- [ ] Testei o Editor de Período
- [ ] Testei o Gestor de Importações
- [ ] Importei uma planilha e revi o histórico
- [ ] Testei atualizar uma planilha (v1 → v2)

---

## 💡 Dicas

1. **Sempre marque como "Período anterior"** quando lançar dados de anos antigos
2. **Use o Lançador Rápido** para correções rápidas (1-3 lançamentos)
3. **Use o Editor de Período** para inserção em massa
4. **Guarde suas planilhas** — o sistema as identifica automaticamente
5. **Não delete planilhas** — atualize-as e reimporte

---

## 🆘 Problemas?

### "Lançamento aparece duplicado"
- Verifique no Gestor de Importações se há dois lotes iguais
- Use [↩️ Desfazer] para remover a importação errada

### "Planilha não reconhecida como atualização"
- Salve a planilha com o mesmo nome
- Certifique-se de que a estrutura (colunas) é a mesma

### "Saldo não bate com o esperado"
- Verifique se há lançamentos sem marcar como "pago"
- Use Editor de Período para ver o resumo de um intervalo

---

## 📞 Próximos Passos (Planejado)

- 🎯 Filtros por tipo de lançamento (mostrar só histórico, só importado, etc)
- 🎯 Relatório automático: "Saldo 2025 + Entradas 2026 = Novo saldo"
- 🎯 Editar lançamentos diretamente no Editor de Período
- 🎯 Integração com lotes de despesas

---

**Versão:** 3.0  
**Data:** janeiro 2026  
**Autor:** Sistema OAB/PA Master
