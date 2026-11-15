package mikolka.vslice.ui.mainmenu;

import mikolka.vslice.freeplay.FreeplayState;
import mikolka.compatibility.freeplay.FreeplayHelpers;
import options.OptionsState;
import flixel.FlxBasic;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.FlxSprite;
import mikolka.vslice.ui.title.TitleState;
import mikolka.vslice.ui.StoryMenuState;
import mikolka.vslice.ui.UIEditor;
import substates.LoreSubState;
import substates.HowToPlaySubState;
import haxe.Json;

#if !LEGACY_PSYCH
#if MODS_ALLOWED
import states.ModsMenuState;
#end
import states.AchievementsMenuState;
import states.CreditsState;
import states.editors.MasterEditorMenu;
#else
import editors.MasterEditorMenu;
#end

import mikolka.compatibility.VsliceOptions;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;

@:access(mikolka.vslice.ui.MainMenuState)
class DesktopMenuState extends FlxBasic
{
	// ============================================================
	// MAIN MENU
	// ============================================================

	var optionShit:Array<String> = [];

	/**
	 * Story Mode and Freeplay are locked until the player views
	 * the Pre-Story Mode Lore. devMode bypasses the lock.
	 */
	function isStoryFreeplayLocked():Bool
	{
		if (ClientPrefs.data.devMode)
			return false;

		return FreeplayHelpers.loreLockEnabled()
			&& !FreeplayHelpers.hasViewedLore();
	}

	function refreshOptionShit():Void
	{
		optionShit = [];

		if (isStoryFreeplayLocked())
		{
			// How To Play occupies Story Mode's normal slot.
			optionShit.push('how_to_play');

			#if MODS_ALLOWED
			optionShit.push('mods');
			#end

			optionShit.push('credits');
		}
		else
		{
			optionShit.push('story_mode');
			optionShit.push('freeplay');

			#if MODS_ALLOWED
			optionShit.push('mods');
			#end

			optionShit.push('credits');
		}
	}

	// ============================================================
	// MAIN MENU STATE
	// ============================================================

	public static var curSelected:Int = 0;

	var selectedSomethin:Bool = false;

	var menuItems:FlxTypedGroup<FlxSprite>;
	var camFollow:FlxObject;

	var host:MainMenuState;

	var gfDance:FlxSprite;
	var gfDanceLeft:Bool = false;
	var gfUseIdle:Bool = false;
	var gfHasDance:Bool = false;

	// ============================================================
	// FIXED BUTTONS
	// ============================================================

	#if ACHIEVEMENTS_ALLOWED
	var achievementItem:FlxSprite;
	#end
	var GF:FlxSprite;
	var optionsItem:FlxSprite;

	// ============================================================
	// CONSTRUCTOR
	// ============================================================

	public function new(host:MainMenuState)
	{
		super();

		this.host = host;
		host.add(this);

		// Always show mouse cursor
		FlxG.mouse.visible = true;

		// ========================================================
		// MENU LOCK STATE
		// ========================================================

		refreshOptionShit();

		// ========================================================
		// BACKGROUND
		// ========================================================

		var yScroll:Float =
			Math.max(
				0.25 - (0.05 * (optionShit.length - 4)),
				0.1
			);

		host.bg.scrollFactor.set(0, yScroll);
		host.bg.updateHitbox();
		host.bg.screenCenter();

		host.magenta.scrollFactor.set(0, yScroll);
		host.magenta.updateHitbox();
		host.magenta.screenCenter();

		// ========================================================
		// CAMERA FOLLOW
		// ========================================================

		camFollow = new FlxObject(0, 0, 1, 1);
		host.add(camFollow);

		// ========================================================
		// MAIN MENU ITEMS
		// ========================================================

		menuItems = new FlxTypedGroup<FlxSprite>();
		host.add(menuItems);

		buildMainMenuItems();

		// ========================================================
		// CAMERA
		// ========================================================

		FlxG.camera.follow(
			camFollow,
			null,
			0.06
		);

		// ========================================================
		// FIXED BUTTONS
		// ========================================================

		createFixedButtons();
		createGF();

		// ========================================================
		// INITIAL SELECTION
		// ========================================================
		// curSelected is static and may still contain the selection
		// from an earlier Main Menu instance. Reset it before
		// touching menuItems so a locked 3-item menu cannot index
		// a stale/null entry and crash.
		curSelected = 0;
		selectedSomethin = false;

		changeItem(0, false);
		applyUIEditorLayout();
		UIEditor.createCustomElements(host, "main-menu");
		UIEditor.applyObjectOrder(host, "main-menu");

		#if TOUCH_CONTROLS_ALLOWED
		host.addTouchPad('UP_DOWN', 'A_B');
		#end
	}


