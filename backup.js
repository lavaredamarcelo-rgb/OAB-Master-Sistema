#!/usr/bin/env node
/**
 * Script de Backup Automático para OAB/PA Master
 *
 * Uso:
 *   node backup.js              # Faz backup de HOJE
 *   node backup.js restore DATE # Restaura backup de DATA (YYYY-MM-DD)
 *
 * Exempolo:
 *   node backup.js
 *   node backup.js restore 2026-08-05
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

const SUPABASE_URL = 'https://pzodgfsekqpumvgigeii.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB6b2RnZnNla3FwdW12Z2lnZWlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQyNjEyNzYsImV4cCI6MjA5OTgzNzI3Nn0.-tQn-ECR6t-waBBuihIesi6LhxJ3s22xORzR3OwMoeQ';

const TABELAS = [
  'perfis', 'eventos', 'presencas', 'cobrancas', 'despesas',
  'avaliacoes', 'metas', 'stats', 'uniformes', 'inventario',
  'saude', 'taticas_confrontos', 'taticas_esquemas', 'taticas_notas',
  'uniforme_numeros_historico', 'documentos', 'logs', 'config',
  'import_lotes', 'balanco_receitas', 'patrocinadores', 'push_subs',
  'tarefas'
];

const BACKUP_DIR = path.join(__dirname, 'backups');

// Garantir que pasta de backups existe
if (!fs.existsSync(BACKUP_DIR)) {
  fs.mkdirSync(BACKUP_DIR, { recursive: true });
}

// Função para fazer requisição HTTPS
function httpRequest(method, path, body = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'pzodgfsekqpumvgigeii.supabase.co',
      path: `/rest/v1${path}`,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'apikey': SUPABASE_KEY,
        'Prefer': 'return=representation'
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(data ? JSON.parse(data) : null);
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

// Função para fazer backup
async function fazBackup() {
  console.log('📦 Iniciando backup...');

  const timestamp = new Date().toISOString().split('T')[0];
  const backupPath = path.join(BACKUP_DIR, `backup-${timestamp}.json`);

  if (fs.existsSync(backupPath)) {
    console.log(`⚠️  Backup de hoje já existe: ${backupPath}`);
    return backupPath;
  }

  const backup = { timestamp: new Date().toISOString(), tabelas: {} };

  for (const tabela of TABELAS) {
    try {
      console.log(`  ⏳ Fazendo backup de: ${tabela}`);
      const dados = await httpRequest('GET', `/${tabela}?limit=10000`);
      backup.tabelas[tabela] = dados || [];
      console.log(`  ✅ ${tabela}: ${(dados || []).length} registros`);
    } catch (err) {
      console.log(`  ⚠️  ${tabela}: ${err.message}`);
      backup.tabelas[tabela] = [];
    }
  }

  fs.writeFileSync(backupPath, JSON.stringify(backup, null, 2));

  console.log(`\n✅ Backup criado: ${backupPath}`);
  console.log(`📊 Total de registros:`);

  let totalRegistros = 0;
  Object.entries(backup.tabelas).forEach(([tab, dados]) => {
    const count = dados.length;
    if (count > 0) {
      console.log(`   ${tab}: ${count}`);
      totalRegistros += count;
    }
  });
  console.log(`   TOTAL: ${totalRegistros} registros\n`);

  return backupPath;
}

// Função para restaurar backup
async function restaurarBackup(data) {
  const backupPath = path.join(BACKUP_DIR, `backup-${data}.json`);

  if (!fs.existsSync(backupPath)) {
    console.error(`❌ Backup não encontrado: ${backupPath}`);
    console.log(`\n📁 Backups disponíveis:`);
    fs.readdirSync(BACKUP_DIR)
      .filter(f => f.startsWith('backup-'))
      .sort()
      .reverse()
      .slice(0, 10)
      .forEach(f => console.log(`   ${f}`));
    process.exit(1);
  }

  console.log(`📂 Restaurando backup: ${data}`);

  const backup = JSON.parse(fs.readFileSync(backupPath, 'utf8'));

  // ⚠️ PERIGOSO: Isso deletaria dados existentes
  console.log('\n⚠️  AVISO: Esta ação irá sobrescrever os dados atuais!');
  console.log('Para restaurar, você precisa fazer manualmente via Supabase Dashboard:');
  console.log('');
  console.log('1. Abra: https://app.supabase.com/project/pzodgfsekqpumvgigeii');
  console.log('2. Editor SQL → Novo Query');
  console.log(`3. Arquivo: ${backupPath}`);
  console.log('4. Copie e execute os dados manualmente ou use: supabase db push\n');

  console.log('Dados disponíveis para restaurar:');
  Object.entries(backup.tabelas).forEach(([tab, dados]) => {
    if (dados.length > 0) {
      console.log(`   ${tab}: ${dados.length} registros`);
    }
  });
}

// Main
async function main() {
  const cmd = process.argv[2];

  try {
    if (cmd === 'restore' && process.argv[3]) {
      await restaurarBackup(process.argv[3]);
    } else if (!cmd || cmd === 'backup') {
      await fazBackup();
    } else {
      console.log('Uso: node backup.js [backup|restore DATA]');
      console.log('  node backup.js          # Faz backup de hoje');
      console.log('  node backup.js restore 2026-08-05  # Restaura backup');
    }
  } catch (err) {
    console.error(`\n❌ Erro: ${err.message}`);
    process.exit(1);
  }
}

main();
