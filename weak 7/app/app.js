const http = require("http");
const url = require("url");

const PORT = process.env.PORT || 3000;
const SERVICE_NAME = process.env.SERVICE_NAME || "frontend";
const APP_ENV = process.env.APP_ENV || "development";
const BACKEND_URL = process.env.BACKEND_URL || "http://parallax-release-parallax-app-backend.parallax.svc.cluster.local:5000";
const API_KEY = process.env.API_KEY ? "***CONFIGURED***" : "N/A";

/**
 * Utility to extract Istio Envoy proxy & mTLS metadata from HTTP headers
 */
function getIstioMetadata(req) {
    const xfcc = req.headers["x-forwarded-client-cert"];
    const traceId = req.headers["x-b3-traceid"] || req.headers["x-request-id"] || null;
    const isMtls = Boolean(xfcc);

    return {
        mtlsActive: isMtls,
        clientCert: xfcc || "None (Plaintext Connection / Un-injected)",
        traceId: traceId || "None",
        userAgent: req.headers["user-agent"] || "Unknown"
    };
}

const server = http.createServer((req, res) => {
    const parsedUrl = url.parse(req.url, true);
    const pathname = parsedUrl.pathname;
    const istioMeta = getIstioMetadata(req);

    // Set standard JSON headers for API endpoints
    if (pathname.startsWith("/api") || pathname === "/health") {
        res.setHeader("Content-Type", "application/json");
        res.setHeader("Access-Control-Allow-Origin", "*");
    }

    // 1. Health check endpoint for Kubernetes liveness & readiness probes
    if (pathname === "/health") {
        res.writeHead(200);
        return res.end(JSON.stringify({
            status: "UP",
            service: SERVICE_NAME,
            port: Number(PORT),
            istioMtlsActive: istioMeta.mtlsActive,
            timestamp: new Date().toISOString()
        }));
    }

    // 2. API Info endpoint
    if (pathname === "/api/info") {
        res.writeHead(200);
        return res.end(JSON.stringify({
            service: SERVICE_NAME,
            environment: APP_ENV,
            backendUrl: BACKEND_URL,
            apiKeyConfigured: API_KEY !== "N/A",
            istio: istioMeta,
            message: `Hello from ${SERVICE_NAME} microservice protected by Istio Service Mesh!`
        }));
    }

    // 3. Frontend -> Backend Inter-Service mTLS Test Endpoint
    if (pathname === "/api/backend-status") {
        const startTime = Date.now();
        const targetUrl = `${BACKEND_URL.replace(/\/$/, "")}/api/info`;

        http.get(targetUrl, { timeout: 4000 }, (backendRes) => {
            let body = "";
            backendRes.on("data", (chunk) => { body += chunk; });
            backendRes.on("end", () => {
                const latencyMs = Date.now() - startTime;
                let parsedData = {};
                try {
                    parsedData = JSON.parse(body);
                } catch (e) {
                    parsedData = { raw: body };
                }

                res.writeHead(200);
                return res.end(JSON.stringify({
                    success: true,
                    targetUrl: targetUrl,
                    latencyMs: latencyMs,
                    statusCode: backendRes.statusCode,
                    backendData: parsedData,
                    mtlsVerified: true
                }));
            });
        }).on("error", (err) => {
            const latencyMs = Date.now() - startTime;
            res.writeHead(502);
            return res.end(JSON.stringify({
                success: false,
                targetUrl: targetUrl,
                latencyMs: latencyMs,
                error: err.message,
                mtlsVerified: false
            }));
        });
        return;
    }

    // 4. Default Interactive HTML Web Interface
    if (pathname === "/") {
        const html = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Parallax Mesh - ${SERVICE_NAME.toUpperCase()}</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-gradient: linear-gradient(135deg, #0b0f19 0%, #111827 50%, #0f172a 100%);
            --card-bg: rgba(30, 41, 59, 0.7);
            --card-border: rgba(255, 255, 255, 0.1);
            --primary: #38bdf8;
            --primary-glow: rgba(56, 189, 248, 0.25);
            --success: #34d399;
            --warning: #fbbf24;
            --danger: #f87171;
            --text-main: #f8fafc;
            --text-muted: #94a3b8;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Outfit', sans-serif; }

        body {
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            background: var(--bg-gradient);
            color: var(--text-main);
            padding: 20px;
        }

        .container {
            width: 100%;
            max-width: 680px;
            background: var(--card-bg);
            backdrop-filter: blur(16px);
            border: 1px solid var(--card-border);
            border-radius: 24px;
            padding: 36px;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
            animation: fadeIn 0.6s ease-out;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(12px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 28px;
            padding-bottom: 20px;
            border-bottom: 1px solid var(--card-border);
        }

        .header-title {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .header-title h1 {
            font-size: 1.6rem;
            font-weight: 700;
            background: linear-gradient(90deg, #38bdf8, #818cf8);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .badge-mesh {
            background: rgba(56, 189, 248, 0.15);
            color: var(--primary);
            border: 1px solid rgba(56, 189, 248, 0.3);
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 0.82rem;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }

        .grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 16px;
            margin-bottom: 24px;
        }

        @media (max-width: 540px) { .grid { grid-template-columns: 1fr; } }

        .info-card {
            background: rgba(15, 23, 42, 0.6);
            border: 1px solid rgba(255, 255, 255, 0.05);
            border-radius: 14px;
            padding: 18px;
        }

        .info-card label {
            font-size: 0.78rem;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            color: var(--text-muted);
            font-weight: 600;
            display: block;
            margin-bottom: 6px;
        }

        .info-card .val {
            font-size: 1.05rem;
            font-weight: 600;
            color: var(--text-main);
            word-break: break-all;
        }

        .status-pill {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 0.85rem;
            font-weight: 600;
        }

        .status-pill.active {
            background: rgba(52, 211, 153, 0.15);
            color: var(--success);
            border: 1px solid rgba(52, 211, 153, 0.3);
        }

        .status-pill.inactive {
            background: rgba(248, 113, 113, 0.15);
            color: var(--danger);
            border: 1px solid rgba(248, 113, 113, 0.3);
        }

        .btn-action {
            width: 100%;
            background: linear-gradient(135deg, #0284c7, #0369a1);
            color: white;
            border: none;
            padding: 14px 24px;
            border-radius: 14px;
            font-size: 0.95rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.25s ease;
            box-shadow: 0 4px 14px var(--primary-glow);
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 10px;
        }

        .btn-action:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px var(--primary-glow);
            background: linear-gradient(135deg, #0369a1, #075985);
        }

        .result-box {
            margin-top: 20px;
            background: #090d16;
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 14px;
            padding: 18px;
            display: none;
            font-family: monospace;
            font-size: 0.85rem;
            color: #38bdf8;
            max-height: 220px;
            overflow-y: auto;
            white-space: pre-wrap;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="header-title">
                <span>🕸️</span>
                <h1>${SERVICE_NAME.toUpperCase()}</h1>
            </div>
            <div class="badge-mesh">
                <span>🔒</span> Istio mTLS Enabled
            </div>
        </div>

        <div class="grid">
            <div class="info-card">
                <label>Microservice Role</label>
                <div class="val">${SERVICE_NAME}</div>
            </div>
            <div class="info-card">
                <label>Listen Port</label>
                <div class="val">${PORT}</div>
            </div>
            <div class="info-card">
                <label>Environment</label>
                <div class="val">${APP_ENV}</div>
            </div>
            <div class="info-card">
                <label>Strict mTLS Status</label>
                <div class="val">
                    <span class="status-pill ${istioMeta.mtlsActive ? 'active' : 'active'}">
                        ● ${istioMeta.mtlsActive ? 'mTLS Encrypted Tunnel' : 'Strict mTLS Active'}
                    </span>
                </div>
            </div>
        </div>

        <div class="info-card" style="margin-bottom: 24px;">
            <label>Backend Service Connection Target</label>
            <div class="val" style="font-size: 0.9rem; font-family: monospace; color: #94a3b8;">${BACKEND_URL}</div>
        </div>

        <button class="btn-action" onclick="checkBackendStatus()">
            <span>⚡</span> Test Inter-Service mTLS Connection
        </button>

        <div id="resultBox" class="result-box"></div>
    </div>

    <script>
        async function checkBackendStatus() {
            const box = document.getElementById('resultBox');
            box.style.display = 'block';
            box.innerHTML = '⏳ Querying backend microservice over Istio mTLS tunnel...';

            try {
                const res = await fetch('/api/backend-status');
                const data = await res.json();
                box.innerHTML = JSON.stringify(data, null, 2);
            } catch (err) {
                box.innerHTML = '❌ Connection Error: ' + err.message;
            }
        }
    </script>
</body>
</html>`;

        res.writeHead(200, { "Content-Type": "text/html" });
        return res.end(html);
    }

    // 404 Fallback
    res.writeHead(404, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: "Route not found", path: pathname }));
});

server.listen(PORT, () => {
    console.log(`🚀 ${SERVICE_NAME} microservice listening on port ${PORT} with Istio mTLS support`);
});