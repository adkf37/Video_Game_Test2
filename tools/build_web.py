"""Export a versioned Godot web build and a minimal Cloud Run deployment context."""
import argparse, datetime, gzip, json, shutil, subprocess
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--godot", required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
stage = (root / "build/cloudrun").resolve()
# This is generated output only. Check the absolute target before replacing it.
if stage != (root / "build" / "cloudrun").resolve() or not stage.is_relative_to(root / "build"):
    raise RuntimeError("Invalid build destination")
if stage.exists():
    shutil.rmtree(stage)
public = stage / "public"
public.mkdir(parents=True)
revision = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], cwd=root, text=True).strip()
version = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%d-%H%M%S") + "-" + revision
game = public / "game" / version
game.mkdir(parents=True)
for name in ["Dockerfile", "nginx.conf"]:
    shutil.copy2(root / "web" / name, stage / name)
for name in ["index.html", "site.css", "site.js", "favicon.svg"]:
    shutil.copy2(root / "web" / name, public / name)
shutil.copy2(root / "artifacts/update-split-screen.png", public / "preview.png")
shutil.copytree(root / "web/mobile", public / "mobile")
for command in [
    [args.godot, "--headless", "--path", str(root / "godot"), "--editor", "--import", "--quit"],
    [args.godot, "--headless", "--path", str(root / "godot"), "--export-release", "Web", str(game / "index.html")]
]:
    result = subprocess.run(command, cwd=root, capture_output=True, text=True)
    log = result.stdout + result.stderr
    print(log[-7000:])
    if result.returncode or "SCRIPT ERROR:" in log or "\nERROR:" in log:
        raise RuntimeError("Godot web build failed")
required = ["index.html", "index.js", "index.wasm", "index.pck"]
if not all((game / name).exists() for name in required):
    raise RuntimeError("Export is missing required files")
shutil.copy2(root / "web/mobile-engine.js", game / "mobile-engine.js")
entry = game / "index.html"
entry.write_text(entry.read_text(encoding="utf-8").replace("<head>", '<head>\n<script src="mobile-engine.js"></script>', 1), encoding="utf-8")
download_size = 0
for path in public.rglob("*"):
    if not path.is_file(): continue
    if path.suffix in [".wasm", ".pck", ".js", ".html", ".css", ".json"]:
        compressed = gzip.compress(path.read_bytes(), compresslevel=9, mtime=0)
        path.with_name(path.name + ".gz").write_bytes(compressed)
        if path.is_relative_to(game): download_size += len(compressed)
    elif path.is_relative_to(game):
        download_size += path.stat().st_size
metadata = {
    "version": version,
    "gamePath": "/game/" + version + "/index.html",
    "downloadMiB": round(download_size / 1024 / 1024, 1),
    "engine": "Godot 4.6.3",
    "threaded": False,
}
(public / "build.json").write_text(json.dumps(metadata, indent=2) + "\n")
(stage / ".gcloudignore").write_text(".git\n.gcloudignore\n")
print("BUILD READY", json.dumps(metadata))
print("DEPLOYMENT CONTEXT", stage)
