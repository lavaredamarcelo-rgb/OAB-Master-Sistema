// Função "push" — envia notificações aos aparelhos inscritos.
// Segredos necessários: VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY
import { createClient } from 'npm:@supabase/supabase-js@2';
import webpush from 'npm:web-push@3';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  try {
    const auth = req.headers.get('Authorization') || '';
    const anon = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: auth } } }
    );
    const { data: { user } } = await anon.auth.getUser();
    if (!user) return new Response('não autenticado', { status: 401, headers: CORS });
    const { data: perfil } = await anon.from('perfis').select('role').eq('id', user.id).single();
    if (!perfil || !['diretoria', 'treinador', 'auxiliar'].includes(perfil.role))
      return new Response('sem permissão', { status: 403, headers: CORS });

    const { titulo, corpo, url } = await req.json();
    webpush.setVapidDetails(
      'mailto:lavaredamarcelo@gmail.com',
      Deno.env.get('VAPID_PUBLIC_KEY')!,
      Deno.env.get('VAPID_PRIVATE_KEY')!
    );
    const svc = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    const { data: subs } = await svc.from('push_subs').select('id,sub');
    let enviados = 0;
    for (const s of subs || []) {
      try {
        await webpush.sendNotification(s.sub as any, JSON.stringify({ titulo, corpo, url }));
        enviados++;
      } catch (e: any) {
        if (e && (e.statusCode === 410 || e.statusCode === 404))
          await svc.from('push_subs').delete().eq('id', s.id);
      }
    }
    return new Response(JSON.stringify({ enviados }), {
      headers: { ...CORS, 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response('erro: ' + (e as Error).message, { status: 500, headers: CORS });
  }
});
