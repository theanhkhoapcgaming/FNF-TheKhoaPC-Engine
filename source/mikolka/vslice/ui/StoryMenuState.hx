package mikolka.vslice.ui;

import mikolka.vslice.ui.UIEditor;

import mikolka.funkin.custom.mobile.MobileScaleMode;
import mikolka.compatibility.VsliceOptions;
import mikolka.vslice.components.crash.UserErrorSubstate;
import mikolka.compatibility.freeplay.FreeplayHelpers;
import mikolka.compatibility.ui.StoryModeHooks;
import mikolka.compatibility.ModsHelper;
import mikolka.vslice.StickerSubState;
import flixel.group.FlxGroup;
import flixel.graphics.FlxGraphic;
import objects.Character;
#if !LEGACY_PSYCH
import backend.CacheSystem;
import states.editors.MasterEditorMenu;
import backend.WeekData;
import backend.Highscore;
import objects.MenuItem;
import objects.MenuCharacter;
import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;
#else
import Paths as CacheSystem;
import editors.MasterEditorMenu;
#end

class StoryMenuState extends MusicBeatState
{
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

	var scoreText:FlxText;

	private static var lastDifficultyName:String = '';

	public var curDifficulty:Int = 1;

	var txtWeekTitle:FlxText;
	var bgSprite:FlxSprite;
	var headerBar:FlxSprite;
	var weekAccentBg:FlxSprite;	
	var tracklistSprite:FlxSprite;

	public static var curWeek:Int = 0;

	public var curSelectedPartial:Float = 0;

	var txtTracklist:FlxText;

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var grpWeekCharacterPreviews:FlxTypedGroup<Character>;

	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	public var loadedWeeks:Array<WeekData> = [];

	var stickerSubState:StickerSubState;

	inline function isWeekScrollHorizontal():Bool
	{
		return UIEditor.getScrollDirection("story-menu") == "horizontal";
	}

	/** Apply per-mod Story Menu layout overrides. */
	function applyUIEditorLayout():Void
	{
		UIEditor.apply("story-menu", "background", bgSprite);
		UIEditor.apply("story-menu", "headerBar", headerBar);
		UIEditor.apply("story-menu", "weekAccent", weekAccentBg);
		UIEditor.apply("story-menu", "tracksImage", tracklistSprite);
		UIEditor.apply("story-menu", "score", scoreText);
		UIEditor.apply("story-menu", "weekTitle", txtWeekTitle);
		UIEditor.apply("story-menu", "tracklist", txtTracklist);
		UIEditor.apply("story-menu", "leftDifficultyArrow", leftArrow);
		UIEditor.apply("story-menu", "rightDifficultyArrow", rightArrow);
		UIEditor.apply("story-menu", "difficulty", sprDifficulty);
		if (grpWeekText != null)
			for (i in 0...grpWeekText.members.length)
				UIEditor.apply("story-menu", "week_" + i, grpWeekText.members[i]);
		if (grpWeekCharacters != null)
			for (i in 0...grpWeekCharacters.members.length)
				UIEditor.apply("story-menu", "character_" + i, grpWeekCharacters.members[i]);
		if (grpWeekCharacterPreviews != null)
			for (i in 0...grpWeekCharacterPreviews.members.length)
				UIEditor.apply("story-menu", "characterPreview_" + i, grpWeekCharacterPreviews.members[i]);
		if (grpLocks != null)
			for (i in 0...grpLocks.members.length)
				UIEditor.apply("story-menu", "lock_" + i, grpLocks.members[i]);
	}

	public function new(?stickers:StickerSubState = null)
	{
		super();

		if (stickers != null)
		{
			stickerSubState = stickers;
		}
	}

