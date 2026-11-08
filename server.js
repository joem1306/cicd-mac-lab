const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const config = JSON.parse(fs.readFileSync(path.join(__dirname, 'version.json'), 'utf8'));
function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
}
function handler(req, res) {
  if (req.url === '/health') {
    res.writeHead(200, {'Content-Type':'text/plain','Cache-Control':'no-store'});
    return res.end('ok');
  }
  if (req.url === '/api/info') {
    res.writeHead(200, {'Content-Type':'application/json','Cache-Control':'no-store'});
    return res.end(JSON.stringify(config));
  }
  if (req.url !== '/') {
    res.writeHead(404, {'Content-Type':'text/plain'}); return res.end('Not found');
  }
  res.writeHead(200, {'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-store'});
  res.end(`<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>CI/CD Release Lab</title>
  <style>body{margin:0;font-family:system-ui,-apple-system,sans-serif;background:#0b1220;color:white;display:grid;min-height:100vh;place-items:center}
  main{max-width:680px;margin:24px;padding:42px;border:1px solid #334155;border-radius:24px;background:#111c30;box-shadow:0 20px 80px #0005}
  .tag{display:inline-block;padding:9px 14px;background:${escapeHtml(config.color)};border-radius:99px;font-weight:700}
  h1{font-size:clamp(28px,5vw,48px);line-height:1.1}p{color:#cbd5e1;font-size:19px}code{color:#93c5fd}
  </style><main><span class="tag">VERSION ${escapeHtml(config.version)}</span><h1>${escapeHtml(config.headline)}</h1>
  <p>${escapeHtml(config.message)}</p><p>Served by container: <code>${escapeHtml(process.env.HOSTNAME || 'local')}</code></p>
  <small>Refresh to check the current release. <a style="color:#93c5fd" href="/api/info">JSON API</a></small></main></html>`);
}
if (require.main === module) {
  http.createServer(handler).listen(3000, '0.0.0.0', () => console.log(`CI/CD lab ${config.version} listening on 3000`));
}
module.exports = {handler, config};