	/** Apply this mod's main-menu layout overrides after UI elements exist. */
	function applyUIEditorLayout():Void
	{
		UIEditor.apply("main-menu", "background", host.bg);
		UIEditor.apply("main-menu", "transitionOverlay", host.magenta);
		UIEditor.apply("main-menu", "gf", GF);
		UIEditor.apply("main-menu", "gfDanceTitle", gfDance);
		UIEditor.apply("main-menu", "options", optionsItem);
		#if ACHIEVEMENTS_ALLOWED
		UIEditor.apply("main-menu", "achievements", achievementItem);
		#end
		if (menuItems != null)
		{
			for (i in 0...menuItems.members.length)
			{
				if (i < optionShit.length)
					UIEditor.apply("main-menu", "menu_" + optionShit[i], menuItems.members[i]);
			}
		}
	}

	/**
	 * Creates menu sprites from the current optionShit list.
	 */
	function buildMainMenuItems():Void
	{
		for (i in 0...optionShit.length)
		{
			var offset:Float =
				108 - (Math.max(optionShit.length, 4) - 4) * 80;

			var menuItem:FlxSprite =
				new FlxSprite(
					100,
					(i * 140) + offset
				);

			menuItem.antialiasing =
				VsliceOptions.ANTIALIASING;

			menuItem.frames =
				Paths.getSparrowAtlas(
					'mainmenu/menu_' + optionShit[i]
				);

			menuItem.animation.addByPrefix(
				'idle',
				optionShit[i] + " basic",
				24
			);

			menuItem.animation.addByPrefix(
				'selected',
				optionShit[i] + " white",
				24
			);

			menuItem.animation.play('idle');
			menuItems.add(menuItem);

			var scr:Float =
				(optionShit.length - 4) * 0.135;

			if (optionShit.length < 6)
				scr = 0;

			menuItem.scrollFactor.set(0, scr);
			menuItem.updateHitbox();
			menuItem.x = 100;
		}
	}

