// 部署到 VPS: ~/agent-server/ask.js
// 在 agent-server 里注册一个 `ask` streaming method。
//
// 【v2 / ACP 常驻】之前每次提问都 spawn 一个 `claude -p --resume` 冷启动进程，
// 每次都要重读 CLAUDE.md、重放历史、重连 MCP —— 这就是 App 比微信/telegram 慢的根因。
// 现在改成和 telegram/微信一样：复用一个常驻的 claude-agent-acp 进程 + 固定会话，
// 进程只启动一次，之后每次提问近乎零启动开销，并实时流式推 block。
//
// 协议（App 端，未变）：
//   App 发:   { method:"ask", params:{ prompt:"...", id:"xxx" } }
//   服务器推: { method:"turn.start", id }
//             { method:"turn.block", params:{ index, block }, id }
//             { method:"turn.done",  params:{ count }, id }
//             { method:"turn.error", params:{ message }, id }

const { spawn } = require('child_process');
const { Readable, Writable } = require('node:stream');
const fs = require('node:fs');
const { registerStreamingTool } = require('./index');
const { markdownToBlocks } = require('./markdownToBlocks');

// agent 工作目录（CLAUDE.md / memory / 工具所在；指向你的 claude-home-agent 部署目录）。配置见 .env
const AGENT_DIR = process.env.AGENT_DIR || `${process.env.HOME}/claude-home-agent`;
const ACP_BIN = 'claude-agent-acp';
const MODEL = process.env.CLAUDE_MODEL || (() => {
    try { return fs.readFileSync(`${AGENT_DIR}/model.txt`, 'utf8').trim() || 'claude-opus-4-8'; }
    catch { return 'claude-opus-4-8'; }
})();

const RICH_UI_PROMPT = `【铁律，必须遵守】
1. 只输出给用户看的最终回答，绝不输出你的思考过程、内心独白、英文分析（如 "User wants...", "I already have..."）。
2. 任何 URL/链接都不准出现在正文文字里——链接只能放在卡片的 amapURL 等字段内。
3. 卡片里已经有的信息（地点名、距离、时长、价格等），不要在文字里重复。文字只写卡片没有的简短上下文。
4. 导航卡的 amapURL 必须用 iosamap:// 开头，不要 https。

你的回答会被渲染成生成式 UI 卡片（类似新版 Siri）。请用 markdown，并在合适时用扩展语法。

【最重要：先文字铺垫，卡片只放纯数据】涉及专属卡片时，先用一句简短自然语言说明上下文/建议，再换行给卡片。卡片里只放纯数据，不要把建议/上下文塞进卡片字段。例如问天气：先写「周日天气很适合打网球：」，下一行给 ::weather 卡（卡里不带穿衣建议，建议写在上面那句话里）。

【通用块】
- 标题 ## ；要点 - 列表；对比数据用表格。
- 提醒/警告独占一行：::callout[info]{💡} 标题 | 正文
- 来源标注：::source 来源名 +3

【专属卡片】（独占一行 + 一行合法 JSON；查到真实数据后填入，查不到退回文字）
- 天气：::weather {"city":"东京","temp":22,"condition":"多云转晴","icon":"🌤","high":24,"low":16}
- 智能家居（查 HA 真实状态）：::devices {"items":[{"name":"客厅氛围灯","on":true,"detail":"暖白60%"},{"name":"餐厅灯","on":false}]}
- 股票：::stock {"name":"贵州茅台","code":"600519","price":1680.5,"change":12.3,"changePct":0.74}
- 打车（行程进度卡）：::ride {"carType":"滴滴专车","dest":"浦东机场","eta":"20:22 到达","status":"前往目的地","plate":"沪A·8888","driver":"王师傅 4.9★","price":48,"progress":0.45}（progress 是 0~1 的行程进度，会画一条带小车的轨道；接驾途中可给小值，快到给大值；不知道就省略）
- 导航：**必须带终点经纬度 toLat/toLng（拿不到坐标就别用导航卡，改用文字）；amapURL 用 iosamap:// 开头的 scheme，不要 https；绝对不要把任何链接/URL 写进正文文字里**：::navigation {"from":"人民广场","to":"浦东机场","distance":"42.5公里","duration":"约48分钟","summary":"走S1沪芦高速","amapURL":"iosamap://path?dlat=31.1443&dlon=121.8083&dname=浦东机场&dev=0&t=0","toLat":31.1443,"toLng":121.8083,"fromLat":31.2304,"fromLng":121.4737}
- 提醒/日程：::reminder {"title":"和Ken吃午饭","time":"今天 12:00-13:30","due":"2026-06-13T12:00:00","note":"东南角石凳旁"}（time 给人看；due 是机器可读的本地 ISO8601 开始时刻 YYYY-MM-DDTHH:mm:ss，区间取起点，务必带上以便加入系统提醒并倒计时）
- 火车票（12306）：**查到车次必须用 ::train 卡，禁止用 markdown 表格列车次；多趟车就发多张 ::train（每张独占一行），一张卡只放一趟车**：::train {"number":"G1234","date":"7月1日","fromStation":"上海虹桥","toStation":"北京南","departTime":"09:15","arriveTime":"13:48","duration":"4h33m","seats":[{"name":"二等座","price":553,"remaining":"有票"},{"name":"一等座","price":933,"remaining":"12张"},{"name":"商务座","price":1748,"remaining":"无"}]}
- 瑞幸咖啡（调瑞幸工具拿到数据后用）：**列菜单/多款咖啡时禁止用 markdown 表格，必须每款一张 ::coffee 卡（独占一行）**。菜单态填 originalPrice(原价划线)+price(到手价)+badge(如"新品"/"首创")；已下单态填 store+pickup+status。**有商品图就填 imageURL（会显示真实图）**。例：::coffee {"name":"生椰拿铁","spec":"大杯 · 冰","originalPrice":20,"price":16.6,"badge":"首创","imageURL":"https://...","icon":"☕️"}
- 美团优惠券（领券/查券后用；多张券发多张卡）：::coupon {"title":"满30减15","amount":"¥15","threshold":"满30元可用","validUntil":"6月30日到期","scope":"全场通用","brand":"美团外卖"}
- 美团酒店（查到酒店后用；多家发多张卡，一张卡一家；**有酒店图就填 imageURL，会作为顶部 banner 显示**）：::hotel {"name":"全季酒店(人民广场店)","rating":4.8,"price":328,"area":"南京路步行街","roomType":"高级大床房","distance":"距您1.2km","tags":["免费取消","含早餐"],"imageURL":"https://..."}

【文件与视频】生成了 Excel/Word/PPT/PDF 等文件，或要发视频时，在回复里写标记（独占一行），App 会渲染成可点击的文件卡 / 内联视频：
- 文件：[send_file:/绝对路径/报表.xlsx]（支持 xlsx/docx/pptx/pdf/csv 等；先一句话说明这是什么文件，再给标记）
- 视频：[send_video:/绝对路径/clip.mp4]
路径必须是 agent 工作目录或 /tmp 下的真实文件绝对路径。不要把路径写进正文当文字解释。

原则：先一句文字铺垫，再用专属卡片；其次结构化块；最后才长段落。简短问题简短答。保持你原有工具能力和人格。不要解释这些语法。`;

