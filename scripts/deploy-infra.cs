#!/usr/bin/env -S dotnet --

using System.Text.RegularExpressions;

var action = "deploy"; string? stack = null; string? env = null;
for (var i = 0; i < args.Length; i++)
{
    if (args[i] is "-h" or "--help") { PrintHelp(); return; }
    if (args[i] is "--env" or "--action" or "--stack") { var value = RequireValue(args, ref i); if (args[i - 1] == "--env") env = value; else if (args[i - 1] == "--action") action = value; else stack = value; }
    else throw new ArgumentException($"Unknown argument: {args[i]}");
}
stack ??= "blog";
if (env is null) throw new ArgumentException("--env is required");
if (!new[] { "blog", "mgmt" }.Contains(stack)) throw new ArgumentException("stack must be one of: blog, mgmt");
if (!new[] { "dev", "prd" }.Contains(env)) throw new ArgumentException("env must be one of: dev, prd");
if (!new[] { "deploy", "validate", "delete", "show" }.Contains(action)) throw new ArgumentException("action must be one of: deploy, validate, delete, or show");
var repoRoot = await GitRootAsync();
var template = Path.Combine(repoRoot, "infra", stack, "main.bicep");
var param = Path.Combine(repoRoot, "infra", stack, env, $"main.{env}.bicepparam");
if (!File.Exists(template)) throw new FileNotFoundException($"Template not found: {template}");
if (!File.Exists(param)) throw new FileNotFoundException($"Param file not found: {param}");
var content = await File.ReadAllTextAsync(param);
var project = Extract(content, "projectName") ?? throw new InvalidOperationException("projectName not found in params");
var paramEnv = Extract(content, "environment") ?? throw new InvalidOperationException("environment not found in params");
var region = Extract(content, "regionCode") ?? throw new InvalidOperationException("regionCode not found in params");
if (project != stack) throw new InvalidOperationException($"projectName must match stack in params ({project} vs {stack})");
var location = region switch { "usw2" or "scus" => "southcentralus", _ => throw new InvalidOperationException($"Unsupported regionCode: {region}") };
var resourceGroup = $"rg-{stack}-{paramEnv}"; var stackName = $"stack-{stack}-{paramEnv}";
PrintSummary(action, stack, env, resourceGroup, location, stackName, template, param);

switch (action)
{
    case "show":
        if (stack == "mgmt") await RegisterProviderAsync(); await RequireResourceGroupAsync(resourceGroup); await ShowStackAsync(stackName, resourceGroup); break;
    case "validate":
        if (stack == "mgmt") await RegisterProviderAsync(); await EnsureResourceGroupAsync(resourceGroup, location); Console.WriteLine("🔍 Validating (what-if)..."); await EnsureAzAsync(["deployment", "group", "what-if", "--resource-group", resourceGroup, "--template-file", template, "--parameters", param], "Validation failed"); Console.WriteLine("\n✅ Validation complete!"); break;
    case "delete":
        Console.WriteLine("🗑️  Deleting deployment stack..."); await EnsureAzAsync(["stack", "group", "delete", "--name", stackName, "--resource-group", resourceGroup, "--action-on-unmanage", "deleteResources", "--yes"], "Delete failed"); Console.WriteLine("\n✅ Stack deleted!"); break;
    case "deploy":
        if (stack == "mgmt") await RegisterProviderAsync(); await EnsureResourceGroupAsync(resourceGroup, location); Console.WriteLine("🔨 Deploying via Deployment Stack..."); await EnsureAzAsync(["stack", "group", "create", "--name", stackName, "--resource-group", resourceGroup, "--template-file", template, "--parameters", param, "--action-on-unmanage", "deleteResources", "--deny-settings-mode", "none", "--yes"], "Deployment failed"); Console.WriteLine("\n✨ Deployment complete!"); break;
}

