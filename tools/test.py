import json, os, pathlib, subprocess, sys, time

ROOT = pathlib.Path(__file__).resolve().parent.parent
SERVICES = {"ReplicatedStorage": "ReplicatedStorage", "ReplicatedFirst": "ReplicatedFirst", "ServerScriptService": "ServerScriptService",
            "StarterPlayerScripts": "StarterPlayer.StarterPlayerScripts", "StarterCharacterScripts": "StarterPlayer.StarterCharacterScripts",
            "ServerStorage": "ServerStorage", "StarterGui": "StarterGui", "Workspace": "Workspace", "SoundService": "SoundService"}
proc = subprocess.Popen(["cmd.exe", "/c", os.path.expandvars(r"%LOCALAPPDATA%\Roblox\mcp.bat")], stdin=subprocess.PIPE,
                        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, encoding="utf-8")
next_id = 0
results = []


def call(method, params=None):
    global next_id
    next_id += 1
    proc.stdin.write(json.dumps({"jsonrpc": "2.0", "id": next_id, "method": method, "params": params or {}}) + "\n")
    proc.stdin.flush()
    while True:
        msg = json.loads(proc.stdout.readline())
        if msg.get("id") == next_id:
            return msg


def tool(name, **args):
    result = call("tools/call", {"name": name, "arguments": args}).get("result", {})
    text = "\n".join(part.get("text", "") for part in result.get("content", []))
    return ("ERROR " if result.get("isError") else "") + text


call("initialize", {"protocolVersion": "2025-06-18", "capabilities": {}, "clientInfo": {"name": "anomalis-test", "version": "0"}})
proc.stdin.write(json.dumps({"jsonrpc": "2.0", "method": "notifications/initialized"}) + "\n")
proc.stdin.flush()
SID = sys.argv[1] if len(sys.argv) > 1 else next(s["id"] for s in json.loads(tool("list_roblox_studios"))["studios"] if "Dysymmetrical" in s["name"])


def luau(code, dm="Server"):
    return tool("execute_luau", studio_id=SID, datamodel_type=dm, code=code).strip()


def lit(text):
    n = 3
    while "]" + "=" * n + "]" in text:
        n += 1
    return "[" + "=" * n + "[" + text + "]" + "=" * n + "]"


def sync():
    items = []
    for folder, service in SERVICES.items():
        for file in sorted((ROOT / "src" / folder).rglob("*.luau")):
            parts = list(file.relative_to(ROOT / "src" / folder).parts)
            name, cls = parts[-1][:-5], "ModuleScript"
            for suffix, kind in ((".server", "Script"), (".client", "LocalScript")):
                if name.endswith(suffix):
                    name, cls = name[: -len(suffix)], kind
            path = service.split(".") + parts[:-1] + ([] if name == "init" else [name])
            items.append(f'go({{{",".join(chr(34) + p + chr(34) for p in path)}}}, "{cls}", {lit(file.read_text(encoding="utf-8"))})')
    head = '''local changed = 0
local function go(path, cls, src)
    local node = game:GetService(path[1])
    for k = 2, #path do
        node = node:FindFirstChild(path[k]) or Instance.new(k == #path and cls or "Folder", node)
        node.Name = path[k]
    end
    if node:IsA("LuaSourceContainer") and node.Source ~= src then node.Source = src changed += 1 end
end
'''
    total = 0
    for i in range(0, len(items), 20):
        out = luau(head + "\n".join(items[i:i + 20]) + "\nreturn changed", "Edit")
        if out.startswith("ERROR"):
            sys.exit("sync failed: " + out[-300:])
        total += int(out)
    return total


def check(name, ok, detail=""):
    results.append((name, bool(ok), detail))
    print(("PASS " if ok else "FAIL ") + name + (f"  ({detail})" if detail else ""), flush=True)


def wait_for(code, want, dm="Server", timeout=60):
    end = time.time() + timeout
    while time.time() < end:
        out = luau(code, dm)
        if want in out:
            return out
        time.sleep(1.5)
    return out


def play(start):
    tool("start_stop_play", studio_id=SID, is_start=start)


def debug_round(as_killer):
    luau(f'''local m = game.ServerScriptService.Managers
m.TimeManager.Source = m.TimeManager.Source:gsub("LobbyTime = 45,", "LobbyTime = 5,"):gsub("MinimumPlayerAmount = 2,", "MinimumPlayerAmount = 1,")
m.RoundManager.Source = m.RoundManager.Source:gsub("CanSpawnKiller = %a+,","CanSpawnKiller = {str(as_killer).lower()},")
workspace:SetAttribute("KillersAllowed", {int(as_killer)})''', "Edit")
    play(True)
    role = "Killer" if as_killer else "Survivor"
    state = wait_for('''local c = game.Players:GetPlayers()[1] and game.Players:GetPlayers()[1].Character
return game.ReplicatedStorage.RoundInfo.CurrentState.Value .. " " .. (c and c:FindFirstChild("Role") and c.Role.Value or "-")''', "InRound " + role)
    check(f"round starts as {role}", "InRound " + role in state, state)
    luau('workspace:SetAttribute("FreezeTime", true)')
    luau('''_G.TestLog = {}
game.ReplicatedStorage.Modules.Network.REMOTE_EVENT.Impact.OnClientEvent:Connect(function(kind, _, _, _, _, _, _, target)
    table.insert(_G.TestLog, kind .. (target and (":" .. target.Name) or ""))
end)''', "Client")
    return "InRound " + role in state


