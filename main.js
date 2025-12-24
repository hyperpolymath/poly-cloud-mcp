#!/usr/bin/env -S deno run --allow-run --allow-read --allow-env
// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// poly-cloud-mcp - Multi-cloud provider MCP server
// Adapters: AWS, GCloud, Azure, DigitalOcean

import * as AWS from "./lib/es6/src/adapters/AWS.res.js";
import * as GCloud from "./lib/es6/src/adapters/GCloud.res.js";
import * as Azure from "./lib/es6/src/adapters/Azure.res.js";
import * as DigitalOcean from "./lib/es6/src/adapters/DigitalOcean.res.js";

const SERVER_INFO = {
  name: "poly-cloud-mcp",
  version: "1.0.0",
  description: "Multi-cloud provider MCP server (AWS, GCP, Azure, DigitalOcean)",
};

// Combine all tools from adapters
const allTools = {
  ...AWS.tools,
  ...GCloud.tools,
  ...Azure.tools,
  ...DigitalOcean.tools,
};

// Route tool calls to appropriate adapter
async function handleToolCall(name, args) {
  if (name.startsWith("aws_")) {
    return await AWS.handleToolCall(name, args);
  } else if (name.startsWith("gcloud_")) {
    return await GCloud.handleToolCall(name, args);
  } else if (name.startsWith("az_")) {
    return await Azure.handleToolCall(name, args);
  } else if (name.startsWith("doctl_")) {
    return await DigitalOcean.handleToolCall(name, args);
  }
  return { TAG: "Error", _0: `Unknown tool: ${name}` };
}

// MCP Protocol handlers
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
  const toolsList = Object.values(allTools).map((tool) => ({
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

async function handleToolsCall(id, params) {
  const { name, arguments: args } = params;
  const result = await handleToolCall(name, args || {});

  if (result.TAG === "Ok") {
    return {
      jsonrpc: "2.0",
      id,
      result: {
        content: [{ type: "text", text: result._0 }],
      },
    };
  } else {
    return {
      jsonrpc: "2.0",
      id,
      result: {
        content: [{ type: "text", text: `Error: ${result._0}` }],
        isError: true,
      },
    };
  }
}

// Main message handler
async function handleMessage(message) {
  const { method, id, params } = message;

  switch (method) {
    case "initialize":
      return handleInitialize(id);
    case "initialized":
      return null;
    case "tools/list":
      return handleToolsList(id);
    case "tools/call":
      return await handleToolsCall(id, params);
    default:
      return {
        jsonrpc: "2.0",
        id,
        error: { code: -32601, message: `Method not found: ${method}` },
      };
  }
}

// stdio transport
const decoder = new TextDecoder();
const encoder = new TextEncoder();

async function readMessage() {
  const buffer = new Uint8Array(65536);
  let data = "";

  while (true) {
    const n = await Deno.stdin.read(buffer);
    if (n === null) return null;

    data += decoder.decode(buffer.subarray(0, n));

    const headerEnd = data.indexOf("\r\n\r\n");
    if (headerEnd === -1) continue;

    const header = data.substring(0, headerEnd);
    const contentLengthMatch = header.match(/Content-Length: (\d+)/i);
    if (!contentLengthMatch) continue;

    const contentLength = parseInt(contentLengthMatch[1]);
    const bodyStart = headerEnd + 4;
    const bodyEnd = bodyStart + contentLength;

    if (data.length < bodyEnd) continue;

    const body = data.substring(bodyStart, bodyEnd);
    data = data.substring(bodyEnd);

    return JSON.parse(body);
  }
}

function writeMessage(message) {
  const body = JSON.stringify(message);
  const header = `Content-Length: ${encoder.encode(body).length}\r\n\r\n`;
  Deno.stdout.writeSync(encoder.encode(header + body));
}

async function main() {
  while (true) {
    const message = await readMessage();
    if (message === null) break;

    const response = await handleMessage(message);
    if (response !== null) {
      writeMessage(response);
    }
  }
}

main().catch(console.error);
