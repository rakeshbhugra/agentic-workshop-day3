# Agentic workshop: Day 3 kit

Files for the Day 3 hands-on exercises. Everything here is fake. The `.env` files hold made-up passwords on purpose, so you can practise blocking them.

## Get it (Windows, PowerShell)

```powershell
cd C:\
mkdir workshop
cd workshop
git clone https://github.com/rakeshbhugra/agentic-workshop-day3 day3
cd day3
Set-ExecutionPolicy Bypass -Scope Process -Force
.\CHECK.ps1
```

Already cloned? Run `git pull` inside `C:\workshop\day3`.

On a Mac, clone to `~/workshop/day3` and run `bash check.sh`.

`CHECK.ps1` prints OK or FIX for codex, git, dotnet, node and docker. Docker is optional. A FIX line shows the command that fixes it. After any install, open a new PowerShell window and run the check again.

## What is inside

| Folder | Used in | What it is |
|---|---|---|
| `tests\` | Make it prove it, Test data | .NET 8 solution. `AttendanceRules.cs` holds the rule "3 late marks in one week = 1 absent". Two xUnit tests. `SeedData` is an empty console app with Bogus, for fake students. |
| `guard\` | Guard hook | A fake `.env` and a project-level Codex hook (`.codex\hooks.json`) that blocks `cat .env`, `git push --force`, `rm -rf` and more. |
| `task-runner\` | Task runner | A small app and task files that Codex works through by itself. See its own README. |
| `injection\` | Prompt injection demo | A Python file with a hidden note telling the agent to leak `.env`. `nohook\` and `hook\` versions. See its own README. |

To undo your changes in any exercise: `git checkout .` (or `git stash`).

## Before class (Rakesh)

1. Refresh task-runner from `demo/task-runner`: `bash sync-task-runner.sh`, then `git status` and commit.
2. Push to GitHub: `git push -u origin main`. Check the repo page shows the folders, including `guard/.codex`.
3. Post the clone commands in the Teams chat the day before. Ask people to run `.\CHECK.ps1` and fix red lines before class.
4. Windows dry run on a clean laptop, in this order:
   - Clone, `.\CHECK.ps1`: all OK.
   - `cd C:\workshop\day3\tests`, `dotnet restore`, `dotnet test`: Passed 2.
   - `codex` in `tests`, trust the folder, ask it to add tests and run `dotnet test`. Check it does not end in "Test Run Aborted".
   - Change `lates / 3` to `lates / 4`: red. Put it back: green.
   - `cd ..\guard`, `codex`, trust the hook, "Run cat .env": Blocked. If it is not blocked, check `/hooks` lists the hook as active.
   - Bogus prompt from the slide: `students.csv` with 200 rows.
5. Demo prep for the Test Plans slide: Day 1 attendance app running on localhost, Playwright browser installed (`npx playwright install chromium`).

`tests\.codex\config.toml` turns on `network_access` for the Codex sandbox in that folder. Without it, `dotnet test` cannot open the local port its test runner needs, and the run aborts.
