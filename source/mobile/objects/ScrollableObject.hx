package mobile.objects;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxRect;
#if TOUCH_CONTROLS_ALLOWED
import flixel.util.FlxSignal;
import flixel.FlxObject;

class ScrollableObject extends TouchZone {
    public var onFullScroll(default,never):FlxTypedSignal<(delta:Int)->Void> = new FlxTypedSignal();
    public var onPartialScroll(default,never):FlxTypedSignal<(delta:Float) ->Void> = new FlxTypedSignal();
    public var onFullScrollSnap(default,never):FlxSignal = new FlxSignal();
    public var onTap(default,never):FlxSignal = new FlxSignal();

    private var isDragging:Bool = false;
    private var isTapping:Bool = false;
    private var lastYPos:Float = 0;
    private var lastXPos:Float = 0;
    private var scrollAxis:String = "vertical";
    private var partialScrollTracker:Float = 0;
    private var scrollScale:Float = 0;
    private var clickButton:FlxObject;

    public function new(scrollScale:Float,x:Float, y:Float, width:Float, height:Float,clickButton:FlxObject, axis:String = "vertical") {
        this.scrollScale = scrollScale;
        this.clickButton = clickButton;
        this.scrollAxis = axis != null && axis.toLowerCase() == "horizontal" ? "horizontal" : "vertical";
        super(x,y,width,height);
    }
    override function update(elapsed:Float) {
        super.update(elapsed);
        var curDelta = getDelta();
        //MusicBea
        if
            #if mobile
            (TouchUtil.justPressed && TouchUtil.overlaps(this))
            #else 
            (FlxG.mouse.justPressed && FlxG.mouse.overlaps(this,this.camera)) 
            #end
        {
            isDragging = false;
            isTapping = true;
            #if mobile
            if (FlxG.touches.getFirst() != null)
            {
                lastXPos = FlxG.touches.getFirst().viewX;
                lastYPos = FlxG.touches.getFirst().viewY;
            }
            #end
        }
        else if( #if mobile TouchUtil.justReleased #else FlxG.mouse.justReleased #end) {
            if(isTapping){
                if(clickButton.camera == null || clickButton.camera.scroll != null){
                    #if mobile
                    if(getjustPressed()?.overlaps(clickButton,clickButton.camera) ?? false) onTap.dispatch();
                    #else
                    if(FlxG.mouse.overlaps(clickButton,clickButton.camera)) onTap.dispatch();
                    #end
                }
                isTapping = false;
            }
            else if(isDragging) {
                onFullScrollSnap.dispatch();
                isDragging = false;
                var curDpad = Controls.instance.isInSubstate ? MusicBeatSubstate.instance.touchPad : MusicBeatState.getState().touchPad;
                if(curDpad != null) curDpad.active = true;
            }
            else return;
            
            partialScrollTracker = 0;
        }
        else if(( #if mobile TouchUtil.pressed || #end FlxG.mouse.pressed) && (Math.abs(curDelta)) > 3)
            {
                if(isTapping){
                    isDragging = true;
                var curDpad = Controls.instance.isInSubstate ? MusicBeatSubstate.instance.touchPad : MusicBeatState.getState().touchPad;
                if(curDpad != null) curDpad.active = false;
                    isTapping = false;
                }
                else if(!isDragging) return;
                // What we moved now
                var dragMove = curDelta*scrollScale;

                partialScrollTracker += dragMove;
                onPartialScroll.dispatch(dragMove);

                if((Math.abs(Math.round(partialScrollTracker))) >= 1){
                    // We have a full scroll
                    var fullScroll = Math.round(partialScrollTracker);
                    partialScrollTracker -= fullScroll;
                    onFullScroll.dispatch(fullScroll);
                }
            }
    }
    private function getjustPressed():FlxTouch
        {
            for (touch in FlxG.touches.list)
                if (touch.justReleased)
                    return touch;
    
            return null;
        }
    private function getDelta():Float {
        #if mobile
        if(FlxG.touches.getFirst() == null) return 0;
        if (scrollAxis == "horizontal") {
            var deltaX = FlxG.touches.getFirst().viewX - lastXPos;
            lastXPos = FlxG.touches.getFirst().viewX;
            return deltaX;
        }
        var deltaY = FlxG.touches.getFirst().viewY - lastYPos;
        lastYPos = FlxG.touches.getFirst().viewY;
        return deltaY;
        #else
        return scrollAxis == "horizontal" ? FlxG.mouse.deltaViewX : FlxG.mouse.deltaViewY;
        #end
    }
    
}
#end