	override function create()
	{
		if (stickerSubState != null)
		{
			// this.persistentUpdate = true;
			// this.persistentDraw = true;

			openSubState(stickerSubState);
			ModsHelper.clearStoredWithoutStickers();
			stickerSubState.degenStickers();
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}
		else
			CacheSystem.clearStoredMemory();
		CacheSystem.clearUnusedMemory();

		persistentUpdate = persistentDraw = true;
		PlayState.isStoryMode = true;
		PlayState.altInstrumentals = null; // ? P-Slice
		WeekData.reloadWeekFiles(true);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		final accept:String = controls.mobileC ? "A" : "ACCEPT";
		final reject:String = controls.mobileC ? "B" : "BACK";

		if (WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			UserErrorSubstate.makeMessage("NO LEVELS ADDED FOR STORY MODE", "\n\nPress " + accept + " to go to the Week Editor Menu.");
			subStateClosed.addOnce(s -> FlxG.switchState(new MasterEditorMenu()));
			return;
		}

		if (curWeek >= WeekData.weeksList.length)
			curWeek = 0;

		#if LEGACY_PSYCH
		scoreText = new FlxText(10, 10, 0, 'LEVEL SCORE: ' + lerpScore, 36);
		#else
		scoreText = new FlxText(10, 10, 0, Language.getPhrase('week_score', 'LEVEL SCORE: {1}', [lerpScore]), 36);
		#end
		scoreText.setFormat(Paths.font("vcr.ttf"), 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		weekAccentBg = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		bgSprite = new FlxSprite(0, 56);
		bgSprite.antialiasing = VsliceOptions.ANTIALIASING;

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		headerBar = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(headerBar);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		var num:Int = 0;
		var itemTargetY:Float = 0;
		for (i in 0...WeekData.weeksList.length)
		{
			var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var isLocked:Bool = FreeplayHelpers.weekIsLocked(WeekData.weeksList[i]);
			if ((!isLocked || !weekFile.hiddenUntilUnlocked) && weekFile != null)
			{
				loadedWeeks.push(weekFile);
				ModsHelper.setDirectoryFromWeek(weekFile);
				var weekThing:MenuItem = new MenuItem(0, bgSprite.y + 396, WeekData.weeksList[i]);
				weekThing.y += ((weekThing.height + 20) * num);
				weekThing.ID = num;
				weekThing.targetY = itemTargetY;
				itemTargetY += Math.max(isWeekScrollHorizontal() ? weekThing.width : weekThing.height, 110) + 10;
				grpWeekText.add(weekThing);

				weekThing.screenCenter(X);
				if (isWeekScrollHorizontal())
					weekThing.y = 480 - weekThing.height / 2;
				// weekThing.updateHitbox();

				// Needs an offset thingie
				if (isLocked)
				{
					var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
					lock.antialiasing = VsliceOptions.ANTIALIASING;
					lock.frames = ui_tex;
					lock.animation.addByPrefix('lock', 'lock');
					lock.animation.play('lock');
					lock.ID = num;
					grpLocks.add(lock);
				}
				num++;
			}
		}

		ModsHelper.setDirectoryFromWeek(loadedWeeks[0]);
		var charArray:Array<String> = loadedWeeks[0].weekCharacters;
		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, charArray[char]);
			weekCharacterThing.y += 70;
			grpWeekCharacters.add(weekCharacterThing);
		}

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		leftArrow = new FlxSprite(FlxG.width - 430, grpWeekText.members[0].y + 10);
		leftArrow.antialiasing = VsliceOptions.ANTIALIASING;
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);

		StoryModeHooks.resetDiffList();
		if (lastDifficultyName == '')
		{
			lastDifficultyName = StoryModeHooks.DEFAULT_DIFF;
		}
		curDifficulty = Math.round(Math.max(0, StoryModeHooks.DEFAULT_DIFFICULTIES.indexOf(lastDifficultyName)));

		sprDifficulty = new FlxSprite(0, leftArrow.y);
		sprDifficulty.antialiasing = VsliceOptions.ANTIALIASING;
		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(leftArrow.x + 376, leftArrow.y);
		rightArrow.antialiasing = VsliceOptions.ANTIALIASING;
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);

		add(new FlxSprite(0, 0).makeGraphic(FlxG.width, 56, 0xFF000000));
		add(weekAccentBg);
		add(bgSprite);
		add(grpWeekCharacters);
		grpWeekCharacterPreviews = new FlxTypedGroup<Character>();
		add(grpWeekCharacterPreviews);

		tracklistSprite = new FlxSprite(FlxG.width * 0.05 + 160, bgSprite.y + 425).loadGraphic(Paths.image('Menu_Tracks'));
		tracklistSprite.antialiasing = VsliceOptions.ANTIALIASING;
		tracklistSprite.x -= tracklistSprite.width / 2;
		add(tracklistSprite);

		txtTracklist = new FlxText(FlxG.width * 0.05, tracklistSprite.y + 60, 0, "", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = Paths.font("vcr.ttf");
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		add(scoreText);
		add(txtWeekTitle);

		changeWeek();
		changeDifficulty();
		applyUIEditorLayout();
		UIEditor.createCustomElements(this, "story-menu");
		UIEditor.applyObjectOrder(this, "story-menu");

		#if TOUCH_CONTROLS_ALLOWED
		addTouchPad('LEFT_FULL', 'A_B_X_Y');

		var button = new TouchZone((FlxG.width / 2) - 210, 460, 420, 160, FlxColor.PURPLE);

		var weekScrollDirection:String = UIEditor.getScrollDirection("story-menu");
		var weekScroll = new ScrollableObject(-0.01, (FlxG.width / 2) - 240, 0, 500, FlxG.height, button, weekScrollDirection);
		weekScroll.onPartialScroll.add(delta -> changeWeek(delta, false));
		weekScroll.onFullScrollSnap.add(() -> changeWeek(0, true));
		weekScroll.onTap.add(() -> selectWeek());
		add(weekScroll);

		// Difficulty uses the opposite drag axis from week selection.
		var difficultyScroll = new ScrollableObject(-0.01, (FlxG.width / 2) - 240, 0, 500, FlxG.height, button, UIEditor.getOppositeScrollDirection("story-menu"));
		difficultyScroll.onFullScroll.add(delta -> changeDifficulty(delta));
		add(difficultyScroll);
		add(button);
		#end

		super.create();
	}

	override function closeSubState()
	{
		persistentUpdate = true;
		if (WeekData.weeksList.length > 0)
			changeWeek();
		super.closeSubState();

		#if TOUCH_CONTROLS_ALLOWED
		removeTouchPad();
		addTouchPad('LEFT_FULL', 'A_B_X_Y');
		#end
	}

	override function update(elapsed:Float)
	{
		UIEditor.updateCustomScript("story-menu", elapsed);
		if (WeekData.weeksList.length < 1)
		{
			if (controls.BACK && !movedBack && !selectedWeek)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				movedBack = true;
				MusicBeatState.switchState(new MainMenuState());
			}
			super.update(elapsed);
			return;
		}

		// scoreText.setFormat(Paths.font("vcr.ttf"), 32);
		if (intendedScore != lerpScore)
		{
			lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 30)));
			if (Math.abs(intendedScore - lerpScore) < 10)
				lerpScore = intendedScore;

			#if LEGACY_PSYCH
			scoreText.text = 'LEVEL SCORE: ${lerpScore}';
			#else
			scoreText.text = Language.getPhrase('week_score', 'LEVEL SCORE: {1}', [lerpScore]);
			#end
		}

		// FlxG.watch.addQuick('font', scoreText.font);

		if (!movedBack && !selectedWeek)
		{
			var changeDiff = false;
			var horizontalWeeks:Bool = isWeekScrollHorizontal();
			var weekPrev:Bool = horizontalWeeks ? controls.UI_LEFT_P : controls.UI_UP_P;
			var weekNext:Bool = horizontalWeeks ? controls.UI_RIGHT_P : controls.UI_DOWN_P;
			if (weekPrev)
			{
				changeWeek(-1, true);
				changeDiff = true;
			}

			if (weekNext)
			{
				changeWeek(1, true);
				changeDiff = true;
			}

			if (FlxG.mouse.wheel != 0)
			{
				changeWeek(-FlxG.mouse.wheel, true);
				changeDifficulty();
			}

			var holdingUiRight = horizontalWeeks ? controls.UI_DOWN : controls.UI_RIGHT;
			var holdingUiLeft = horizontalWeeks ? controls.UI_UP : controls.UI_LEFT;
			var pressedUiLeft = horizontalWeeks ? controls.UI_UP_P : controls.UI_LEFT_P;
			var pressedUiRight = horizontalWeeks ? controls.UI_DOWN_P : controls.UI_RIGHT_P;
			#if TOUCH_CONTROLS_ALLOWED
			#if debug
			if (FlxG.mouse.overlaps(leftArrow))
			{
				holdingUiLeft = true;
				pressedUiLeft = FlxG.mouse.justPressed;
			}
			if (FlxG.mouse.overlaps(rightArrow))
			{
				holdingUiRight = true;
				pressedUiRight = FlxG.mouse.justPressed;
			}
			#end
			if (TouchUtil.overlaps(leftArrow))
			{
				holdingUiLeft = true;
				pressedUiLeft = TouchUtil.justPressed;
			}
			if (TouchUtil.overlaps(rightArrow))
			{
				holdingUiRight = true;
				pressedUiRight = TouchUtil.justPressed;
			}
			#end

			if (holdingUiRight)
				rightArrow.animation.play('press')
			else
				rightArrow.animation.play('idle');

			if (holdingUiLeft)
				leftArrow.animation.play('press');
			else
				leftArrow.animation.play('idle');

			if (pressedUiRight)
				changeDifficulty(1);
			else if (pressedUiLeft)
				changeDifficulty(-1);
			else if (changeDiff)
				changeDifficulty();

			if (FlxG.keys.justPressed.CONTROL #if TOUCH_CONTROLS_ALLOWED || touchPad.buttonX.justPressed #end
				&& backend.ClientPrefs.data.devMode)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubstate());
				#if TOUCH_CONTROLS_ALLOWED
				removeTouchPad();
				#end
			}
			else if (controls.RESET #if TOUCH_CONTROLS_ALLOWED || touchPad.buttonY.justPressed #end)
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubState('', curDifficulty, '', curWeek));
				#if TOUCH_CONTROLS_ALLOWED
				removeTouchPad();
				#end
				// FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			else if (controls.ACCEPT)
				selectWeek();
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			MusicBeatState.switchState(new MainMenuState());
		}

		super.update(elapsed);
		var offY:Float = grpWeekText.members[curWeek].targetY;

		// scroll up (move down)
		var partialDiff = (curSelectedPartial - curWeek);
		var curItem = grpWeekText.members[curWeek];
		if (partialDiff > 0 && grpWeekText.length > curWeek + 1)
		{
			var nextItem = grpWeekText.members[curWeek + 1];
			offY = FlxMath.lerp(curItem.targetY, nextItem.targetY, partialDiff);
		} // negative
		else if (partialDiff < 0 && 0 <= curWeek - 1)
		{
			var prevItem = grpWeekText.members[curWeek - 1];
			offY = FlxMath.lerp(prevItem.targetY, curItem.targetY, 1 + partialDiff);
		}

		var horizontalWeeks:Bool = isWeekScrollHorizontal();
		for (num => item in grpWeekText.members)
		{
			if (horizontalWeeks)
			{
				var targetX:Float = (FlxG.width - item.width) / 2 + (MobileScaleMode.gameCutoutSize.x / 2) + item.targetY - offY;
				var targetY:Float = 480 - item.height / 2;
				item.x = FlxMath.lerp(targetX, item.x, Math.exp(-elapsed * 10.2));
				item.y = FlxMath.lerp(targetY, item.y, Math.exp(-elapsed * 10.2));
			}
			else
				item.y = FlxMath.lerp(item.targetY - offY + 480, item.y, Math.exp(-elapsed * 10.2));
		}

		for (num => lock in grpLocks.members)
		{
			var weekItem:MenuItem = grpWeekText.members[lock.ID];
			lock.x = weekItem.x + weekItem.width + 10;
			lock.y = weekItem.y + weekItem.height / 2 - lock.height / 2;
		}
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		if (!FreeplayHelpers.weekIsLocked(loadedWeeks[curWeek].fileName))
		{
			var succsess = StoryModeHooks.prepareWeek(this);
			if (!succsess)
				return;
			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));

				grpWeekText.members[curWeek].isFlashing = true;
				for (char in grpWeekCharacters.members)
				{
					if (char.character != '' && char.hasConfirmAnimation)
					{
						char.animation.play('confirm');
					}
				}
				stopspamming = true;
			}
			StoryModeHooks.moveWeekToPlayState();
		}
		else
			FlxG.sound.play(Paths.sound('cancelMenu'));
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = StoryModeHooks.DIFFICULTIES.length - 1;
		if (curDifficulty >= StoryModeHooks.DIFFICULTIES.length)
			curDifficulty = 0;

		ModsHelper.setDirectoryFromWeek(loadedWeeks[curWeek]);

		var diff:String = StoryModeHooks.getDifficultyString(curDifficulty);

		// Check for animated difficulties
		if (Paths.fileExists('images/menudifficulties/' + Paths.formatToSongPath(diff) + ".xml",BINARY))
		{
			var newFrames = Paths.getSparrowAtlas('menudifficulties/' + Paths.formatToSongPath(diff));
			sprDifficulty.frames = newFrames;
			sprDifficulty.animation.addByPrefix('idle', 'idle0', 24, true);
			if (VsliceOptions.FLASHBANG)
				sprDifficulty.animation.play('idle');
			sprDifficulty.x = leftArrow.x + 60;
			sprDifficulty.x += (308 - sprDifficulty.width) / 3;
			sprDifficulty.alpha = 0;
			sprDifficulty.y = leftArrow.y - sprDifficulty.height + 50;

			FlxTween.cancelTweensOf(sprDifficulty);
			FlxTween.tween(sprDifficulty, {y: sprDifficulty.y + 30, alpha: 1}, 0.07);
		}
		else
		{
			var newImage:FlxGraphic = Paths.image('menudifficulties/' + Paths.formatToSongPath(diff));
			// trace(Mods.currentModDirectory + ', menudifficulties/' + Paths.formatToSongPath(diff));

			if (sprDifficulty.graphic != newImage)
			{
				sprDifficulty.loadGraphic(newImage);
				sprDifficulty.x = leftArrow.x + 60;
				sprDifficulty.x += (308 - sprDifficulty.width) / 3;
				sprDifficulty.alpha = 0;
				sprDifficulty.y = leftArrow.y - sprDifficulty.height + 50;

				FlxTween.cancelTweensOf(sprDifficulty);
				FlxTween.tween(sprDifficulty, {y: sprDifficulty.y + 30, alpha: 1}, 0.07);
			}
		}
		lastDifficultyName = diff;

		#if !switch
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end
	}

	var lerpScore:Int = 49324858;
	var intendedScore:Int = 0;

	function changeWeek(change:Float = 0, usePrecision:Bool = false):Void
	{
		if (usePrecision)
		{
			if (change != 0)
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			curWeek = FlxMath.wrap(curWeek + Std.int(change), 0, loadedWeeks.length - 1);
			curSelectedPartial = curWeek;
		}
		else
		{
			curSelectedPartial = FlxMath.bound(curSelectedPartial + change, 0, loadedWeeks.length - 1);
			if (curWeek != Math.round(curSelectedPartial))
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

			curWeek = Math.round(curSelectedPartial);
		}

		var leWeek:WeekData = loadedWeeks[curWeek];
		ModsHelper.setDirectoryFromWeek(leWeek);

		#if LEGACY_PSYCH
		var leName:String = leWeek.storyName;
		#else
		var leName:String = Language.getPhrase('storyname_${leWeek.fileName}', leWeek.storyName);
		#end
		txtWeekTitle.text = leName.toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		var unlocked:Bool = !FreeplayHelpers.weekIsLocked(leWeek.fileName);
		for (num => item in grpWeekText.members)
		{
			item.alpha = 0.6;
			if (num - curWeek == 0 && unlocked)
				item.alpha = 1;
		}

		bgSprite.visible = true;
		var assetName:String = leWeek.weekBackground;
		if (assetName == null || assetName.length < 1)
		{
			bgSprite.visible = false;
		}
		else
		{
			bgSprite.loadGraphic(Paths.image('menubackgrounds/menu_' + assetName));
			// In case some 2 year old mod breaks
			if (MobileScaleMode.enabled)
				bgSprite.screenCenter(X);
		}
		PlayState.storyWeek = curWeek;

		StoryModeHooks.loadDifficultiesFromWeek();
		difficultySelectors.visible = unlocked;

		if (StoryModeHooks.DIFFICULTIES.contains(StoryModeHooks.DEFAULT_DIFF))
			curDifficulty = Math.round(Math.max(0, StoryModeHooks.DEFAULT_DIFFICULTIES.indexOf(StoryModeHooks.DEFAULT_DIFF)));
		else
			curDifficulty = 0;

		var newPos:Int = StoryModeHooks.DIFFICULTIES.indexOf(lastDifficultyName);
		// trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if (newPos > -1)
		{
			curDifficulty = newPos;
		}
		updateText();
	}

	/** Build previews directly from character IDs declared in weekdata.json. */
	function refreshWeekCharacterPreviews(week:WeekData):Void
	{
		if (grpWeekCharacterPreviews == null)
			return;

		grpWeekCharacterPreviews.clear();
		if (week.weekCharacterPreviews == null)
			return;

		for (entry in week.weekCharacterPreviews)
		{
			if (entry == null)
				continue;
			var characterId:String = Reflect.hasField(entry, "character") ? Std.string(Reflect.field(entry, "character")) : "";
			if (characterId == null || characterId.length == 0)
				continue;

			// Keep previews responsive to the current window like weekCharacters.
			// x/y are authored at the 1280x720 design resolution and scaled automatically.
			var baseX:Float = Reflect.hasField(entry, "x") ? Std.parseFloat(Std.string(Reflect.field(entry, "x"))) : 0;
			var baseY:Float = Reflect.hasField(entry, "y") ? Std.parseFloat(Std.string(Reflect.field(entry, "y"))) : 0;
			var previewScale:Float = Reflect.hasField(entry, "scale") ? Std.parseFloat(Std.string(Reflect.field(entry, "scale"))) : 1;
			var previewFlipX:Bool = Reflect.hasField(entry, "flipX") && Std.string(Reflect.field(entry, "flipX")).toLowerCase() == "true";
			if (Math.isNaN(baseX)) baseX = 0;
			if (Math.isNaN(baseY)) baseY = 0;
			var px:Float = baseX * (FlxG.width / 1280);
			var py:Float = baseY * (FlxG.height / 720);
			if (Math.isNaN(px)) px = 0;
			if (Math.isNaN(py)) py = 0;
			if (Math.isNaN(previewScale) || previewScale <= 0) previewScale = 1;

			try
			{
				var preview = new Character(px, py, characterId);
				preview.scale.set(previewScale, previewScale);
				preview.flipX = previewFlipX;
				preview.updateHitbox();
				preview.dance();
				grpWeekCharacterPreviews.add(preview);
			}
			catch (e:Dynamic)
			{
				trace('[StoryMenuState] Could not load week character preview "' + characterId + '": ' + e);
			}
		}
	}

	function updateText()
	{
		var weekArray:Array<String> = loadedWeeks[curWeek].weekCharacters;
		for (i in 0...grpWeekCharacters.length)
		{
			grpWeekCharacters.members[i].changeCharacter(weekArray[i]);
		}

		var leWeek:WeekData = loadedWeeks[curWeek];
		refreshWeekCharacterPreviews(leWeek);
		var stringThing:Array<String> = [];
		for (i in 0...leWeek.songs.length)
		{
			stringThing.push(leWeek.songs[i][0]);
		}

		txtTracklist.text = '';
		for (i in 0...stringThing.length)
		{
			txtTracklist.text += stringThing[i] + '\n';
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();

		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		#if !switch
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end
	}

	override function destroy():Void
	{
		UIEditor.destroyCustomScript("story-menu");
		super.destroy();
	}
}