def log():
    return luau('return table.concat(_G.TestLog, ",")', "Client")


def console_errors():
    lines = tool("get_console_output", studio_id=SID).splitlines()
    return sorted({lines[i - 1].strip() + " @ " + lines[i + 1].strip() for i, line in enumerate(lines[:-1]) if i and "Stack Begin" in line})


def survivor_phase():
    if not debug_round(False):
        return
    total = luau('return workspace:GetAttribute("GeneratorsTotal")')
    check("map has 5 generators", total == "5", total)
    time.sleep(1)
    tip = luau('local l = game.Players.LocalPlayer.PlayerGui.RoundTips:FindFirstChildOfClass("TextLabel") return l.Text .. "|" .. tostring(l.TextFits)', "Client")
    check("round tip shows and fits", tip.split("|")[0] != "" and tip.endswith("true"), tip[:60])

    generators = luau('local n = {} for _, g in workspace.Map:FindFirstChild("Generators", true):GetChildren() do table.insert(n, g.Name) end return table.concat(n, ",")').split(",")
    for name, mode in ((generators[0], "hit"), (generators[1], "miss")):
        luau(f'''local panel = workspace.Map:FindFirstChild("Generators", true)["{name}"].Panel
local spot = panel.Position + panel.CFrame.LookVector * 4
game.Players:GetPlayers()[1].Character:PivotTo(CFrame.lookAt(spot, panel.Position * Vector3.new(1, 0, 1) + Vector3.new(0, spot.Y, 0)))''')
        time.sleep(0.5)
        luau(f'''_G.GenEnded = false
local events = game.ReplicatedStorage.Modules.Network.REMOTE_EVENT
local input = events.GeneratorCheckInput
if _G.GenConn then _G.GenConn:Disconnect() _G.EndConn:Disconnect() end
_G.GenConn = events.GeneratorCheck.OnClientEvent:Connect(function(delay, sweep, zone, width)
    task.delay(if "{mode}" == "hit" then delay + (zone + width / 2) * sweep else 0, function() input:FireServer() end)
end)
_G.EndConn = events.GeneratorCheckEnded.OnClientEvent:Connect(function() _G.GenEnded = true end)
local prompt = workspace.Map:FindFirstChild("Generators", true)["{name}"].Panel:FindFirstChildOfClass("ProximityPrompt")
prompt:InputHoldBegin() task.wait(0.1) prompt:InputHoldEnd()''', "Client")
        if mode == "hit":
            out = wait_for(f'local g = workspace.Map:FindFirstChild("Generators", true)["{name}"] return tostring(g:GetAttribute("Repaired")) .. " " .. tostring(g:GetAttribute("Progress")) .. " " .. tostring(workspace:GetAttribute("GeneratorsRepaired"))', "true", timeout=25)
            check("generator repairs in 6 checks", out.startswith("true 6 1"), out)
        else:
            out = wait_for('return tostring(_G.GenEnded)', "true", "Client", timeout=6)
            progress = luau(f'return tostring(workspace.Map:FindFirstChild("Generators", true)["{name}"]:GetAttribute("Progress"))')
            check("missed check fails the repair", out == "true" and progress == "0", f"ended={out} progress={progress}")

    luau(f'''local panel = workspace.Map:FindFirstChild("Generators", true)["{generators[2]}"].Panel
local spot = panel.Position + panel.CFrame.LookVector * 12
game.Players:GetPlayers()[1].Character:PivotTo(CFrame.lookAt(spot, panel.Position * Vector3.new(1, 0, 1) + Vector3.new(0, spot.Y, 0)))''')
    reloading = 'return tostring(game.Players:GetPlayers()[1].Character:FindFirstChild("Slowness", true) ~= nil)'
    for _ in range(2):
        tool("user_keyboard_input", studio_id=SID, datamodel_type="Client", actions=[{"action": "keyPress", "key_code": "E"}, {"action": "wait", "wait_time_ms": 500}])
        if luau(reloading) == "true":
            break
    reloaded = luau(reloading)
    tool("user_keyboard_input", studio_id=SID, datamodel_type="Client", actions=[{"action": "wait", "wait_time_ms": 5500}, {"action": "keyPress", "key_code": "R"}, {"action": "wait", "wait_time_ms": 2500}])
    check("Commander shot leaves a surface impact", "Shot" in log(), f"reload started={reloaded} log={log()}")

    luau('''local root = game.Players:GetPlayers()[1].Character.PrimaryPart
local fake = Instance.new("Model") fake.Name = "TestKiller" fake:SetAttribute("CharacterName", "NullexVoyd")
local part = Instance.new("Part") part.Name = "HumanoidRootPart" part.Anchored = true part.CanCollide = false part.Size = Vector3.new(2, 5, 2)
part.CFrame = root.CFrame * CFrame.new(0, 0, -15) part.Parent = fake fake.PrimaryPart = part
local role = Instance.new("StringValue") role.Name = "Role" role.Value = "Killer" role.Parent = fake
fake.Parent = workspace.Players''')
    time.sleep(1)
    near = luau('local e = game.Players.LocalPlayer.PlayerGui.TerrorPulse:FindFirstChildOfClass("CanvasGroup") local lo, hi = 1, 0 for _ = 1, 8 do lo = math.min(lo, e.GroupTransparency) hi = math.max(hi, e.GroupTransparency) task.wait(0.1) end return string.format("%.2f %.2f", lo, hi)', "Client")
    luau('workspace.Players.TestKiller:Destroy()')
    time.sleep(0.5)
    far = luau('return string.format("%.2f", game.Players.LocalPlayer.PlayerGui.TerrorPulse:FindFirstChildOfClass("CanvasGroup").GroupTransparency)', "Client")
    lo, hi = map(float, near.split())
    check("terror edge pulses near the killer", lo < 0.9 and hi - lo > 0.03 and far == "1.00", f"near {near}, gone {far}")
    errors = console_errors()
    check("no script errors (survivor)", not errors, "; ".join(errors)[:300])
    play(False)


