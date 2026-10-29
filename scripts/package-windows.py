#!/usr/bin/env python3
"""Package an existing MinGW Windows build from Linux. Never executes PE files."""
import argparse,hashlib,json,re,shutil,subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('--qt',required=True,type=Path)
p.add_argument('--exe',required=True,type=Path)
p.add_argument('--runtime',required=True,type=Path)
p.add_argument('--output',required=True,type=Path)
p.add_argument('--receiver',type=Path)
a=p.parse_args(); out=a.output
# Refuse to package over an earlier run, so stale DLLs can never ship.
if out.exists() and any(out.iterdir()): raise SystemExit(f'{out} is not empty; remove it first')
out.mkdir(parents=True,exist_ok=True)
shutil.copy2(a.exe,out/'FakeClicker.exe')
if a.receiver: shutil.copy2(a.receiver,out/'FakeClickerReceiver.exe')
shutil.copytree(a.qt/'qml',out/'qml',dirs_exist_ok=True)
for group in ['platforms','imageformats','iconengines']:
    shutil.copytree(a.qt/'plugins'/group,out/'plugins'/group,dirs_exist_ok=True)
# The compiler's own runtime wins over the copies in the Qt kit: the EXE was linked against it.
lookup={p.name.lower():p for d in [a.qt/'bin',a.runtime] for p in d.glob('*.dll')}
system=set('imagehlp authz shcore advapi32 avrt bcrypt cfgmgr32 comctl32 comdlg32 crypt32 d2d1 d3d9 d3d11 d3d12 dcomp dnsapi dwmapi dwrite dxgi dxguid gdi32 glu32 hid imm32 iphlpapi kernel32 mpr msvcrt msimg32 ncrypt netapi32 normaliz ntdll ole32 oleaut32 opengl32 powrprof propsys psapi rpcrt4 secur32 setupapi shell32 shlwapi user32 userenv usp10 uxtheme version winhttp wininet winmm winscard winspool wintrust ws2_32 wtsapi32 ucrtbase'.split())
seen=set(); missing=set(); copied=[]
for name in ['opengl32sw.dll','d3dcompiler_47.dll']:
    if name in lookup: shutil.copy2(lookup[name],out/name)
queue=list(out.rglob('*.dll'))+list(out.glob('*.exe'))
while queue:
    binary=queue.pop()
    if str(binary) in seen: continue
    seen.add(str(binary))
    result=subprocess.run(['x86_64-w64-mingw32-objdump','-p',str(binary)],capture_output=True,text=True,check=True)
    for name in re.findall(r'DLL Name:\s*(\S+)',result.stdout):
        low=name.lower()
        if low.startswith(('api-ms-','ext-ms-')) or low.removesuffix('.dll') in system: continue
        dest=out/name
        if dest.exists(): continue
        source=lookup.get(low)
        if source is None: missing.add(name); continue
        shutil.copy2(source,dest); queue.append(dest); copied.append(name)
(out/'qt.conf').write_text('[Paths]\nPrefix=.\nPlugins=plugins\nQmlImports=qml\n')
report={'PE_files_audited':len(seen),'dependency_DLLs_copied':len(copied),'unresolved_non_system_DLLs':sorted(missing),'note':'Static import audit, not proof of Windows runtime or delay-loaded system APIs.'}
(out/'dependency-audit.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))
if missing: raise SystemExit(1)
# Ship the user docs, sample profiles and the licences of everything bundled (Qt, GCC runtime, Geist).
for name in ['START-HERE.txt','README.md','DESIGN.md','QA.md','REFERENCES.md','Как работает Fake Clicker.md']:
    shutil.copy2(root/name,out/name)
for folder in ['examples','licenses']: shutil.copytree(root/folder,out/folder)
sha=lambda f: hashlib.sha256(f.read_bytes()).hexdigest()
info={'name':'Fake Clicker',
      'version':re.search(r'project\(FakeClicker VERSION (\S+)',(root/'CMakeLists.txt').read_text()).group(1),
      'target':'Windows 10/11 x64, Release, MinGW-w64 (cross-built on Linux)',
      'qt':re.search(r'QT_VERSION = (\S+)',(a.qt/'mkspecs/qconfig.pri').read_text()).group(1),
      'sha256':{f.name:sha(f) for f in sorted(out.glob('*.exe'))},
      'windows_runtime_tested':False,'details':'QA.md'}
(out/'build-info.json').write_text(json.dumps(info,indent=2)+'\n')
files=sorted(f for f in out.rglob('*') if f.is_file())
(out/'SHA256SUMS.txt').write_text(''.join(f'{sha(f)}  {f.relative_to(out).as_posix()}\n' for f in files),encoding='utf-8')
print(f'{len(files)} files, SHA256SUMS.txt and build-info.json written to {out}')
