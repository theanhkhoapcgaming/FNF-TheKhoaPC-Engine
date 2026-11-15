package substates;

import backend.ClientPrefs;
import backend.MusicBeatSubstate;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import StringTools as HaxeStringTools;

private typedef HowToPlayPicture =
{
	var id:String;
	var name:String;
	var x:Float;
	var y:Float;
	var scaleX:Float;
	var scaleY:Float;
};

private typedef HowToPlayPictureMarker =
{
	var id:String;
	var caption:String;
	var startIndex:Int;
	var afterNewline:Bool;
};

/**
 * Custom How To Play screen used by the lore lock.
 *
 * data/unlock.txt format:
 *
 * EN-US
 * 'Click How To Play, then View Lore to unlock Story Mode and Freeplay.'
 *
 * VI-VN
 * 'Nhấn How To Play, sau đó chọn View Lore để mở khóa Story Mode và Freeplay.'
 *
 * The selected text is determined automatically from
 * backend.ClientPrefs.data.language.
 *
 * EN-US is the Global/fallback language. If the current game language
 * does not have a matching section, EN-US is used.
 */
class HowToPlaySubState extends MusicBeatSubstate
{
	static var languageSteps:Map<String, Array<String>> = new Map();
	static var pictures:Array<HowToPlayPicture> = [];

	var stepIndex:Int = 0;
	var currentLanguage:String = 'EN-US';

	var bg:FlxSprite;
	var titleText:FlxText;
	var textBox:FlxSprite;
	var instructionText:FlxText;
	var counterText:FlxText;
	var pictureSprites:Array<FlxSprite> = [];
	var pictureCaptions:Array<FlxText> = [];

	public function new()
	{
		super();

		loadUnlockData();
		currentLanguage = resolveLanguage();

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.75;
		bg.scrollFactor.set(0, 0);
		add(bg);

		titleText = new FlxText(0, 45, FlxG.width, 'HOW TO PLAY', 42);
		titleText.setFormat(
			Paths.font('vcr.ttf'),
			42,
			FlxColor.WHITE,
			CENTER,
			FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK
		);
		titleText.borderSize = 2;
		titleText.scrollFactor.set(0, 0);
		add(titleText);

		textBox = new FlxSprite().makeGraphic(
			Std.int(FlxG.width * 0.85),
			Std.int(FlxG.height * 0.65),
			FlxColor.BLACK
		);
		textBox.alpha = 0.85;
		textBox.screenCenter();
		textBox.scrollFactor.set(0, 0);
		add(textBox);

		instructionText = new FlxText(
			textBox.x + 35,
			textBox.y + 35,
			textBox.width - 70,
			'',
			24
		);
		instructionText.setFormat(
			Paths.font('vcr.ttf'),
			24,
			FlxColor.WHITE,
			LEFT,
			FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK
		);
		instructionText.borderSize = 1.5;
		instructionText.scrollFactor.set(0, 0);
		add(instructionText);

		counterText = new FlxText(
			25,
			FlxG.height - 55,
			FlxG.width - 50,
			'',
			18
		);
		counterText.setFormat(
			Paths.font('vcr.ttf'),
			18,
			FlxColor.WHITE,
			CENTER,
			FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK
		);
		counterText.borderSize = 1.5;
		counterText.scrollFactor.set(0, 0);
		add(counterText);

		refreshView();
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

		var steps:Array<String> = getCurrentSteps();
		if (steps.length == 0)
			return;

		if (controls.UI_UP_P)
		{
			if (stepIndex > 0)
				stepIndex--;

			FlxG.sound.play(Paths.sound('scrollMenu'));
			refreshView();
			return;
		}

		if (controls.UI_DOWN_P)
		{
			if (stepIndex < steps.length - 1)
				stepIndex++;

			FlxG.sound.play(Paths.sound('scrollMenu'));
			refreshView();
			return;
		}

		if (controls.ACCEPT)
		{
			if (stepIndex < steps.length - 1)
			{
				stepIndex++;
				FlxG.sound.play(Paths.sound('scrollMenu'));
				refreshView();
			}
			else
			{
				// The final step returns to the first page.
				// It does NOT open the Lore screen.
				stepIndex = 0;
				FlxG.sound.play(Paths.sound('confirmMenu'));
				refreshView();
			}
		}
	}