def slash():
    tool("user_mouse_input", studio_id=SID, datamodel_type="Client", actions=[{"action": "moveTo", "x": 500, "y": 300}, {"action": "mouseButtonClick", "mouse_button": "left"}, {"action": "wait", "wait_time_ms": 1500}])


def killer_phase():
    if not debug_round(True):
        return
    luau('''local panel = workspace.Map:FindFirstChild("Generators", true):GetChildren()[1].Panel
local base = panel.Position + panel.CFrame.LookVector * 14
local char = game.Players:GetPlayers()[1].Character
char:PivotTo(CFrame.lookAt(base, base + Vector3.new(-5, 0, 0)))
local crate = workspace.Map:FindFirstChild("ReactiveProps", true):GetChildren()[1]
crate.AssemblyLinearVelocity = Vector3.zero
crate.CFrame = CFrame.new(char.PrimaryPart.Position + char.PrimaryPart.CFrame.LookVector * 3.5 + Vector3.new(0, -1.5, 0))
_G.TestCrate = crate _G.CrateStart = crate.Position''')
    time.sleep(1)
    luau('_G.CrateStart = _G.TestCrate.Position')
    slash()
    moved = luau('return string.format("%.2f", (_G.TestCrate.Position - _G.CrateStart).Magnitude)')
    check("slash pushes a reactive crate", float(moved) > 0.5, moved + " studs")
    check("slash leaves a surface impact", "Melee" in log(), log())
    time.sleep(1.5)
    health = luau('''local p = game.Players:GetPlayers()[1]
p.Character.Archivable = true
local dummy = p.Character:Clone()
p.Character.Archivable = false
dummy.Name = "TestSurvivor"
for _, s in dummy:GetDescendants() do if s:IsA("BaseScript") then s:Destroy() end end
dummy.Role.Value = "Survivor"
local root = p.Character.PrimaryPart
dummy:PivotTo(root.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0))
dummy.Parent = workspace.Players
_G.TestDummy = dummy
return tostring(dummy:FindFirstChildOfClass("Humanoid").Health)''')
    slash()
    after = luau('return tostring(_G.TestDummy:FindFirstChildOfClass("Humanoid").Health)')
    check("slash damages a survivor", float(after) < float(health), f"{health} -> {after}")
    check("body hit reaches clients", "Body:TestSurvivor" in log(), log())
    errors = console_errors()
    check("no script errors (killer)", not errors, "; ".join(errors)[:300])
    play(False)


try:
    play(False)
    print("synced", sync(), "scripts", flush=True)
    survivor_phase()
    killer_phase()
finally:
    play(False)
    sync()
    luau('workspace:SetAttribute("KillersAllowed", 1) workspace:SetAttribute("FreezeTime", nil)', "Edit")
    proc.kill()
failed = [name for name, ok, _ in results if not ok]
print(f"\n{len(results) - len(failed)}/{len(results)} passed" + (": FAILED " + ", ".join(failed) if failed else ""))
sys.exit(1 if failed else 0)
