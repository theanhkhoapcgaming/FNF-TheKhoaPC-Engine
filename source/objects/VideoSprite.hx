package objects;

import haxe.Int64;
import substates.PauseSubState;
import flixel.addons.display.FlxPieDial;

#if hxvlc
import hxvlc.flixel.FlxVideoSprite;
#end
#if hxCodec
import hxcodec.flixel.FlxVideoSprite;
#end
#if html5
import objects.WebVideoSprite as FlxVideoSprite;
#end

class VideoSprite extends FlxSpriteGroup {
	#if VIDEOS_ALLOWED
	private static var precachedVideos:Map<String, VideoSprite> = new Map();

	/**
	 * Warms up a video ahead of time by starting the VLC pipeline silently,
	 * then pausing after video output setup and playback-time progress.
	 */
	public static function precacheVideo(path:String):Bool
	{
		if (path == null || path.trim().length == 0)
			return false;

		if (precachedVideos.exists(path))
			return true;

		#if hxvlc
		// Warm up the real VLC playback pipeline and retain this same player.
		var prepared = new VideoSprite(path, false, false, false, false, true);
		if (!prepared.precacheStarted)
		{
			prepared.destroy();
			return false;
		}
		precachedVideos.set(path, prepared);
		return true;
		#else
		// Other backends do not expose a reusable pre-open operation.
		return false;
		#end
	}

	public static function takePrecachedVideo(path:String, isWaiting:Bool, canSkip:Bool, shouldLoop:Bool, legacyMode:Bool):VideoSprite
	{
		var prepared = precachedVideos.get(path);
		if (prepared == null)
			return null;

		// The loop flag is passed to VLC while opening the media. A video
		// precached without loop options cannot safely be converted afterwards.
		if (shouldLoop)
		{
			precachedVideos.remove(path);
			prepared.destroy();
			return null;
		}

		precachedVideos.remove(path);
		prepared.waiting = isWaiting;
		prepared.canSkip = canSkip;
		prepared.legacyMode = legacyMode;
		prepared.doWeLoop = shouldLoop;

		if (isWaiting && prepared.cover != null)
		{
			prepared.remove(prepared.cover, true);
			prepared.cover.destroy();
			prepared.cover = null;
		}

		return prepared;
	}

	public var finishCallback:Void->Void = null;
	public var onSkip:Void->Void = null;

	final _timeToSkip:Float = 1;
	public var holdingTime:Float = 0;
	public var videoSprite:FlxVideoSprite;
	public var cover:FlxSprite;
	public var canSkip:Bool = false;

	private var videoName:String;

	// A precached instance is initialized by briefly starting VLC playback.
	// Keep it in preload mode until hxVLC reports that initialization paused.
	private var isPrecacheOnly:Bool = false;
	private var precacheReady:Bool = false;
	private var precacheFormatReady:Bool = false;
	private var precacheHasProgress:Bool = false;
	private var precachePauseRequested:Bool = false;
	private var playWhenPrecacheReady:Bool = false;
	private var precacheVolume:Int = 100;
	public var precacheStarted(default, null):Bool = false;

	public var waiting:Bool = false;
	public var didPlay:Bool = false;

	var pauseJustClosed:Bool = false;
	public var legacyMode(default, null):Bool = false;

	private var doWeLoop:Bool = false; // for hxCodec