	function refreshView():Void
	{
		var steps:Array<String> = getCurrentSteps();

		titleText.text = 'HOW TO PLAY';

		if (steps.length == 0)
		{
			instructionText.text =
				'No instructions were found for this language.'
				+ '\n\nGlobal language: EN-US';
			counterText.text = 'BACK: Return';
			return;
		}

		if (stepIndex >= steps.length)
			stepIndex = steps.length - 1;

		var rawStepText:String = steps[stepIndex];
		var visibleStepText:String = removePictureMarkers(rawStepText);

		refreshPictures(rawStepText);
		instructionText.text = visibleStepText;

		if (stepIndex >= steps.length - 1)
		{
			counterText.text =
				'Step ' + (stepIndex + 1) + '/' + steps.length
				+ ' | ENTER: First Page | BACK: Return';
		}
		else
		{
			counterText.text =
				'Step ' + (stepIndex + 1) + '/' + steps.length
				+ ' | UP/DOWN: Next/Previous | ENTER: Next | BACK: Return';
		}
	}

	function refreshPictures(stepText:String):Void
	{
		for (sprite in pictureSprites)
		{
			if (sprite != null)
				remove(sprite, true);
		}
		pictureSprites = [];

		for (caption in pictureCaptions)
		{
			if (caption != null)
				remove(caption, true);
		}
		pictureCaptions = [];

		// Picture/caption markers are laid out after the text has been
		// parsed. A picture preceded by a real/newline escape is placed
		// on the line immediately below the preceding text line.
		var markers:Array<HowToPlayPictureMarker> = extractPictureMarkers(stepText);
		for (marker in markers)
		{
			var picture:HowToPlayPicture = findPicture(marker.id);
			if (picture == null)
				continue;

			if (!Paths.fileExists('images/howtoplay/' + picture.name + '.png', IMAGE))
			{
				trace('[HowToPlay] Picture not found: images/howtoplay/' + picture.name + '.png');
				continue;
			}

			var posX:Float = picture.x;
			var posY:Float = picture.y;

			if (marker.afterNewline)
			{
				// When the marker is preceded by \n, place the picture in
				// the text flow, but keep the PICTURES x/y values as custom
				// offsets. This means x/y no longer get discarded just because
				// the picture is being flowed below a text line.
				var before:String = stepText.substring(0, marker.startIndex);
				var lineCount:Int = before.split('\n').length - 1;
				var lineHeight:Float = instructionText.size * 1.25;
				var flowX:Float = textBox.x + 35;
				var flowY:Float = textBox.y + 35 + (lineCount * lineHeight);
				posX = flowX + picture.x;
				posY = flowY + picture.y;
			}

			var sprite:FlxSprite = new FlxSprite(posX, posY);
			sprite.loadGraphic(Paths.image('howtoplay/' + picture.name));
			sprite.scale.set(picture.scaleX, picture.scaleY);
			sprite.updateHitbox();
			sprite.scrollFactor.set(0, 0);
			add(sprite);
			pictureSprites.push(sprite);

			if (marker.caption != null && marker.caption.length > 0)
			{
				var caption:FlxText = new FlxText(
					sprite.x,
					sprite.y + sprite.height + 8,
					Math.max(sprite.width, 160),
					marker.caption,
					18
				);
				caption.setFormat(
					Paths.font('vcr.ttf'),
					18,
					FlxColor.WHITE,
					CENTER,
					FlxTextBorderStyle.OUTLINE,
					FlxColor.BLACK
				);
				caption.borderSize = 1.5;
				caption.scrollFactor.set(0, 0);
				add(caption);
				pictureCaptions.push(caption);
			}
		}
	}

