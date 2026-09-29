#!/usr/bin/env -S dotnet --

if (args.Contains("--help") || args.Contains("-h")) { Console.WriteLine("Usage: dn.cs\nCreate today's planner note and open it with the configured editor."); return; }
var noteDir = Environment.GetEnvironmentVariable("DAILY_NOTE_DIR") ?? Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "workspace", "planner");
var taskList = Environment.GetEnvironmentVariable("DAILY_NOTE_TASKS_LIST") ?? Path.Combine(noteDir, "tasks-list.txt");
Directory.CreateDirectory(noteDir);
var notePath = Path.Combine(noteDir, $"{DateTime.Now:MM-dd}.org");
if (!File.Exists(notePath) || new FileInfo(notePath).Length == 0)
{
    var lines = new List<string> { DateTime.Now.ToString() , "" };
    if (File.Exists(taskList)) lines.AddRange(File.ReadLines(taskList).Where(x => !string.IsNullOrWhiteSpace(x)));
    await File.WriteAllLinesAsync(notePath, lines);
}
var opener = Environment.GetEnvironmentVariable("VISUAL") ?? Environment.GetEnvironmentVariable("EDITOR");
if (!string.IsNullOrWhiteSpace(opener)) { var parts = opener.Split(' ', StringSplitOptions.RemoveEmptyEntries); await RunAsync(parts[0], parts.Skip(1).Append(notePath)); }
else if (FileOnPath("nvim")) await RunAsync("nvim", [notePath]);
else if (FileOnPath("xdg-open")) await RunAsync("xdg-open", [notePath]);
else { Console.Error.WriteLine("dn: no editor or opener found"); Environment.Exit(1); }
static bool FileOnPath(string command) => Environment.GetEnvironmentVariable("PATH")?.Split(Path.PathSeparator).Any(p => File.Exists(Path.Combine(p, command))) == true;
static async Task RunAsync(string command, IEnumerable<string> arguments) { using var p = new System.Diagnostics.Process { StartInfo = new System.Diagnostics.ProcessStartInfo { FileName = command, UseShellExecute = false } }; foreach (var a in arguments) p.StartInfo.ArgumentList.Add(a); if (!p.Start()) throw new InvalidOperationException($"Could not start {command}"); await p.WaitForExitAsync(); Environment.Exit(p.ExitCode); }
