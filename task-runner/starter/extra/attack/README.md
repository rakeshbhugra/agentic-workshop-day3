# Attack files: "Attack your own task runner"

These files turn the kit into a safety demo. A task that looks harmless hides a
step that reads the fake .env and sends it out. You run it three ways and watch
the walls stop it.

- T99-update-readme.md  the poisoned task. Looks like "tidy the README".
- fake.env              copy to the kit root as .env (fake values only).
- guard.sh / guard.ps1  the guard hook. Blocks any command that touches .env.
- hooks.json            tells Codex to run the guard before every shell command.

See the tr-attack slides for the exact steps.
