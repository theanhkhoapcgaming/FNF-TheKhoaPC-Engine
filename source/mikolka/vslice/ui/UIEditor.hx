package mikolka.vslice.ui;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.FlxBasic;
import flixel.FlxCamera;
import mikolka.funkin.custom.NativeFileSystem;
import backend.Mods;
import backend.BaseGame;
import mikolka.vslice.ui.GlobalOrderRenderer.GlobalOrderRenderEntry;
import mikolka.funkin.custom.mobile.MobileScaleMode;
#if HSCRIPT_ALLOWED
import psychlua.HScript;
#end

/**
 * Declarative UI layouts and optional per-provider HScript custom UI overrides.
 * Base Game is preferred when globally mounted; enabled mods are fallback providers.
 */
class UIEditor
{
    static var cache:Map<String, Dynamic> = new Map<String, Dynamic>();
    static var missing:Map<String, Bool> = new Map<String, Bool>();
    static var registeredElements:Map<String, Map<String, FlxSprite>> = new Map<String, Map<String, FlxSprite>>();
    static var registeredOrder:Map<String, Array<String>> = new Map<String, Array<String>>();
    #if HSCRIPT_ALLOWED
    static var customScripts:Map<String, HScript> = new Map<String, HScript>();
    static var customStates:Map<String, flixel.FlxState> = new Map<String, flixel.FlxState>();
    static var customHiddenSprites:Map<String, Array<Dynamic>> = new Map<String, Array<Dynamic>>();
    static var customStateMembers:Map<String, Array<FlxBasic>> = new Map<String, Array<FlxBasic>>();
    #end

    /** Clear cached layouts so edits are picked up by the next menu construction. */
    public static function refresh():Void
    {
        cache = new Map<String, Dynamic>();
        missing = new Map<String, Bool>();
        registeredElements = new Map<String, Map<String, FlxSprite>>();
        registeredOrder = new Map<String, Array<String>>();
        #if HSCRIPT_ALLOWED
        var activeScreens:Array<String> = [];
        for (screen in customScripts.keys()) activeScreens.push(screen);
        for (screen in activeScreens) destroyCustomScript(screen);
        customScripts = new Map<String, HScript>();
        customStates = new Map<String, flixel.FlxState>();
        customHiddenSprites = new Map<String, Array<Dynamic>>();
        customStateMembers = new Map<String, Array<FlxBasic>>();
        #end
        trace("[UIEditor] UI layout cache refreshed");
    }

    /** Resolve the first available UI JSON from Base Game or enabled mods. */
    static function getConfigNames(screen:String):Array<String>
    {
        // Accept both the original internal IDs and the friendlier filenames
        // used by the UIEditor configuration files.
        switch (screen)
        {
            case "story-menu": return ["story-mode", "story-menu"];
            case "freeplay": return ["free-play", "freeplay"];
            default: return [screen];
        }
    }

    static function resolveConfigPath(screen:String):String
    {
        var names:Array<String> = getConfigNames(screen);
        // Base Game has absolute priority whenever it is mounted globally.
        if (Mods.getGlobalMods().contains(Mods.BASE_GAME_ID))
        {
            for (name in names)
            {
                var basePath:String = BaseGame.path("uieditor/" + name + ".json");
                if (NativeFileSystem.exists(basePath)) return basePath;
            }
        }

        // If Base Game has no layout for this screen, search enabled mods in
        // their configured order. A mod does not need a special UI-provider flag.
        var enabledMods:Array<String> = Mods.parseList().enabled;
        if (enabledMods != null)
        {
            for (mod in enabledMods)
            {
                if (Mods.isBaseGameFolder(mod)) continue;
                for (name in names)
                {
                    var modPath:String = Paths.mods(mod + "/uieditor/" + name + ".json");
                    if (NativeFileSystem.exists(modPath)) return modPath;
                }
            }
        }
        return null;
    }

    static function getConfig(screen:String):Dynamic
    {
        var path:String = resolveConfigPath(screen);
        if (path == null)
        {
            missing.set(screen, true);
            return null;
        }

        // Key by the actual source path so a provider change cannot reuse a
        // layout cached from a different pack.
        var cacheKey:String = path;
        if (cache.exists(cacheKey)) return cache.get(cacheKey);
        if (missing.exists(cacheKey)) return null;

        try
        {
            var raw:String = NativeFileSystem.getContent(path);
            if (raw == null || raw.trim().length == 0) throw "Empty UI editor file";
            var parsed:Dynamic = haxe.Json.parse(raw);
            cache.set(cacheKey, parsed);
            return parsed;
        }
        catch (e:Dynamic)
        {
            trace('[UIEditor] Could not read ' + path + ': ' + Std.string(e));
            missing.set(cacheKey, true);
            return null;
        }
    }

