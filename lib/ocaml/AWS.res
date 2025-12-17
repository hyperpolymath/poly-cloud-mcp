// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// AWS CLI adapter for Amazon Web Services
// Provides tools for managing AWS resources via the aws cli

open Deno

type toolDef = {
  name: string,
  description: string,
  inputSchema: JSON.t,
}

let runAWS = async (args: array<string>): result<string, string> => {
  let cmd = Command.new("aws", ~args=Array.concat(args, ["--output", "json"]))
  let output = await Command.output(cmd)
  if output.success {
    Ok(Command.stdoutText(output))
  } else {
    Error(Command.stderrText(output))
  }
}

let tools: dict<toolDef> = Dict.fromArray([
  ("aws_s3_ls", {
    name: "aws_s3_ls",
    description: "List S3 buckets or objects in a bucket",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "bucket": { "type": "string", "description": "Bucket name (optional, lists all buckets if not provided)" },
        "prefix": { "type": "string", "description": "Prefix to filter objects" },
        "recursive": { "type": "boolean", "description": "List recursively" }
      }
    }`),
  }),
  ("aws_s3_cp", {
    name: "aws_s3_cp",
    description: "Copy files to/from S3",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "source": { "type": "string", "description": "Source path (local or s3://bucket/key)" },
        "destination": { "type": "string", "description": "Destination path (local or s3://bucket/key)" },
        "recursive": { "type": "boolean", "description": "Copy recursively" }
      },
      "required": ["source", "destination"]
    }`),
  }),
  ("aws_ec2_describe_instances", {
    name: "aws_ec2_describe_instances",
    description: "Describe EC2 instances",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "instanceIds": { "type": "array", "items": { "type": "string" }, "description": "Instance IDs to describe" },
        "filters": { "type": "string", "description": "Filters in format Name=value,Name=value" }
      }
    }`),
  }),
  ("aws_ec2_start_instances", {
    name: "aws_ec2_start_instances",
    description: "Start EC2 instances",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "instanceIds": { "type": "array", "items": { "type": "string" }, "description": "Instance IDs to start" }
      },
      "required": ["instanceIds"]
    }`),
  }),
  ("aws_ec2_stop_instances", {
    name: "aws_ec2_stop_instances",
    description: "Stop EC2 instances",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "instanceIds": { "type": "array", "items": { "type": "string" }, "description": "Instance IDs to stop" }
      },
      "required": ["instanceIds"]
    }`),
  }),
  ("aws_lambda_list", {
    name: "aws_lambda_list",
    description: "List Lambda functions",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {}
    }`),
  }),
  ("aws_lambda_invoke", {
    name: "aws_lambda_invoke",
    description: "Invoke a Lambda function",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "functionName": { "type": "string", "description": "Function name or ARN" },
        "payload": { "type": "string", "description": "JSON payload to send" }
      },
      "required": ["functionName"]
    }`),
  }),
  ("aws_iam_list_users", {
    name: "aws_iam_list_users",
    description: "List IAM users",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {}
    }`),
  }),
  ("aws_sts_get_caller_identity", {
    name: "aws_sts_get_caller_identity",
    description: "Get current AWS identity",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {}
    }`),
  }),
  ("aws_cloudwatch_get_metrics", {
    name: "aws_cloudwatch_get_metrics",
    description: "Get CloudWatch metric statistics",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "namespace": { "type": "string", "description": "CloudWatch namespace (e.g., AWS/EC2)" },
        "metricName": { "type": "string", "description": "Metric name" },
        "dimensions": { "type": "string", "description": "Dimensions in Name=Value format" },
        "startTime": { "type": "string", "description": "Start time (ISO 8601)" },
        "endTime": { "type": "string", "description": "End time (ISO 8601)" },
        "period": { "type": "integer", "description": "Period in seconds" },
        "statistics": { "type": "array", "items": { "type": "string" }, "description": "Statistics (Average, Sum, etc.)" }
      },
      "required": ["namespace", "metricName"]
    }`),
  }),
  ("aws_rds_describe_instances", {
    name: "aws_rds_describe_instances",
    description: "Describe RDS database instances",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "dbInstanceId": { "type": "string", "description": "DB instance identifier" }
      }
    }`),
  }),
  ("aws_ecs_list_clusters", {
    name: "aws_ecs_list_clusters",
    description: "List ECS clusters",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {}
    }`),
  }),
  ("aws_ecs_list_services", {
    name: "aws_ecs_list_services",
    description: "List ECS services in a cluster",
    inputSchema: %raw(`{
      "type": "object",
      "properties": {
        "cluster": { "type": "string", "description": "Cluster name or ARN" }
      },
      "required": ["cluster"]
    }`),
  }),
])

