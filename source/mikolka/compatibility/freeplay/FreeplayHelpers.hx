package mikolka.compatibility.freeplay;

import haxe.Exception;
import haxe.Json;
import backend.StageData;
import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;
import mikolka.vslice.components.crash.UserErrorSubstate;
import openfl.utils.AssetType;
import mikolka.vslice.freeplay.pslice.BPMCache;
import mikolka.vslice.freeplay.FreeplayState;
import backend.Song;
import backend.Highscore;
import backend.WeekData;

class FreeplayHelpers
{
	public static var BPM(get, set):Float;

	public static function set_BPM(value:Float)
	{
		Conductor.bpm = value;
		return value;
	}

	public static function get_BPM()
	{
		return Conductor.bpm;
	}

	public static function loadSongs():Array<FreeplaySongData>
	{
		var songs = [];
		WeekData.reloadWeekFiles(false);
		// programmatically adds the songs via LevelRegistry and SongRegistry
		for (i in 0...WeekData.weeksList.length)
		{
			if (weekIsLocked(WeekData.weeksList[i]))
				continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]); // TODO tweak this
			if (leWeek == null)
				continue;

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				// trace("pushing "+song);
				var colors:Array<Int> = song[2];
				if (colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				var sngCard = new FreeplaySongData(i, song[0], song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
				// songName, weekNum, songCharacter, color
				if (sngCard.songDifficulties.length == 0)
					continue;

				songs.push(sngCard);
			}
		}
		return songs;
	}

	public static function moveToPlaystate(state:FreeplayState, cap:FreeplaySongData, currentDifficulty:String, ?targetInstId:String)
	{
		// FunkinSound.emptyPartialQueue();

		// Paths.setCurrentLevel(cap.songData.levelId);
		state.persistentUpdate = false;
		Mods.currentModDirectory = cap.folder;

		var diffId = cap.loadAndGetDiffId();
		if (diffId == -1)
		{
			trace("SELECTED DIFFICULTY IS MISSING: " + currentDifficulty);
			diffId = 0;
		}
		if (targetInstId != null && targetInstId != "default")
		{
			var instPath = '${Paths.formatToSongPath(targetInstId)}/Inst.ogg';
			if (Paths.fileExists(instPath, AssetType.BINARY, false, "songs"))
			{
				PlayState.altInstrumentals = targetInstId;
			}
			else
			{
				@:privateAccess
				state.capsuleOptionsMenu.busy = false;
				UserErrorSubstate.makeMessage("Missing instrumentals", 'Couldn\'t find Inst in \nsongs/${instPath}\nMake sure that there is a Inst.ogg file');
				return;
			}
		}
		else
			PlayState.altInstrumentals = null; // ? P-Slice

		var songLowercase:String = Paths.formatToSongPath(cap.getNativeSongId());
		var poop:String = Highscore.formatSong(songLowercase, diffId); // TODO //currentDifficulty);
		/*#if MODS_ALLOWED
			if(!NativeFileSystem.exists(Paths.modsJson(songLowercase + '/' + poop)) && !NativeFileSystem.exists(Paths.json(songLowercase + '/' + poop))) {
			#else
			if(!OpenFlAssets.exists(Paths.json(songLowercase + '/' + poop))) {
			#end
				poop = songLowercase;
				curDifficulty = 1;
				trace('Couldnt find file');
		}*/
		trace(poop);

		try
		{
			PlayState.SONG = Song.loadFromJson(poop, songLowercase);
			if(PlayState.SONG == null) throw "Song parsing failed!";
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = diffId;

			var directory = StageData.forceNextDirectory;
			LoadingState.loadNextDirectory();
			StageData.forceNextDirectory = directory;

			// @:privateAccess
			// if(PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
			// {
			// 	trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
			// 	Paths.freeGraphicsFromMemory();
			// }
			#if STRICT_LOADING_SCREEN
			if (!backend.ClientPrefs.data.strictLoadingScreen)
				LoadingState.prepareToSong();
			#end

			trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
		}
		catch (e:Exception)
		{
			trace('ERROR! $e');
			UserErrorSubstate.makeMessage("Failed to load a song", '${e.message}\n\n${e.details()}');
			@:privateAccess {
				state.busy = false;
				state.letterSort.inputEnabled = true;
			}
			return;
		}

		#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
		LoadingState.loadAndSwitchState(new PlayState(), true);

		FlxG.sound.music.volume = 0;

		#if (MODS_ALLOWED && DISCORD_ALLOWED)
		DiscordClient.loadModRPC();
		#end
	}

	/**
	 * Returns whether this pack wants Story Mode/Freeplay to stay locked
	 * until the player has viewed the lore.
	 *
	 * pack.json:
	 * {
	 *     "lockStoryFreeplayUntilLore": true
	 * }
	 */
	public static function loreLockEnabled():Bool
	{
		if (!Paths.fileExists('pack.json', TEXT))
			return false;

		try
		{
			var packData:Dynamic = Json.parse(Paths.getTextFromFile('pack.json'));
			return Reflect.hasField(packData, 'lockStoryFreeplayUntilLore')
				&& Reflect.field(packData, 'lockStoryFreeplayUntilLore') == true;
		}
		catch (e:Dynamic)
		{
			trace('[LoreLock] Failed to read pack.json: ' + e);
			return false;
		}
	}

	static function loreSaveKey():String
	{
		var packName:String = 'default';
		if (Paths.fileExists('pack.json', TEXT))
		{
			try
			{
				var packData:Dynamic = Json.parse(Paths.getTextFromFile('pack.json'));
				if (Reflect.hasField(packData, 'name'))
				{
					var parsedName:String = Std.string(Reflect.field(packData, 'name'));
					if (parsedName != null && parsedName.length > 0)
						packName = parsedName;
				}
			}
			catch (e:Dynamic) {}
		}

		// Keep the save key safe and separate for different packs.
		// Do not use StringTools.replace() here: P-Slice's StringTools
		// is mikolka.funkin.utils.StringTools and does not provide replace().
		packName = packName.split(' ').join('_');
		packName = packName.split('/').join('_');
		packName = packName.split('\\\\').join('_');
		return 'pslice_lore_viewed_' + packName;
	}

	public static function hasViewedLore():Bool
	{
		if (!loreLockEnabled())
			return true;

		var value:Dynamic = Reflect.field(FlxG.save.data, loreSaveKey());
		return value == true;
	}

	public static function markLoreViewed():Void
	{
		if (!loreLockEnabled())
			return;

		Reflect.setField(FlxG.save.data, loreSaveKey(), true);
		FlxG.save.flush();
	}

	public static function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		if (leWeek == null)
			return true;

		// Developer mode bypasses the pack's lore lock and normal week locks.
		if (backend.ClientPrefs.data.devMode)
			return false;

		if (loreLockEnabled() && !hasViewedLore())
			return true;

		return (!leWeek.startUnlocked
			&& leWeek.weekBefore != null
			&& leWeek.weekBefore.length > 0
			&& (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	public static function exitFreeplay()
	{
		BPMCache.instance.clearCache();
		Mods.loadTopMod();
		FlxG.signals.postStateSwitch.dispatch(); // ? for the screenshot plugin to clean itself
	}

	public inline static function openResetScoreState(state:FreeplayState, sng:FreeplaySongData, onScoreReset:() -> Void = null)
	{
		state.openSubState(new ResetScoreSubState(sng.songName, sng.loadAndGetDiffId(), sng.songCharacter, -1, onScoreReset));
	}

	public inline static function openGameplayChanges(state:FreeplayState)
	{
		if (!backend.ClientPrefs.data.devMode)
			return;

		state.openSubState(new GameplayChangersSubstate());
	}

	public static function loadDiffsFromWeek(songData:FreeplaySongData)
	{
		Mods.currentModDirectory = songData.folder;
		PlayState.storyWeek = songData.levelId; // TODO
		Difficulty.loadFromWeek();
	}

	public static function getDifficultyName()
	{
		return Difficulty.list[PlayState.storyDifficulty].toUpperCase();
	}

	public static function updateConductorSongTime(time:Float)
	{
		Conductor.songPosition = time;
	}
}