    /** Read the menu scroll axis from its UIEditor JSON. Defaults to vertical. */
    public static function getScrollDirection(screen:String):String
    {
        var config:Dynamic = getConfig(screen);
        if (config == null) return "vertical";

        // Keep the original shared key for backwards compatibility, while
        // also accepting the explicit names used by each menu. This avoids
        // silently ignoring song/week scroll settings in existing layouts.
        var value:Dynamic = null;
        if (screen == "freeplay") value = Reflect.field(config, "songScrollDirection");
        else if (screen == "story-menu") value = Reflect.field(config, "weekScrollDirection");
        if (value == null) value = Reflect.field(config, "scrollDirection");
        if (value == null) return "vertical";

        var direction:String = ~/^\s+|\s+$/g.replace(Std.string(value), "").toLowerCase();
        return (direction == "horizontal" || direction == "horiz" || direction == "x")
            ? "horizontal" : "vertical";
    }

    /** Return the opposite axis for difficulty scrolling. */
    public static function getOppositeScrollDirection(screen:String):String
    {
        return getScrollDirection(screen) == "horizontal" ? "vertical" : "horizontal";
    }

    /** Apply the named element's optional layout properties to an existing sprite. */
    public static function apply(screen:String, element:String, sprite:FlxSprite):Void
    {
        if (sprite == null || element == null) return;
        var config:Dynamic = getConfig(screen);
        if (config == null) return;
        // Register every built-in UI sprite even when JSON has no `elements`
        // object; a successful custom script must be able to replace the full UI.
        registerElement(screen, element, sprite);
        if (config.elements != null)
            applyData(sprite, Reflect.field(config.elements, element), element);
        // Some screens register JSON UI before applying their built-in layout
        // hooks. If the custom script has already committed, hide late-registered
        // sprites too so the override remains complete.
        hideSpriteForCustomScript(screen, sprite);
    }

