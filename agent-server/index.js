const http = require('http');
const fs = require('fs');
const path = require('path');
const { WebSocketServer } = require('ws');
const { randomUUID } = require('crypto');

// ── 加载 .env（无需 dotenv 依赖）──
(() => {
    const envFile = path.join(__dirname, '.env');
    if (!fs.existsSync(envFile)) return;
    for (const line of fs.readFileSync(envFile, 'utf8').split('\n')) {
        const m = line.match(/^\s*([A-Z_][A-Z0-9_]*)\s*=\s*(.*)\s*$/);
        if (m && !process.env[m[1]]) process.env[m[1]] = m[2].replace(/^["']|["']$/g, '');
    }
})();

// ── Config（从环境变量读，见 .env.example）──
const PORT = process.env.PORT || 3000;
const AUTH_TOKEN = process.env.AUTH_TOKEN || '';
if (!AUTH_TOKEN) {
    console.error('[Config] 缺少 AUTH_TOKEN，请在 .env 里设置（参考 .env.example）');
    process.exit(1);
}

// ── Tool Registry ──
const tools = {};

function registerTool(method, handler) {
    tools[method] = handler;
    console.log('[Tools] Registered:', method);
}

// ── Auth ──
function authenticate(token) {
    return token === AUTH_TOKEN;
}

function extractToken(req) {
    const auth = req.headers['authorization'] || '';
    if (auth.startsWith('Bearer ')) return auth.slice(7);
    const url = new URL(req.url, 'http://localhost');
    return url.searchParams.get('token') || '';
}

// ── WebSocket Clients ──
const streamingTools = {};
function registerStreamingTool(method, handler){ streamingTools[method]=handler; console.log("[Tools] Registered streaming:", method); }

const wsClients = new Set();

function pushToPhone(method, params) {
    const msg = JSON.stringify({ method, params, id: randomUUID() });
    for (const ws of wsClients) {
        if (ws.readyState === 1) {
            ws.send(msg);
            console.log('[WS] Pushed:', method);
        }
    }
}

// ── Handle JSON-RPC Request ──
async function handleRequest(body) {
    const { method, params, id } = body;

    if (!method) {
        return { error: { code: -32600, message: 'Missing method' }, id };
    }

    const handler = tools[method];
    if (!handler) {
        return { error: { code: -32601, message: 'Unknown method: ' + method }, id };
    }

    try {
        const raw = await handler(params || {});
        // Always return an object, never a bare array
        const result = Array.isArray(raw) ? { items: raw } : raw;
        return { result, id };
    } catch (err) {
        console.error('[Error]', method, err.message);
        return { error: { code: -32000, message: err.message }, id };
    }
}

// ── HTTP Server ──
const server = http.createServer(async (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') { res.writeHead(200); res.end(); return; }

    if (req.url === '/health') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'ok', tools: Object.keys(tools), clients: wsClients.size }));
        return;
    }

    const token = extractToken(req);
    if (!authenticate(token)) {
        res.writeHead(401, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Unauthorized' }));
        return;
    }

    // 文件下载：GET /file?path=...&token=...（App 文件卡/视频卡点击时拉取）
    // 安全：只允许 agent 工作目录 / tmp 下的文件，禁止路径穿越。
    if (req.method === 'GET' && req.url.startsWith('/file')) {
        const u = new URL(req.url, 'http://localhost');
        const fp = path.resolve(u.searchParams.get('path') || '');
        const agentDir = process.env.AGENT_DIR || `${process.env.HOME}/claude-home-agent`;
        const allowed = [agentDir, '/tmp'];
        const ok = allowed.some((dir) => fp.startsWith(dir + '/') || fp === dir);
        if (!ok || !fs.existsSync(fp) || !fs.statSync(fp).isFile()) {
            res.writeHead(404, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ error: 'file not found' }));
            return;
        }
        const name = encodeURIComponent(path.basename(fp));
        res.writeHead(200, {
            'Content-Type': 'application/octet-stream',
            'Content-Disposition': `attachment; filename*=UTF-8''${name}`,
            'Content-Length': fs.statSync(fp).size,
        });
        fs.createReadStream(fp).pipe(res);
        return;
    }

    if (req.method !== 'POST' || req.url !== '/rpc') {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Not found. Use POST /rpc' }));
        return;
    }

    let body = '';
    for await (const chunk of req) body += chunk;

    let parsed;
    try { parsed = JSON.parse(body); } catch {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid JSON' }));
        return;
    }

    const result = await handleRequest(parsed);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(result));
});

// ── WebSocket Server ──
const wss = new WebSocketServer({ server });

wss.on('connection', (ws, req) => {
    const token = extractToken(req);
    if (!authenticate(token)) {
        ws.close(4001, 'Unauthorized');
        return;
    }

    wsClients.add(ws);
    console.log('[WS] Client connected. Total:', wsClients.size);

    ws.on('message', async (data) => {
        let parsed;
        try { parsed = JSON.parse(data); } catch { return; }
        if (parsed && streamingTools[parsed.method]) {
            const id = parsed.id || (parsed.params && parsed.params.id);
            const push = (method, params) => { if (ws.readyState===1) ws.send(JSON.stringify({ method, params, id })); };
            try { streamingTools[parsed.method](parsed.params||{}, push); } catch(e){ push("turn.error",{message:e.message}); }
            return;
        }
        const result = await handleRequest(parsed);
        ws.send(JSON.stringify(result));
    });

    ws.on('close', () => {
        wsClients.delete(ws);
        console.log('[WS] Client disconnected. Total:', wsClients.size);
    });

    ws.send(JSON.stringify({
        method: 'connected',
        params: { message: 'Agent VPS ready', tools: Object.keys(tools) }
    }));
});

// ── Built-in Tools ──

registerTool('ping', async () => {
    return { pong: true, time: new Date().toISOString(), tools: Object.keys(tools) };
});

registerTool('push_test', async (params) => {
    pushToPhone('notification', { title: 'Test', body: params.message || 'Hello from VPS' });
    return { pushed: true };
});

// ── Export for future tool modules ──
module.exports = { registerTool, registerStreamingTool, pushToPhone };

// ── Load tool modules ──
require('./ask');

// ── Start ──
server.listen(PORT, '0.0.0.0', () => {
    console.log('[Server] Agent VPS running on port ' + PORT);
    console.log('[Server] HTTP: POST /rpc');
    console.log('[Server] WS: ws://0.0.0.0:' + PORT + '?token=...');
});
