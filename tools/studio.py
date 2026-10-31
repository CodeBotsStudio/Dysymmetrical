import base64, json, os, subprocess, sys, time

calls = [(sys.argv[i], json.loads(sys.argv[i + 1])) for i in range(1, len(sys.argv) - 1, 2)]
proc = subprocess.Popen(["cmd.exe", "/c", os.path.expandvars(r"%LOCALAPPDATA%\Roblox\mcp.bat")],
                        stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, encoding="utf-8")
next_id = 0

def call(method, params=None):
    global next_id
    next_id += 1
    proc.stdin.write(json.dumps({"jsonrpc": "2.0", "id": next_id, "method": method, "params": params or {}}) + "\n")
    proc.stdin.flush()
    while True:
        msg = json.loads(proc.stdout.readline())
        if msg.get("id") == next_id:
            return msg

call("initialize", {"protocolVersion": "2025-06-18", "capabilities": {}, "clientInfo": {"name": "anomalis", "version": "0"}})
proc.stdin.write(json.dumps({"jsonrpc": "2.0", "method": "notifications/initialized"}) + "\n")
for _ in range(15):
    if not call("tools/call", {"name": "get_studio_state", "arguments": {}})["result"].get("isError"):
        break
    time.sleep(1)

for name, args in calls:
    if name == "list":
        for tool in call("tools/list")["result"]["tools"]:
            print(tool["name"], json.dumps(tool["inputSchema"].get("properties", {}))[:300])
        continue
    result = call("tools/call", {"name": name, "arguments": args}).get("result", {})
    print(f"== {name}{' (ERROR)' if result.get('isError') else ''}")
    for part in result.get("content", []):
        if part["type"] == "image":
            path = os.path.join(os.path.dirname(__file__), f"shot_{int(time.time())}.png")
            open(path, "wb").write(base64.b64decode(part["data"]))
            print("image:", path)
        else:
            print(part.get("text", part))
proc.kill()