	public function new(videoName:String, isWaiting:Bool, canSkip:Bool = false, shouldLoop:Dynamic = false, legacyMode:Bool = false, isPrecache:Bool = false) {
		super();

		this.isPrecacheOnly = isPrecache;
		this.doWeLoop = shouldLoop;
		this.legacyMode = legacyMode;
		this.videoName = videoName;
		scrollFactor.set();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		waiting = isWaiting;
		if(!waiting)
		{
			cover = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
			cover.scale.set(FlxG.width + 100, FlxG.height + 100);
			cover.screenCenter();
			cover.scrollFactor.set();
			add(cover);
		}

		// initialize sprites
		videoSprite = new FlxVideoSprite();
		videoSprite.antialiasing = ClientPrefs.data.antialiasing;
		add(videoSprite);
		if(canSkip) this.canSkip = true;

		// callbacks
		#if web
		if(!shouldLoop) videoSprite.finishCallback = finishVideo;
		#else
		if(!shouldLoop) videoSprite.bitmap.onEndReached.add(function()
		{
			// The preload warm-up briefly starts playback. Do not let that
			// warm-up trigger the real cutscene's finish callback.
			if (!isPrecacheOnly)
				finishVideo();
		});
		#if hxvlc
		videoSprite.bitmap.onFormatSetup.add(function()
		#else
		videoSprite.bitmap.onTextureSetup.add(function()
		#end
		{
			/*
			#if hxvlc
			var wd:Int = videoSprite.bitmap.formatWidth;
			var hg:Int = videoSprite.bitmap.formatHeight;
			trace('Video Resolution: ${wd}x${hg}');
			videoSprite.scale.set(FlxG.width / wd, FlxG.height / hg);
			#end
			*/
			videoSprite.setGraphicSize(FlxG.initialWidth);
			videoSprite.updateHitbox();
			videoSprite.screenCenter();
			if (isPrecacheOnly)
			{
				precacheFormatReady = true;
				tryFinishPrecache();
			}
		});
		// Start the real media load, or run a silent warm-up pass. We wait for
		// format setup + playback progress before pausing the preload instance.
		#if hxvlc
		if (isPrecache)
		{
			videoSprite.bitmap.onPaused.add(onPrecachePaused);
			videoSprite.bitmap.onTimeChanged.add(onPrecacheTimeChanged);
			precacheVolume = videoSprite.bitmap.volume;
			videoSprite.bitmap.volume = 0; // Never leak warm-up audio into gameplay.
			precacheStarted = videoSprite.load(videoName, shouldLoop ? ['input-repeat=65545'] : null);
			if (precacheStarted)
				precacheStarted = videoSprite.play();
		}
		else
			videoSprite.load(videoName, shouldLoop ? ['input-repeat=65545'] : null);
		#end

		#end
	}

	var alreadyDestroyed:Bool = false;
	override function destroy()
	{
		if(alreadyDestroyed)
			return;

		trace('Video destroyed');
		if(cover != null)
		{
			remove(cover);
			cover.destroy();
		}

		finishCallback = null;
		onSkip = null;

		if(FlxG.state != null)
		{
			if(FlxG.state.members.contains(this))
				FlxG.state.remove(this);

			if(FlxG.state.subState != null && FlxG.state.subState.members.contains(this))
				FlxG.state.subState.remove(this);
		}
		super.destroy();
		alreadyDestroyed = true;
	}

	override function update(elapsed:Float)
	{
		if (!legacyMode && Controls.instance.pressed('pause') #if android || FlxG.android.justReleased.BACK #end && !pauseJustClosed && PlayState.instance != null )
			{
				var game = PlayState.instance;
					FlxG.camera.followLerp = 0;
					FlxG.state.persistentUpdate = false;
					FlxG.state.persistentDraw = true;
					pause();
					game.paused = true;
					var pauseState = new PauseSubState(true,VIDEO);
					pauseState.cutscene_allowSkipping = canSkip;
					pauseState.cutscene_hardReset = false;
					pauseJustClosed = true; // solely to prevent double-pausing
					game.openSubState(pauseState);

					game.subStateClosed.addOnce(s ->{ //TODO
						switch (pauseState.specialAction){
							case SKIP:{
								//finishCallback = null;
								#if web
								videoSprite.finishVideo();
								#else
								videoSprite.bitmap.onEndReached.dispatch();
								#end
								PlayState.instance.remove(this);
								trace('Skipped video');
							}
							case RESUME:{
								resume();
								FlxTimer.wait(0.4,() -> pauseJustClosed = false);
							}
							case NOTHING:{
								finishCallback = null;
							}
							case RESTART:{
								#if web
								videoSprite.restartVideo();
								#else
								videoSprite.bitmap.time = 0;
								#end
								resume();
							}
						}
						
					});
			}
		super.update(elapsed);
	}
	function finishVideo()
		{
			if (!alreadyDestroyed)
			{
				if(finishCallback != null)
					finishCallback();
	
				destroy();
			}
		}
	public function resume() videoSprite?.resume();
	public function pause() videoSprite?.pause();
	public function setSpeed(playbackRate:Float) {
		#if web
		if (videoSprite?.netStream != null)
			videoSprite.netStream.speed = playbackRate;
		#else
		if (videoSprite?.bitmap != null)
			videoSprite.bitmap.rate = playbackRate;
		#end
	}

	private function onPrecacheTimeChanged(time:Int64):Void
	{
		if (!isPrecacheOnly || time <= 0)
			return;

		precacheHasProgress = true;
		tryFinishPrecache();
	}

	private function tryFinishPrecache():Void
	{
		// Wait until VLC has configured its video output and playback time has
		// advanced. This is a much stronger readiness signal than load()/play()
		// returning successfully, and avoids the immediate-pause race in
		// hxVLC's convenience precache() wrapper.
		if (isPrecacheOnly && precacheFormatReady && precacheHasProgress && !precachePauseRequested)
		{
			precachePauseRequested = true;
			videoSprite.pause();
		}
	}

	private function onPrecachePaused():Void
	{
		if (!isPrecacheOnly || !precachePauseRequested)
			return;

		// Warm-up playback advances the VLC clock. Rewind only after VLC
		// confirms that playback has actually paused, otherwise the seek can
		// race with the decoder and the cutscene starts several seconds late.
		videoSprite.bitmap.time = 0;
		precacheReady = true;
		if (playWhenPrecacheReady)
		{
			playWhenPrecacheReady = false;
			isPrecacheOnly = false;
			restorePrecacheVolume();
			videoSprite.play();
		}
	}

	private function restorePrecacheVolume():Void
	{
		#if hxvlc
		if (videoSprite != null && videoSprite.bitmap != null)
			videoSprite.bitmap.volume = precacheVolume;
		#end
	}

	public function play() {
		#if hxvlc
		// If gameplay requests the cutscene before VLC has completed its warm-up,
		// queue the play request instead of restarting an uninitialized player.
		if (isPrecacheOnly && !precacheReady)
		{
			playWhenPrecacheReady = true;
			return;
		}
		if (isPrecacheOnly)
		{
			// Also rewind here: this covers the case where the cached player
			// finished warming up before PlayState takes it from the cache.
			videoSprite.bitmap.time = 0;
			isPrecacheOnly = false;
			restorePrecacheVolume();
		}
		videoSprite.play();
		#elseif web
		videoSprite.netStream.play(videoName);
		#else
		videoSprite.play(videoName, doWeLoop);
		if (FlxG.autoPause)
		{
			FlxG.signals.focusGained.remove(videoSprite.resume);
			FlxG.signals.focusLost.remove(videoSprite.pause);
		}
		#end
	}

	#end
}