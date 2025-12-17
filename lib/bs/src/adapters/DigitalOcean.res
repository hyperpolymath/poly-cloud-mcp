// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// DigitalOcean CLI adapter
// Provides tools for managing DigitalOcean resources via doctl

open Deno

type toolDef = {
  name: string,
  description: string,
  inputSchema: JSON.t,
}

let runDoctl = async (args: array<string>): result<string, string> => {
  let cmd = Command.new("doctl", ~args=Array.concat(args, ["--output", "json"]))
  let output = await Command.output(cmd)
  if output.success {
    Ok(Command.stdoutText(output))
  } else {
    Error(Command.stderrText(output))
  }
}

let tools: dict<toolDef> = Dict.fromArray([
  ("doctl_droplet_list", {
    name: "doctl_droplet_list",
    description: "List DigitalOcean droplets",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "region": { "type": "string", "description": "Filter by region" },
        "tag": { "type": "string", "description": "Filter by tag" }
      }
    }`),
  }),
  ("doctl_droplet_create", {
    name: "doctl_droplet_create",
    description: "Create a new droplet",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "name": { "type": "string", "description": "Droplet name" },
        "region": { "type": "string", "description": "Region slug (e.g., nyc1, sfo3)" },
        "size": { "type": "string", "description": "Size slug (e.g., s-1vcpu-1gb)" },
        "image": { "type": "string", "description": "Image slug or ID (e.g., ubuntu-22-04-x64)" },
        "sshKeys": { "type": "array", "items": { "type": "string" }, "description": "SSH key IDs or fingerprints" },
        "tags": { "type": "array", "items": { "type": "string" }, "description": "Tags to apply" }
      },
      "required": ["name", "region", "size", "image"]
    }`),
  }),
  ("doctl_droplet_delete", {
    name: "doctl_droplet_delete",
    description: "Delete a droplet",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "id": { "type": "string", "description": "Droplet ID" },
        "force": { "type": "boolean", "description": "Force deletion without confirmation" }
      },
      "required": ["id"]
    }`),
  }),
  ("doctl_droplet_actions", {
    name: "doctl_droplet_actions",
    description: "Perform actions on droplet (power-on, power-off, reboot, etc.)",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "id": { "type": "string", "description": "Droplet ID" },
        "action": { "type": "string", "enum": ["power-on", "power-off", "reboot", "shutdown", "enable-backups", "disable-backups"], "description": "Action to perform" }
      },
      "required": ["id", "action"]
    }`),
  }),
  ("doctl_kubernetes_cluster_list", {
    name: "doctl_kubernetes_cluster_list",
    description: "List Kubernetes clusters",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {}
    }`),
  }),
  ("doctl_kubernetes_cluster_kubeconfig", {
    name: "doctl_kubernetes_cluster_kubeconfig",
    description: "Get kubeconfig for a cluster",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "clusterId": { "type": "string", "description": "Cluster ID or name" }
      },
      "required": ["clusterId"]
    }`),
  }),
  ("doctl_database_list", {
    name: "doctl_database_list",
    description: "List managed databases",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {}
    }`),
  }),
  ("doctl_spaces_list", {
    name: "doctl_spaces_list",
    description: "List Spaces (object storage buckets)",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "region": { "type": "string", "description": "Region" }
      }
    }`),
  }),
  ("doctl_apps_list", {
    name: "doctl_apps_list",
    description: "List App Platform apps",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {}
    }`),
  }),
  ("doctl_domain_list", {
    name: "doctl_domain_list",
    description: "List domains",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {}
    }`),
  }),
  ("doctl_domain_records", {
    name: "doctl_domain_records",
    description: "List DNS records for a domain",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "domain": { "type": "string", "description": "Domain name" }
      },
      "required": ["domain"]
    }`),
  }),
  ("doctl_account_get", {
    name: "doctl_account_get",
    description: "Get current account info",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {}
    }`),
  }),
  ("doctl_balance_get", {
    name: "doctl_balance_get",
    description: "Get account balance",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {}
    }`),
  }),
])

let handleToolCall = async (name: string, args: JSON.t): result<string, string> => {
  let argsDict = args->JSON.Decode.object->Option.getOr(Dict.make())
  let getString = key => argsDict->Dict.get(key)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
  let getBool = key => argsDict->Dict.get(key)->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
  let getArray = key => argsDict->Dict.get(key)->Option.flatMap(JSON.Decode.array)->Option.getOr([])

  switch name {
  | "doctl_droplet_list" => {
      let region = getString("region")
      let tag = getString("tag")

      let args = ["compute", "droplet", "list"]
      let args = region !== "" ? Array.concat(args, ["--region", region]) : args
      let args = tag !== "" ? Array.concat(args, ["--tag-name", tag]) : args
      await runDoctl(args)
    }
  | "doctl_droplet_create" => {
      let dropletName = getString("name")
      let region = getString("region")
      let size = getString("size")
      let image = getString("image")
      let sshKeys = getArray("sshKeys")->Array.filterMap(JSON.Decode.string)
      let tags = getArray("tags")->Array.filterMap(JSON.Decode.string)

      let args = ["compute", "droplet", "create", dropletName, "--region", region, "--size", size, "--image", image]
      let args = sshKeys->Array.length > 0 ? Array.concat(args, ["--ssh-keys", sshKeys->Array.join(",")]) : args
      let args = tags->Array.length > 0 ? Array.concat(args, ["--tag-names", tags->Array.join(",")]) : args
      await runDoctl(args)
    }
  | "doctl_droplet_delete" => {
      let id = getString("id")
      let force = getBool("force")

      let args = ["compute", "droplet", "delete", id]
      let args = force ? Array.concat(args, ["--force"]) : args
      await runDoctl(args)
    }
  | "doctl_droplet_actions" => {
      let id = getString("id")
      let action = getString("action")
      await runDoctl(["compute", "droplet-action", action, id])
    }
  | "doctl_kubernetes_cluster_list" => await runDoctl(["kubernetes", "cluster", "list"])
  | "doctl_kubernetes_cluster_kubeconfig" => {
      let clusterId = getString("clusterId")
      await runDoctl(["kubernetes", "cluster", "kubeconfig", "show", clusterId])
    }
  | "doctl_database_list" => await runDoctl(["databases", "list"])
  | "doctl_spaces_list" => {
      // Note: doctl doesn't have direct spaces list command - uses serverless storage API
      // This lists available regions that support Spaces
      await runDoctl(["compute", "region", "list"])
    }
  | "doctl_apps_list" => await runDoctl(["apps", "list"])
  | "doctl_domain_list" => await runDoctl(["compute", "domain", "list"])
  | "doctl_domain_records" => {
      let domain = getString("domain")
      await runDoctl(["compute", "domain", "records", "list", domain])
    }
  | "doctl_account_get" => await runDoctl(["account", "get"])
  | "doctl_balance_get" => await runDoctl(["balance", "get"])
  | _ => Error("Unknown tool: " ++ name)
  }
}
