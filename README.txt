================================================================================
  BLADE & SORCERY MOD DOCTOR
  A diagnostic utility for identifying problematic mods
================================================================================

SAFE & TRANSPARENT
------------------
- No installer, no .exe, no admin rights needed
- All files are plain text - open in Notepad to read them
- ModDoctor.bat only runs the PowerShell script (you can verify this)
- Reads your log file only - does not modify anything

WHAT IT DOES
------------
This PowerShell script reads your Player.log file and identifies:
  - Outdated mods (wrong game version)
  - Broken mods (corrupted JSON files)
  - Missing ColliderGroups (items with physics issues)
  - Missing assets (references to non-existent files)

HOW TO USE
----------
1. Run Blade & Sorcery at least once (to generate Player.log)
2. Double-click ModDoctor.bat

   That's it! The .bat file just runs the script - you can open it in Notepad
   to verify it's safe (no hidden code, no internet, no system changes).

3. Advanced: Custom log path - edit ModDoctor.bat and add -LogPath "C:\path"
   at the end of the powershell line, or run from PowerShell:
   .\ModDoctor.ps1 -LogPath "C:\path\to\Player.log"

WHERE IS PLAYER.LOG?
--------------------
Default location:
  %USERPROFILE%\AppData\LocalLow\Warpfrog\BladeAndSorcery\Player.log

On most systems:
  C:\Users\YourName\AppData\LocalLow\Warpfrog\BladeAndSorcery\Player.log

POWERSHELL EXECUTION POLICY
---------------------------
If you get "script execution is disabled", run PowerShell as Administrator and:
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

Or run the script with bypass:
  powershell -ExecutionPolicy Bypass -File ModDoctor.ps1

RECOMMENDATIONS
---------------
- Mods marked with X won't work - update or remove them
- Warnings may cause visual/physics glitches but the game may still run
- Always run B&S once before using this tool (fresh log = accurate results)

================================================================================
