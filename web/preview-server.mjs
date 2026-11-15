// Development-only static server matching production gzip and MIME behavior.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
const root = path.resolve('../build/cloudrun/public');
const types = {'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.json':'application/json','.css':'text/css','.wasm':'application/wasm','.pck':'application/octet-stream','.png':'image/png','.svg':'image/svg+xml'};
http.createServer((request,response) => {
  let pathname;
  try { pathname = decodeURIComponent(new URL(request.url,'http://localhost').pathname); } catch { response.writeHead(400).end(); return; }
  if (pathname === '/health') { response.writeHead(200).end('ok'); return; }
  let file = path.resolve(root,'.' + pathname);
  if (file !== root && !file.startsWith(root + path.sep)) { response.writeHead(403).end(); return; }
  if (fs.existsSync(file) && fs.statSync(file).isDirectory()) file = path.join(file,'index.html');
  if (!fs.existsSync(file)) { response.writeHead(404).end(); return; }
  const headers = {'Content-Type': types[path.extname(file)] || 'application/octet-stream','Cache-Control':'no-store'};
  if ((request.headers['accept-encoding'] || '').includes('gzip') && fs.existsSync(file + '.gz')) { file += '.gz'; headers['Content-Encoding'] = 'gzip'; headers.Vary = 'Accept-Encoding'; }
  headers['Content-Length'] = fs.statSync(file).size;
  response.writeHead(200,headers);
  fs.createReadStream(file).pipe(response);
}).listen(8088,'127.0.0.1',() => console.log('Web preview http://127.0.0.1:8088'));