	/**
	 * Rebuilds the menu after LoreSubState closes.
	 * If the lore was completed, How To Play is replaced by
	 * Story Mode and Freeplay is restored immediately.
	 */
	function rebuildMainMenuItems():Void
	{
		// Always rebuild after returning from a substate.
		// The previous version compared the lock state with itself after
		// closing the substate, so it could return without restoring the
		// menu sprites. This is especially noticeable after How To Play
		// because its selected menu item was still being flickered.
		refreshOptionShit();

		if (menuItems != null)
		{
			for (item in menuItems.members)
			{
				if (item != null)
				{
					item.visible = true;
					item.active = true;
					item.alpha = 1.0;
					item.kill();
				}
			}

			menuItems.clear();
			menuItems.visible = true;
		}

		curSelected = 0;
		selectedSomethin = false;

		buildMainMenuItems();

		if (menuItems != null && menuItems.length > 0)
			changeItem(0, false);
		applyUIEditorLayout();
	}


function createGF()
	{
		// ============================================================
		// TITLESTATE-COMPATIBLE GF CONFIG
		// ============================================================
		var characterImage:String = 'gfDanceTitle';
		var animationName:String = 'gfDance';
		var gfPosition:FlxPoint = FlxPoint.get(512, 40);

		var useIdle:Bool = false;
		var hasDanceIndices:Bool = false;

		// TitleState defaults. These are used only when there is
		// no JSON or the JSON cannot be parsed.
		var danceLeftFrames:Array<Int> = [
			15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
			25, 26, 27, 28, 29
		];

		var danceRightFrames:Array<Int> = [
			30, 0, 1, 2, 3, 4, 5, 6, 7, 8,
			9, 10, 11, 12, 13, 14
		];

		var jsonFound:Bool =
			Paths.fileExists('images/gfDanceTitle.json', TEXT);

		var jsonLoaded:Bool = false;

		// ============================================================
		// LOAD JSON THROUGH PATHS
		// ============================================================
		if (jsonFound)
		{
			var titleRaw:String =
				Paths.getTextFromFile('images/gfDanceTitle.json');

			if (titleRaw != null && titleRaw.length > 0)
			{
				try
				{
					#if LEGACY_PSYCH
					var titleJSON:Dynamic = Json.parse(titleRaw);
					#else
					var titleJSON:Dynamic =
						tjson.TJSON.parse(titleRaw);
					#end

					jsonLoaded = true;

					if (titleJSON.animation != null
						&& titleJSON.animation.length > 0)
					{
						animationName = titleJSON.animation;
					}

					// Explicit idle:true always means idle.
					useIdle = (titleJSON.idle == true);

					var hasLeft:Bool =
						titleJSON.dance_left != null
						&& titleJSON.dance_left.length > 0;

					var hasRight:Bool =
						titleJSON.dance_right != null
						&& titleJSON.dance_right.length > 0;

					if (hasLeft && hasRight)
					{
						danceLeftFrames =
							titleJSON.dance_left;

						danceRightFrames =
							titleJSON.dance_right;

						hasDanceIndices = true;
					}
					else
					{
						// A valid Mod JSON without both index arrays
						// is an IDLE configuration.
						useIdle = true;
						hasDanceIndices = false;
					}

					trace(
						'[DesktopMenu] GF JSON loaded: '
						+ (useIdle ? 'IDLE' : 'DANCE')
					);
				}
				catch (e:haxe.Exception)
				{
					trace(
						'[DesktopMenu] WARNING: '
						+ 'gfDanceTitle.json is broken. '
						+ 'Using TitleState defaults.'
					);
				}
			}
		}

		// No JSON -> TitleState defaults -> dance.
		if (!jsonFound)
		{
			hasDanceIndices = true;
			useIdle = false;
		}
		else if (!jsonLoaded)
		{
			// Empty/broken JSON -> TitleState defaults.
			hasDanceIndices = true;
			useIdle = false;
		}

		gfUseIdle = useIdle || !hasDanceIndices;
		gfHasDance = !gfUseIdle;

		// ============================================================
		// CREATE GF SPRITE
		// ============================================================
		gfDance = new FlxSprite();

		gfDance.frames =
			Paths.getSparrowAtlas(characterImage);

		gfDance.antialiasing =
			VsliceOptions.ANTIALIASING;

		gfDance.scrollFactor.set(0, 0);
		gfDance.scale.set(0.7, 0.7);

		gfDance.x =
			FlxG.width
			- gfDance.width
			+ 70;

		gfDance.y =
			FlxG.height
			- gfDance.height
			- 150;

		// ============================================================
		// CREATE ANIMATION
		// ============================================================
		if (gfUseIdle)
		{
			// Mod atlas:
			// gfDance0000, gfDance0001, ...
			//
			// Therefore "gfDance" is the Sparrow prefix.
			gfDance.animation.addByPrefix(
				'idle',
				animationName,
				24,
				true
			);

			gfDance.animation.play(
				'idle',
				true
			);

			trace(
				'[DesktopMenu] GF animation: IDLE / '
				+ animationName
			);
		}
		else
		{
			gfDance.animation.addByIndices(
				'danceLeft',
				animationName,
				danceLeftFrames,
				'',
				24,
				false
			);

			gfDance.animation.addByIndices(
				'danceRight',
				animationName,
				danceRightFrames,
				'',
				24,
				false
			);

			gfDance.animation.play(
				'danceRight',
				true
			);

			trace(
				'[DesktopMenu] GF animation: DANCE / '
				+ animationName
			);
		}

		// GF belongs to MainMenuState, not DesktopMenuState,
		// because DesktopMenuState is only the controller.
		host.add(gfDance);
	}

function danceGF()
	{
		if (gfDance == null || gfUseIdle)
			return;

		gfDanceLeft = !gfDanceLeft;

		if (gfDanceLeft)
			gfDance.animation.play('danceRight', true);
		else
			gfDance.animation.play('danceLeft', true);
	}

