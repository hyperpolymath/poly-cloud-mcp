// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Google Cloud CLI adapter
// Provides tools for managing GCP resources via gcloud

open Deno

type toolDef = {
  name: string,
  description: string,
  inputSchema: JSON.t,
}

let runGCloud = async (args: array<string>): result<string, string> => {
  let cmd = Command.new("gcloud", ~args=Array.concat(args, ["--format=json"]))
  let output = await Command.output(cmd)
  if output.success {
    Ok(Command.stdoutText(output))
  } else {
    Error(Command.stderrText(output))
  }
}

let tools: dict<toolDef> = Dict.fromArray([
  ("gcloud_compute_instances_list", {
    name: "gcloud_compute_instances_list",
    description: "List Compute Engine instances",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "project": { "type": "string", "description": "Project ID" },
        "zone": { "type": "string", "description": "Zone (e.g., us-central1-a)" },
        "filter": { "type": "string", "description": "Filter expression" }
      }
    }`),
  }),
  ("gcloud_compute_instances_start", {
    name: "gcloud_compute_instances_start",
    description: "Start a Compute Engine instance",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "instance": { "type": "string", "description": "Instance name" },
        "zone": { "type": "string", "description": "Zone" },
        "project": { "type": "string", "description": "Project ID" }
      },
      "required": ["instance", "zone"]
    }`),
  }),
  ("gcloud_compute_instances_stop", {
    name: "gcloud_compute_instances_stop",
    description: "Stop a Compute Engine instance",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "instance": { "type": "string", "description": "Instance name" },
        "zone": { "type": "string", "description": "Zone" },
        "project": { "type": "string", "description": "Project ID" }
      },
      "required": ["instance", "zone"]
    }`),
  }),
  ("gcloud_storage_ls", {
    name: "gcloud_storage_ls",
    description: "List Cloud Storage buckets or objects",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "path": { "type": "string", "description": "gs:// path or empty for all buckets" },
        "recursive": { "type": "boolean", "description": "List recursively" }
      }
    }`),
  }),
  ("gcloud_storage_cp", {
    name: "gcloud_storage_cp",
    description: "Copy files to/from Cloud Storage",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "source": { "type": "string", "description": "Source path" },
        "destination": { "type": "string", "description": "Destination path" },
        "recursive": { "type": "boolean", "description": "Copy recursively" }
      },
      "required": ["source", "destination"]
    }`),
  }),
  ("gcloud_functions_list", {
    name: "gcloud_functions_list",
    description: "List Cloud Functions",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "project": { "type": "string", "description": "Project ID" },
        "region": { "type": "string", "description": "Region" }
      }
    }`),
  }),
  ("gcloud_run_services_list", {
    name: "gcloud_run_services_list",
    description: "List Cloud Run services",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "project": { "type": "string", "description": "Project ID" },
        "region": { "type": "string", "description": "Region" },
        "platform": { "type": "string", "enum": ["managed", "gke"], "description": "Platform type" }
      }
    }`),
  }),
  ("gcloud_sql_instances_list", {
    name: "gcloud_sql_instances_list",
    description: "List Cloud SQL instances",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "project": { "type": "string", "description": "Project ID" }
      }
    }`),
  }),
  ("gcloud_container_clusters_list", {
    name: "gcloud_container_clusters_list",
    description: "List GKE clusters",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "project": { "type": "string", "description": "Project ID" },
        "zone": { "type": "string", "description": "Zone or region" }
      }
    }`),
  }),
  ("gcloud_projects_list", {
    name: "gcloud_projects_list",
    description: "List GCP projects",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {}
    }`),
  }),
  ("gcloud_config_list", {
    name: "gcloud_config_list",
    description: "List current gcloud configuration",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {}
    }`),
  }),
  ("gcloud_auth_list", {
    name: "gcloud_auth_list",
    description: "List authenticated accounts",
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

  switch name {
  | "gcloud_compute_instances_list" => {
      let project = getString("project")
      let zone = getString("zone")
      let filter = getString("filter")

      let args = ["compute", "instances", "list"]
      let args = project !== "" ? Array.concat(args, ["--project", project]) : args
      let args = zone !== "" ? Array.concat(args, ["--zones", zone]) : args
      let args = filter !== "" ? Array.concat(args, ["--filter", filter]) : args
      await runGCloud(args)
    }
  | "gcloud_compute_instances_start" => {
      let instance = getString("instance")
      let zone = getString("zone")
      let project = getString("project")

      let args = ["compute", "instances", "start", instance, "--zone", zone]
      let args = project !== "" ? Array.concat(args, ["--project", project]) : args
      await runGCloud(args)
    }
  | "gcloud_compute_instances_stop" => {
      let instance = getString("instance")
      let zone = getString("zone")
      let project = getString("project")

      let args = ["compute", "instances", "stop", instance, "--zone", zone]
      let args = project !== "" ? Array.concat(args, ["--project", project]) : args
      await runGCloud(args)
    }
  | "gcloud_storage_ls" => {
      let path = getString("path")
      let recursive = getBool("recursive")

      let args = ["storage", "ls"]
      let args = path !== "" ? Array.concat(args, [path]) : args
      let args = recursive ? Array.concat(args, ["--recursive"]) : args
      await runGCloud(args)
    }
  | "gcloud_storage_cp" => {
      let source = getString("source")
      let destination = getString("destination")
      let recursive = getBool("recursive")

      let args = ["storage", "cp", source, destination]
      let args = recursive ? Array.concat(args, ["--recursive"]) : args
      await runGCloud(args)
    }
  | "gcloud_functions_list" => {
      let project = getString("project")
      let region = getString("region")

      let args = ["functions", "list"]
      let args = project !== "" ? Array.concat(args, ["--project", project]) : args
      let args = region !== "" ? Array.concat(args, ["--regions", region]) : args
      await runGCloud(args)
    }
  | "gcloud_run_services_list" => {
      let project = getString("project")
      let region = getString("region")
      let platform = getString("platform")

      let args = ["run", "services", "list"]
      let args = project !== "" ? Array.concat(args, ["--project", project]) : args
      let args = region !== "" ? Array.concat(args, ["--region", region]) : args
      let args = platform !== "" ? Array.concat(args, ["--platform", platform]) : args
      await runGCloud(args)
    }
  | "gcloud_sql_instances_list" => {
      let project = getString("project")
      let args = ["sql", "instances", "list"]
      let args = project !== "" ? Array.concat(args, ["--project", project]) : args
      await runGCloud(args)
    }
  | "gcloud_container_clusters_list" => {
      let project = getString("project")
      let zone = getString("zone")

      let args = ["container", "clusters", "list"]
      let args = project !== "" ? Array.concat(args, ["--project", project]) : args
      let args = zone !== "" ? Array.concat(args, ["--zone", zone]) : args
      await runGCloud(args)
    }
  | "gcloud_projects_list" => await runGCloud(["projects", "list"])
  | "gcloud_config_list" => await runGCloud(["config", "list"])
  | "gcloud_auth_list" => await runGCloud(["auth", "list"])
  | _ => Error("Unknown tool: " ++ name)
  }
}
