"""Masking proxy: hides names before the AI sees them, puts them back in the answer.

    python proxy.py          start on http://localhost:8787
    python proxy.py --log    also write what the model received to model_saw.log

Claude Code:  ANTHROPIC_BASE_URL=http://localhost:8787  (goes to api.anthropic.com)
Codex:        base_url http://localhost:8787/codex      (goes to the ChatGPT backend)
Standard library only. No pip install needed.
"""
import http.client, http.server, json, sys, urllib.parse

# ---- EDIT HERE: real value -> what the AI sees instead ----------------------
MASKS = {"Riya": "[NAME_1]"}
# ------------------------------------------------------------------------------

PORT = 8787
# Path prefix -> real server. The first prefix that matches wins.
UPSTREAMS = {
    "/codex": "https://chatgpt.com/backend-api/codex",  # Codex signed in with ChatGPT
    "": "https://api.anthropic.com",                    # everything else: Claude Code
}
LOG = "model_saw.log" if "--log" in sys.argv else None
SKIP = {"host", "content-length", "accept-encoding", "connection", "transfer-encoding"}


def mask(text):
    count = 0
    for real, fake in MASKS.items():
        count += text.count(real)
        text = text.replace(real, fake)
    return text, count


def unmask(text):
    count = 0
    for real, fake in MASKS.items():
        count += text.count(fake)
        text = text.replace(fake, real)
    return text, count


def ends_with_part_of_fake(text):
    """True if the text ends with the start of a placeholder, like '[NAME'."""
    return any(fake[:i] and text.endswith(fake[:i])
               for fake in MASKS.values() for i in range(1, len(fake)))


def delta_text(event):
    """The streamed text piece in an SSE event, as (dict, key), or None.
    OpenAI: {"delta": "..."}. Anthropic: {"delta": {"text": "..."}} or partial_json."""
    if isinstance(event.get("delta"), str):
        return event, "delta"
    d = event.get("delta")
    if isinstance(d, dict):
        for key in ("text", "partial_json", "thinking"):
            if isinstance(d.get(key), str):
                return d, key
    return None


def sse_events(resp):
    """Yield (other lines, data) for each Server-Sent Event in the stream."""
    lines = []
    for line in iter(resp.readline, b""):
        line = line.decode("utf-8", "replace")
        if line.strip():
            lines.append(line)
        elif lines:
            yield split_event(lines)
            lines = []
    if lines:
        yield split_event(lines)


def split_event(lines):
    head = "".join(l for l in lines if not l.startswith("data:"))
    return head, "".join(l[5:].strip() for l in lines if l.startswith("data:"))


class Proxy(http.server.BaseHTTPRequestHandler):
    def do_GET(self): self.forward()
    def do_POST(self): self.forward()
    def do_PUT(self): self.forward()
    def do_DELETE(self): self.forward()

    def forward(self):
        if self.headers.get("Upgrade", "").lower() == "websocket":
            # We only speak plain HTTPS. Codex falls back to HTTPS when this fails.
            print(f"   {self.path}: WebSocket refused, client should use HTTPS")
            return self.send_error(426, "Use HTTPS, not WebSocket")

        prefix = next(p for p in UPSTREAMS if self.path.startswith(p))
        url = urllib.parse.urlsplit(UPSTREAMS[prefix] + self.path[len(prefix):])

        body = self.rfile.read(int(self.headers.get("Content-Length") or 0))
        if body and self.headers.get("Content-Encoding"):
            return self.send_error(415, f"Compressed body ({self.headers['Content-Encoding']}) not supported")
        text, n = mask(body.decode("utf-8", "replace"))
        body = text.encode()
        print(f"-> {self.command} {url.netloc}{url.path}   masked {n} x {', '.join(MASKS)}")
        if LOG and body:
            with open(LOG, "a", encoding="utf-8") as f:
                f.write(f"=== {url.path}\n{text}\n\n")

        headers = {k: v for k, v in self.headers.items() if k.lower() not in SKIP}
        headers["Accept-Encoding"] = "identity"  # plain text back, so we can read it
        conn = http.client.HTTPSConnection(url.netloc, timeout=600)
        conn.request(self.command, url.path + (f"?{url.query}" if url.query else ""), body, headers)
        resp = conn.getresponse()

        self.send_response(resp.status)
        for k, v in resp.getheaders():
            if k.lower() not in SKIP | {"content-encoding"}:
                self.send_header(k, v)
        if "text/event-stream" in resp.getheader("Content-Type", ""):
            self.end_headers()  # no length: the stream ends when we close
            total = self.stream(resp)
        else:
            out, total = unmask(resp.read().decode("utf-8", "replace"))
            out = out.encode()
            self.send_header("Content-Length", str(len(out)))
            self.end_headers()
            self.wfile.write(out)
        print(f"<- {resp.status}   unmasked {total}")
        conn.close()

    def stream(self, resp):
        """Pass a Server-Sent Events stream through, one event at a time.
        A placeholder can be split across two events ('[NAME' then '_1]').
        So when a text piece ends with the start of a placeholder, we hold that
        event back and glue the next text piece onto it before sending."""
        total, held = 0, None  # held = an event waiting for the next text piece
        for head, data in sse_events(resp):
            try:
                obj = json.loads(data)
            except ValueError:
                obj = None
            piece = delta_text(obj) if isinstance(obj, dict) else None
            if not piece:  # not a text piece: swap names in the whole event
                if held:
                    self.send_event(*held)
                    held = None
                data, n = unmask(data)
                total += n
                self.send_event(head, data)
                continue
            if held:  # glue this text piece onto the held event
                hd, hk = delta_text(held[1])
                hd[hk] += piece[0][piece[1]]
                (head, obj), held = held, None
                piece = delta_text(obj)
            d, k = piece
            d[k], n = unmask(d[k])
            total += n
            if ends_with_part_of_fake(d[k]):
                held = (head, obj)
            else:
                self.send_event(head, obj)
        if held:
            self.send_event(*held)
        return total

    def send_event(self, head, data):
        if not isinstance(data, str):
            data = json.dumps(data, ensure_ascii=False)
        self.wfile.write(f"{head}data: {data}\n\n".encode())
        self.wfile.flush()

    def log_message(self, *args):
        pass  # keep the console to our own lines


if __name__ == "__main__":
    print(f"Masking proxy on http://localhost:{PORT}   masks: {MASKS}")
    if LOG:
        print(f"Writing what the model receives to {LOG}")
    http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Proxy).serve_forever()
