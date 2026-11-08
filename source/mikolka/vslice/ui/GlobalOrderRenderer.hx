package mikolka.vslice.ui;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxSprite;

/**
 * Draws UIEditor sprites as individual objects in one global order, regardless
 * of which FlxGroup or parent state member owns them. The sprites remain in
 * their original containers, so normal update/input ownership is preserved.
 */
typedef GlobalOrderRenderEntry = {
        var sprite:FlxSprite;
        var cameras:Array<FlxCamera>;
};

class GlobalOrderRenderer extends FlxBasic
{
    var entries:Array<GlobalOrderRenderEntry>;

    public function new(entries:Array<GlobalOrderRenderEntry>)
    {
        super();
        this.entries = entries == null ? [] : entries;
    }

    override public function draw():Void
    {
        for (entry in entries)
        {
            if (entry == null || entry.sprite == null) continue;
            var sprite:FlxSprite = entry.sprite;
            // Restore the sprite's original camera list only for this draw call.
            sprite.cameras = entry.cameras;
            sprite.draw();
            // Keep it suppressed during the next frame's ordinary group draw.
            sprite.cameras = [];
        }
    }

    override public function destroy():Void
    {
        // Restore camera assignments if the state is destroyed before another draw.
        if (entries != null)
        {
            for (entry in entries)
            {
                if (entry != null && entry.sprite != null)
                    entry.sprite.cameras = entry.cameras;
            }
            entries = null;
        }
        super.destroy();
    }
}
