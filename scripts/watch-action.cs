#!/usr/bin/env -S dotnet --

using System.Text.Json.Nodes;

var workflow = "Push to dev"; var force = false;
for (var i = 0; i < args.Length; i++)
{
    if (args[i] is "--help" or "-h") { PrintHelp(); return; }
    if (args[i] is "--workflow" or "-w") workflow = i + 1 < args.Length ? args[++i] : throw new ArgumentException("--workflow requires a value.");
    else if (args[i] == "--force") force = true;
    else if (!args[i].StartsWith('-')) workflow = args[i];
    else throw new ArgumentException($"Unknown option: {args[i]}");
}
Console.WriteLine($"Finding latest '{workflow}' workflow run...");
var runsText = await GhAsync(["run", "list", "--limit", "10", "--json", "name,databaseId,status,conclusion"]);
var runs = JsonNode.Parse(runsText)?.AsArray() ?? [];
var run = runs.FirstOrDefault(x => string.Equals(x?["name"]?.ToString(), workflow, StringComparison.Ordinal));
if (run is null) Fail($"No '{workflow}' workflow runs found");
var runId = run!["databaseId"]!.ToString(); Console.WriteLine($"Found workflow run:\n   ID: {runId}\n   Status: {run["status"]}\n   Conclusion: {run["conclusion"]}");
var status = run["status"]?.ToString(); var conclusion = run["conclusion"]?.ToString();
if (status == "completed" && !force)
{
    if (conclusion == "success") { Console.WriteLine("✅ Workflow run completed successfully"); Console.WriteLine(await GhAsync(["run", "view", runId])); }
    else if (conclusion == "failure") { Console.WriteLine("❌ Workflow run completed with failure"); await ShowFailedLogsAsync(runId); }
    else { Console.WriteLine($"Workflow run completed with conclusion: {conclusion}"); Console.WriteLine(await GhAsync(["run", "view", runId])); }
}
else
{
    Console.WriteLine($"Watching workflow run {runId}...\n   Press Ctrl+C to stop watching");
    var watch = await GhResultAsync(["run", "watch", runId, "--exit-status"]);
    if (watch.ExitCode == 0) { Console.WriteLine("Showing run summary..."); Console.WriteLine(await GhAsync(["run", "view", runId])); }
    else { Console.WriteLine("Showing failed job logs..."); await ShowFailedLogsAsync(runId); }
}

async Task ShowFailedLogsAsync(string id)
{
    var repo = (await GhAsync(["repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"])).Trim(); Console.WriteLine("Fetching failed job logs...");
    var jobs = await GhAsync(["api", $"repos/{repo}/actions/runs/{id}/jobs"]); var jobsJson = JsonNode.Parse(jobs)?["jobs"]?.AsArray() ?? [];
    var failed = jobsJson.FirstOrDefault(x => x?["conclusion"]?.ToString() == "failure");
    if (failed is null) { Console.WriteLine("No failed jobs found."); var fallback = await GhResultAsync(["run", "view", id, "--log-failed"]); Console.Write(fallback.Output); Environment.Exit(1); }
    Console.WriteLine("\nFailed steps:"); foreach (var step in failed["steps"]?.AsArray() ?? []) if (step?["conclusion"]?.ToString() == "failure") Console.WriteLine($"  - {step["name"]}");
    var logs = await GhAsync(["api", $"repos/{repo}/actions/jobs/{failed["id"]}/logs"]); Console.WriteLine("\nError details:"); foreach (var line in logs.Split('\n').Where(x => x.Contains("error", StringComparison.OrdinalIgnoreCase) || x.Contains("fail", StringComparison.OrdinalIgnoreCase)).TakeLast(30)) Console.WriteLine(line);
}
static async Task<string> GhAsync(IEnumerable<string> args) { var result = await GhResultAsync(args); if (result.ExitCode != 0) Fail($"gh command failed: {result.Error.Trim()}"); return result.Output.Trim(); }
static async Task<(int ExitCode, string Output, string Error)> GhResultAsync(IEnumerable<string> args) { using var p = new System.Diagnostics.Process { StartInfo = new System.Diagnostics.ProcessStartInfo { FileName = "gh", UseShellExecute = false, RedirectStandardOutput = true, RedirectStandardError = true } }; foreach (var a in args) p.StartInfo.ArgumentList.Add(a); if (!p.Start()) return (-1, "", "Could not start gh"); var output = await p.StandardOutput.ReadToEndAsync(); var error = await p.StandardError.ReadToEndAsync(); await p.WaitForExitAsync(); return (p.ExitCode, output, error); }
static void Fail(string message) { Console.Error.WriteLine($"❌ {message}"); Environment.Exit(1); }
static void PrintHelp() => Console.WriteLine("Usage: watch-action.cs [WORKFLOW] [--workflow NAME] [--force]\nWatch the latest GitHub Actions workflow run by name.");