async Task RegisterProviderAsync() => await EnsureAzAsync(["provider", "register", "--namespace", "Microsoft.OperationalInsights", "--wait"], "Failed to register provider Microsoft.OperationalInsights");
async Task EnsureResourceGroupAsync(string group, string groupLocation)
{
    var existing = await RunAzAsync(["group", "show", "--name", group, "--query", "location", "--output", "tsv"]);
    if (existing.ExitCode == 0 && !string.IsNullOrWhiteSpace(existing.Output)) { var current = existing.Output.Trim(); if (current != groupLocation) Console.WriteLine($"ℹ️  Resource group {group} already exists in {current}; reusing that location."); return; }
    await EnsureAzAsync(["group", "create", "--name", group, "--location", groupLocation, "--output", "none"], $"Failed to create resource group {group}");
}
async Task RequireResourceGroupAsync(string group)
{
    var result = await RunAzAsync(["group", "exists", "--name", group, "--output", "tsv"]); if (result.Output.Trim() != "true") throw new InvalidOperationException($"Resource group not found: {group}");
}
async Task ShowStackAsync(string stackIdentifier, string group)
{
    Console.WriteLine("\n📋 Showing deployment stack resources..."); var idsResult = await RunAzAsync(["stack", "group", "show", "--name", stackIdentifier, "--resource-group", group, "--query", "resources[].id", "--output", "tsv"]); EnsureResult(idsResult, $"Stack not found: {stackIdentifier}"); var ids = idsResult.Output.Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries); Console.WriteLine($"Fetching full config for {ids.Length} managed resources...\n");
    var summaries = new List<(string Name, string Type)>();
    foreach (var id in ids)
    {
        var summary = await RunAzAsync(["resource", "show", "--ids", id, "--query", "{name:name,type:type,id:id}", "--output", "tsv"]); EnsureResult(summary, $"Could not fetch resource: {id}"); var fields = summary.Output.Trim().Split('\t', 3); var resourceName = fields.ElementAtOrDefault(0) ?? ""; var type = fields.ElementAtOrDefault(1) ?? ""; summaries.Add((resourceName, type)); var full = await RunAzAsync(["resource", "show", "--ids", id, "--output", "json"]); Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\u001b[1;36m" + resourceName + "\u001b[0m\n   " + type + "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"); Console.WriteLine(full.ExitCode == 0 ? full.Output : $"  ⚠️  Could not fetch: {full.Error.Trim()}"); Console.WriteLine();
    }
    Console.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\nManaged Resources (" + summaries.Count + ")\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"); foreach (var (resourceName, type) in summaries) Console.WriteLine($"  ✅ {resourceName} ({type})"); Console.WriteLine("\n✅ Done!");
}
async Task EnsureAzAsync(IEnumerable<string> arguments, string context) { var result = await RunAzAsync(arguments); EnsureResult(result, context); }
async Task<CommandResult> RunAzAsync(IEnumerable<string> arguments) => await RunAsync("az", arguments, repoRoot);
static void EnsureResult(CommandResult result, string context) { if (result.ExitCode != 0) { Console.Error.WriteLine($"❌ {context}\n{result.Error.Trim()}"); Environment.Exit(result.ExitCode); } }
static string? Extract(string content, string name) => Regex.Match(content, $"param\\s+{Regex.Escape(name)}\\s*=\\s*'([^']*)'").Groups[1].Value is { Length: > 0 } value ? value : null;
static async Task<string> GitRootAsync() { var result = await RunAsync("git", ["rev-parse", "--show-toplevel"], Directory.GetCurrentDirectory()); if (result.ExitCode != 0) throw new InvalidOperationException("Could not determine git repository root."); return result.Output.Trim(); }
static string RequireValue(string[] values, ref int index) => ++index < values.Length ? values[index] : throw new ArgumentException($"{values[index - 1]} requires a value.");
static void PrintSummary(string action, string stack, string env, string group, string location, string name, string template, string param) => Console.WriteLine($"\n🚀 Blog Infrastructure Deployment\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\nAction:           {action}\nStack:            {stack}\nEnvironment:      {env}\nResource Group:   {group}\nRG Location:      {location}\nStack Name:       {name}\nTemplate:         {template}\nParameters:       {param}\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
static void PrintHelp() => Console.WriteLine("Usage: deploy-infra.cs --stack blog|mgmt --env dev|prd [--action deploy|validate|delete|show]\nDeploys infrastructure via Azure Deployment Stacks.");
static async Task<CommandResult> RunAsync(string command, IEnumerable<string> arguments, string workingDirectory) { using var p = new System.Diagnostics.Process { StartInfo = new System.Diagnostics.ProcessStartInfo { FileName = command, WorkingDirectory = workingDirectory, UseShellExecute = false, RedirectStandardOutput = true, RedirectStandardError = true } }; foreach (var a in arguments) p.StartInfo.ArgumentList.Add(a); if (!p.Start()) return new(-1, "", "Could not start command"); var output = await p.StandardOutput.ReadToEndAsync(); var error = await p.StandardError.ReadToEndAsync(); await p.WaitForExitAsync(); return new(p.ExitCode, output, error); }
record CommandResult(int ExitCode, string Output, string Error);
