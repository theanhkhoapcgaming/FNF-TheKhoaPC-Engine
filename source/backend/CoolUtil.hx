package backend;

#if cpp
@:cppFileCode('#include <thread>')
#end
class CoolUtil
{
	public static function checkForUpdates(
		url:String = null,
		onComplete:Void->Void = null
	):String
	{
		
		if (url == null || url.length == 0)
			url = "https://gamebanana.com/apiv7/Mod/737738?_csvProperties=_aFiles";

		var localVersion:String =
			Std.string(mikolka.vslice.ui.MainMenuState.KPCEngineVersion).trim();

		if (localVersion == 'UNAVAILABLE'
			|| localVersion.toLowerCase() == 'temp')
		{
			trace('Bản Demo hoặc lỗi đọc file. Bỏ qua check update.');

			if (onComplete != null)
				onComplete();

			return localVersion;
		}

		if (!ClientPrefs.data.checkForUpdates)
		{
			if (onComplete != null)
				onComplete();

			return localVersion;
		}

		trace('Đang kết nối tới GameBanana API v7...');

		var http:haxe.Http = new haxe.Http(url);
		var completed:Bool = false;

		function finish():Void
		{
			if (completed)
				return;

			completed = true;

			if (onComplete != null)
				onComplete();
		}

		http.onData = function(data:String)
		{
			try
			{
				var json:Dynamic = haxe.Json.parse(data);
				var filesArray:Array<Dynamic> = null;

				if (Std.isOfType(json, Array))
				{
					filesArray = cast json;
				}
				else if (Reflect.hasField(json, '_aFiles'))
				{
					filesArray =
						cast Reflect.field(json, '_aFiles');
				}

				if (filesArray != null && filesArray.length > 0)
				{
					var latestFile:Dynamic = filesArray[0];

					if (Reflect.hasField(latestFile, '_sVersion'))
					{
						var newVersion:String =
							Std.string(
								Reflect.field(latestFile, '_sVersion')
							).trim();

						trace(
							'Kết nối thành công! Bản Online: '
							+ newVersion
							+ ' | Máy của bạn: '
							+ localVersion
						);

						if (newVersion.length > 0
							&& newVersion != 'UNAVAILABLE'
							&& newVersion != localVersion)
						{
							states.InitState.updateVersion =
								newVersion;
							states.InitState.mustUpdate = true;
						}
					}
					else
					{
						trace(
							'GameBanana file không có _sVersion.'
						);
					}
				}
				else
				{
					trace(
						'Không lấy được dữ liệu mảng _aFiles từ API.'
					);
				}
			}
			catch (e:Dynamic)
			{
				trace(
					'Lỗi xử lý JSON API v7: $e'
				);
			}

			http.onData = null;
			http.onError = null;
			finish();
		};

		http.onError = function(error:String)
		{
			trace(
				'Lỗi mạng không thể tải GameBanana: $error'
			);

			http.onData = null;
			http.onError = null;
			finish();
		};

		http.request();

		return localVersion;
	}

	inline public static function quantize(f:Float, snap:Float){
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		return (m / snap);
	}

	inline public static function capitalize(text:String)
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();

	inline public static function coolTextFile(path:String):Array<String>
	{
		var daList:String = null;
		if(NativeFileSystem.exists(path)) daList = NativeFileSystem.getContent(path);
		return daList != null ? listFromString(daList) : [];
	}

	/**
	 * Return string with first character uppercase'd, rest lowercase'd
	 * @param	str
	 * @return
	 */
	inline public static function FUL(str:String):String
	{
		return str.substr(0, 1).toUpperCase() + str.substr(1, str.length - 1).toLowerCase();
	}

	inline public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if(color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	inline public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
			daList[i] = daList[i].trim();

		return daList;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if(decimals < 1)
			return Math.floor(value);

		return Math.floor(value * Math.pow(10, decimals)) / Math.pow(10, decimals);
	}

	#if linux
	public static function sortAlphabetically(list:Array<String>):Array<String> {
		if (list == null) return [];

		list.sort((a, b) -> {
			var upperA = a.toUpperCase();
			var upperB = b.toUpperCase();

			return upperA < upperB ? -1 : upperA > upperB ? 1 : 0;
		});
		return list;
	}
	#end

	inline public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth)
		{
			for(row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:FlxColor = sprite.pixels.getPixel32(col, row);
				if(colorOfThisPixel.alphaFloat > 0.05)
				{
					colorOfThisPixel = FlxColor.fromRGB(colorOfThisPixel.red, colorOfThisPixel.green, colorOfThisPixel.blue, 255);
					var count:Int = countByColor.exists(colorOfThisPixel) ? countByColor[colorOfThisPixel] : 0;
					countByColor[colorOfThisPixel] = count + 1;
				}
			}
		}

		var maxCount = 0;
		var maxKey:Int = 0;
		countByColor[FlxColor.BLACK] = 0;
		for(key => count in countByColor)
		{
			if(count >= maxCount)
			{
				maxCount = count;
				maxKey = key;
			}
		}
		countByColor = [];
		return maxKey;
	}

	inline public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max) dumbArray.push(i);

		return dumbArray;
	}

	inline public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	inline public static function openFolder(folder:String, absolute:Bool = false) {
		#if sys
			if(!absolute) folder =  Sys.getCwd() + '$folder';

			folder = folder.replace('/', '\\');
			if(folder.endsWith('/')) folder.substr(0, folder.length - 1);

			#if linux
			var command:String = '/usr/bin/xdg-open';
			#else
			var command:String = 'explorer.exe';
			#end
			Sys.command(command, [folder]);
			trace('$command $folder');
		#else
			FlxG.log.error("Platform is not supported for CoolUtil.openFolder");
		#end
	}

	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String {
		final company:String = FlxG.stage.application.meta.get('company');
		return '${company}/${flixel.util.FlxSave.validate("PsychEngine")}';
	}

	public static function setTextBorderFromString(text:FlxText, border:String)
	{
		switch(border.toLowerCase().trim())
		{
			case 'shadow':
				text.borderStyle = SHADOW;
			case 'outline':
				text.borderStyle = OUTLINE;
			case 'outline_fast', 'outlinefast':
				text.borderStyle = OUTLINE_FAST;
			default:
				text.borderStyle = NONE;
		}
	}

	public static function showPopUp(message:String, title:String):Void
	{
		#if android
		AndroidTools.showAlertDialog(title, message, {name: "OK", func: null}, null);
		#else
		FlxG.stage.window.alert(message, title);
		#end
	}

	#if cpp
	@:functionCode('
		return std::thread::hardware_concurrency();
	')
	#end
	public static function getCPUThreadsCount():Int
	{
		return 1;
	}
}
