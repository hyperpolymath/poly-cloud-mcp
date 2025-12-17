// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Azure CLI adapter
// Provides tools for managing Azure resources via az cli

open Deno

type toolDef = {
  name: string,
  description: string,
  inputSchema: JSON.t,
}

let runAz = async (args: array<string>): result<string, string> => {
  let cmd = Command.new("az", ~args=Array.concat(args, ["--output", "json"]))
  let output = await Command.output(cmd)
  if output.success {
    Ok(Command.stdoutText(output))
  } else {
    Error(Command.stderrText(output))
  }
}

let tools: dict<toolDef> = Dict.fromArray([
  ("az_vm_list", {
    name: "az_vm_list",
    description: "List Azure virtual machines",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "resourceGroup": { "type": "string", "description": "Resource group name" },
        "subscription": { "type": "string", "description": "Subscription ID" }
      }
    }`),
  }),
  ("az_vm_start", {
    name: "az_vm_start",
    description: "Start an Azure VM",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "name": { "type": "string", "description": "VM name" },
        "resourceGroup": { "type": "string", "description": "Resource group" }
      },
      "required": ["name", "resourceGroup"]
    }`),
  }),
  ("az_vm_stop", {
    name: "az_vm_stop",
    description: "Stop an Azure VM",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "name": { "type": "string", "description": "VM name" },
        "resourceGroup": { "type": "string", "description": "Resource group" }
      },
      "required": ["name", "resourceGroup"]
    }`),
  }),
  ("az_storage_account_list", {
    name: "az_storage_account_list",
    description: "List storage accounts",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "resourceGroup": { "type": "string", "description": "Resource group" },
        "subscription": { "type": "string", "description": "Subscription ID" }
      }
    }`),
  }),
  ("az_storage_blob_list", {
    name: "az_storage_blob_list",
    description: "List blobs in a container",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "containerName": { "type": "string", "description": "Container name" },
        "accountName": { "type": "string", "description": "Storage account name" },
        "prefix": { "type": "string", "description": "Blob prefix filter" }
      },
      "required": ["containerName", "accountName"]
    }`),
  }),
  ("az_webapp_list", {
    name: "az_webapp_list",
    description: "List Azure Web Apps",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "resourceGroup": { "type": "string", "description": "Resource group" },
        "subscription": { "type": "string", "description": "Subscription ID" }
      }
    }`),
  }),
  ("az_functionapp_list", {
    name: "az_functionapp_list",
    description: "List Azure Functions apps",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "resourceGroup": { "type": "string", "description": "Resource group" },
        "subscription": { "type": "string", "description": "Subscription ID" }
      }
    }`),
  }),
  ("az_aks_list", {
    name: "az_aks_list",
    description: "List AKS clusters",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "resourceGroup": { "type": "string", "description": "Resource group" },
        "subscription": { "type": "string", "description": "Subscription ID" }
      }
    }`),
  }),
  ("az_sql_server_list", {
    name: "az_sql_server_list",
    description: "List Azure SQL servers",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "resourceGroup": { "type": "string", "description": "Resource group" },
        "subscription": { "type": "string", "description": "Subscription ID" }
      }
    }`),
  }),
  ("az_group_list", {
    name: "az_group_list",
    description: "List resource groups",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "subscription": { "type": "string", "description": "Subscription ID" }
      }
    }`),
  }),
  ("az_account_show", {
    name: "az_account_show",
    description: "Show current Azure account/subscription",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {}
    }`),
  }),
  ("az_account_list", {
    name: "az_account_list",
    description: "List Azure subscriptions",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {}
    }`),
  }),
])

let handleToolCall = async (name: string, args: JSON.t): result<string, string> => {
  let argsDict = args->JSON.Decode.object->Option.getOr(Dict.make())
  let getString = key => argsDict->Dict.get(key)->Option.flatMap(JSON.Decode.string)->Option.getOr("")

  switch name {
  | "az_vm_list" => {
      let resourceGroup = getString("resourceGroup")
      let subscription = getString("subscription")

      let args = ["vm", "list"]
      let args = resourceGroup !== "" ? Array.concat(args, ["--resource-group", resourceGroup]) : args
      let args = subscription !== "" ? Array.concat(args, ["--subscription", subscription]) : args
      await runAz(args)
    }
  | "az_vm_start" => {
      let vmName = getString("name")
      let resourceGroup = getString("resourceGroup")
      await runAz(["vm", "start", "--name", vmName, "--resource-group", resourceGroup])
    }
  | "az_vm_stop" => {
      let vmName = getString("name")
      let resourceGroup = getString("resourceGroup")
      await runAz(["vm", "stop", "--name", vmName, "--resource-group", resourceGroup])
    }
  | "az_storage_account_list" => {
      let resourceGroup = getString("resourceGroup")
      let subscription = getString("subscription")

      let args = ["storage", "account", "list"]
      let args = resourceGroup !== "" ? Array.concat(args, ["--resource-group", resourceGroup]) : args
      let args = subscription !== "" ? Array.concat(args, ["--subscription", subscription]) : args
      await runAz(args)
    }
  | "az_storage_blob_list" => {
      let containerName = getString("containerName")
      let accountName = getString("accountName")
      let prefix = getString("prefix")

      let args = ["storage", "blob", "list", "--container-name", containerName, "--account-name", accountName]
      let args = prefix !== "" ? Array.concat(args, ["--prefix", prefix]) : args
      await runAz(args)
    }
  | "az_webapp_list" => {
      let resourceGroup = getString("resourceGroup")
      let subscription = getString("subscription")

      let args = ["webapp", "list"]
      let args = resourceGroup !== "" ? Array.concat(args, ["--resource-group", resourceGroup]) : args
      let args = subscription !== "" ? Array.concat(args, ["--subscription", subscription]) : args
      await runAz(args)
    }
  | "az_functionapp_list" => {
      let resourceGroup = getString("resourceGroup")
      let subscription = getString("subscription")

      let args = ["functionapp", "list"]
      let args = resourceGroup !== "" ? Array.concat(args, ["--resource-group", resourceGroup]) : args
      let args = subscription !== "" ? Array.concat(args, ["--subscription", subscription]) : args
      await runAz(args)
    }
  | "az_aks_list" => {
      let resourceGroup = getString("resourceGroup")
      let subscription = getString("subscription")

      let args = ["aks", "list"]
      let args = resourceGroup !== "" ? Array.concat(args, ["--resource-group", resourceGroup]) : args
      let args = subscription !== "" ? Array.concat(args, ["--subscription", subscription]) : args
      await runAz(args)
    }
  | "az_sql_server_list" => {
      let resourceGroup = getString("resourceGroup")
      let subscription = getString("subscription")

      let args = ["sql", "server", "list"]
      let args = resourceGroup !== "" ? Array.concat(args, ["--resource-group", resourceGroup]) : args
      let args = subscription !== "" ? Array.concat(args, ["--subscription", subscription]) : args
      await runAz(args)
    }
  | "az_group_list" => {
      let subscription = getString("subscription")
      let args = ["group", "list"]
      let args = subscription !== "" ? Array.concat(args, ["--subscription", subscription]) : args
      await runAz(args)
    }
  | "az_account_show" => await runAz(["account", "show"])
  | "az_account_list" => await runAz(["account", "list"])
  | _ => Error("Unknown tool: " ++ name)
  }
}