	// ============================================================
	// CREATE FIXED BUTTONS
	// ============================================================

	function createFixedButtons():Void
	{
		// ========================================================
		// GF :))
		// ========================================================

		


		// ========================================================
		// ACHIEVEMENTS
		// ========================================================

		#if ACHIEVEMENTS_ALLOWED

		achievementItem = new FlxSprite();

		achievementItem.antialiasing =
			VsliceOptions.ANTIALIASING;

		achievementItem.frames =
			Paths.getSparrowAtlas(
				'mainmenu/menu_achievements'
			);

		achievementItem.animation.addByPrefix(
			'idle',
			'achievements idle',
			24
		);

		achievementItem.animation.addByPrefix(
			'selected',
			'achievements selected',
			24
		);

		achievementItem.animation.play('idle');
		achievementItem.scale.set(0.75, 0.75);
		achievementItem.updateHitbox();

		// --------------------------------------------------------
		// FIXED SCREEN POSITION
		// --------------------------------------------------------

		achievementItem.x =
			FlxG.width
			- achievementItem.width
			- 250;

		achievementItem.y =
			FlxG.height
			- achievementItem.height
			- 10;

		// --------------------------------------------------------
		// DO NOT MOVE WITH CAMERA
		// --------------------------------------------------------

		achievementItem.scrollFactor.set(0, 0);

		host.add(achievementItem);

		#end

		// ========================================================
		// OPTIONS
		// ========================================================

		optionsItem = new FlxSprite();

		optionsItem.antialiasing =
			VsliceOptions.ANTIALIASING;

		optionsItem.frames =
			Paths.getSparrowAtlas(
				'mainmenu/menu_options'
			);

		optionsItem.animation.addByPrefix(
			'idle',
			'options idle',
			24
		);

		optionsItem.animation.addByPrefix(
			'selected',
			'options selected',
			24
		);

		optionsItem.animation.play('idle');
		optionsItem.scale.set(0.75, 0.75);
		optionsItem.updateHitbox();

		// --------------------------------------------------------
		// FIXED SCREEN POSITION
		// --------------------------------------------------------

		optionsItem.x =
			FlxG.width
			- optionsItem.width
			- 40;

		optionsItem.y =
			FlxG.height
			- optionsItem.height
			- 10;

		// --------------------------------------------------------
		// DO NOT MOVE WITH CAMERA
		// --------------------------------------------------------

		optionsItem.scrollFactor.set(0, 0);

		host.add(optionsItem);
	}

	// ============================================================
	// UPDATE
	// ============================================================

	override function update(elapsed:Float)
	{
		UIEditor.updateCustomScript("main-menu", elapsed);
		// Keep cursor visible
		FlxG.mouse.visible = true;

		if (!selectedSomethin)
		{
			// ====================================================
			// KEYBOARD
			// ====================================================

			if (host.controls.UI_UP_P)
				changeItem(-1, true);

			if (host.controls.UI_DOWN_P)
				changeItem(1, true);

			// ====================================================
			// MOUSE MAIN MENU
			// ====================================================

			updateMainMenuMouse();

			// ====================================================
			// MOUSE FIXED BUTTONS
			// ====================================================

			updateFixedButtonsMouse();

			// ====================================================
			// BACK
			// ====================================================

			if (host.controls.BACK)
			{
				selectedSomethin = true;

				FlxG.sound.play(
					Paths.sound('cancelMenu')
				);

				MusicBeatState.switchState(
					new TitleState()
				);
			}

			// ====================================================
			// ACCEPT
			// ====================================================

			if (host.controls.ACCEPT)
			{
				acceptCurrentItem();
			}

			// ====================================================
			// DEBUG (Chỉ cho phép truy cập khi devMode = true)
			// ====================================================

			if (
				ClientPrefs.data.devMode && (
					#if LEGACY_PSYCH
					FlxG.keys.anyJustPressed(
						ClientPrefs.keyBinds
							.get('debug_1')
							.filter(s -> s != -1)
					) || FlxG.keys.justPressed.SEVEN
					#else
					host.controls.justPressed('debug_1') || FlxG.keys.justPressed.SEVEN
					#end
				)
			)
			{
				selectedSomethin = true;

				FlxTransitionableState.skipNextTransIn = false;
				FlxTransitionableState.skipNextTransOut = false;

				MusicBeatState.switchState(
					new MasterEditorMenu()
				);
			}
		}

		super.update(elapsed);
	}

