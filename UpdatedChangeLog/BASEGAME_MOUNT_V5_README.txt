NEWER SOURCE - BASE GAME GLOBAL PACK MOUNT (v5)

What this patch does
- Mounts assets/basegame/ as a virtual mod pack identified by __BASE_GAME__.
- Routes legacy Paths.mods("__BASE_GAME__/...") calls to assets/basegame/... so direct mod file lookups (including songs, data JSON, achievements, videos, fonts and other pack content) can resolve Base Game files.
- Keeps Base Game at the front of global pack lookup while allowing the currently selected mod to override it.
- Loads week JSON files from assets/basegame/weeks/, using weekList.txt when present and discovering .json files when it is absent.
- Checks that pack.json, at least one valid week JSON with a non-empty songs array, and actual song files exist before startup.
- Adds a WeekData trace line showing which week IDs were actually loaded.

Important
- The uploaded NEWERsource.zip contains source code only; it does not contain the actual assets/basegame data files. Therefore this archive integrates/mounts the Base Game data directory, but cannot physically bundle data that was not included in the upload.
- Keep the real Base Game content at export/release/windows/bin/assets/basegame/ (beside the executable's assets folder) for a Windows build using NATIVE_LOOKUP.
- Rebuild the executable from this source. Replacing source files without rebuilding does not change the existing EXE.
- This patch has not been compiled in this environment because Haxe is not installed here.