    /** Add optional JSON-defined sprite/text elements to a menu state. */
    public static function createCustomElements(state:flixel.FlxState, screen:String):Void
    {
        if (state == null) return;
        var config:Dynamic = getConfig(screen);
        if (config != null && config.customElements != null)
        {
        var customElements:Array<Dynamic> = cast config.customElements;
        for (data in customElements)
        {
            if (data == null) continue;
            var kind:String = data.type == null ? "sprite" : Std.string(data.type).toLowerCase();
            var x:Float = data.x == null ? 0 : data.x;
            var y:Float = data.y == null ? 0 : data.y;
            var sprite:FlxSprite = null;

            if (kind == "text")
            {
                var textValue:String = data.text == null ? "" : Std.string(data.text);
                var width:Float = data.width == null ? 0 : data.width;
                var size:Int = data.textSize == null ? 24 : Std.int(data.textSize);
                var textSprite:flixel.text.FlxText = new flixel.text.FlxText(x, y, width, textValue, size);
                if (data.font != null)
                    textSprite.setFormat(Paths.font(Std.string(data.font)), size);
                sprite = textSprite;
            }
            else if (kind == "sprite")
            {
                sprite = new FlxSprite(x, y);
                if (data.image != null && Std.string(data.image).length > 0)
                    sprite.loadGraphic(Paths.image(Std.string(data.image)));
            }
            else if (kind == "animatedsprite" || kind == "animated_sprite")
            {
                sprite = new FlxSprite(x, y);
                if (data.image == null || Std.string(data.image).length == 0)
                {
                    trace('[UIEditor] animatedSprite is missing its image/atlas: ' + Std.string(data.id));
                    continue;
                }

                // Use the same atlas resolver as StageData so Sparrow and
                // other supported atlas formats follow the engine's paths.
                sprite.frames = Paths.getAtlas(Std.string(data.image));

                var animations:Array<Dynamic> = data.animations == null ? [] : cast data.animations;
                var firstAnimation:String = data.playAnimation == null
                    ? (data.firstAnimation == null ? null : Std.string(data.firstAnimation))
                    : Std.string(data.playAnimation);

                for (animData in animations)
                {
                    if (animData == null) continue;
                    // Accept both the StageData format (anim/name) and the
                    // friendlier UIEditor format (name/prefix).
                    var usesStageDataFormat:Bool = animData.anim != null;
                    var animId:String = usesStageDataFormat
                        ? Std.string(animData.anim)
                        : (animData.name == null ? null : Std.string(animData.name));
                    var prefix:String = usesStageDataFormat
                        ? (animData.name == null ? null : Std.string(animData.name))
                        : (animData.prefix == null ? null : Std.string(animData.prefix));
                    if (prefix == null || prefix.length == 0) prefix = animId;
                    if (animId == null || animId.length == 0 || prefix == null || prefix.length == 0)
                    {
                        trace('[UIEditor] Skipping animatedSprite animation with missing name/prefix');
                        continue;
                    }

                    var fps:Int = animData.fps == null ? 24 : Std.int(animData.fps);
                    var loop:Bool = animData.loop == null ? false : (animData.loop == true);
                    var indices:Array<Int> = animData.indices == null ? null : cast animData.indices;
                    if (indices != null && indices.length > 0)
                        sprite.animation.addByIndices(animId, prefix, indices, '', fps, loop);
                    else
                        sprite.animation.addByPrefix(animId, prefix, fps, loop);


                    if (firstAnimation == null) firstAnimation = animId;
                }

                if (firstAnimation != null && sprite.animation.getByName(firstAnimation) != null)
                    sprite.animation.play(firstAnimation, true);
                else if (sprite.animation.getNameList().length > 0)
                    sprite.animation.play(sprite.animation.getNameList()[0], true);
            }
            else
            {
                trace('[UIEditor] Unsupported custom element type: ' + kind);
                continue;
            }

            var antialiasing:Dynamic = Reflect.field(data, "antialiasing");
            if (antialiasing != null && Std.isOfType(antialiasing, Bool))
                sprite.antialiasing = antialiasing;

            var customId:String = data.id == null ? kind : Std.string(data.id);
            applyData(sprite, data, customId);
            registerElement(screen, customId, sprite);
            state.add(sprite);
        }
        }
        loadCustomScript(state, screen, config);
    }