	// ============================================================
	// MOUSE - MAIN MENU
	// ============================================================

	function updateMainMenuMouse():Void
	{
		for (i in 0...menuItems.members.length)
		{
			var item:FlxSprite =
				menuItems.members[i];

			if (item == null)
				continue;

			if (!item.exists || !item.visible)
				continue;

			if (FlxG.mouse.overlaps(item))
			{
				// Mouse hover changes selection
				// WITHOUT playing scrollMenu.

				if (curSelected != i)
				{
					changeItemTo(i);
				}

				// Mouse click
				if (FlxG.mouse.justPressed)
				{
					acceptCurrentItem();
				}

				break;
			}
		}
	}

	// ============================================================
	// MOUSE - FIXED BUTTONS
	// ============================================================

	function updateFixedButtonsMouse():Void
	{
		// ========================================================
		// GF / LORE
		// ========================================================

		if (gfDance != null
			&& gfDance.exists
			&& gfDance.visible
			&& FlxG.mouse.overlaps(gfDance))
		{
			if (FlxG.mouse.justPressed)
			{
				openLoreSubState();
				return;
			}
		}

		// ========================================================
		// ACHIEVEMENTS
		// ========================================================

		#if ACHIEVEMENTS_ALLOWED

		if (
			achievementItem != null
			&& achievementItem.exists
			&& achievementItem.visible
		)
		{
			if (FlxG.mouse.overlaps(achievementItem))
			{
				achievementItem.animation.play(
					'selected'
				);

				achievementItem.centerOffsets();

				if (FlxG.mouse.justPressed)
				{
					acceptFixedButton('awards');
				}
			}
			else
			{
				achievementItem.animation.play(
					'idle'
				);

				achievementItem.centerOffsets();
			}
		}

		#end

		// ========================================================
		// OPTIONS
		// ========================================================

		if (
			optionsItem != null
			&& optionsItem.exists
			&& optionsItem.visible
		)
		{
			if (FlxG.mouse.overlaps(optionsItem))
			{
				optionsItem.animation.play(
					'selected'
				);

				optionsItem.centerOffsets();

				if (FlxG.mouse.justPressed)
				{
					acceptFixedButton('options');
				}
			}
			else
			{
				optionsItem.animation.play(
					'idle'
				);

				optionsItem.centerOffsets();
			}
		}
	}

	function openLoreSubState():Void
	{
		if (!Paths.fileExists('data/lore.txt', TEXT))
		{
			trace('[Lore] data/lore.txt not found. Ignoring lore button.');
			return;
		}

		FlxG.sound.play(Paths.sound('confirmMenu'));

		host.persistentDraw = true;
		host.persistentUpdate = false;

		host.openSubState(new LoreSubState());
		host.subStateClosed.addOnce(function(_)
		{
			host.persistentUpdate = true;

			// The actual Lore screen is what marks the lore as viewed.
			// Re-check the lock after it closes.
			rebuildMainMenuItems();
			selectedSomethin = false;
		});
	}