const GREETINGS = /^(你好|您好|hi|hello|hey|在吗|哈喽|嗨|早|谢谢|多谢|thanks?|ok|好的)[\s!！。.~]*$/i;

// ── ACP 常驻连接（进程级单例） ──
let acpMod = null;          // 动态 import 的 ESM SDK
let acpProc = null;
let acpConn = null;
let acpReady = false;
let appSessionId = null;
let systemPrompted = false; // RICH_UI_PROMPT 只在会话第一轮注入
const collectors = new Map();

async function loadSdk() {
    if (!acpMod) acpMod = await import('@agentclientprotocol/sdk');
    return acpMod;
}

async function ensureAcp() {
    if (acpReady && acpConn) return acpConn;
    const { ClientSideConnection, PROTOCOL_VERSION, ndJsonStream } = await loadSdk();

    console.log('[Ask] spawning claude-agent-acp (常驻)...');
    const proc = spawn(ACP_BIN, [], {
        stdio: ['pipe', 'pipe', 'inherit'],
        env: {
            ...process.env,
            CLAUDE_MODEL: MODEL,
            NODE_OPTIONS: '--max-old-space-size=256',
            PATH: `${AGENT_DIR}/node_modules/.bin:${process.env.PATH}`,
        },
        cwd: AGENT_DIR,
    });
    acpProc = proc;
    proc.on('exit', (code) => {
        console.log('[Ask] acp exited code=' + code + '，下次提问会自动重启');
        acpReady = false; acpConn = null; acpProc = null;
        appSessionId = null; systemPrompted = false; collectors.clear();
        // 关键：进程崩溃时，正在 await conn.prompt 的请求会永久挂起 → askBusy 永远 true
        // → 整个串行队列死锁。这里主动给在途请求推 error 并释放队列。
        if (inFlight) { inFlight.fail('助手进程中断了，请重试'); }
    });

    const conn = new ClientSideConnection((_agent) => ({
        sessionUpdate: async (params) => {
            const collector = collectors.get(params.sessionId);
            if (collector) collector.handleUpdate(params);
        },
        // App 端不弹权限：全自动批准（和 telegram 一致）
        requestPermission: async (params) => {
            const opt = params.options && params.options[0];
            return { outcome: { outcome: 'selected', optionId: (opt && opt.optionId) || 'allow' } };
        },
    }), ndJsonStream(Writable.toWeb(proc.stdin), Readable.toWeb(proc.stdout)));

    await conn.initialize({
        protocolVersion: PROTOCOL_VERSION,
        clientInfo: { name: 'agent-server-ask', version: '2.0.0' },
        clientCapabilities: {},
    });
    console.log('[Ask] ACP ready (model=' + MODEL + ')');
    acpConn = conn; acpReady = true;
    return conn;
}