    /** Load the optional HScript declared by the selected JSON provider. */
    static function loadCustomScript(state:flixel.FlxState, screen:String, config:Dynamic):Void
    {
        if (state == null || config == null) return;
        var scriptName:Dynamic = Reflect.field(config, "custom-script");
        if (scriptName == null) scriptName = Reflect.field(config, "customScript");
        if (scriptName == null) return;
        var name:String = ~/^\s+|\s+$/g.replace(Std.string(scriptName), "");
        if (name.length == 0) return;

        var configPath:String = resolveConfigPath(screen);
        if (configPath == null) return;
        var slash:Int = configPath.lastIndexOf("/");
        var folder:String = slash < 0 ? "" : configPath.substr(0, slash + 1);
        // JSON registration is deliberately data-driven: only look beside the
        // selected JSON, so a mod cannot accidentally load another pack's code.
        var scriptPath:String = null;
        var candidateName:String = name;
        if (candidateName.indexOf("/") >= 0 || candidateName.indexOf("\\") >= 0 || candidateName.indexOf("..") >= 0)
        {
            trace('[UIEditor] Rejected unsafe custom-script path: ' + candidateName);
            return;
        }
        var candidate:String = folder + candidateName;
        if (candidateName.toLowerCase().endsWith(".hxc"))
        {
            if (NativeFileSystem.exists(candidate)) scriptPath = candidate;
        }
        else
        {
            if (NativeFileSystem.exists(candidate + ".hxc")) scriptPath = candidate + ".hxc";
        }
        if (scriptPath == null)
        {
            trace('[UIEditor] Custom .hxc script not found beside ' + configPath + ': ' + name);
            return;
        }
        #if HSCRIPT_ALLOWED
        if (customScripts.exists(screen)) destroyCustomScript(screen);
        var baseline:Array<FlxBasic> = [];
        for (member in state.members) if (member != null) baseline.push(member);
        customStates.set(screen, state);
        customStateMembers.set(screen, baseline);
        // Snapshot every top-level screen member as well as individually
        // registered sprites (some UI is nested inside groups).
        var hidden:Array<Dynamic> = [];
        for (member in baseline)
        {
            hidden.push({object: member, visible: member.visible, active: member.active});
        }
        var elements:Map<String, FlxSprite> = registeredElements.get(screen);
        if (elements != null)
        {
            for (sprite in elements)
            {
                if (sprite == null) continue;
                var alreadySaved:Bool = false;
                for (saved in hidden) if (saved.object == sprite) alreadySaved = true;
                var snapshot:Dynamic = {
                    object: sprite, sprite: sprite, visible: sprite.visible, active: sprite.active,
                    x: sprite.x, y: sprite.y, alpha: sprite.alpha, angle: sprite.angle,
                    scaleX: sprite.scale.x, scaleY: sprite.scale.y, color: sprite.color,
                    scrollX: sprite.scrollFactor.x, scrollY: sprite.scrollFactor.y
                };
                if (Std.isOfType(sprite, flixel.text.FlxText))
                {
                    snapshot.text = cast(sprite, flixel.text.FlxText).text;
                    snapshot.textSize = cast(sprite, flixel.text.FlxText).size;
                }
                if (!alreadySaved) hidden.push(snapshot);
            }
        }
        customHiddenSprites.set(screen, hidden);
        var script:HScript = null;
        try
        {
            script = new HScript(null, scriptPath, {state: state, uiScreen: screen, uiEditor: UIEditor});
            if (script.exists("onCreate")) script.call("onCreate", []);

            // Only commit override after parsing and onCreate both succeed.
            customScripts.set(screen, script);
            for (entry in hidden)
            {
                entry.object.visible = false;
                entry.object.active = false;
            }
            customStateMembers.set(screen, baseline);
            trace('[UIEditor] Custom UI override enabled: ' + scriptPath);
        }
        catch (e:Dynamic)
        {
            trace('[UIEditor] Custom script onCreate/load failed (' + scriptPath + '): ' + Std.string(e));
            if (script != null)
            {
                try { if (script.exists("onDestroy")) script.call("onDestroy", []); }
                catch (cleanupError:Dynamic) trace('[UIEditor] Custom script cleanup failed (' + screen + '): ' + Std.string(cleanupError));
                script.destroy();
            }
            restoreJsonUI(screen);
        }
        #else
        trace('[UIEditor] HScript is not enabled; cannot run ' + scriptPath);
        #end
    }

    /** Execute onUpdate; any runtime failure disables the script and restores JSON UI. */
    public static function updateCustomScript(screen:String, elapsed:Float):Void
    {
        #if HSCRIPT_ALLOWED
        var script:HScript = customScripts.get(screen);
        if (script != null && script.exists("onUpdate"))
        {
            try script.call("onUpdate", [elapsed])
            catch (e:Dynamic)
            {
                trace('[UIEditor] Custom script onUpdate failed (' + screen + '): ' + Std.string(e));
                destroyCustomScript(screen);
            }
        }
        #end
    }

    /** Call onDestroy and release the script without leaving hidden JSON objects. */
    public static function destroyCustomScript(screen:String):Void
    {
        #if HSCRIPT_ALLOWED
        var script:HScript = customScripts.get(screen);
        if (script != null)
        {
            try { if (script.exists("onDestroy")) script.call("onDestroy", []); }
            catch (e:Dynamic) trace('[UIEditor] Custom script onDestroy failed (' + screen + '): ' + Std.string(e));
            script.destroy();
            customScripts.remove(screen);
            restoreJsonUI(screen);
        }
        #end
    }

    /** Restore JSON-controlled elements and remove state members created by a failed script. */
    static function restoreJsonUI(screen:String):Void
    {
        #if HSCRIPT_ALLOWED
        var state:flixel.FlxState = customStates.get(screen);
        var baseline:Array<FlxBasic> = customStateMembers.get(screen);
        if (state != null && baseline != null)
        {
            var keep:Map<FlxBasic, Bool> = new Map<FlxBasic, Bool>();
            for (member in baseline) keep.set(member, true);
            var extras:Array<FlxBasic> = [];
            for (member in state.members) if (member != null && !keep.exists(member)) extras.push(member);
            for (member in extras)
            {
                state.remove(member, true);
                member.destroy();
            }
        }
        var hidden = customHiddenSprites.get(screen);
        if (hidden != null)
        {
            for (entry in hidden)
            {
                if (entry.object == null) continue;
                entry.object.visible = entry.visible;
                entry.object.active = entry.active;
                if (entry.sprite == null) continue;
                entry.sprite.setPosition(entry.x, entry.y);
                entry.sprite.alpha = entry.alpha;
                entry.sprite.angle = entry.angle;
                entry.sprite.scale.set(entry.scaleX, entry.scaleY);
                entry.sprite.color = entry.color;
                entry.sprite.scrollFactor.set(entry.scrollX, entry.scrollY);
                if (Reflect.hasField(entry, "text") && Std.isOfType(entry.sprite, flixel.text.FlxText))
                {
                    cast(entry.sprite, flixel.text.FlxText).text = entry.text;
                    cast(entry.sprite, flixel.text.FlxText).size = entry.textSize;
                }
            }
        }
        customStates.remove(screen);
        customHiddenSprites.remove(screen);
        customStateMembers.remove(screen);
        #end
    }

