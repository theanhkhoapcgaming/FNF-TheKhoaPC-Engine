package objects;

#if VIDEOS_ALLOWED
#if (hxCodec >= "3.0.0")
import hxcodec.flixel.FlxVideo as VideoHandler;
#elseif (hxCodec >= "2.6.1")
import hxcodec.VideoHandler as VideoHandler;
#elseif (hxCodec == "2.6.0")
import VideoHandler as VideoHandler;
#elseif hxCodec
import vlc.MP4Handler as VideoHandler;
#end
#end

/**
 * Psych Engine 0.7.3-compatible cutscene playback path.
 *
 * The original 0.7.3 source selected the hxCodec API by installed version:
 * hxCodec 3.x uses hxcodec.flixel.FlxVideo, 2.6.1+ uses
 * hxcodec.VideoHandler, and older releases use vlc.MP4Handler.
 * Keep this player separate from the modern VideoSprite controller.
 */
class Psych073VideoPlayer
{
	public static function play(videoPath:String, onComplete:Void->Void):Bool
	{
		#if VIDEOS_ALLOWED
			#if hxCodec
				var video:VideoHandler = new VideoHandler();
				#if (hxCodec >= "3.0.0")
				video.play(videoPath);
				video.onEndReached.add(function()
				{
					video.dispose();
					if (onComplete != null) onComplete();
				}, true);
				#else
				video.playVideo(videoPath);
				video.finishCallback = function()
				{
					if (onComplete != null) onComplete();
				};
				#end
				return true;
			#else
				FlxG.log.warn("LegacyVideoPlayer requires hxCodec. No legacy video backend was compiled.");
				return false;
			#end
		#else
			FlxG.log.warn("Videos are disabled in this build.");
			return false;
		#end
	}
}