async function getSession() {
    if (appSessionId) return appSessionId;
    const conn = await ensureAcp();
    const res = await conn.newSession({ cwd: AGENT_DIR, mcpServers: [] });
    appSessionId = res.sessionId;
    systemPrompted = false;
    console.log('[Ask] session created: ' + appSessionId);
    return appSessionId;
}

// 流式收集器：每个 agent_message_chunk 到达就累积文本并 reflow 推 block。
class StreamCollector {
    constructor(push) {
        this.push = push;
        this.curText = '';
        this.pushed = [];
        this.started = false;
    }
    ensureStart() { if (!this.started) { this.started = true; this.push('turn.start', {}); } }
    reflow() {
        this.ensureStart();
        const blocks = markdownToBlocks(this.curText);
        for (let i = 0; i < blocks.length; i++) {
            const next = JSON.stringify(blocks[i]);
            if (this.pushed[i] !== next) { this.push('turn.block', { index: i, block: blocks[i] }); this.pushed[i] = next; }
        }
    }
    handleUpdate(notification) {
        const update = notification.update;
        if (update.sessionUpdate === 'agent_message_chunk') {
            const c = update.content;
            if (c && c.type === 'text' && c.text) { this.curText += c.text; this.reflow(); }
        }
    }
    count() { return this.pushed.length; }
}

// 当前在跑的请求（供 ACP 崩溃时主动收尾，避免队列死锁）
let inFlight = null;

async function runAsk(params, push, done) {
    const finish = (() => { let called = false; return () => { if (!called) { called = true; inFlight = null; done(); } }; })();
    // 注册在途请求：ACP 进程崩溃时由 exit handler 调用 fail()
    inFlight = { fail: (msg) => { try { push('turn.error', { message: msg }); } catch {} finish(); } };
    const prompt = (params && params.prompt) || '';
    // 图片（base64）+ mime；有图时即使没文字也照常处理（看图回答）
    const imageB64 = params && params.image;
    const imageMime = (params && params.imageMime) || 'image/jpeg';
    if (!prompt && !imageB64) { push('turn.error', { message: 'empty prompt' }); finish(); return; }

    // 闲聊快路径（仅纯文字闲聊；带图一律进 ACP）
    if (!imageB64 && GREETINGS.test(prompt.trim())) {
        push('turn.start', {});
        push('turn.block', { index: 0, block: { type: 'text', text: '你好 👋 有什么可以帮你的？' } });
        push('turn.done', { count: 1 });
        finish();
        return;
    }

    let collector = null;
    let sessionId = null;
    try {
        const conn = await ensureAcp();
        sessionId = await getSession();
        collector = new StreamCollector(push);
        collectors.set(sessionId, collector);

        // RICH_UI_PROMPT 只在会话首轮注入（之后 claude 已记住，避免每轮重复浪费 token）
        const textPart = prompt || '请看这张图片。';
        const userText = systemPrompted ? textPart : (RICH_UI_PROMPT + '\n\n———\n用户问：' + textPart);
        systemPrompted = true;

        // ACP prompt 数组：先文字，再图片块（有图才加）。格式同 telegram。
        const promptBlocks = [{ type: 'text', text: userText }];
        if (imageB64) {
            promptBlocks.push({ type: 'image', data: imageB64, mimeType: imageMime });
        }
        // 超时兜底：ACP 卡住（不崩溃也不返回）时，180s 后放弃，避免队列永久占用。
        const PROMPT_TIMEOUT = 180000;
        await Promise.race([
            conn.prompt({ sessionId, prompt: promptBlocks }),
            new Promise((_, rej) => setTimeout(() => rej(new Error('响应超时')), PROMPT_TIMEOUT)),
        ]);

        // 收尾：把最终文本再 reflow 一次，确保最后一块也推到
        if (collector.started) collector.reflow();
        if (!collector.started) {
            // 一个 chunk 都没来（极少见）→ 给个兜底
            push('turn.start', {});
            push('turn.block', { index: 0, block: { type: 'text', text: '（没有返回内容）' } });
        }
        push('turn.done', { count: collector.count() });
        finish();
    } catch (e) {
        console.error('[Ask] error:', e && e.message);
        push('turn.error', { message: (e && e.message) || 'ask failed' });
        finish();
    } finally {
        if (sessionId) collectors.delete(sessionId);
    }
}

// 串行队列：app 的请求排队，一个跑完才放下一个（同一会话不能并发 prompt）。
const askQueue = [];
let askBusy = false;
function drainAsk() {
    if (askBusy || askQueue.length === 0) return;
    askBusy = true;
    const { params, push } = askQueue.shift();
    let released = false;
    const done = () => { if (released) return; released = true; askBusy = false; setImmediate(drainAsk); };
    try { runAsk(params, push, done); }
    catch (e) { try { push('turn.error', { message: e.message }); } catch {} done(); }
}
function askHandler(params, push) {
    askQueue.push({ params, push });
    drainAsk();
}

registerStreamingTool('ask', askHandler);
console.log('[Ask] streaming tool registered (ACP 常驻模式)');

// 启动即预热 ACP，省掉第一条消息的冷启动等待
ensureAcp().then(() => getSession()).catch(e => console.error('[Ask] prewarm failed:', e && e.message));
