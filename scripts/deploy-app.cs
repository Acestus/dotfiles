#!/usr/bin/env -S dotnet --

var env = (string?)null; var stack = "blog"; string? resourceGroup = null; string? functionApp = null; var skipBuild = false; var skipValidation = false;
for (var i = 0; i < args.Length; i++)
{
    if (args[i] is "-h" or "--help") { PrintHelp(); return; }
    switch (args[i])
    {
        case "--env": env = RequireValue(args, ref i); break;
        case "--stack": stack = RequireValue(args, ref i); if (stack != "blog") throw new ArgumentException("--stack must be blog"); break;
        case "--resource-group": resourceGroup = RequireValue(args, ref i); break;
        case "--function-app": functionApp = RequireValue(args, ref i); break;
        case "--skip-build": skipBuild = true; break;
        case "--skip-validation": skipValidation = true; break;
        default: throw new ArgumentException($"Unknown argument: {args[i]}");
    }
}
if (env is null) throw new ArgumentException("--env is required");
var configs = new Dictionary<string, (string App, string Group)> { ["dev"] = ("func-blog-dev-usw2-001", "rg-blog-dev"), ["prd"] = ("func-blog-prd-usw2-001", "rg-blog-prd") };
if (!configs.TryGetValue(env, out var defaults)) throw new ArgumentException($"Unknown env: {env}");
functionApp ??= defaults.App; resourceGroup ??= defaults.Group;
var repoRoot = await GitRootAsync(); var jar = Path.Combine(repoRoot, "target", "blog-0.1.0.jar"); var zipDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".cache", "dotfiles-deploy"); var zip = Path.Combine(zipDir, "blog-deploy.zip");
PrintSummary(env, functionApp, resourceGroup);
if (!skipBuild)
{
    Console.WriteLine("Step 1/5: Prep content..."); await RunCheckedAsync("clojure", ["-X:prep"], repoRoot); Console.WriteLine("✅ Content prepped\n");
    Console.WriteLine("Step 2/5: Run tests..."); await RunCheckedAsync("clojure", ["-M:test"], repoRoot); Console.WriteLine("✅ Tests passed\n");
    Console.WriteLine("Step 3/5: Build uberjar..."); await RunCheckedAsync("clojure", ["-T:build", "uber"], repoRoot); Console.WriteLine("✅ Uberjar built");
}
if (!File.Exists(jar)) throw new FileNotFoundException($"Jar not found: {jar} (run without --skip-build)");
if (!skipValidation)
{
    Console.WriteLine("Validating function app..."); var validation = await RunAsync("az", ["functionapp", "show", "--name", functionApp, "--resource-group", resourceGroup, "-o", "json"], repoRoot); if (validation.ExitCode != 0) { Console.Error.WriteLine($"❌ ERROR: Function app '{functionApp}' not found in '{resourceGroup}'\n{validation.Error.Trim()}"); Environment.Exit(1); } Console.WriteLine($"✅ Function app '{functionApp}' found");
}
Directory.CreateDirectory(zipDir); if (File.Exists(zip)) File.Delete(zip);
Console.WriteLine("\nStep 4/5: Create deployment archive..."); var zipArgs = new[] { "-r", zip, "host.json", "Health/function.json", "Pages/function.json", "target/blog-0.1.0.jar", "content/", "resources/" }; await RunCheckedAsync("zip", zipArgs, repoRoot); Console.WriteLine($"✅ Archive: {zip} ({new FileInfo(zip).Length / 1024} KB)");
Console.WriteLine("\nStep 5/5: Deploy to Azure Functions..."); await RunCheckedAsync("az", ["functionapp", "deployment", "source", "config-zip", "--name", functionApp, "--resource-group", resourceGroup, "--src", zip, "--build-remote", "false", "--timeout", "120"], repoRoot); Console.WriteLine("✅ Deployment complete\n");
Console.WriteLine($"Deployment Summary\n===================\nFunction App: {functionApp}\nResource Group: {resourceGroup}\nDeploy Method: az functionapp deployment source config-zip\n\nNext steps:\n  1. Monitor deployment logs for {functionApp}\n  2. Open https://{functionApp}.azurewebsites.net/\n\n✨ Done!\n🌐 https://{functionApp}.azurewebsites.net/");

static string RequireValue(string[] values, ref int index) => ++index < values.Length ? values[index] : throw new ArgumentException($"{values[index - 1]} requires a value.");
static async Task<string> GitRootAsync() { var result = await RunAsync("git", ["rev-parse", "--show-toplevel"], Directory.GetCurrentDirectory()); if (result.ExitCode != 0) throw new InvalidOperationException("Could not determine git repository root."); return result.Output.Trim(); }
static void PrintSummary(string env, string app, string group) => Console.WriteLine($"\n🚀 Blog App Deployment\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\nEnvironment:      {env}\nFunction App:     {app}\nResource Group:   {group}\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
static void PrintHelp() => Console.WriteLine("Usage: deploy-app.cs --stack blog --env dev|prd [--resource-group NAME] [--function-app NAME] [--skip-build] [--skip-validation]\nBuilds the blog and deploys to Azure Functions.");
static async Task RunCheckedAsync(string command, IEnumerable<string> args, string cwd) { var result = await RunAsync(command, args, cwd); if (result.ExitCode != 0) { Console.Error.WriteLine($"❌ {command} failed\n{result.Error.Trim()}"); Environment.Exit(result.ExitCode); } }
static async Task<CommandResult> RunAsync(string command, IEnumerable<string> args, string cwd) { using var p = new System.Diagnostics.Process { StartInfo = new System.Diagnostics.ProcessStartInfo { FileName = command, WorkingDirectory = cwd, UseShellExecute = false, RedirectStandardOutput = true, RedirectStandardError = true } }; foreach (var a in args) p.StartInfo.ArgumentList.Add(a); if (!p.Start()) return new(-1, "", "Could not start command"); var output = await p.StandardOutput.ReadToEndAsync(); var error = await p.StandardError.ReadToEndAsync(); await p.WaitForExitAsync(); return new(p.ExitCode, output, error); }
record CommandResult(int ExitCode, string Output, string Error);