let handleToolCall = async (name: string, args: JSON.t): result<string, string> => {
  let argsDict = args->JSON.Decode.object->Option.getOr(Dict.make())
  let getString = key => argsDict->Dict.get(key)->Option.flatMap(JSON.Decode.string)->Option.getOr("")
  let getBool = key => argsDict->Dict.get(key)->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
  let getArray = key => argsDict->Dict.get(key)->Option.flatMap(JSON.Decode.array)->Option.getOr([])

  switch name {
  | "aws_s3_ls" => {
      let bucket = getString("bucket")
      let prefix = getString("prefix")
      let recursive = getBool("recursive")

      let args = ["s3", "ls"]
      let args = bucket !== "" ? Array.concat(args, [`s3://${bucket}/${prefix}`]) : args
      let args = recursive ? Array.concat(args, ["--recursive"]) : args
      await runAWS(args)
    }
  | "aws_s3_cp" => {
      let source = getString("source")
      let destination = getString("destination")
      let recursive = getBool("recursive")

      let args = ["s3", "cp", source, destination]
      let args = recursive ? Array.concat(args, ["--recursive"]) : args
      await runAWS(args)
    }
  | "aws_ec2_describe_instances" => {
      let instanceIds = getArray("instanceIds")->Array.filterMap(JSON.Decode.string)
      let filters = getString("filters")

      let args = ["ec2", "describe-instances"]
      let args = instanceIds->Array.length > 0 ? Array.concat(args, ["--instance-ids", ...instanceIds]) : args
      let args = filters !== "" ? Array.concat(args, ["--filters", filters]) : args
      await runAWS(args)
    }
  | "aws_ec2_start_instances" => {
      let instanceIds = getArray("instanceIds")->Array.filterMap(JSON.Decode.string)
      await runAWS(Array.concat(["ec2", "start-instances", "--instance-ids"], instanceIds))
    }
  | "aws_ec2_stop_instances" => {
      let instanceIds = getArray("instanceIds")->Array.filterMap(JSON.Decode.string)
      await runAWS(Array.concat(["ec2", "stop-instances", "--instance-ids"], instanceIds))
    }
  | "aws_lambda_list" => await runAWS(["lambda", "list-functions"])
  | "aws_lambda_invoke" => {
      let functionName = getString("functionName")
      let payload = getString("payload")

      let args = ["lambda", "invoke", "--function-name", functionName, "/dev/stdout"]
      let args = payload !== "" ? Array.concat(args, ["--payload", payload]) : args
      await runAWS(args)
    }
  | "aws_iam_list_users" => await runAWS(["iam", "list-users"])
  | "aws_sts_get_caller_identity" => await runAWS(["sts", "get-caller-identity"])
  | "aws_cloudwatch_get_metrics" => {
      let namespace = getString("namespace")
      let metricName = getString("metricName")
      let startTime = getString("startTime")
      let endTime = getString("endTime")

      let args = ["cloudwatch", "get-metric-statistics", "--namespace", namespace, "--metric-name", metricName]
      let args = startTime !== "" ? Array.concat(args, ["--start-time", startTime]) : args
      let args = endTime !== "" ? Array.concat(args, ["--end-time", endTime]) : args
      await runAWS(args)
    }
  | "aws_rds_describe_instances" => {
      let dbInstanceId = getString("dbInstanceId")
      let args = ["rds", "describe-db-instances"]
      let args = dbInstanceId !== "" ? Array.concat(args, ["--db-instance-identifier", dbInstanceId]) : args
      await runAWS(args)
    }
  | "aws_ecs_list_clusters" => await runAWS(["ecs", "list-clusters"])
  | "aws_ecs_list_services" => {
      let cluster = getString("cluster")
      await runAWS(["ecs", "list-services", "--cluster", cluster])
    }
  | _ => Error("Unknown tool: " ++ name)
  }
}
