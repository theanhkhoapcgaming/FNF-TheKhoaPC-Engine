package backend;

/** Shared looping background music for all editors except the Chart Editor. */
class EditorMusic
{
	public static function play():Void
	{
		FlxG.sound.playMusic(Paths.music('chartEditorLoop'));
	}
}
