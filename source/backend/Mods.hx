package backend;

import mikolka.vslice.components.crash.CrashServer;
import openfl.utils.Assets;
import haxe.Json;

typedef ModsList = {
	enabled:Array<String>,
	disabled:Array<String>,
	all:Array<String>
};

class Mods
{
	/** Virtual entry used by the Mod State for the separately stored Base Game pack. */
	public static inline var BASE_GAME_ID:String = "__BASE_GAME__";

	public static inline function isBaseGameFolder(folder:String):Bool
		return folder == BASE_GAME_ID;

	public static function hasEnabledIndependentMod(?enabledMods:Array<String>, ?excluding:String = null):Bool
	{
		if (enabledMods == null) enabledMods = parseList().enabled;
		for (mod in enabledMods)
		{
			if (isBaseGameFolder(mod) || mod == excluding) continue;
			var pack:Dynamic = getPack(mod);
			if (pack != null && Reflect.field(pack, "IndependentMod") == true) return true;
		}
		return false;
	}

	public static function canDisableBaseGame(?enabledMods:Array<String>):Bool
		return hasEnabledIndependentMod(enabledMods);

	static public var currentModDirectory(default,set):String = '';
	public static final ignoreModFolders:Array<String> = [
		'characters',
		'custom_events',
		'custom_notetypes',
		'registry',
		'data',
		'songs',
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'achievements'
	];

	private static var globalMods:Array<String> = [];

	inline public static function getGlobalMods()
		return globalMods;

	inline public static function pushGlobalMods() // prob a better way to do this but idc
	{
		globalMods = [];
		for(mod in parseList().enabled)
		{
			var pack:Dynamic = getPack(mod);
			// The Base Game is globally available whenever enabled, regardless of pack.json flags.
			if(isBaseGameFolder(mod) || (pack != null && pack.runsGlobally)) globalMods.push(mod);
		}
		CrashServer.updateGlobalMods(globalMods);
		return globalMods;
	}

	inline public static function getModDirectories():Array<String>
	{
		var list:Array<String> = [];
		#if MODS_ALLOWED
		var modsFolder:String = Paths.mods();
		if(NativeFileSystem.exists(modsFolder)) {
			for (folder in NativeFileSystem.readDirectory(modsFolder))
			{
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (NativeFileSystem.isDirectory(path) && !ignoreModFolders.contains(folder.toLowerCase()) && !list.contains(folder))
					list.push(folder);
			}
		}
		#end
		return list;
	}
	
	inline public static function mergeAllTextsNamed(path:String, ?defaultDirectory:String = null, allowDuplicates:Bool = false)
	{
		if(defaultDirectory == null) defaultDirectory = Paths.getSharedPath();
		defaultDirectory = defaultDirectory.trim();
		if(!defaultDirectory.endsWith('/')) defaultDirectory += '/';
		if(!defaultDirectory.startsWith('assets/')) defaultDirectory = 'assets/$defaultDirectory';

		var mergedList:Array<String> = [];
		var paths:Array<String> = directoriesWithFile(defaultDirectory, path);

		var defaultPath:String = defaultDirectory + path;
		if(paths.contains(defaultPath))
		{
			paths.remove(defaultPath);
			paths.insert(0, defaultPath);
		}
		// The Base Game pack has priority over bundled shared data and other global mods.
		var basePath:String = BaseGame.path(path);
		if (Mods.getGlobalMods().contains(Mods.BASE_GAME_ID) && paths.contains(basePath))
		{
			paths.remove(basePath);
			paths.insert(0, basePath);
		}

		for (file in paths)
		{
			var list:Array<String> = CoolUtil.coolTextFile(file);
			for (value in list)
				if((allowDuplicates || !mergedList.contains(value)) && value.length > 0)
					mergedList.push(value);
		}
		return mergedList;
	}

