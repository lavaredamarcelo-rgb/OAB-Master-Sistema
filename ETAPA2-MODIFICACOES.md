# 🔧 ETAPA 2: Modificações no index.html

## Modificações Necessárias

### 1. Reorganizar Financeiro (função tFin)

**O que fazer:**
- Renomear "Despesas" para "Balanço"
- Dentro de Balanço, adicionar 2 sub-abas: "Receitas" e "Despesas"

**Modificar em tFin():**
```javascript
// ANTES:
return `<div class="tabbtns">
  <button class="${sub==='c'?'on':''}" onclick="subState.finTab='c';renderTab()">💰 Cobranças</button>
  <button class="${sub==='d'?'on':''}" onclick="subState.finTab='d';renderTab()">🧾 Despesas do time</button>
  ...

// DEPOIS:
return `<div class="tabbtns">
  <button class="${sub==='c'?'on':''}" onclick="subState.finTab='c';renderTab()">💰 Cobranças</button>
  <button class="${sub==='b'?'on':''}" onclick="subState.finTab='b';renderTab()">📊 Balanço</button>
  ...
```

**Criar tFinBalanco():**
Nova função que mostra:
- Sub-abas: "Receitas" | "Despesas"
- Receitas consolidadas (automáticas) + manuais
- Despesas gerais
- Saldo total = Receitas - Despesas

### 2. Melhorar Uniformes (função tUni)

**CRUD de Materiais:**
- [✏️ Editar] — Modal para editar nome, marca, cor, detalhes
- [✕] — Deletar material
- [+] — Adicionar novo material

**Numeração Flexível:**
- Interface para adicionar números: "1-10,15,33"
- Remover números específicos
- Entregar/devolver números

### 3. Funções Novas Necessárias

```javascript
// Consolidar cobranças pagas automaticamente
async function consolidaCobracas()
async function desconsolidaCobanca(id)

// CRUD de Materiais
async function editaMaterial(id)
async function deletaMaterial(id)
async function novaMaterial()

// Numeração
async function adicionaNumeros(uniformeId, especificacao)
async function removeNumero(uniformeId, numero)
async function entregrNumero(uniformeId, numero, atletaId)
async function devolveNumero(uniformeId, numero)
```

---

## Estratégia de Implementação

Como há MUITO código, vou fazer em 3 passos:

**PASSO 1:** Deploy parcial com Balanço básico
**PASSO 2:** Deploy com CRUD de Uniformes
**PASSO 3:** Polish e integração completa

Isso vai ser mais rápido do que fazer tudo de uma vez.

---

## Status Atual

✅ Schemas SQL rodados com sucesso
✅ carregaTudo() atualizado para carregar novos dados
⏳ Faltam: Modificações na UI (tFin + tUni + funções novas)

---

**Próximo passo:** Implementar as modificações. Quer que eu comece?
