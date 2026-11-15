"""Fetch only the official Godot 4.6.3 web templates from the release archive."""
import io
import os
import urllib.request
import zipfile
from pathlib import Path

URL = "https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable/Godot_v4.6.3-stable_export_templates.tpz"
SIZE = 1255918323

class RemoteArchive(io.RawIOBase):
    def __init__(self):
        self.position = 0
        self.url = URL
    def seekable(self): return True
    def readable(self): return True
    def tell(self): return self.position
    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else (self.position + offset if whence == 1 else SIZE + offset)
        return self.position
    def read(self, size=-1):
        if size < 0: size = SIZE - self.position
        size = min(size, SIZE - self.position)
        if size <= 0: return b""
        request = urllib.request.Request(self.url, headers={"Range": f"bytes={self.position}-{self.position + size - 1}"})
        with urllib.request.urlopen(request, timeout=120) as response:
            if response.status != 206:
                raise RuntimeError("Release server did not honor the partial download request")
            self.url = response.url
            data = response.read()
        if len(data) != size: raise RuntimeError("Incomplete template download")
        self.position += len(data)
        return data

destination = Path(os.environ["APPDATA"]) / "Godot/export_templates/4.6.3.stable"
destination.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(RemoteArchive()) as archive:
    for name in ["web_nothreads_release.zip", "web_nothreads_debug.zip"]:
        path = destination / name
        if path.exists():
            print("Already installed:", name)
            continue
        matches = [entry for entry in archive.namelist() if entry.endswith("/" + name)]
        if len(matches) != 1: raise RuntimeError("Unexpected template archive contents")
        data = archive.read(matches[0])
        with zipfile.ZipFile(io.BytesIO(data)) as template:
            if template.testzip() is not None: raise RuntimeError("Corrupt web template")
        path.write_bytes(data)
        print("Installed:", name, len(data), "bytes", flush=True)
