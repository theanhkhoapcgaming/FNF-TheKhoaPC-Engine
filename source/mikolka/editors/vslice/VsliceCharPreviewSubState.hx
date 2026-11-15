package mikolka.editors.vslice;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxSubState;
import flixel.math.FlxMath;

/**
 * Character Preview Interactive SubState for P-Slice Chart Editor
 */
class VsliceCharPreviewSubState extends FlxSubState {
    private var previewGroup:VsliceCharacterPreview;
    private var backgroundBox:FlxSprite;
    private var infoText:FlxText;
    private var charDetailsText:FlxText;
    
    private var currentAnimIndex:Int = 0;
    private var availableAnims:Array<String> = ['idle', 'singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

    private var targetWindowWidth:Float = 500;
    private var targetWindowHeight:Float = 450;

    public function new(charName:String = 'bf') {
        super();

        var darkLayer:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        darkLayer.alpha = 0.65;
        add(darkLayer);

        previewGroup = new VsliceCharacterPreview(FlxG.width / 2, FlxG.height / 2 + 80, charName, false);

        targetWindowWidth = FlxMath.bound(previewGroup.calculatedWidth + 240, 480, FlxG.width - 100);
        targetWindowHeight = FlxMath.bound(previewGroup.calculatedHeight + 180, 400, FlxG.height - 80);

        backgroundBox = new FlxSprite(FlxG.width / 2 - targetWindowWidth / 2, FlxG.height / 2 - targetWindowHeight / 2)
            .makeGraphic(Std.int(targetWindowWidth), Std.int(targetWindowHeight), 0xFF22242B);
        backgroundBox.alpha = 0.92;
        add(backgroundBox);

        add(previewGroup);

        infoText = new FlxText(backgroundBox.x + 20, backgroundBox.y + 15, targetWindowWidth - 40, "", 15);
        infoText.setFormat(null, 15, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        add(infoText);

        charDetailsText = new FlxText(backgroundBox.x + 20, backgroundBox.y + targetWindowHeight - 45, targetWindowWidth - 40, "", 13);
        charDetailsText.setFormat(null, 13, 0xFFCCAA, CENTER, OUTLINE, FlxColor.BLACK);
        add(charDetailsText);

        updatePreviewAnim();
        updateJsonDetailsText(charName);
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        if (FlxG.keys.justPressed.LEFT) {
            currentAnimIndex--;
            if (currentAnimIndex < 0) currentAnimIndex = availableAnims.length - 1;
            updatePreviewAnim();
        }
        if (FlxG.keys.justPressed.RIGHT) {
            currentAnimIndex++;
            if (currentAnimIndex >= availableAnims.length) currentAnimIndex = 0;
            updatePreviewAnim();
        }

        if (FlxG.keys.justPressed.ESCAPE) {
            close();
        }
    }

    private function updatePreviewAnim():Void {
        var animToPlay:String = availableAnims[currentAnimIndex];
        if (previewGroup.character.animation.getByName(animToPlay) != null) {
            previewGroup.playAnim(animToPlay, true);
            infoText.text = 'V-SLICE CHARACTER PREVIEW\n[◄ / ►] Animation: ' + animToPlay + ' | [ESC] Close';
        } else {
            infoText.text = 'V-SLICE CHARACTER PREVIEW\nAnimation "' + animToPlay + '" not found!';
        }
    }

    private function updateJsonDetailsText(charName:String):Void {
        var posX = previewGroup.charOffset.x;
        var posY = previewGroup.charOffset.y;
        var camX = previewGroup.camOffset.x;
        var camY = previewGroup.camOffset.y;
        var scale = previewGroup.jsonScale;

        charDetailsText.text = 'Char: ' + charName + ' | Scale: ' + scale + ' | Char Offset: [' + posX + ', ' + posY + '] | Cam Offset: [' + camX + ', ' + camY + ']';
    }
}