    /** Snapshot and hide a sprite registered after a custom override started. */
    static function hideSpriteForCustomScript(screen:String, sprite:FlxSprite):Void
    {
        #if HSCRIPT_ALLOWED
        if (sprite == null || !customScripts.exists(screen)) return;
        var hidden:Array<Dynamic> = customHiddenSprites.get(screen);
        if (hidden == null) hidden = [];
        for (entry in hidden) if (entry.sprite == sprite) return;
        var snapshot:Dynamic = {
            object: sprite, sprite: sprite, visible: sprite.visible, active: sprite.active,
            x: sprite.x, y: sprite.y, alpha: sprite.alpha, angle: sprite.angle,
            scaleX: sprite.scale.x, scaleY: sprite.scale.y, color: sprite.color,
            scrollX: sprite.scrollFactor.x, scrollY: sprite.scrollFactor.y
        };
        if (Std.isOfType(sprite, flixel.text.FlxText))
        {
            snapshot.text = cast(sprite, flixel.text.FlxText).text;
            snapshot.textSize = cast(sprite, flixel.text.FlxText).size;
        }
        hidden.push(snapshot);
        customHiddenSprites.set(screen, hidden);
        sprite.visible = false;
        sprite.active = false;
        #end
    }

    /** Register a named sprite so objectOrder can find built-in and custom elements. */
    static function registerElement(screen:String, element:String, sprite:FlxSprite):Void
    {
        if (screen == null || element == null || sprite == null) return;
        if (!registeredElements.exists(screen))
        {
            registeredElements.set(screen, new Map<String, FlxSprite>());
            registeredOrder.set(screen, []);
        }
        var elements = registeredElements.get(screen);
        if (!elements.exists(element)) registeredOrder.get(screen).push(element);
        elements.set(element, sprite);
    }

    /**
     * Apply objectOrder as a GLOBAL render list. Registered sprites are removed
     * from their normal render passes by assigning an empty camera list, but
     * remain in their original groups/states for update, input and animation.
     * A final renderer draws each sprite individually in the requested order.
     */
    public static function applyObjectOrder(state:flixel.FlxState, screen:String):Void
    {
        if (state == null) return;
        var config:Dynamic = getConfig(screen);
        if (config == null || config.objectOrder == null) return;
        var elements:Map<String, FlxSprite> = registeredElements.get(screen);
        var names:Array<String> = registeredOrder.get(screen);
        if (elements == null || names == null) return;

        var ordered:Array<FlxSprite> = [];
        var included:Map<String, Bool> = new Map<String, Bool>();
        var order:Array<Dynamic> = cast config.objectOrder;

        // Explicit JSON order is bottom-to-top.
        for (entry in order)
        {
            if (entry == null) continue;
            var name:String = Std.string(entry);
            var sprite:FlxSprite = elements.get(name);
            if (sprite == null || included.exists(name)) continue;
            ordered.push(sprite);
            included.set(name, true);
        }

        // Keep unlisted registered elements in their original registration order.
        for (name in names)
        {
            if (included.exists(name)) continue;
            var sprite:FlxSprite = elements.get(name);
            if (sprite != null)
            {
                ordered.push(sprite);
                included.set(name, true);
            }
        }

        if (ordered.length == 0) return;

        // Prevent the original parent/group draw calls from drawing these sprites.
        // Their membership is deliberately NOT changed.
        var renderEntries:Array<GlobalOrderRenderEntry> = [];
        for (sprite in ordered)
        {
            var originalCameras:Array<FlxCamera> = sprite.cameras;
            renderEntries.push({sprite: sprite, cameras: originalCameras});
            sprite.cameras = [];
        }

        // Added last: this renderer draws after normal state members, while each
        // target keeps its own original camera assignment when rendered.
        state.add(new GlobalOrderRenderer(renderEntries));
    }

