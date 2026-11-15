package substates;

import backend.ClientPrefs;
import mikolka.compatibility.freeplay.FreeplayHelpers;
import backend.MusicBeatSubstate;
import backend.Paths;
import objects.Alphabet;
import objects.Character;
import objects.HealthIcon;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import StringTools as HaxeStringTools;

typedef LoreCharacterData =
{
	var name:String;
	var characters:Array<String>;
	var lore:String;
	var icons:Array<String>;
	var bgColor:FlxColor;
	var flipX:Bool;
	var offsetX:Float;
	var offsetY:Float;
}

class LoreSubState extends MusicBeatSubstate
{
	static var storyText:String = '';
	static var characters:Array<LoreCharacterData> = [];

	var options:Array<String> = ['Pre-Story Mode Lore', 'Characters Lore'];
	var grpOptions:FlxTypedGroup<Alphabet>;
	var curSelected:Int = 0;

	var bg:FlxSprite;
	var titleText:Alphabet;

	var inStoryView:Bool = false;
	var storyBox:FlxSprite;
	var storyFlxText:FlxText;

	// === EASTER EGG UNLOCK ===
	var enterCount:Int = 0;

	public function new()
	{
		super();

		// Luôn nạp lại dữ liệu lore mới nhất mỗi khi tạo Substate
		loadLoreData();

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.75;
		bg.scrollFactor.set(0, 0);
		add(bg);

		titleText = new Alphabet(0, 50, "LORE", true);
		titleText.screenCenter(X);
		titleText.scrollFactor.set(0, 0);
		add(titleText);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 260 + (i * 120), options[i], true);
			optionText.screenCenter(X);
			optionText.scrollFactor.set(0, 0);
			optionText.ID = i;
			grpOptions.add(optionText);
		}

		storyBox = new FlxSprite().makeGraphic(Std.int(FlxG.width * 0.85), Std.int(FlxG.height * 0.65), FlxColor.BLACK);
		storyBox.alpha = 0.85;
		storyBox.screenCenter();
		storyBox.scrollFactor.set(0, 0);
		storyBox.visible = false;
		add(storyBox);

		storyFlxText = new FlxText(storyBox.x + 25, storyBox.y + 25, storyBox.width - 50, '', 22);
		storyFlxText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		storyFlxText.borderSize = 1.5;
		storyFlxText.scrollFactor.set(0, 0);
		storyFlxText.visible = false;
		add(storyFlxText);

		changeSelection(0);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (inStoryView)
		{
			// === ĐẾM 10 LẦN ENTER KHI Ở MÀN HÌNH STORY LORE ===
			if (controls.ACCEPT)
			{
				if (!ClientPrefs.data.devMode)
				{
					enterCount++;

					if (enterCount >= 10)
					{
						ClientPrefs.data.devMode = true;
						ClientPrefs.saveSettings();

						FlxG.sound.play(Paths.sound('confirmMenu'), 0.8);
						FlxG.camera.flash(FlxColor.WHITE, 0.4);
					}
				}
			}

			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				inStoryView = false;
				storyBox.visible = false;
				storyFlxText.visible = false;
				grpOptions.visible = true;
				titleText.visible = true;
			}
			else
			{
				var minY:Float = storyBox.y + 25;
				var maxY:Float = storyBox.y + 25;
				if (storyFlxText.height > storyBox.height - 50)
					minY = (storyBox.y + storyBox.height - 25) - storyFlxText.height;

				if (controls.UI_UP)
					storyFlxText.y += 300 * elapsed;
				else if (controls.UI_DOWN)
					storyFlxText.y -= 300 * elapsed;

				storyFlxText.y = FlxMath.bound(storyFlxText.y, minY, maxY);
			}
			return;
		}

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
			return;
		}

		if (controls.ACCEPT)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			if (curSelected == 0)
			{
				inStoryView = true;
				storyFlxText.text = (storyText != null && storyText.length > 0) ? storyText : "Can't find the story in data/lore.txt";
				storyFlxText.y = storyBox.y + 25;
				storyBox.visible = true;
				storyFlxText.visible = true;
				grpOptions.visible = false;
				titleText.visible = false;

				// Opening the actual story lore counts as viewing the lore.
				if (storyText != null && storyText.length > 0)
					FreeplayHelpers.markLoreViewed();

				enterCount = 0;
			}
			else if (curSelected == 1)
			{
				if (characters.length > 0)
					openSubState(new LoreCharactersSubState(characters));
				else
					trace('[Lore] Không có danh sách nhân vật.');
			}
		}
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);
		if (change != 0)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		for (item in grpOptions.members)
		{
			if (item.ID == curSelected)
			{
				item.alpha = 1.0;
				item.scale.set(1.0, 1.0);
			}
			else
			{
				item.alpha = 0.5;
				item.scale.set(0.8, 0.8);
			}
		}
	}

	static function loadLoreData():Void
	{
		storyText = '';
		characters = [];

		if (!Paths.fileExists('data/lore.txt', TEXT))
		{
			trace('[Lore] data/lore.txt not found.');
			return;
		}

		var raw:String = Paths.getTextFromFile('data/lore.txt');
		if (raw == null || raw.length == 0)
			return;

		var section:String = '';
		for (rawLine in raw.split('\n'))
		{
			var line:String = HaxeStringTools.trim(rawLine.replace('\r', ''));
			if (line.length == 0 || HaxeStringTools.startsWith(line, '#'))
				continue;

			switch (line.toLowerCase())
			{
				case 'story':
					section = 'story';
				case 'characters':
					section = 'characters';
				default:
					switch (section)
					{
						case 'story':
							var storyLine = line;
							if (storyLine.length >= 2 && storyLine.charAt(0) == '"' && storyLine.charAt(storyLine.length - 1) == '"')
								storyLine = storyLine.substring(1, storyLine.length - 1);
							if (storyText.length > 0)
								storyText += '\n';
							storyText += storyLine;

						case 'characters':
							parseCharacterLine(line);
					}
			}
		}
	}

	static function parseCharacterLine(line:String):Void
	{
		var parts:Array<String> = line.split('::');
		if (parts.length < 5)
		{
			trace('[Lore] Invalid character line: ' + line);
			return;
		}

		var rawChars:Array<String> = parts[1].split(',');
		var charList:Array<String> = [];
		for (c in rawChars)
		{
			var trimmed = HaxeStringTools.trim(c);
			if (trimmed.length > 0)
				charList.push(trimmed);
		}

		var rawIcons:Array<String> = parts[3].split(',');
		var iconList:Array<String> = [];
		for (i in rawIcons)
		{
			var trimmed = HaxeStringTools.trim(i);
			if (trimmed.length > 0)
				iconList.push(trimmed);
		}

		var isFlipX:Bool = false;
		if (parts.length >= 6)
			isFlipX = (HaxeStringTools.trim(parts[5]).toLowerCase() == 'true');

		var offX:Float = 0;
		if (parts.length >= 7)
		{
			var parsedX:Float = Std.parseFloat(HaxeStringTools.trim(parts[6]));
			if (!Math.isNaN(parsedX))
				offX = parsedX;
		}

		var offY:Float = 0;
		if (parts.length >= 8)
		{
			var parsedY:Float = Std.parseFloat(HaxeStringTools.trim(parts[7]));
			if (!Math.isNaN(parsedY))
				offY = parsedY;
		}

		var data:LoreCharacterData =
		{
			name: HaxeStringTools.trim(parts[0]),
			characters: charList,
			lore: HaxeStringTools.trim(parts[2]),
			icons: iconList,
			bgColor: parseColor(HaxeStringTools.trim(parts[4])),
			flipX: isFlipX,
			offsetX: offX,
			offsetY: offY
		};

		if (data.name.length > 0 && data.characters.length > 0)
			characters.push(data);
	}

	static function parseColor(value:String):FlxColor
	{
		if (value == null || value.length == 0)
			return FlxColor.BLACK;

		var v = value;
		if (HaxeStringTools.startsWith(v, '#'))
			v = v.substring(1);
		else if (HaxeStringTools.startsWith(v.toLowerCase(), '0x'))
			v = v.substring(2);

		if (v.length == 6)
			v = 'FF' + v;

		var parsed = Std.parseInt('0x' + v);
		return parsed == null ? FlxColor.BLACK : FlxColor.fromInt(parsed);
	}
}

