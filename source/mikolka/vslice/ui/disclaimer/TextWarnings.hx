package mikolka.vslice.ui.disclaimer;

import flixel.FlxState;

class OutdatedState extends WarningState
{

	public function new(newVersion:String,nextState:FlxState) {
		final bro:String = #if mobile 'Mobile Players' #else 'Player!' #end;
		final escape:String = (controls.mobileC) ? 'B' : 'ESCAPE';

		var guh = "Sup "+bro+", looks like you're running\n
		TheKhoaPC Engine V." + MainMenuState.KPCEngineVersion + ",\n
		please update to Version " + newVersion + "!\n
		Press "+escape+" to proceed anyway.\n
		\n
		Thank you for Playing this Engine!";
		super(guh,() ->{
			CoolUtil.browserLoad("https://github.com/theanhkhoapcgaming/FNF-TheKhoaPC-Engine");
			if(onExit != null) onExit();
		},onExit,nextState);
	}
}
class FlashingState extends WarningState{
	public function new(nextState:FlxState) {

		final enter:String = controls.mobileC ? 'A' : 'ENTER';
		final escape:String = controls.mobileC ? 'B' : 'ESCAPE';
		var text = 	"Hey, watch out!\n
			This Mod contains some flashing lights!\n
			Press "+enter+" to Disable it! Or press "+escape+" to Ignore it!\n
			You've been warned!";
		super(text,() ->{
			#if LEGACY_PSYCH
			ClientPrefs.flashing = false;
			#else
			ClientPrefs.data.flashing = false;
			#end
			ClientPrefs.saveSettings();
		},() ->{},nextState);
	}
}
