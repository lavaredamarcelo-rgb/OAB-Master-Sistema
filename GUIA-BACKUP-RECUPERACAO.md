# 📦 Guia Completo: Backup e Recuperação do OAB/PA Master

## 🎯 Objetivo
Proteger os dados do sistema contra perda ou corrupção, com capacidade de restauração completa em caso de desastre.

---

## 📋 Arquivos de Backup

Foram criados 2 arquivos no seu projeto:

1. **`backup.js`** - Script de backup manual
2. **`backup-agendado.sh`** - Script para automação (crontab)

---

## 🚀 Como Usar

### **1. Fazer Backup Manual (Quando Quiser)**

```bash
cd /Users/marcelolavareda/OAB-Master-Sistema
node backup.js
```

**Resultado:**
- Cria arquivo: `backups/backup-YYYY-MM-DD.json`
- Exporta TODAS as 23 tabelas do Supabase
- Mostra relatório com quantidade de registros

**Exemplo de saída:**
```
📦 Iniciando backup...
  ⏳ Fazendo backup de: perfis
  ✅ perfis: 5 registros
  ⏳ Fazendo backup de: eventos
  ✅ eventos: 12 registros
  ... (mais tabelas)

✅ Backup criado: backups/backup-2026-08-05.json
📊 Total de registros: 145 registros
```

---

### **2. Agendar Backup Automático (Diariamente)**

#### **Opção A: Usar crontab (Linux/Mac)**

```bash
# Editar crontab
crontab -e

# Adicionar esta linha (roda todo dia às 2 da manhã):
0 2 * * * /Users/marcelolavareda/OAB-Master-Sistema/backup-agendado.sh >> /Users/marcelolavareda/OAB-Master-Sistema/backup.log 2>&1
```

**Verificar se funciona:**
```bash
# Ver próximas tarefas agendadas
crontab -l

# Ver logs dos backups
tail -f /Users/marcelolavareda/OAB-Master-Sistema/backup.log
```

#### **Opção B: Usar Launchd (Mac - Recomendado)**

Criar arquivo: `~/Library/LaunchAgents/com.oabmaster.backup.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.oabmaster.backup</string>
    
    <key>Program</key>
    <string>/Users/marcelolavareda/OAB-Master-Sistema/backup-agendado.sh</string>
    
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    
    <key>StandardOutPath</key>
    <string>/Users/marcelolavareda/OAB-Master-Sistema/backup.log</string>
    
    <key>StandardErrorPath</key>
    <string>/Users/marcelolavareda/OAB-Master-Sistema/backup-error.log</string>
</dict>
</plist>
```

**Ativar:**
```bash
launchctl load ~/Library/LaunchAgents/com.oabmaster.backup.plist
launchctl start com.oabmaster.backup
```

**Desativar:**
```bash
launchctl unload ~/Library/LaunchAgents/com.oabmaster.backup.plist
```

---

### **3. Restaurar Backup (Em Caso de Emergência)**

#### **Passo 1: Localizar backup disponível**

```bash
cd /Users/marcelolavareda/OAB-Master-Sistema
node backup.js restore 2026-08-05  # Mude a data conforme necessário
```

**Mostra:**
- Lista de backups disponíveis
- Quantos registros cada tabela tem

#### **Passo 2: Restaurar dados no Supabase**

⚠️ **IMPORTANTE**: A restauração é **manual e cuidadosa** para evitar sobrescrever dados incorretamente.

**Método 1: Via Supabase Dashboard (Mais Seguro)**

1. Abra: https://app.supabase.com/project/pzodgfsekqpumvgigeii
2. Vá para **SQL Editor**
3. Abra o arquivo de backup: `backups/backup-2026-08-05.json`
4. Copie os dados JSON
5. Execute as operações de INSERT manualmente
6. Verifique os dados antes de confirmar

**Método 2: Via Script (Automático - Em Desenvolvimento)**

```bash
# Futuramente, será possível fazer:
# node backup.js restore 2026-08-05 --confirm
```

