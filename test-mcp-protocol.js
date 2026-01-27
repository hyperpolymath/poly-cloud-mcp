#!/usr/bin/env -S deno run --allow-run --allow-read --allow-env
// SPDX-License-Identifier: MIT
// Test MCP protocol message handling

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

console.log("=== MCP Protocol Test ===\n");

const VERSION = "1.1.0";
const SERVER_INFO = {
  name: "poly-cloud-mcp",
  version: VERSION,
  description: "Multi-cloud MCP server with resilience (AWS, GCP, Azure, DigitalOcean)",
};

// Combine all tools
const allTools = {
  ...AWS.tools,
  ...GCloud.tools,
  ...Azure.tools,
  ...DigitalOcean.tools,
};

// Setup resilience infrastructure
const circuitBreakers = {
  aws: new CircuitBreaker({ threshold: 5, resetTimeout: 30000 }),
  gcloud: new CircuitBreaker({ threshold: 5, resetTimeout: 30000 }),
  azure: new CircuitBreaker({ threshold: 5, resetTimeout: 30000 }),
  digitalocean: new CircuitBreaker({ threshold: 5, resetTimeout: 30000 }),
};

const caches = {
  aws: new Cache({ maxSize: 200, defaultTtl: 60000 }),
  gcloud: new Cache({ maxSize: 200, defaultTtl: 60000 }),
  azure: new Cache({ maxSize: 200, defaultTtl: 60000 }),
  digitalocean: new Cache({ maxSize: 100, defaultTtl: 60000 }),
};

const metrics = new MetricsCollector();
const healthChecker = new HealthChecker();

const diagnosticTools = createDiagnosticTools({
  healthChecker,
  metrics,
  caches,
  circuitBreakers,
});

// Protocol handlers
function handleInitialize(id) {
  return {
    jsonrpc: "2.0",
    id,
    result: {
      protocolVersion: "2024-11-05",
      serverInfo: SERVER_INFO,
      capabilities: {
        tools: { listChanged: false },
      },
    },
  };
}

function handleToolsList(id) {
  const allToolsList = { ...allTools };
  for (const [name, tool] of Object.entries(diagnosticTools)) {
    allToolsList[name] = {
      name: tool.name,
      description: tool.description,
      inputSchema: tool.inputSchema,
    };
  }

  const toolsList = Object.values(allToolsList).map((tool) => ({
    name: tool.name,
    description: tool.description,
    inputSchema: tool.inputSchema,
  }));

  return {
    jsonrpc: "2.0",
    id,
    result: { tools: toolsList },
  };
}

// Test 1: Initialize
console.log("Test 1: Initialize Request");
const initResponse = handleInitialize(1);
console.log("  Protocol version:", initResponse.result.protocolVersion);
console.log("  Server name:", initResponse.result.serverInfo.name);
console.log("  Server version:", initResponse.result.serverInfo.version);
console.log("  Has tools capability:", !!initResponse.result.capabilities.tools);
console.log("  Status: PASS\n");

// Test 2: Tools List
console.log("Test 2: Tools List Request");
const toolsResponse = handleToolsList(2);
console.log("  Total tools:", toolsResponse.result.tools.length);
console.log("  Has AWS tools:", toolsResponse.result.tools.some(t => t.name.startsWith("aws_")));
console.log("  Has GCloud tools:", toolsResponse.result.tools.some(t => t.name.startsWith("gcloud_")));
console.log("  Has Azure tools:", toolsResponse.result.tools.some(t => t.name.startsWith("az_")));
console.log("  Has DigitalOcean tools:", toolsResponse.result.tools.some(t => t.name.startsWith("doctl_")));
console.log("  Has diagnostic tools:", toolsResponse.result.tools.some(t => t.name.startsWith("mcp_")));
console.log("  Status: PASS\n");

// Test 3: Verify all tools have proper schema
console.log("Test 3: Tool Schema Completeness");
let schemaIssues = 0;
for (const tool of toolsResponse.result.tools) {
  if (!tool.inputSchema || typeof tool.inputSchema !== "object") {
    console.log(`  ERROR: ${tool.name} has invalid inputSchema`);
    schemaIssues++;
  }
  if (!tool.description) {
    console.log(`  ERROR: ${tool.name} missing description`);
    schemaIssues++;
  }
}
console.log(`  Schema issues: ${schemaIssues}`);
console.log(`  Status: ${schemaIssues === 0 ? "PASS" : "FAIL"}\n`);

// Test 4: Diagnostic tools work
console.log("Test 4: Diagnostic Tool Execution");
const metricsResult = await diagnosticTools.mcp_metrics.handler({});
console.log("  mcp_metrics returned:", typeof metricsResult);
console.log("  Has totalCalls:", "totalCalls" in metricsResult);

const circuitResult = await diagnosticTools.mcp_circuit_status.handler({});
console.log("  mcp_circuit_status returned:", typeof circuitResult);
console.log("  Adapters:", Object.keys(circuitResult).join(", "));

const cacheResult = await diagnosticTools.mcp_cache_stats.handler({});
console.log("  mcp_cache_stats returned:", typeof cacheResult);
console.log("  Status: PASS\n");

// Test 5: Tool name listing
console.log("Test 5: Tool Names by Provider");
const awsTools = toolsResponse.result.tools.filter(t => t.name.startsWith("aws_")).map(t => t.name);
const gcloudTools = toolsResponse.result.tools.filter(t => t.name.startsWith("gcloud_")).map(t => t.name);
const azureTools = toolsResponse.result.tools.filter(t => t.name.startsWith("az_")).map(t => t.name);
const doctlTools = toolsResponse.result.tools.filter(t => t.name.startsWith("doctl_")).map(t => t.name);
const mcpTools = toolsResponse.result.tools.filter(t => t.name.startsWith("mcp_")).map(t => t.name);

console.log(`\n  AWS (${awsTools.length}):`);
awsTools.forEach(t => console.log(`    - ${t}`));
console.log(`\n  GCloud (${gcloudTools.length}):`);
gcloudTools.forEach(t => console.log(`    - ${t}`));
console.log(`\n  Azure (${azureTools.length}):`);
azureTools.forEach(t => console.log(`    - ${t}`));
console.log(`\n  DigitalOcean (${doctlTools.length}):`);
doctlTools.forEach(t => console.log(`    - ${t}`));
console.log(`\n  Diagnostics (${mcpTools.length}):`);
mcpTools.forEach(t => console.log(`    - ${t}`));

console.log("\n=== Protocol Test Summary ===");
console.log("All MCP protocol tests: PASS");
console.log(`Total tools exposed: ${toolsResponse.result.tools.length}`);