	function openHowToPlaySubState():Void
	{
		if (!Paths.fileExists('data/unlock.txt', TEXT))
		{
			trace('[HowToPlay] data/unlock.txt not found. Ignoring How To Play button.');
			selectedSomethin = false;
			return;
		}

		FlxG.sound.play(Paths.sound('confirmMenu'));

		host.persistentDraw = true;
		host.persistentUpdate = false;

		host.openSubState(new HowToPlaySubState());
		host.subStateClosed.addOnce(function(_)
		{
			host.persistentUpdate = true;

			// Re-check the lore lock after How To Play closes.
			// The How To Play screen itself does not unlock anything;
			// the actual Lore screen marks the lore as viewed.
			rebuildMainMenuItems();

			// If the lock state did not change, rebuildMainMenuItems()
			// intentionally returns early, so clear the selection lock
			// here as well.
			selectedSomethin = false;
		});
	}

	public function beatHit()
	{
		if (gfDance == null || gfUseIdle || !gfHasDance)
			return;

		danceGF();
	}

	// ============================================================
	// CHANGE ITEM
	// ============================================================

	function changeItem(
		huh:Int = 0,
		playSound:Bool = true
	)
	{
		if (menuItems == null || menuItems.length <= 0)
			return;

		// curSelected is static, so it can outlive the current group.
		// Normalize it before dereferencing the selected member.
		if (curSelected < 0 || curSelected >= menuItems.members.length
			|| menuItems.members[curSelected] == null)
		{
			curSelected = 0;
			while (curSelected < menuItems.members.length
				&& menuItems.members[curSelected] == null)
			{
				curSelected++;
			}

			if (curSelected >= menuItems.members.length)
				return;
		}

		// --------------------------------------------------------
		// SOUND
		// --------------------------------------------------------

		if (huh != 0 && playSound)
		{
			FlxG.sound.play(
				Paths.sound('scrollMenu')
			);
		}

		// --------------------------------------------------------
		// RESET CURRENT
		// --------------------------------------------------------

		menuItems.members[curSelected]
			.animation.play('idle');

		menuItems.members[curSelected]
			.updateHitbox();

		menuItems.members[curSelected].x = 100;

		// --------------------------------------------------------
		// CHANGE SELECTION
		// --------------------------------------------------------

		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;

		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		// --------------------------------------------------------
		// SELECT NEW
		// --------------------------------------------------------

		menuItems.members[curSelected]
			.animation.play('selected');

		menuItems.members[curSelected]
			.centerOffsets();

		menuItems.members[curSelected].x = 100;

		// --------------------------------------------------------
		// CAMERA
		// --------------------------------------------------------

		camFollow.setPosition(
			menuItems.members[curSelected]
				.getGraphicMidpoint().x,

			menuItems.members[curSelected]
				.getGraphicMidpoint().y
				- (
					menuItems.length > 4
					? menuItems.length * 8
					: 0
				)
		);

		// changeItem resets x to the vanilla value (100). Reapply the
		// configured layout after every selection change so custom x/y
		// coordinates remain authoritative when switching elements.
		applyUIEditorLayout();
	}

	// ============================================================
	// CHANGE ITEM DIRECTLY
	// Mouse uses this so there is NO scroll sound.
	// ============================================================

	function changeItemTo(newSelection:Int):Void
	{
		if (menuItems == null || menuItems.length <= 0)
			return;

		if (
			newSelection < 0
			|| newSelection >= menuItems.length
		)
			return;

		if (curSelected < 0 || curSelected >= menuItems.members.length
			|| menuItems.members[curSelected] == null)
			curSelected = newSelection;

		if (curSelected == newSelection)
		{
			if (menuItems.members[curSelected] == null)
				return;
			return;
		}

		// --------------------------------------------------------
		// RESET OLD
		// --------------------------------------------------------

		menuItems.members[curSelected]
			.animation.play('idle');

		menuItems.members[curSelected]
			.updateHitbox();

		menuItems.members[curSelected].x = 100;

		// --------------------------------------------------------
		// NEW SELECTION
		// --------------------------------------------------------

		curSelected = newSelection;

		menuItems.members[curSelected]
			.animation.play('selected');

		menuItems.members[curSelected]
			.centerOffsets();

		menuItems.members[curSelected].x = 100;

		// --------------------------------------------------------
		// CAMERA
		// --------------------------------------------------------

		camFollow.setPosition(
			menuItems.members[curSelected]
				.getGraphicMidpoint().x,

			menuItems.members[curSelected]
				.getGraphicMidpoint().y
				- (
					menuItems.length > 4
					? menuItems.length * 8
					: 0
				)
		);

		applyUIEditorLayout();
	}

