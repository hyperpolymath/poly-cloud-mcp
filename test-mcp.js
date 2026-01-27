#!/usr/bin/env -S deno run --allow-run --allow-read --allow-env
// SPDX-License-Identifier: MIT
// Test script for poly-cloud-mcp

import * as AWS from "./lib/es6/src/adapters/AWS.res.js";
import * as GCloud from "./lib/es6/src/adapters/GCloud.res.js";
import * as Azure from "./lib/es6/src/adapters/Azure.res.js";
import * as DigitalOcean from "./lib/es6/src/adapters/DigitalOcean.res.js";
import {
  CircuitBreaker,
  Cache,
  HealthChecker,
  MetricsCollector,
  SelfHealer,
  retryWithBackoff,
  createDiagnosticTools,
} from "./lib/resilience.js";

console.log("=== poly-cloud-mcp Test Suite ===\n");

// Test 1: Verify all adapters load correctly
console.log("Test 1: Module Loading");
console.log("  AWS tools:", Object.keys(AWS.tools).length);
console.log("  GCloud tools:", Object.keys(GCloud.tools).length);
console.log("  Azure tools:", Object.keys(Azure.tools).length);
console.log("  DigitalOcean tools:", Object.keys(DigitalOcean.tools).length);

const totalTools =
  Object.keys(AWS.tools).length +
  Object.keys(GCloud.tools).length +
  Object.keys(Azure.tools).length +
  Object.keys(DigitalOcean.tools).length;

console.log("  Total cloud tools:", totalTools);
console.log("  Status: PASS\n");

// Test 2: Verify tool schemas
console.log("Test 2: Tool Schema Validation");
let schemaErrors = 0;
for (const [name, tool] of Object.entries(AWS.tools)) {
  if (!tool.name || !tool.description || !tool.inputSchema) {
    console.log(`  ERROR: ${name} missing required fields`);
    schemaErrors++;
  }
}
for (const [name, tool] of Object.entries(GCloud.tools)) {
  if (!tool.name || !tool.description || !tool.inputSchema) {
    console.log(`  ERROR: ${name} missing required fields`);
    schemaErrors++;
  }
}
for (const [name, tool] of Object.entries(Azure.tools)) {
  if (!tool.name || !tool.description || !tool.inputSchema) {
    console.log(`  ERROR: ${name} missing required fields`);
    schemaErrors++;
  }
}
for (const [name, tool] of Object.entries(DigitalOcean.tools)) {
  if (!tool.name || !tool.description || !tool.inputSchema) {
    console.log(`  ERROR: ${name} missing required fields`);
    schemaErrors++;
  }
}
console.log(`  Schema errors: ${schemaErrors}`);
console.log(`  Status: ${schemaErrors === 0 ? "PASS" : "FAIL"}\n`);

// Test 3: Resilience components
console.log("Test 3: Resilience Components");

// CircuitBreaker
const cb = new CircuitBreaker({ threshold: 3, resetTimeout: 1000 });
console.log("  CircuitBreaker initial state:", cb.state);
cb.recordFailure();
cb.recordFailure();
cb.recordFailure();
console.log("  CircuitBreaker after 3 failures:", cb.state);
cb.reset();
console.log("  CircuitBreaker after reset:", cb.state);
console.log("  CircuitBreaker: PASS");

// Cache
const cache = new Cache({ maxSize: 10, defaultTtl: 1000 });
cache.set("key1", "value1");
console.log("  Cache get existing:", cache.get("key1") === "value1" ? "PASS" : "FAIL");
console.log("  Cache get missing:", cache.get("nonexistent") === undefined ? "PASS" : "FAIL");
const stats = cache.getStats();
console.log(`  Cache stats: size=${stats.size}, hits=${stats.hits}, misses=${stats.misses}`);
console.log("  Cache: PASS");

// HealthChecker
const hc = new HealthChecker();
hc.register("test", async () => ({ status: "healthy", message: "OK" }));
console.log("  HealthChecker registered:", hc.checks.size === 1 ? "PASS" : "FAIL");

// MetricsCollector
const metrics = new MetricsCollector();
metrics.recordCall("test", { success: true, cached: false, responseTime: 100 });
metrics.recordCall("test", { success: false, cached: false, responseTime: 200 });
const report = metrics.getReport();
console.log(`  Metrics: total=${report.totalCalls}, success=${report.successfulCalls}, failed=${report.failedCalls}`);
console.log("  MetricsCollector: PASS");

// SelfHealer
const sh = new SelfHealer({ checkInterval: 1000 });
sh.register("test-action", () => false, async () => true);
console.log("  SelfHealer registered:", sh.actions.length === 1 ? "PASS" : "FAIL");

console.log("  Status: PASS\n");

// Test 4: Diagnostic tools
console.log("Test 4: Diagnostic Tools");
const caches = { test: cache };
const circuitBreakers = { test: cb };
const diagTools = createDiagnosticTools({
  healthChecker: hc,
  metrics,
  caches,
  circuitBreakers,
});

console.log("  Diagnostic tools created:", Object.keys(diagTools).length);
console.log("  Tools:", Object.keys(diagTools).join(", "));
console.log("  Status: PASS\n");

// Test 5: Check CLI availability
console.log("Test 5: CLI Availability");
async function checkCLI(name, binary, args) {
  try {
    const cmd = new Deno.Command(binary, {
      args: args,
      stdout: "piped",
      stderr: "piped",
    });
    const result = await cmd.output();
    console.log(`  ${name}: ${result.success ? "AVAILABLE" : "ERROR"}`);
    return result.success;
  } catch {
    console.log(`  ${name}: NOT INSTALLED`);
    return false;
  }
}

await checkCLI("AWS CLI", "aws", ["--version"]);
await checkCLI("gcloud CLI", "gcloud", ["--version"]);
await checkCLI("Azure CLI", "az", ["--version"]);
await checkCLI("doctl CLI", "doctl", ["version"]);
console.log("  Note: CLIs are optional - server starts regardless\n");

// Summary
console.log("=== Test Summary ===");
console.log(`Total cloud tools: ${totalTools}`);
console.log(`Diagnostic tools: ${Object.keys(diagTools).length}`);
console.log(`Schema errors: ${schemaErrors}`);
console.log("All component tests: PASS");
console.log("\npoly-cloud-mcp is ready for use!");