	inline public static function directoriesWithFile(path:String, fileToFind:String, mods:Bool = true)
	{
		var foldersToCheck:Array<String> = [];
		if(NativeFileSystem.exists(path + fileToFind))
			foldersToCheck.push(path + fileToFind);

		// Week folder
		if(Paths.currentLevel != null && Paths.currentLevel != path)
		{
			var pth:String = Paths.getFolderPath(fileToFind, Paths.currentLevel);
			if(NativeFileSystem.exists(pth))
				foldersToCheck.push(pth);
		}

		#if MODS_ALLOWED
		if(mods)
		{
			// Global mods first
			for(mod in Mods.getGlobalMods())
			{
				var folder:String = Mods.isBaseGameFolder(mod) ? BaseGame.path(fileToFind) : Paths.mods(mod + '/' + fileToFind);
				if(NativeFileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
			}

			// Then "PsychEngine/mods/" main folder
			var folder:String = Paths.mods(fileToFind);
			if(NativeFileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(Paths.mods(fileToFind));

			// And lastly, the loaded mod's folder
			if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			{
				var folder:String = Paths.mods(Mods.currentModDirectory + '/' + fileToFind);
				if(NativeFileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);

			}
		}
		#end
		return foldersToCheck;
	}

	public static function getPack(?folder:String = null):Dynamic
	{
		#if MODS_ALLOWED
		if(folder == null) folder = Mods.currentModDirectory;
		if (isBaseGameFolder(folder)) return BaseGame.readPack();

		var path = Paths.mods(folder + '/pack.json');
		if(NativeFileSystem.exists(path)) {
			try {
				var rawJson:String = NativeFileSystem.getContent(path);
				if(rawJson != null && rawJson.length > 0) return tjson.TJSON.parse(rawJson);
			} catch(e:Dynamic) {
				trace(e);
			}
		}
		#end
		return null;
	}

	/** Read per-user mod toggles, falling back to the legacy relative path for upgrades. */
	private static function readSavedModList():Array<String>
	{
		var userPath:String = StorageUtil.getStorageDirectory() + 'modsList.txt';
		try
		{
			if (NativeFileSystem.exists(userPath))
			{
				var content:String = NativeFileSystem.getContent(userPath);
				if (content != null) return CoolUtil.listFromString(content);
			}
		}
		catch (e:Dynamic)
			trace('[Mods] Could not read user mod list: ' + e);
		return CoolUtil.coolTextFile('modsList.txt');
	}

	public static var updatedOnState:Bool = false;
	inline public static function parseList():ModsList {
		if(!updatedOnState) updateModList();
		var list:ModsList = {enabled: [], disabled: [], all: []};

		#if MODS_ALLOWED
		try {
			for (mod in readSavedModList())
			{
				//trace('Mod: $mod');
				if(mod.trim().length < 1) continue;

				var dat = mod.split("|");
				list.all.push(dat[0]);
				if (dat[1] == "1")
					list.enabled.push(dat[0]);
				else
					list.disabled.push(dat[0]);
			}
		} catch(e) {
			trace(e);
		}
		#end
		return list;
	}
	
	/**
	 * Reads pack enablement defaults from mods/modList.txt.
	 * User choices are stored separately in the user's data directory and take precedence.
	 * Format: FolderName|1 (enabled by default) or FolderName|0 (disabled by default).
	 */
	private static function getDefaultModEnabled(folder:String):Bool
	{
		var configPath:String = Paths.mods('modList.txt');
		if (!NativeFileSystem.exists(configPath)) return true;
		try
		{
			var lines = CoolUtil.coolTextFile(configPath);
			for (line in lines)
			{
				var value = line.trim();
				if (value.length == 0 || value.charAt(0) == '#') continue;
				var data = value.split('|');
				if (data.length >= 2 && data[0].trim() == folder)
					return data[1].trim() == '1' || data[1].trim().toLowerCase() == 'true' || data[1].trim().toLowerCase() == 'enabled';
			}
		}
		catch (e:Dynamic)
			trace('[Mods] Could not read mods/modList.txt: ' + e);
		return true;
	}

	private static function updateModList()
	{
		#if MODS_ALLOWED
		// Find all that are already ordered
		var list:Array<Array<Dynamic>> = [];
		var added:Array<String> = [];
		try {
			for (mod in readSavedModList())
			{
				var dat:Array<String> = mod.split("|");
				var folder:String = dat[0];
				if (isBaseGameFolder(folder)) continue; // rebuilt as the first, always-enabled entry below
				if(folder.trim().length > 0 && NativeFileSystem.exists(Paths.mods(folder)) && NativeFileSystem.isDirectory(Paths.mods(folder)) && !added.contains(folder))
				{
					added.push(folder);
					list.push([folder, (dat[1] == "1")]);
				}
			}
		} catch(e) {
			trace(e);
		}
		
		// Scan for folders that aren't on modsList.txt yet
		for (folder in getModDirectories())
		{
			if(folder.trim().length > 0 && NativeFileSystem.exists(Paths.mods(folder)) && NativeFileSystem.isDirectory(Paths.mods(folder)) &&
			!ignoreModFolders.contains(folder.toLowerCase()) && !added.contains(folder))
			{
				added.push(folder);
				list.push([folder, getDefaultModEnabled(folder)]); // User data overrides these defaults once the mod is saved.
				//Shadow Mario (2023): What the fuck was bb thinking
			}
		}

		// Base Game is a first-class pack, stored outside mods/ and always listed first.
		list.insert(0, [BASE_GAME_ID, true]);

		// Now save file
		var fileStr:String = '';
		for (values in list)
		{
			if(fileStr.length > 0) fileStr += '\n';
			fileStr += values[0] + '|' + (values[1] ? '1' : '0');
		}
		try{
			File.saveContent( StorageUtil.getStorageDirectory() + 'modsList.txt', fileStr);
		}
		catch(x:Exception){} // In case you don't move it from AppTranslocation
		updatedOnState = true;
		//trace('Saved modsList.txt');
		#end
	}

	public static function loadTopMod()
	{
		Mods.currentModDirectory = '';
		
		#if MODS_ALLOWED
		var list:Array<String> = Mods.parseList().enabled;
		if (list != null)
		{
			for (mod in list)
			{
				if (isBaseGameFolder(mod)) continue;
				Mods.currentModDirectory = mod;
				break;
			}
		}
		#end
	}

	static function set_currentModDirectory(value:String):String {
		CrashServer.updateModDir(value);
		return currentModDirectory = value;
	}
}