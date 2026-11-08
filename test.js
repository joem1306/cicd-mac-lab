const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const {handler,config} = require('./server');
function request(url) {
  return new Promise((resolve,reject)=>{
    const server=http.createServer(handler).listen(0,'127.0.0.1',()=>{
      http.get(`http://127.0.0.1:${server.address().port}${url}`,res=>{
        let body=''; res.on('data',chunk=>body+=chunk);
        res.on('end',()=>server.close(()=>resolve({status:res.statusCode,body,headers:res.headers})));
      }).on('error',reject);
    });
    server.on('error',reject);
  });
}
test('version metadata is valid',()=>{
  assert.match(config.version,/^\d+\.\d+\.\d+$/);
  assert.match(config.color,/^#[0-9a-fA-F]{6}$/);
  assert.ok(config.headline.length>5);
});
test('health endpoint responds',async()=>{
  const r=await request('/health');assert.equal(r.status,200);assert.equal(r.body,'ok');
});
test('API exposes same version',async()=>{
  const r=await request('/api/info');assert.equal(r.status,200);
  assert.equal(JSON.parse(r.body).version,config.version);
});
test('homepage visibly displays version and headline',async()=>{
  const r=await request('/');assert.equal(r.status,200);
  assert.ok(r.body.includes(`VERSION ${config.version}`));
  assert.ok(r.body.includes(config.headline));
});
test('unknown path is 404',async()=>{
  assert.equal((await request('/not-found')).status,404);
});
