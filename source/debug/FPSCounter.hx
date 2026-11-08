package debug;

import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.events.Event;
import openfl.system.System as OpenFlSystem;
import lime.system.System as LimeSystem;
import openfl.Assets;
import openfl.text.TextFieldAutoSize;
import states.MainMenuState;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
#if cpp
#if windows
@:cppFileCode('#include <windows.h>')
#elseif (ios || mac)
@:cppFileCode('#include <mach-o/arch.h>')
#else
@:headerInclude('sys/utsname.h')
#end
#end
class FPSCounter extends TextField
{
	// Thông tin mod ở góc trên bên phải
private var modInfo:TextField;

private static inline var MOD_NAME:String =
    "Love, Madness and the Left Behinds";

private static inline var MOD_AUTHOR:String =
    "(TheKhoaPC's Super Charting Mod)";

private static inline var MOD_VERSION:String =
    MainMenuState.SCMVersion;

private static inline var HUD_RED:Int = 0xFFFF3030;

	public var currentFPS(default, null):Int;
	public var memoryMegas(get, never):Float;

	@:noCompletion private var times:Array<Float>;
	public var os:String = '';
	
	// TextField phụ để hiển thị thông tin Mod bên góc phải màn hình
	public var rightTextField:TextField;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0xFF0000)
	{
		
var vcr:String = getVCRFont();

defaultTextFormat = new TextFormat(vcr, 16, HUD_RED);
width = FlxG.width;
height = 90;
multiline = true;
selectable = false;
mouseEnabled = false;
textColor = HUD_RED;
text = "FPS: ";

modInfo = new TextField();
modInfo.defaultTextFormat = new TextFormat(
    vcr,
    16,
    HUD_RED,
    false,
    false,
    false,
    null,
    null,
    TextFormatAlign.RIGHT
);

modInfo.selectable = false;
modInfo.mouseEnabled = false;
modInfo.multiline = true;
modInfo.wordWrap = false;
modInfo.textColor = HUD_RED;
modInfo.width = FlxG.width - 20;
modInfo.height = 80;
modInfo.x = FlxG.game.x + 10;
modInfo.y = FlxG.game.y + 10;
modInfo.alpha = 0.7;
modInfo.text = MOD_NAME + "\n" + MOD_AUTHOR
    + "\nVersion: " + MOD_VERSION;

FlxG.game.addChild(modInfo);

	}

	var deltaTimeout:Float = 0.0;

	// Event Handlers
	private override function __enterFrame(deltaTime:Float):Void
	{
		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000) times.shift();

		if (deltaTimeout < 50) {
			deltaTimeout += deltaTime;
			return;
		}

		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;		
		updateText();
		deltaTimeout = 0.0;
	}

	
public dynamic function updateText():Void
{
    text =
        'FPS: $currentFPS' +
        '\nMemory: ${flixel.util.FlxStringUtil.formatBytes(memoryMegas)}' +
        '\nVersion: Psych Engine 1.0.4 (V-Slice 0.7.6)';

    // Giữ màu đỏ như overlay trong ảnh
    textColor = HUD_RED;

    // Cập nhật vị trí nếu kích thước game thay đổi
    modInfo.x = FlxG.game.x + 10;
    modInfo.y = FlxG.game.y + 10;
    modInfo.width = FlxG.width - 20;

    modInfo.text =
        MOD_NAME + '\n' +
        MOD_AUTHOR + '\n' +
        MOD_VERSION;
}


	inline function get_memoryMegas():Float
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);

	public inline function positionFPS(X:Float, Y:Float, ?scale:Float = 1){
		scaleX = scaleY = #if android (scale > 1 ? scale : 1) #else (scale < 1 ? scale : 1) #end;
		x = FlxG.game.x + X;
		y = FlxG.game.y + Y;
	}

	#if cpp
	#if windows
	@:functionCode('
		SYSTEM_INFO osInfo;

		GetSystemInfo(&osInfo);

		switch(osInfo.wProcessorArchitecture)
		{
			case 9:
				return ::String("x86_64");
			case 5:
				return ::String("ARM");
			case 12:
				return ::String("ARM64");
			case 6:
				return ::String("IA-64");
			case 0:
				return ::String("x86");
			default:
				return ::String("Unknown");
		}
	')
	#elseif (ios || mac)
	@:functionCode('
		const NXArchInfo *archInfo = NXGetLocalArchInfo();
    	return ::String(archInfo == NULL ? "Unknown" : archInfo->name);
	')
	#else
	@:functionCode('
		struct utsname osInfo{};
		uname(&osInfo);
		return ::String(osInfo.machine);
	')
	#end
	@:noCompletion
	private function getArch():String
	{
		return "Unknown";
	}
	#end
}