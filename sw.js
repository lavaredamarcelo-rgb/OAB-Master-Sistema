self.addEventListener('install',e=>self.skipWaiting());
self.addEventListener('activate',e=>e.waitUntil(clients.claim()));
self.addEventListener('push',e=>{
  let d={}; try{ d=e.data?e.data.json():{}; }catch(_){ d={corpo:e.data&&e.data.text()}; }
  e.waitUntil(self.registration.showNotification(d.titulo||'⚽ OAB/PA Master',{
    body:d.corpo||'', icon:'/escudo-192.png', badge:'/escudo-192.png', data:{url:d.url||'/'}
  }));
});
self.addEventListener('notificationclick',e=>{
  e.notification.close();
  e.waitUntil(clients.matchAll({type:'window'}).then(ws=>{
    for(const w of ws){ if('focus' in w) return w.focus(); }
    return clients.openWindow(e.notification.data&&e.notification.data.url||'/');
  }));
});
