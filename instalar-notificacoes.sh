#!/bin/bash
# Instala a função de notificações do OAB/PA Master no Supabase.
set -e
cd "$(dirname "$0")"
echo ""
echo "⚽ OAB/PA Master — instalação das notificações"
echo "=============================================="
echo ""
echo "1º) Vai abrir o navegador pedindo autorização do Supabase."
echo "    Clique em AUTORIZAR / ACCEPT e volte para esta janela."
echo ""
npx --yes supabase login
echo ""
echo "2º) Enviando a função de notificações..."
npx --yes supabase functions deploy push --project-ref pzodgfsekqpumvgigeii
echo ""
echo "3º) Cadastrando as chaves de notificação..."
PUB=$(python3 -c "import json;print(json.load(open('vapid.json'))['publicKey'])")
PRIV=$(python3 -c "import json;print(json.load(open('vapid.json'))['privateKey'])")
npx --yes supabase secrets set VAPID_PUBLIC_KEY="$PUB" VAPID_PRIVATE_KEY="$PRIV" --project-ref pzodgfsekqpumvgigeii
echo ""
echo "✅ PRONTO! Notificações instaladas com sucesso."
echo "   Pode fechar esta janela e avisar o Claude."