---

## 📂 Estrutura de Backups

```
OAB-Master-Sistema/
├── backups/
│   ├── backup-2026-08-01.json    (semana 1)
│   ├── backup-2026-08-02.json    (semana 2)
│   ├── backup-2026-08-05.json    (backup mais recente)
│   └── ...
├── backup.js                      (script de backup)
├── backup-agendado.sh             (script agendado)
└── backup.log                      (logs dos backups)
```

**Cada arquivo JSON contém:**
```json
{
  "timestamp": "2026-08-05T10:30:00Z",
  "tabelas": {
    "perfis": [{ id: 1, nome: "João", ... }, ...],
    "eventos": [{ id: 1, nome: "Treino", ... }, ...],
    "cobrancas": [{ id: 1, valor: 100, ... }, ...],
    ...
  }
}
```

---

## 🔐 Estratégia de Proteção em Camadas

### **Camada 1: Código (Git)**
- ✅ Commits regulares no Git
- ✅ Histórico completo recuperável
- ✅ Branchs para desenvolvimento

### **Camada 2: Dados (Backups JSON)**
- ✅ Backup diário automático
- ✅ 7 dias de histórico
- ✅ Fácil de restaurar

### **Camada 3: Supabase Nativo**
- ⚠️ Backups automáticos (plano pago)
- ⚠️ Pontos de restauração (até 7-30 dias)
- ⚠️ Point-in-time recovery

### **Camada 4: Staging**
- 📋 TODO: Criar ambiente de teste
- 📋 TODO: Sincronizar dados semanais

---

## ⚡ Checklist de Segurança

- [ ] Script de backup criado
- [ ] Primeiro backup manual feito
- [ ] Crontab/Launchd configurado
- [ ] Logs de backup sendo gerados
- [ ] Verificou que backups estão em `backups/`
- [ ] Testou restauração (em staging, não produção)
- [ ] Documentou procedimento de emergência
- [ ] Compartilhou acesso de backup com co-admin

---

## 🆘 Procedimento de Emergência

**Se o sistema cair:**

1. **Backup automático?**
   ```bash
   ls -la backups/backup-*.json
   ```

2. **Código está em Git?**
   ```bash
   git log --oneline | head -5
   ```

3. **Restaurar código:**
   ```bash
   git reset --hard <commit-id>
   git push -f origin main  # ⚠️ Use com cuidado!
   ```

4. **Restaurar dados:**
   ```bash
   node backup.js restore <data>
   ```

5. **Testar em localhost:**
   ```bash
   python3 -m http.server 8003
   # Abra http://localhost:8003/index.html
   ```

6. **Fazer deploy:**
   ```bash
   git push origin main
   # Vercel fará deploy automaticamente
   ```

---

## 📊 Relatório de Status

Execute para ver status completo:

```bash
#!/bin/bash
echo "📦 Status de Backup OAB/PA Master"
echo "=================================="
echo ""
echo "Código (Git):"
git log --oneline -1

echo ""
echo "Backups disponíveis:"
ls -lh backups/backup-*.json | wc -l
echo "Backup mais recente:"
ls -1t backups/backup-*.json | head -1

echo ""
echo "Logs de backup:"
tail -5 backup.log
```

---

## 🎓 Próximas Melhorias Recomendadas

1. **Supabase Backup Automático** (pago)
   - Backups automáticos cada hora
   - Retenção de 7-30 dias
   - Point-in-time recovery

2. **AWS S3 Replication**
   - Cópia dos backups em nuvem
   - Proteção contra perda local

3. **Slack Notifications**
   - Alertar quando backup falha
   - Relatório diário de status

4. **Versionamento de Schema**
   - Versionar mudanças de tabelas
   - Rollback de alterações acidentais

---

## 📞 Suporte

Se precisar de ajuda:
1. Verifique os logs: `tail -f backup.log`
2. Teste manualmente: `node backup.js`
3. Verifique conectividade Supabase
4. Restaure código do Git se necessário