	function findPicture(id:String):HowToPlayPicture
	{
		for (picture in pictures)
		{
			if (picture.id == id)
				return picture;
		}
		trace('[HowToPlay] Unknown picture id: ' + id);
		return null;
	}

	/**
	 * Supported picture syntax:
	 *
	 *   <\\p>imageID<\\p>
	 *   <\\pt>(imageID)\\tCaption text<\\pt>
	 *
	 * The second form creates the same picture plus a caption below it.
	 */
	static function extractPictureMarkers(text:String):Array<HowToPlayPictureMarker>
	{
		var result:Array<HowToPlayPictureMarker> = [];
		var searchFrom:Int = 0;
		while (searchFrom < text.length)
		{
			var normalTag:String = '<\\p>';
			var captionTag:String = '<\\pt>';
			var normalIndex:Int = text.indexOf(normalTag, searchFrom);
			var captionIndex:Int = text.indexOf(captionTag, searchFrom);
			var useCaption:Bool = captionIndex >= 0 && (normalIndex < 0 || captionIndex < normalIndex);
			var openIndex:Int = useCaption ? captionIndex : normalIndex;
			if (openIndex < 0)
				break;
			var tag:String = useCaption ? captionTag : normalTag;
			var closeIndex:Int = text.indexOf(tag, openIndex + tag.length);
			if (closeIndex < 0)
			{
				trace('[HowToPlay] Unterminated picture marker in: ' + text);
				break;
			}
			var content:String = text.substring(openIndex + tag.length, closeIndex);
			var id:String = content;
			var caption:String = '';
			if (useCaption)
			{
				var tabIndex:Int = content.indexOf('\t');
				if (tabIndex < 0)
					tabIndex = content.indexOf('\\t');
				if (tabIndex >= 0)
				{
					id = HaxeStringTools.trim(content.substring(0, tabIndex));
					caption = HaxeStringTools.trim(content.substring(tabIndex + 1));
				}
				else
					id = HaxeStringTools.trim(content);
				if (id.length >= 2 && id.charAt(0) == '(' && id.charAt(id.length - 1) == ')')
					id = HaxeStringTools.trim(id.substring(1, id.length - 1));
			}
			else
				id = HaxeStringTools.trim(id);
			var afterNewline:Bool = openIndex > 0 && text.charAt(openIndex - 1) == '\n';
			if (id.length > 0)
			{
				result.push({
					id: id,
					caption: caption,
					startIndex: openIndex,
					afterNewline: afterNewline
				});
			}
			searchFrom = closeIndex + tag.length;
		}
		return result;
	}

	static function extractPictureIds(text:String):Array<String>
	{
		var result:Array<String> = [];
		for (marker in extractPictureMarkers(text))
		{
			if (!result.contains(marker.id))
				result.push(marker.id);
		}
		return result;
	}

	/** Removes both normal and caption picture markers from FlxText. */
	static function removePictureMarkers(text:String):String
	{
		var result:String = text;
		var markers:Array<HowToPlayPictureMarker> = extractPictureMarkers(result);
		for (i in 0...markers.length)
		{
			// Re-scan from the beginning because removing one marker changes
			// the character offsets of all later markers.
			var normalTag:String = '<\\p>';
			var captionTag:String = '<\\pt>';
			var n:Int = result.indexOf(normalTag);
			var c:Int = result.indexOf(captionTag);
			var open:Int = c >= 0 && (n < 0 || c < n) ? c : n;
			if (open < 0)
				break;
			var tag:String = (open == c && c >= 0) ? captionTag : normalTag;
			var close:Int = result.indexOf(tag, open + tag.length);
			if (close < 0)
				break;
			result = result.substring(0, open) + result.substring(close + tag.length);
		}
		return result;
	}

