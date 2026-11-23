"""Build a CurseForge-installable ZIP from only the runtime files."""
from pathlib import Path
import sys
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
toc = root / "ShamanFit.toc"
runtime = [line.strip() for line in toc.read_text().splitlines()
           if line.strip() and not line.startswith("#")]
target = Path(sys.argv[1] if len(sys.argv) > 1 else "ShamanFit.zip").resolve()
target.parent.mkdir(parents=True, exist_ok=True)
temporary = target.with_suffix(".tmp")
with ZipFile(temporary, "w", compression=ZIP_DEFLATED) as archive:
    for name in ["ShamanFit.toc", *runtime, "NOTICE.txt"]:
        archive.write(root / name, "ShamanFit/" + name)
with ZipFile(temporary) as archive:
    assert archive.testzip() is None
temporary.replace(target)
print(target)