    static function applyData(sprite:FlxSprite, data:Dynamic, element:String):Void
    {
        if (sprite == null || data == null) return;
        // UIEditor JSON coordinates are authored in the normal game layout.
        // Apply the same horizontal cutout compensation used by weekCharacters
        // so every JSON-positioned element follows Wide Screen Mode consistently.
        // gameCutoutSize.x is zero when Wide Screen Mode is disabled.
        var wideScreenOffsetX:Float = MobileScaleMode.gameCutoutSize.x / 2;
        setFloat(data, "x", function(v) sprite.x = v + wideScreenOffsetX);
        setFloat(data, "y", function(v) sprite.y = v);
        setFloat(data, "alpha", function(v) sprite.alpha = v);
        setFloat(data, "angle", function(v) sprite.angle = v);
        setFloat(data, "scaleX", function(v) sprite.scale.x = v);
        setFloat(data, "scaleY", function(v) sprite.scale.y = v);

        // Accept a combined scrollFactor value for both built-in and custom
        // elements. Supported JSON forms:
        //   "scrollFactor": 0.5
        //   "scrollFactor": [0.5, 1]
        //   "scrollFactor": {"x": 0.5, "y": 1}
        // The legacy per-axis keys below take precedence when also supplied.
        var scrollFactor:Dynamic = Reflect.field(data, "scrollFactor");
        if (scrollFactor != null)
        {
            if (Std.isOfType(scrollFactor, Int) || Std.isOfType(scrollFactor, Float))
            {
                sprite.scrollFactor.set(scrollFactor, scrollFactor);
            }
            else if (Std.isOfType(scrollFactor, Array))
            {
                var factors:Array<Dynamic> = cast scrollFactor;
                if (factors.length > 0 && (Std.isOfType(factors[0], Int) || Std.isOfType(factors[0], Float)))
                    sprite.scrollFactor.x = factors[0];
                if (factors.length > 1 && (Std.isOfType(factors[1], Int) || Std.isOfType(factors[1], Float)))
                    sprite.scrollFactor.y = factors[1];
            }
            else
            {
                setFloat(scrollFactor, "x", function(v) sprite.scrollFactor.x = v);
                setFloat(scrollFactor, "y", function(v) sprite.scrollFactor.y = v);
            }
        }
        setFloat(data, "scrollFactorX", function(v) sprite.scrollFactor.x = v);
        setFloat(data, "scrollFactorY", function(v) sprite.scrollFactor.y = v);

        var visible:Dynamic = Reflect.field(data, "visible");
        if (visible != null && Std.isOfType(visible, Bool)) sprite.visible = visible;
        var active:Dynamic = Reflect.field(data, "active");
        if (active != null && Std.isOfType(active, Bool)) sprite.active = active;

        var color:Dynamic = Reflect.field(data, "color");
        if (color != null)
        {
            try
            {
                var colorString:String = Std.string(color);
                if (colorString.indexOf("#") == 0) colorString = colorString.substr(1);
                if (colorString.indexOf("0x") == 0) colorString = colorString.substr(2);
                var parsedColor:Int = Std.parseInt("0x" + colorString);
                if (parsedColor >= 0 && colorString.length <= 6) parsedColor |= 0xFF000000;
                sprite.color = parsedColor;
            }
            catch (e:Dynamic) trace('[UIEditor] Invalid color for ' + element);
        }

        var text:Dynamic = Reflect.field(data, "text");
        if (text != null && Std.isOfType(sprite, flixel.text.FlxText))
            cast(sprite, flixel.text.FlxText).text = Std.string(text);

        var textSize:Dynamic = Reflect.field(data, "textSize");
        if (textSize != null && Std.isOfType(sprite, flixel.text.FlxText))
            cast(sprite, flixel.text.FlxText).size = Std.int(textSize);
    }

    static function setFloat(data:Dynamic, name:String, setter:Float->Void):Void
    {
        var value:Dynamic = Reflect.field(data, name);
        if (value != null && (Std.isOfType(value, Int) || Std.isOfType(value, Float)))
            setter(value);
    }
}
