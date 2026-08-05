#!/bin/bash
# Script para rodar backup automaticamente
# Coloque isso em crontab para rodar diariamente
#
# Uso em crontab (executa todo dia às 2 da manhã):
#   0 2 * * * /Users/marcelolavareda/OAB-Master-Sistema/backup-agendado.sh >> /Users/marcelolavareda/OAB-Master-Sistema/backup.log 2>&1

cd /Users/marcelolavareda/OAB-Master-Sistema

echo "🔄 Iniciando backup agendado: $(date)"
node backup.js

if [ $? -eq 0 ]; then
  echo "✅ Backup completado com sucesso: $(date)"
else
  echo "❌ Erro no backup: $(date)"
  exit 1
fi
