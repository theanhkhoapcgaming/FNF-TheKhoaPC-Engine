package mikolka.vslice.ui;

import flixel.FlxObject;
import mikolka.vslice.ui.mainmenu.DesktopMenuState;
import mikolka.vslice.ui.title.TitleState;
import options.OptionsState;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String =
		'1.0.4 (V-Slice 0.8.7)';
	
	public static var MenuPsychVersion:String =
		'1.0.4';

	public static var MenuBaseVersion:String =
		'0.8.7';

	public static var KPCEngineVersion:String =
		'0.05';

	public static var pSliceVersion:String = '3.4.2';

	// ============================================================
	// HOST DATA
	// ============================================================

	var bg:FlxSprite;
	var magenta:FlxSprite;
	var camFollow:FlxObject;

	var desktopMenu:DesktopMenuState;

	static var showOutdatedWarning:Bool = true;

	// ============================================================
	// CONSTRUCTOR
	// ============================================================

	public function new(transition:Bool = true)
	{
		super();
	}

	// ============================================================
	// CREATE
	// ============================================================

	override function create()
	{
		super.create();

		// --------------------------------------------------------
		// MOD STACK MUST BE READY BEFORE DesktopMenuState CREATES
		// ANY MOD-RESOLVED ASSETS.
		// --------------------------------------------------------
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end

		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(
			"In the Selection Place",
			null
		);
		#end

		persistentUpdate = true;
		persistentDraw = true;

		// --------------------------------------------------------
		// BACKGROUND
		// --------------------------------------------------------
		var yScroll:Float = 0.25;

		bg = new FlxSprite(-80)
			.loadGraphic(Paths.image('menuBG'));

		bg.antialiasing =
			ClientPrefs.data.antialiasing;

		bg.scrollFactor.set(
			0,
			yScroll
		);

		bg.setGraphicSize(
			Std.int(bg.width * 1.175)
		);

		bg.updateHitbox();
		bg.screenCenter();

		add(bg);

		// --------------------------------------------------------
		// MAGENTA TRANSITION SPRITE
		// --------------------------------------------------------
		magenta = new FlxSprite(-80)
			.loadGraphic(Paths.image('menuDesat'));

		magenta.antialiasing =
			ClientPrefs.data.antialiasing;

		magenta.scrollFactor.set(
			0,
			yScroll
		);

		magenta.setGraphicSize(
			Std.int(magenta.width * 1.175)
		);

		magenta.updateHitbox();
		magenta.screenCenter();

		magenta.visible = false;
		magenta.color = 0xFFfd719b;

		add(magenta);

		// --------------------------------------------------------
		// CAMERA FOLLOW
		// --------------------------------------------------------
		camFollow =
			new FlxObject(0, 0, 1, 1);

		add(camFollow);

		FlxG.camera.follow(
			camFollow,
			null,
			0.15
		);

		// --------------------------------------------------------
		// VERSION INFO
		// --------------------------------------------------------
		createVersionTexts();

		// --------------------------------------------------------
		// THE ONLY MENU CONTROLLER
		// --------------------------------------------------------
		//
		// DesktopMenuState:
		//   - owns menuItems
		//   - owns mouse/keyboard menu input
		//   - owns GF
		//   - owns fixed buttons
		//   - owns menu navigation
		//
		// It adds itself to this state, so its update() is called
		// automatically by Flixel.
		//
		desktopMenu =
			new DesktopMenuState(this);

		// --------------------------------------------------------
		// ACHIEVEMENT
		// --------------------------------------------------------
		#if ACHIEVEMENTS_ALLOWED
		var leDate:Date = Date.now();

		if (leDate.getDay() == 5
			&& leDate.getHours() >= 18)
		{
			Achievements.unlock(
				'friday_night_play'
			);
		}

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

	}

	// ============================================================
	// VERSION TEXT
	// ============================================================

	function createVersionTexts():Void
	{
		var kpcver:FlxText = new FlxText(
			12,
			FlxG.height - 70,
			0,
			"TheKhoaPC Engine V."
				+ KPCEngineVersion,
			12
		);

		kpcver.scrollFactor.set();

		kpcver.setFormat(
			Paths.font("vcr.ttf"),
			16,
			FlxColor.WHITE,
			LEFT,
			FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK
		);

		add(kpcver);

		var kpcscm:FlxText = new FlxText(
			12,
			FlxG.height - 50,
			0,
			"Friday Night Funkin' V."
				+ MenuBaseVersion,
			12
		);

		kpcscm.scrollFactor.set();

		kpcscm.setFormat(
			Paths.font("vcr.ttf"),
			16,
			FlxColor.WHITE,
			LEFT,
			FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK
		);

		add(kpcscm);

		var psychVer:FlxText = new FlxText(
			12,
			FlxG.height - 30,
			0,
			"Psych Engine v"
				+ MenuPsychVersion,
			12
		);

		psychVer.scrollFactor.set();

		psychVer.setFormat(
			Paths.font("vcr.ttf"),
			16,
			FlxColor.WHITE,
			LEFT,
			FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK
		);

		add(psychVer);

		var announce:FlxText = new FlxText(
			FlxG.width - 200,
			FlxG.height - 24,
			0,
			"(Global Engine)",
			12
		);

		announce.scrollFactor.set();

		announce.setFormat(
			Paths.font("vcr.ttf"),
			16,
			FlxColor.WHITE,
			RIGHT,
			FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK
		);

		add(announce);
	}

	// ============================================================
	// OPTIONS
	// ============================================================

	public function goToOptions():Void
	{
		MusicBeatState.switchState(
			new OptionsState()
		);

		OptionsState.onPlayState = false;

		if (PlayState.SONG != null)
		{
			PlayState.SONG.arrowSkin = null;
			PlayState.SONG.splashSkin = null;
			PlayState.stageUI = 'normal';
		}
	}

	// ============================================================
	// BEAT
	// ============================================================

	override function beatHit()
	{
		super.beatHit();

		if (desktopMenu != null)
			desktopMenu.beatHit();
	}

	// ============================================================
	// UPDATE
	// ============================================================

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
