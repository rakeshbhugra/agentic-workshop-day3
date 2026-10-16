# Masking proxy

A tiny program that sits between your AI agent and the AI company.

```
Codex / Claude Code  ->  proxy.py on your laptop  ->  OpenAI / Anthropic
```

Every prompt passes through `proxy.py`. On the way out it swaps `Riya` for `[NAME_1]`. On the way back it swaps `[NAME_1]` back to `Riya`. So the AI never sees the real name, but you still read it in the answer.

One file, Python standard library only. No `pip install`.

## 1. Start the proxy

Windows (PowerShell):

```powershell
cd C:\workshop\day3\proxy
python proxy.py --log
```

Mac:

```bash
cd ~/workshop/day3/proxy
python3 proxy.py --log
```

Leave this window open. Each request prints a line:

```
-> POST chatgpt.com/backend-api/codex/responses   masked 1 x Riya
<- 200   unmasked 4
```

`--log` also writes every request body, exactly as the AI receives it, to `model_saw.log`. Search it for `Riya`: you should find nothing.

No `python` on Windows? Install it with `winget install Python.Python.3.12`, then open a new PowerShell window.

## 2. Send Claude Code through it

Open a second window.

```powershell
$env:ANTHROPIC_BASE_URL="http://localhost:8787"
claude
```

Mac: `ANTHROPIC_BASE_URL=http://localhost:8787 claude`

Your normal login still works. The proxy passes your login headers on to `api.anthropic.com`.

## 3. Send Codex through it

Copy the profile file once:

```powershell
copy proxy.config.toml $env:USERPROFILE\.codex\proxy.config.toml
codex --profile proxy
```

Mac: `cp proxy.config.toml ~/.codex/ && codex --profile proxy`

Without `--profile proxy`, Codex goes straight to OpenAI as usual. Nothing else changes.

The profile adds a custom provider that points at `http://localhost:8787/codex`. With `requires_openai_auth = true`, Codex keeps using your ChatGPT sign-in. The proxy forwards to `https://chatgpt.com/backend-api/codex`, which is where Codex goes when you sign in with ChatGPT.

One-off, without the profile file (works in PowerShell and on Mac):

```
codex exec -c model_provider=px -c model_providers.px.name=px -c model_providers.px.base_url=http://localhost:8787/codex -c model_providers.px.requires_openai_auth=true "Write one line greeting a student named Riya"
```

Why not `openai_base_url`? It also works for the URL, but then Codex first tries a WebSocket (the proxy refuses it) and sends zstd-compressed bodies that the standard library cannot read. The custom provider uses plain HTTPS and plain JSON.

## 4. Try it

Ask: `Write one line greeting a student named Riya`. You see "Riya" in the answer. The proxy window shows `masked 1 x Riya`. `model_saw.log` shows `[NAME_1]`.

It also masks files the agent reads. Put `Riya - 3 late marks` in a file and ask the agent to read it.

## 5. Make it yours

Edit the `MASKS` dict at the top of `proxy.py`:

```python
MASKS = {"Riya": "[NAME_1]", "9876543210": "[PHONE_1]"}
```

Ideas: mask phone numbers with a regex, block any prompt that contains `sk-` or `password=`, log every prompt with the user name, count tokens per team, add your company rules to every prompt.

Run `python test_proxy.py` after a change. It checks masking and the streaming case where `[NAME_1]` arrives in two pieces.

## Notes

- The proxy listens on `127.0.0.1` only, so other machines cannot reach it.
- It sees every prompt and your login headers. Run it only on your own machine or your own server.
- A model sometimes notices the placeholder and says so. A realistic fake name (`"Riya": "Asha"`) avoids that, but is harder to spot in the log.
- Simple word swap: it also changes "Riya" inside longer words, and it does not catch "riya" or "RIYA".
