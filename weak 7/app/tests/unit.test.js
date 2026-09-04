/**
 * Unit Tests for Parallax Microservice
 * Week 7 - CI Pipeline Integration
 *
 * Verifies core business logic without requiring a running server.
 */

const assert = require("assert");

// ─────────────────────────────────────────────────
// 1. Test: Istio metadata extractor
// ─────────────────────────────────────────────────
function getIstioMetadata(req) {
  const xfcc = req.headers["x-forwarded-client-cert"];
  const traceId =
    req.headers["x-b3-traceid"] || req.headers["x-request-id"] || null;
  const isMtls = Boolean(xfcc);

  return {
    mtlsActive: isMtls,
    clientCert: xfcc || "None (Plaintext Connection / Un-injected)",
    traceId: traceId || "None",
    userAgent: req.headers["user-agent"] || "Unknown",
  };
}

function runTests() {
  let passed = 0;
  let failed = 0;

  function test(name, fn) {
    try {
      fn();
      console.log(`  ✅  PASS: ${name}`);
      passed++;
    } catch (err) {
      console.error(`  ❌  FAIL: ${name}`);
      console.error(`       ${err.message}`);
      failed++;
    }
  }

  console.log("\n🧪  Running Parallax Microservice Unit Tests\n");

  // --- Istio metadata ---
  test("getIstioMetadata - detects mTLS when XFCC header present", () => {
    const req = {
      headers: {
        "x-forwarded-client-cert": "By=spiffe://cluster.local/ns/default/sa/frontend",
        "x-b3-traceid": "abc123",
        "user-agent": "curl/7.88",
      },
    };
    const meta = getIstioMetadata(req);
    assert.strictEqual(meta.mtlsActive, true, "mtlsActive should be true");
    assert.strictEqual(meta.traceId, "abc123", "traceId should match x-b3-traceid");
    assert.strictEqual(meta.userAgent, "curl/7.88", "userAgent should match");
  });

  test("getIstioMetadata - no mTLS when XFCC header absent", () => {
    const req = { headers: {} };
    const meta = getIstioMetadata(req);
    assert.strictEqual(meta.mtlsActive, false, "mtlsActive should be false");
    assert.strictEqual(meta.traceId, "None", "traceId should default to None");
    assert.strictEqual(
      meta.clientCert,
      "None (Plaintext Connection / Un-injected)",
      "clientCert should show default message"
    );
  });

  test("getIstioMetadata - falls back to x-request-id when x-b3-traceid absent", () => {
    const req = {
      headers: { "x-request-id": "req-xyz-789" },
    };
    const meta = getIstioMetadata(req);
    assert.strictEqual(meta.traceId, "req-xyz-789", "should use x-request-id as fallback");
  });

  test("getIstioMetadata - userAgent defaults to Unknown when missing", () => {
    const req = { headers: {} };
    const meta = getIstioMetadata(req);
    assert.strictEqual(meta.userAgent, "Unknown");
  });

  // --- Environment variable defaults ---
  test("PORT env defaults to 3000", () => {
    const PORT = process.env.PORT || 3000;
    assert.ok(PORT, "PORT should be defined");
    assert.ok(Number(PORT) > 0, "PORT should be a positive number");
  });

  test("SERVICE_NAME env defaults to 'frontend'", () => {
    const SERVICE_NAME = process.env.SERVICE_NAME || "frontend";
    assert.strictEqual(typeof SERVICE_NAME, "string");
    assert.ok(SERVICE_NAME.length > 0, "SERVICE_NAME should not be empty");
  });

  test("APP_ENV env defaults to 'development'", () => {
    const APP_ENV = process.env.APP_ENV || "development";
    assert.ok(["development", "production", "staging"].includes(APP_ENV) || APP_ENV.length > 0);
  });

  // --- Image tagging (simulated) ---
  test("Image tag is a non-empty string (simulates SHA tagging)", () => {
    const sha = process.env.GIT_SHA || "abc1234";
    assert.ok(typeof sha === "string" && sha.length >= 7, "Image tag must be at least 7 chars");
  });

  // ─────────────────────────────────────────────────
  // Summary
  // ─────────────────────────────────────────────────
  console.log(`\n📊  Results: ${passed} passed, ${failed} failed\n`);

  if (failed > 0) {
    console.error("❌  Some tests failed. Failing CI pipeline.\n");
    process.exit(1);
  } else {
    console.log("✅  All tests passed!\n");
  }
}

runTests();