	// ============================================================
	// ACCEPT MAIN MENU
	// ============================================================

	function acceptCurrentItem():Void
	{
		if (selectedSomethin)
			return;

		if (
			curSelected < 0
			|| curSelected >= optionShit.length
		)
			return;

		FlxG.sound.play(
			Paths.sound('confirmMenu')
		);

		FlxTransitionableState.skipNextTransIn = false;
		FlxTransitionableState.skipNextTransOut = false;

		selectedSomethin = true;

		if (VsliceOptions.FLASHBANG)
		{
			FlxFlicker.flicker(
				host.magenta,
				1.1,
				0.15,
				false
			);
		}

		// --------------------------------------------------------
		// FLICKER SELECTED ITEM
		// --------------------------------------------------------

		FlxFlicker.flicker(
			menuItems.members[curSelected],
			1,
			0.06,
			false,
			false,
			function(flick:FlxFlicker)
			{
				switch (optionShit[curSelected])
				{
					// ============================================
					// HOW TO PLAY / LORE UNLOCK
					// ============================================

					case 'how_to_play':
						openHowToPlaySubState();

					// ============================================
					// STORY
					// ============================================

					case 'story_mode':
						MusicBeatState.switchState(
							new StoryMenuState()
						);

					// ============================================
					// FREEPLAY
					// ============================================

					case 'freeplay':
					{
						host.persistentDraw = true;
						host.persistentUpdate = false;

						FlxTransitionableState.skipNextTransIn = true;
						FlxTransitionableState.skipNextTransOut = true;

						host.openSubState(
							new FreeplayState()
						);

						host.subStateOpened.addOnce(
							state ->
							{
								for (
									i in 0...menuItems.members.length
								)
								{
									menuItems.members[i].revive();
									menuItems.members[i].alpha = 1;
									menuItems.members[i].visible = true;
								}

								selectedSomethin = false;

								changeItem(
									0,
									false
								);
							}
						);
					}

					// ============================================
					// MODS
					// ============================================

					#if MODS_ALLOWED

					case 'mods':
						MusicBeatState.switchState(
							new ModsMenuState()
						);

					#end

					// ============================================
					// CREDITS
					// ============================================

					case 'credits':
						MusicBeatState.switchState(
							new CreditsState()
						);
				}
			}
		);

		// --------------------------------------------------------
		// FADE OTHER MAIN MENU ITEMS
		// --------------------------------------------------------

		for (i in 0...menuItems.members.length)
		{
			if (i == curSelected)
				continue;

			FlxTween.tween(
				menuItems.members[i],
				{alpha: 0},
				0.4,
				{
					ease: FlxEase.quadOut,

					onComplete:
						function(twn:FlxTween)
						{
							menuItems.members[i].kill();
						}
				}
			);
		}
	}

	// ============================================================
	// ACCEPT FIXED BUTTON
	// ============================================================

	function acceptFixedButton(button:String):Void
	{
		if (selectedSomethin)
			return;

		selectedSomethin = true;

		FlxG.sound.play(
			Paths.sound('confirmMenu')
		);

		FlxTransitionableState.skipNextTransIn = false;
		FlxTransitionableState.skipNextTransOut = false;

		switch (button)
		{
			// ====================================================
			// ACHIEVEMENTS
			// ====================================================

			#if ACHIEVEMENTS_ALLOWED

			case 'awards':
				MusicBeatState.switchState(
					new AchievementsMenuState()
				);

			#end

			// ====================================================
			// OPTIONS
			// ====================================================

			case 'options':
				host.goToOptions();
		}
	}

	override function destroy():Void
	{
		UIEditor.destroyCustomScript("main-menu");
		super.destroy();
	}
}