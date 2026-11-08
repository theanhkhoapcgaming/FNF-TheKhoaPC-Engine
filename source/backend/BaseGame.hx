package backend;

import haxe.Json;
import mikolka.funkin.custom.NativeFileSystem;

/** Filesystem-backed Base Game pack. Core week/song data is required at runtime. */
class BaseGame
{
	public static inline var DIRECTORY:String = "assets/basegame";
	public static inline var PACK_FILE:String = "pack.json";

	public static inline function path(?relative:String = ""):String
		return relative == null || relative.length == 0 ? DIRECTORY : DIRECTORY + "/" + relative;

	public static function readPack():Dynamic
	{
		var file = path(PACK_FILE);
		if (!NativeFileSystem.exists(file)) return null;
		try
		{
			var content = NativeFileSystem.getContent(file);
			if (content == null || trimWhitespace(content).length == 0) return null;
			var pack:Dynamic = Json.parse(content);
			if (pack == null || Reflect.field(pack, "name") == null) return null;
			return pack;
		}
		catch (e:Dynamic)
		{
			trace('[BaseGame] Invalid pack.json: ' + e);
			return null;
		}
	}

	static function hasFiles(directory:String):Bool
	{
		if (!NativeFileSystem.exists(directory) || !NativeFileSystem.isDirectory(directory)) return false;
		for (entry in NativeFileSystem.readDirectory(directory))
		{
			var child = directory + "/" + entry;
			if (NativeFileSystem.isDirectory(child))
			{
				if (hasFiles(child)) return true;
			}
			else if (entry.length > 0) return true;
		}
		return false;
	}

	/** Trim whitespace without relying on the project's custom StringTools class. */
	static function trimWhitespace(value:String):String
	{
		return ~/^\s+|\s+$/g.replace(value, "");
	}

	/** Validate actual week definitions. weekList.txt is preferred, but the engine
	 * also supports discovering individual week JSON files directly from weeks/.
	 */
	static function hasValidWeekData():Bool
	{
		var weeksDir = path("weeks");
		if (!NativeFileSystem.exists(weeksDir) || !NativeFileSystem.isDirectory(weeksDir)) return false;
		var candidates:Array<String> = [];
		var listPath = path("weeks/weekList.txt");
		if (NativeFileSystem.exists(listPath))
		{
			var rawList = NativeFileSystem.getContent(listPath);
			if (rawList != null)
				for (line in rawList.split("\n"))
				{
					var name = trimWhitespace(line.replace("\r", ""));
					if (name.length == 0 || name.charAt(0) == "#") continue;
					var candidate = path("weeks/" + name + ".json");
					if (NativeFileSystem.exists(candidate) && !candidates.contains(candidate)) candidates.push(candidate);
				}
		}
		// Match WeekData's fallback behavior: discover JSON files even without a list.
		for (entry in NativeFileSystem.readDirectory(weeksDir))
		{
			if (entry.toLowerCase().endsWith(".json"))
			{
				var candidate = path("weeks/" + entry);
				if (!candidates.contains(candidate)) candidates.push(candidate);
			}
		}
		for (candidate in candidates)
		{
			try
			{
				var rawWeek = NativeFileSystem.getContent(candidate);
				if (rawWeek == null || trimWhitespace(rawWeek).length == 0) continue;
				var week:Dynamic = Json.parse(rawWeek);
				var songs:Dynamic = Reflect.field(week, "songs");
				if (songs != null && Std.isOfType(songs, Array) && (cast songs:Array<Dynamic>).length > 0)
					return true;
			}
			catch (e:Dynamic)
				trace('[BaseGame] Invalid week file ' + candidate + ': ' + e);
		}
		return false;
	}

	/** Base Game is incomplete if either its week definitions or song assets are absent. */
	public static function isInstalled():Bool
	{
		return readPack() != null
			&& hasValidWeekData()
			&& hasFiles(path("songs"));
	}

	public static function missingMessage():String
		return 'BASE GAME IS MISSING OR INCOMPLETE\n\n'
			+ 'The engine cannot start because required Base Game data was not found or is invalid.\n\n'
			+ 'Expected folder: ' + DIRECTORY + '\n'
			+ 'Required: pack.json, at least one valid JSON week with a non-empty songs array, and actual files under songs/. A weekList.txt is recommended but individual week JSON files can also be discovered.\n\n'
			+ 'Restore/update the complete Base Game files, then launch again.';
}
