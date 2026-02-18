# Blade & Sorcery Mod Doctor

A diagnostic utility that parses your `Player.log` and identifies problematic mods.

## What it does

- **Outdated mods** – Wrong game version (won't load)
- **Broken mods** – Corrupted JSON files
- **Missing ColliderGroups** – Items with physics issues (shows which mod)
- **Missing assets** – References to non-existent files (shows which mod)

## Requirements

- Windows
- PowerShell (built into Windows)

## Usage

1. Launch Blade & Sorcery at least once (to generate `Player.log`)
2. Double-click **ModDoctor.bat**

The script auto-detects your log file in:
- `%USERPROFILE%\AppData\LocalLow\Warpfrog\BladeAndSorcery\Player.log`
- Same folder as the script
- `Documents\My Games\BladeAndSorcery\`

### Custom log path

```powershell
.\ModDoctor.ps1 -LogPath "C:\path\to\Player.log"
```

## Files

| File | Description |
|------|--------------|
| `ModDoctor.bat` | Launcher – double-click to run |
| `ModDoctor.ps1` | Main script – parses the log |
| `README.txt` | User instructions |

## Safety

- No installer, no .exe, no admin rights
- All files are plain text – open in Notepad to verify
- Reads your log file only – does not modify anything
- No internet access

## License

MIT – use, modify, distribute freely.
