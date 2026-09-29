#!/usr/bin/env -S dotnet --

if (args.Contains("--help") || args.Contains("-h"))
{
    Console.WriteLine("Usage: git-daily.cs");
    Console.WriteLine("Stages all changes, asks Copilot for a commit message, commits, and pushes.");
    return;
}

await RunAsync("git", ["add", "-A"]);
var status = await RunCaptureAsync("git", ["status", "--short"]);
if (string.IsNullOrWhiteSpace(status.Output)) { Console.WriteLine("Nothing to commit."); return; }
Console.WriteLine("Changes staged:"); Console.WriteLine(status.Output);
Console.WriteLine();
const string prompt = "Inspect the staged git changes in the current repository and output only one concise commit message, no quotes, no markdown. Use git diff --cached if needed.";
var copilot = await RunCaptureAsync("copilot", ["-p", prompt, "--silent", "--allow-tool", "shell(git:*)", "--allow-all-paths", "--no-color"]);
if (copilot.ExitCode != 0) throw new InvalidOperationException($"Copilot failed: {copilot.Error.Trim()}");
var commitMessage = copilot.Output.Trim().Split(['\r', '\n'], StringSplitOptions.RemoveEmptyEntries).FirstOrDefault()?.Trim().Trim('"');
if (string.IsNullOrWhiteSpace(commitMessage)) throw new InvalidOperationException("Copilot did not return a commit message.");
Console.WriteLine("Suggested commit message:\n  " + commitMessage + "\n");
await RunAsync("git", ["commit", "--message", commitMessage]);
await RunAsync("git", ["push"]);
Console.WriteLine("Pushed successfully.");

static async Task RunAsync(string command, IEnumerable<string> arguments)
{
    var result = await RunCaptureAsync(command, arguments); if (result.ExitCode != 0) { Console.Error.Write(result.Error); Environment.Exit(result.ExitCode); }
}
static async Task<(int ExitCode, string Output, string Error)> RunCaptureAsync(string command, IEnumerable<string> arguments)
{
    using var process = new System.Diagnostics.Process { StartInfo = new System.Diagnostics.ProcessStartInfo { FileName = command, UseShellExecute = false, RedirectStandardOutput = true, RedirectStandardError = true } };
    foreach (var argument in arguments) process.StartInfo.ArgumentList.Add(argument); if (!process.Start()) return (-1, "", "Could not start command"); var output = await process.StandardOutput.ReadToEndAsync(); var error = await process.StandardError.ReadToEndAsync(); await process.WaitForExitAsync(); return (process.ExitCode, output, error);
}