	function getCurrentSteps():Array<String>
	{
		var steps:Array<String> = languageSteps.get(currentLanguage);
		if (steps != null && steps.length > 0)
			return steps;

		// EN-US is Global/fallback.
		steps = languageSteps.get('EN-US');
		return steps == null ? [] : steps;
	}

	static function resolveLanguage():String
	{
		var language:String = ClientPrefs.data.language;
		if (language == null || language.length == 0)
			return 'EN-US';

		return language.toUpperCase();
	}

	static function loadUnlockData():Void
	{
		languageSteps = new Map();
		pictures = [];

		if (!Paths.fileExists('data/unlock.txt', TEXT))
		{
			trace('[HowToPlay] data/unlock.txt not found.');
			return;
		}

		var raw:String = Paths.getTextFromFile('data/unlock.txt');
		if (raw == null || raw.length == 0)
			return;

		var currentLanguage:String = '';
		var readingPictures:Bool = false;

		for (rawLine in raw.split('\n'))
		{
			var line:String = HaxeStringTools.trim(rawLine.replace('\r', ''));
			if (line.length == 0 || HaxeStringTools.startsWith(line, '#'))
				continue;

			if (isLanguageCode(line))
			{
				currentLanguage = line.toUpperCase();
				readingPictures = false;
				if (!languageSteps.exists(currentLanguage))
					languageSteps.set(currentLanguage, []);
				continue;
			}

			if (line.toUpperCase() == 'PICTURES')
			{
				readingPictures = true;
				continue;
			}

			if (readingPictures)
			{
				parsePictureLine(line);
				continue;
			}

			if (currentLanguage.length == 0)
				continue;

			var step:String = line;
			if (step.length >= 2)
			{
				var first:String = step.charAt(0);
				var last:String = step.charAt(step.length - 1);
				if ((first == "'" && last == "'") || (first == '"' && last == '"'))
					step = step.substring(1, step.length - 1);
			}

			// Allow \n inside a quoted page to create a real line break.
			step = step.split('\\n').join('\n');

			languageSteps.get(currentLanguage).push(step);
		}
	}

	static function parsePictureLine(line:String):Void
	{
		var parts:Array<String> = line.split('::');
		if (parts.length != 6)
		{
			trace('[HowToPlay] Invalid picture line: ' + line);
			return;
		}

		// The identifier is arbitrary. `image1` is only an example.
		// It must match the identifier used between <\p> markers in the text.
		var id:String = HaxeStringTools.trim(parts[0]);
		if (id.length == 0)
		{
			trace('[HowToPlay] Picture id cannot be empty: ' + line);
			return;
		}

		var name:String = HaxeStringTools.trim(parts[1]);
		if (name.length >= 2)
		{
			var first:String = name.charAt(0);
			var last:String = name.charAt(name.length - 1);
			if ((first == "'" && last == "'") || (first == '"' && last == '"'))
				name = name.substring(1, name.length - 1);
		}

		if (HaxeStringTools.endsWith(name.toLowerCase(), '.png'))
			name = name.substring(0, name.length - 4);

		var picture:HowToPlayPicture =
		{
			id: id,
			name: name,
			x: Std.parseFloat(HaxeStringTools.trim(parts[2])),
			y: Std.parseFloat(HaxeStringTools.trim(parts[3])),
			scaleX: Std.parseFloat(HaxeStringTools.trim(parts[4])),
			scaleY: Std.parseFloat(HaxeStringTools.trim(parts[5]))
		};

		pictures.push(picture);
	}

	static function isLanguageCode(value:String):Bool
	{
		if (value.length != 5 || value.charAt(2) != '-')
			return false;

		for (i in 0...5)
		{
			if (i == 2)
				continue;

			var c:String = value.charAt(i).toUpperCase();
			if (c < 'A' || c > 'Z')
				return false;
		}

		return true;
	}
}