class LoreCharactersSubState extends MusicBeatSubstate
{
	var data:Array<LoreCharacterData>;
	var selectedChar:Int = 0;
	var selectedSkin:Int = 0;

	var bg:FlxSprite;
	var character:Character;
	var icon:HealthIcon;
	var nameText:Alphabet;
	var loreText:FlxText;
	var counterText:FlxText;

	public function new(source:Array<LoreCharacterData>)
	{
		super();
		data = source == null ? [] : source;

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		bg.scrollFactor.set(0, 0);
		add(bg);

		loreText = new FlxText(50, 200, 750, '', 22);
		loreText.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		loreText.borderSize = 2;
		loreText.scrollFactor.set(0, 0);
		add(loreText);

		counterText = new FlxText(50, FlxG.height - 55, FlxG.width - 100, '', 18);
		counterText.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		counterText.borderSize = 1.5;
		counterText.scrollFactor.set(0, 0);
		add(counterText);

		if (data.length > 0)
		{
			refreshCharacterView();
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
			return;
		}

		if (data.length > 0)
		{
			var entry = data[selectedChar];
			var changed:Bool = false;

			if (controls.UI_LEFT_P)
			{
				selectedChar = FlxMath.wrap(selectedChar - 1, 0, data.length - 1);
				selectedSkin = 0;
				changed = true;
			}
			else if (controls.UI_RIGHT_P)
			{
				selectedChar = FlxMath.wrap(selectedChar + 1, 0, data.length - 1);
				selectedSkin = 0;
				changed = true;
			}
			else if (controls.UI_UP_P)
			{
				if (entry.characters.length > 1)
				{
					selectedSkin = FlxMath.wrap(selectedSkin - 1, 0, entry.characters.length - 1);
					changed = true;
				}
			}
			else if (controls.UI_DOWN_P)
			{
				if (entry.characters.length > 1)
				{
					selectedSkin = FlxMath.wrap(selectedSkin + 1, 0, entry.characters.length - 1);
					changed = true;
				}
			}

			if (changed)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				refreshCharacterView();
			}
		}
	}

	function refreshCharacterView():Void
	{
		if (data.length == 0)
			return;

		var entry = data[selectedChar];
		bg.color = entry.bgColor;

		if (selectedSkin >= entry.characters.length)
			selectedSkin = 0;

		var curCharSkin:String = entry.characters[selectedSkin];
		var curIcon:String = (selectedSkin < entry.icons.length) ? entry.icons[selectedSkin] : entry.icons[0];

		if (nameText != null)
		{
			remove(nameText, true);
			nameText.destroy();
			nameText = null;
		}

		if (icon != null)
		{
			remove(icon, true);
			icon.destroy();
			icon = null;
		}

		if (character != null)
		{
			remove(character, true);
			character.destroy();
			character = null;
		}

		nameText = new Alphabet(50, 50, entry.name, true);
		nameText.setScale(0.6);
		nameText.scrollFactor.set(0, 0);
		add(nameText);

		icon = new HealthIcon(curIcon, false);
		icon.setPosition(nameText.x + nameText.width + 20, nameText.y + 10);
		icon.scrollFactor.set(0, 0);
		add(icon);

		loreText.text = entry.lore;

		var skinInfo:String = (entry.characters.length > 1) ? ' | Skin: ' + (selectedSkin + 1) + '/' + entry.characters.length : '';
		counterText.text = 'Character No. ' + (selectedChar + 1) + '/' + data.length + skinInfo + '\n< LEFT/RIGHT: Change Character | UP/DOWN: Switch Skin >';

		try
		{
			character = new Character(0, 0, curCharSkin, false);
			if (character != null)
			{
				var finalScale:Float = 0.7 * character.jsonScale;
				character.scale.set(finalScale, finalScale);
				character.updateHitbox();

				character.x = (FlxG.width * 0.75) - (character.width / 2) + entry.offsetX;
				character.y = (FlxG.height * 0.5) - (character.height / 2) + entry.offsetY;

				character.flipX = entry.flipX;
				character.scrollFactor.set(0, 0);

				add(character);
				character.dance();
			}
		}
		catch (e:Dynamic)
		{
			trace('[Lore] Không thể tạo nhân vật "' + curCharSkin + '": ' + e);
		}

		remove(loreText, true);
		remove(counterText, true);
		add(loreText);
		add(counterText);
	}
	
	override function beatHit()
	{
		super.beatHit();

		if (character != null)
		{
			character.dance();
		}
	}
}