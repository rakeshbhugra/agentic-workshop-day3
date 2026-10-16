"""Quick check, no network: python test_proxy.py"""
import io, json
from proxy import Proxy, mask

assert mask('{"text": "Riya was late. Riya is back."}') == ('{"text": "[NAME_1] was late. [NAME_1] is back."}', 2)

# A streamed answer where the placeholder is split across two events.
openai = (
    'event: response.output_text.delta\ndata: {"delta": "Hi [NA"}\n\n'
    'event: response.output_text.delta\ndata: {"delta": "ME_1]!"}\n\n'
    'event: response.completed\ndata: {"text": "Hi [NAME_1]!"}\n\n'
)
anthropic = (
    'event: content_block_delta\ndata: {"delta": {"type": "text_delta", "text": "Hello ["}}\n\n'
    'event: content_block_delta\ndata: {"delta": {"type": "text_delta", "text": "NAME_1], welcome"}}\n\n'
    'event: message_stop\ndata: {}\n\n'
)
for stream in (openai, anthropic):
    p = Proxy.__new__(Proxy)
    p.wfile = io.BytesIO()
    p.stream(io.BytesIO(stream.encode()))
    out = p.wfile.getvalue().decode()
    texts = []
    for line in out.splitlines():
        if line.startswith("data:"):
            d = json.loads(line[5:]).get("delta")
            texts.append(d if isinstance(d, str) else (d or {}).get("text", ""))
    joined = "".join(texts)
    assert "NAME" not in out, out
    assert "Riya" in joined, out
print("OK")
