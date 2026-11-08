package mikolka.editors.vslice;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import objects.Character;
import haxe.Json;
import sys.io.File;
import sys.FileSystem;

/**
 * Dynamic V-Slice Character Preview with auto-scaling & JSON bounds checking.
 * Remastered for P-Slice / Funkin-0.8.7 Architecture.
 */
class VsliceCharacterPreview extends FlxSpriteGroup {
    public var character:Character;
    public var charShadow:FlxSprite;
    
    public var charOffset:FlxPoint = new FlxPoint(0, 0);
    public var camOffset:FlxPoint = new FlxPoint(0, 0);
    public var jsonScale:Float = 1.0;
    
    public var calculatedWidth:Float = 200;
    public var calculatedHeight:Float = 300;
    public var maxAnimBound:FlxRect = new FlxRect(0, 0, 0, 0);

    private var basePosition:FlxPoint = new FlxPoint(0, 0);

    public function new(x:Float, y:Float, charName:String = 'bf', isPlayer:Bool = false) {
        super(x, y);
        basePosition.set(x, y);

        charShadow = new FlxSprite(0, 0);
        charShadow.makeGraphic(120, 28, FlxColor.BLACK);
        charShadow.alpha = 0.35;
        charShadow.offset.set(60, 14);
        add(charShadow);

        reloadCharacter(charName, isPlayer);
    }

    public function reloadCharacter(charName:String, isPlayer:Bool):Void {
        if (character != null) {
            remove(character);
            character.destroy();
        }

        readJsonData(charName);

        character = new Character(0, 0, charName, isPlayer);
        character.debugMode = true;
        
        calculateAnimationBounds();

        updateCharacterPosition();
        add(character);
    }

    private function readJsonData(charName:String):Void {
        var path:String = 'characters/' + charName + '.json';
        #if MODS_ALLOWED
        var modPath:String = Paths.modFolders('characters/' + charName + '.json');
        if (FileSystem.exists(modPath)) path = modPath;
        else if (FileSystem.exists(Paths.json('characters/' + charName))) path = Paths.json('characters/' + charName);
        #end

        if (FileSystem.exists(path)) {
            try {
                var rawJson:String = File.getContent(path);
                var json:Dynamic = Json.parse(rawJson);
                
                if (json.position != null) {
                    charOffset.set(json.position[0], json.position[1]);
                } else {
                    charOffset.set(0, 0);
                }

                if (json.camera_position != null) {
                    camOffset.set(json.camera_position[0], json.camera_position[1]);
                } else {
                    camOffset.set(0, 0);
                }

                if (json.scale != null) {
                    jsonScale = json.scale;
                } else {
                    jsonScale = 1.0;
                }
            } catch (e:Dynamic) {
                trace('Error reading character JSON: ' + e);
            }
        }
    }

    private function calculateAnimationBounds():Void {
        if (character == null) return;

        var w:Float = character.width > 0 ? character.width : 200;
        var h:Float = character.height > 0 ? character.height : 300;

        calculatedWidth = w * jsonScale;
        calculatedHeight = h * jsonScale;

        maxAnimBound.set(-calculatedWidth / 2, -calculatedHeight, calculatedWidth, calculatedHeight);
    }

    public function playAnim(animName:String, force:Bool = true, reversed:Bool = false, frame:Int = 0):Void {
        if (character != null && character.animation.getByName(animName) != null) {
            character.playAnim(animName, force, reversed, frame);
            updateCharacterPosition();
        }
    }

    public function updateCharacterPosition():Void {
        if (character == null) return;
        
        var animOffset:FlxPoint = new FlxPoint(0, 0);
        if (character.animOffsets.exists(character.animation.curAnim.name)) {
            var offsets = character.animOffsets.get(character.animation.curAnim.name);
            animOffset.set(offsets[0], offsets[1]);
        }

        character.x = basePosition.x - (character.frameWidth * jsonScale / 2) - charOffset.x - animOffset.x + camOffset.x;
        character.y = basePosition.y - (character.frameHeight * jsonScale) - charOffset.y - animOffset.y + camOffset.y;

        if (charShadow != null) {
            charShadow.x = basePosition.x + camOffset.x;
            charShadow.y = basePosition.y + 10 + camOffset.y;
        }
    }
}
