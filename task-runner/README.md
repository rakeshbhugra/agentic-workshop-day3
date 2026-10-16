# Task runner: Codex picks up tasks on a schedule

Drop a task file in `tasks/inbox/`. A scheduled `codex exec` reads every task marked `status: todo`. It starts one worker agent per task, and the workers run at the same time. Each worker writes a report. The main agent keeps a board up to date.

The workers use a cheap model on low reasoning, so a full run is a few hundred thousand tokens, not millions.

The app is a tiny homework tracker in `app/` (open `app/index.html` in a browser, no server needed).

## Folders

```
task-runner/
  app/                  the app the tasks change
  tasks/inbox/          one .md file per task (status: todo)
  tasks/done/           finished tasks are moved here
  runs/board.md         task, helper, status, start and finish time
  runs/T01.md ...       one report per task: what it did, files, how to check
  runs/last.md          the main agent's final reply
  runs/transcripts/     full record of every run (.jsonl from codex exec --json)
  orchestrator-prompt.md  the instructions the main agent gets
  starter/              clean copy used by reset (do not edit)
```

## Run it once (Windows, PowerShell)

```powershell
git clone https://github.com/rakeshbhugra/agentic-workshop-day3 C:\workshop\day3
cd C:\workshop\day3\task-runner
.\run-once.ps1
```

The repo is already a git repo, so `git diff` works without any `git init`. The kit is a folder inside it; it does not need its own `.git`.

If PowerShell blocks the script, run this once: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

Mac or Linux: same steps, with `./run-once.sh`.

The first run in a new folder adds that folder as trusted in `%USERPROFILE%\.codex\config.toml`. That is expected.

## Watch it live (two terminals)

Terminal 1, runs now and then every 2 minutes:

```powershell
.\schedule.ps1 watch
```

Terminal 2, shows the board, refreshed every 5 seconds:

```powershell
.\schedule.ps1 board
```

Add your own task while it runs: copy any file in `tasks/inbox/`, give it a new id (T07), change the text, and keep `status: todo`. The next pass picks it up. `starter/extra/T06-pending-count.md` is a ready one to try.

Press Ctrl+C in both terminals to stop.

## Schedule it

```powershell
.\schedule.ps1 install              # every 15 min for the next 8 hours
.\schedule.ps1 install -Minutes 10
.\schedule.ps1 install -At 02:00    # once a day at 2 am
.\schedule.ps1 remove               # stop it and delete it
```

It uses Windows Task Scheduler. A run is killed after 20 minutes, and a second copy never starts while one is running. It runs only while you are logged in.

Mac or Linux: `./schedule.sh install 15` adds a cron line. `./schedule.sh remove` takes it out.

## Check the results

- `runs/board.md` for the overview.
- `runs/<id>.md` for each task: what changed and how to check it by hand.
- `git diff` to see every line it changed. Commit what you keep. `git checkout -- app` throws the rest away.
- `runs/transcripts/*.jsonl` when something went wrong. It has every command the agent ran.

A failed task stays in `tasks/inbox/` with `status: failed`. Fix the task text, set it back to `status: todo`, and the next run tries again.

## Start over

```powershell
.\reset.ps1
```

This deletes `app/`, `tasks/` and `runs/` and copies the clean versions back from `starter/`.

## Safety

- Codex runs with `-s workspace-write`. It can only write inside this folder, and it has no network.
- When there are no todo tasks, the script stops before calling Codex, so idle runs cost nothing.
- A person reviews every change before it goes anywhere. The runner never pushes.

The PowerShell scripts have not been run on Windows yet. The `.sh` versions were tested on a Mac with Codex CLI 0.162.
