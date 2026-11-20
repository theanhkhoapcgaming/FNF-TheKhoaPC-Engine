package states.editors.boxes;

import backend.StageData;
import objects.Character;
import states.editors.content.PreloadListSubState;
import backend.StageData.LoadFilters;

@:allow(states.editors.StageEditorState)
class StageEditorMainBox extends PsychUIBox {
    private final host:StageEditorState;

    public function new(host:StageEditorState) {
        this.host = host;
        super(FlxG.width - 225, 10, 200, 420, ['Meta', 'Data', 'Object', 'Note Types']);
        addDataTab();
		addObjectTab();
		addMetaTab();
    }


	var directoryDropDown:PsychUIDropDownMenu;
	var uiInputText:PsychUIInputText;
	var hideGirlfriendCheckbox:PsychUICheckBox;
	var zoomStepper:PsychUINumericStepper;
	var cameraSpeedStepper:PsychUINumericStepper;
	var camDadStepperX:PsychUINumericStepper;
	var camDadStepperY:PsychUINumericStepper;
	var camGfStepperX:PsychUINumericStepper;
	var camGfStepperY:PsychUINumericStepper;
	var camBfStepperX:PsychUINumericStepper;
	var camBfStepperY:PsychUINumericStepper;

	function addDataTab()
	{
		var tab_group = getTab('Data').menu;
        var stageJson = host.stageJson;

		var objX = 10;
		var objY = 20;
		tab_group.add(new FlxText(objX, objY - 18, 150, 'Compiled Assets:'));

		var folderList:Array<String> = [''];

		for (folder in NativeFileSystem.readDirectory('assets/'))
			if (NativeFileSystem.isDirectory('assets/$folder') && folder != 'shared' && !Mods.ignoreModFolders.contains(folder))
				folderList.push(folder);

		var saveButton:PsychUIButton = new PsychUIButton(width - 90, height - 50, 'Save', function()
		{
			host.saveData();
		});
		tab_group.add(saveButton);

		directoryDropDown = new PsychUIDropDownMenu(objX, objY, folderList, function(sel:Int, selected:String)
		{
			stageJson.directory = selected;
			host.saveObjectsToJson();
			FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new StageEditorState(host.lastLoadedStage, stageJson));
		});
		directoryDropDown.selectedLabel = stageJson.directory;

		objY += 50;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'UI Style:'));
		uiInputText = new PsychUIInputText(objX, objY, 100, stageJson.stageUI != null ? stageJson.stageUI : '', 8);
		uiInputText.onChange = function(old:String, cur:String) stageJson.stageUI = uiInputText.text;

		objY += 30;
		hideGirlfriendCheckbox = new PsychUICheckBox(objX, objY, 'Hide Girlfriend?', 100);
		hideGirlfriendCheckbox.onClick = function()
		{
			stageJson.hide_girlfriend = hideGirlfriendCheckbox.checked;
			host.gf.visible = !hideGirlfriendCheckbox.checked;
			if (host.focusRadioGroup.checked > -1)
			{
				var point = host.focusOnTarget(host.focusRadioGroup.labels[host.focusRadioGroup.checked]);
				host.camFollow.setPosition(point.x, point.y);
			}
		};
		hideGirlfriendCheckbox.checked = !host.gf.visible;

		objY += 50;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Camera Offsets:'));

		objY += 20;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Opponent:'));

		var cx:Float = 0;
		var cy:Float = 0;
		if (stageJson.camera_opponent != null && stageJson.camera_opponent.length > 1)
		{
			cx = stageJson.camera_opponent[0];
			cy = stageJson.camera_opponent[0];
		}
		camDadStepperX = new PsychUINumericStepper(objX, objY, 50, cx, -10000, 10000, 0);
		camDadStepperY = new PsychUINumericStepper(objX + 80, objY, 50, cy, -10000, 10000, 0);
		camDadStepperX.onValueChange = camDadStepperY.onValueChange = function()
		{
			if (stageJson.camera_opponent == null)
				stageJson.camera_opponent = [0, 0];
			stageJson.camera_opponent[0] = camDadStepperX.value;
			stageJson.camera_opponent[1] = camDadStepperY.value;
			host._updateCamera();
		};

		objY += 40;
		var cx:Float = 0;
		var cy:Float = 0;
		if (stageJson.camera_girlfriend != null && stageJson.camera_girlfriend.length > 1)
		{
			cx = stageJson.camera_girlfriend[0];
			cy = stageJson.camera_girlfriend[0];
		}
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Girlfriend:'));
		camGfStepperX = new PsychUINumericStepper(objX, objY, 50, cx, -10000, 10000, 0);
		camGfStepperY = new PsychUINumericStepper(objX + 80, objY, 50, cy, -10000, 10000, 0);
		camGfStepperX.onValueChange = camGfStepperY.onValueChange = function()
		{
			if (stageJson.camera_girlfriend == null)
				stageJson.camera_girlfriend = [0, 0];
			stageJson.camera_girlfriend[0] = camGfStepperX.value;
			stageJson.camera_girlfriend[1] = camGfStepperY.value;
			host._updateCamera();
		};

		objY += 40;
		var cx:Float = 0;
		var cy:Float = 0;
		if (stageJson.camera_boyfriend != null && stageJson.camera_boyfriend.length > 1)
		{
			cx = stageJson.camera_boyfriend[0];
			cy = stageJson.camera_boyfriend[0];
		}
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Boyfriend:'));
		camBfStepperX = new PsychUINumericStepper(objX, objY, 50, cx, -10000, 10000, 0);
		camBfStepperY = new PsychUINumericStepper(objX + 80, objY, 50, cy, -10000, 10000, 0);
		camBfStepperX.onValueChange = camBfStepperY.onValueChange = function()
		{
			if (stageJson.camera_boyfriend == null)
				stageJson.camera_boyfriend = [0, 0];
			stageJson.camera_boyfriend[0] = camBfStepperX.value;
			stageJson.camera_boyfriend[1] = camBfStepperY.value;
			host._updateCamera();
		};

		objY += 50;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Camera Data:'));
		objY += 20;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Zoom:'));
		zoomStepper = new PsychUINumericStepper(objX, objY, 0.05, stageJson.defaultZoom, host.minZoom, host.maxZoom, 2);
		zoomStepper.onValueChange = function()
		{
			stageJson.defaultZoom = zoomStepper.value;
			FlxG.camera.zoom = stageJson.defaultZoom;
		};

		tab_group.add(new FlxText(objX + 80, objY - 18, 100, 'Speed:'));
		cameraSpeedStepper = new PsychUINumericStepper(objX + 80, objY, 0.1, stageJson.camera_speed != null ? stageJson.camera_speed : 1, 0, 10, 2);
		cameraSpeedStepper.onValueChange = function()
		{
			stageJson.camera_speed = cameraSpeedStepper.value;
			FlxG.camera.followLerp = 0.04 * stageJson.camera_speed;
		};
		FlxG.camera.followLerp = 0.04 * cameraSpeedStepper.value;

		tab_group.add(hideGirlfriendCheckbox);
		tab_group.add(camDadStepperX);
		tab_group.add(camDadStepperY);
		tab_group.add(camGfStepperX);
		tab_group.add(camGfStepperY);
		tab_group.add(camBfStepperX);
		tab_group.add(camBfStepperY);
		tab_group.add(zoomStepper);
		tab_group.add(cameraSpeedStepper);

		tab_group.add(uiInputText);
		tab_group.add(directoryDropDown);
	}



	var colorInputText:PsychUIInputText;
	var nameInputText:PsychUIInputText;
	var characterDropdown:PsychUIDropDownMenu;
	var characterLabel:FlxText;
	var characterChoices:Array<String> = [];
	var noteTypeCheckboxes:Array<PsychUICheckBox> = [];
	var noteTypeMenu:FlxSpriteGroup;
	var noteTypeBaseX:Float = 10;
	var noteTypeBaseY:Float = 28;
	var noteTypeLabel:FlxText;
	var noteTypeEmptyText:FlxText;
	var noteTypeScrollLabel:FlxText;
	var noteTypePagePrevious:PsychUIButton;
	var noteTypePageNext:PsychUIButton;
	var noteTypePageIndex:Int = 0;
	var noteTypeVisibleCount:Int = 10;
	var noteTypeListTop:Float = 0;
	var characterAppearanceUI:Array<Dynamic> = [];
	var noteTypesTabWasSelected:Bool = false;
	var imgTxt:FlxText;
	var imgButton:PsychUIButton;
	var animationsButton:PsychUIButton;

	var scaleStepperX:PsychUINumericStepper;
	var scaleStepperY:PsychUINumericStepper;
	var scrollStepperX:PsychUINumericStepper;
	var scrollStepperY:PsychUINumericStepper;
	var angleStepper:PsychUINumericStepper;
	var alphaStepper:PsychUINumericStepper;

	var antialiasingCheckbox:PsychUICheckBox;
	var flipXCheckBox:PsychUICheckBox;
	var flipYCheckBox:PsychUICheckBox;
	var lowQualityCheckbox:PsychUICheckBox;
	var highQualityCheckbox:PsychUICheckBox;

	function getSelected(blockReserved:Bool = true)
	{
		var selected:Int = host.spriteListRadioGroup.checked;
		if (selected >= 0)
		{
			var spr = host.stageSprites[host.spriteListRadioGroup.labels.length - selected - 1];
			if (spr != null && (!blockReserved || !StageData.reservedNames.contains(spr.type)))
				return spr;
		}
		return null;
	}

	function addObjectTab()
	{
		var tab_group = getTab('Object').menu;

		var objX = 10;
		var objY = 30;
		tab_group.add(new FlxText(objX, objY - 18, 150, 'Name (for Lua/HScript):'));
		nameInputText = new PsychUIInputText(objX, objY, 120, '', 8);
		nameInputText.customFilterPattern = ~/[^a-zA-Z0-9_\-]*/g;
		nameInputText.onChange = function(old:String, cur:String)
		{
			// change name
			var selected = getSelected();
			if (selected != null)
			{
				var changedName:String = nameInputText.text;
				if (changedName.length < 1)
				{
					host.showOutput('Sprite name cannot be empty!', true);
					return;
				}

				if (StageData.reservedNames.contains(changedName.toLowerCase()) || ['bf', 'boyfriend', 'dad', 'opponent', 'gf', 'girlfriend', '0', '1', '2'].contains(changedName.toLowerCase()))
				{
					host.showOutput('To avoid conflicts, this name cannot be used!', true);
					return;
				}

				for (basic in host.stageSprites)
				{
					if (selected != basic && basic.name == changedName)
					{
						host.showOutput('Name "$changedName" is already in use!', true);
						return;
					}
				}

				selected.name = changedName;
				host.spriteListRadioGroup.checkedRadio.label = selected.name;
				host.outputTime = 0;
				host.outputTxt.alpha = 0;
			}
		};
		tab_group.add(nameInputText);

		characterChoices = getCharacterChoices();
		characterLabel = new FlxText(objX, 0, 150, 'Character:', 8);
		characterDropdown = new PsychUIDropDownMenu(objX, 0, characterChoices, function(sel:Int, selectedID:String)
		{
			var selected = getSelected();
			if (selected == null || selected.type != 'stageCharacter' || selectedID == null || selectedID.length < 1) return;
			try
			{
				var char:Character = cast selected.sprite;
				// The new Character ID supplies its own JSON configuration; keep only Stage placement.
				var oldX:Float = selected.x;
				var oldY:Float = selected.y;
				char.changeCharacter(selectedID);
				selected.x = oldX;
				selected.y = oldY;
				selected.characterID = selectedID;
				characterDropdown.selectedLabel = selectedID;
				host.unsavedProgress = true;
				host.showOutput('Character changed to ' + selectedID);
			}
			catch (e:Dynamic)
				host.showOutput('Could not change character: ' + e, true);
		});
		characterLabel.visible = false;
		characterDropdown.visible = false;

		objY += 35;
		imgTxt = new FlxText(objX, objY - 15, 200, 'Image: ', 8);
		imgButton = new PsychUIButton(objX, objY, 'Change Image', function()
		{
			trace('attempt to load image');
			host.loadImage();
		});
		tab_group.add(imgButton);
		tab_group.add(imgTxt);

		animationsButton = new PsychUIButton(objX + 90, objY, 'Animations', function()
		{
			var selected = getSelected();
			if (selected == null)
				return;

			if (selected.type != 'animatedSprite')
			{
				host.showOutput('Only Animated Sprites can hold Animation data.', true);
				return;
			}

			host.destroySubStates = false;
			host.persistentDraw = false;
			host.animationEditor.target = selected;
			host.unsavedProgress = true;
			host.openSubState(host.animationEditor);
		});
		tab_group.add(animationsButton);

		objY += 45;
		var colorLabel = new FlxText(objX, objY - 18, 80, 'Color:');
		tab_group.add(colorLabel);
		characterAppearanceUI.push(colorLabel);
		colorInputText = new PsychUIInputText(objX, objY, 80, 'FFFFFF', 8);
		colorInputText.filterMode = ONLY_ALPHANUMERIC;
		colorInputText.onChange = function(old:String, cur:String)
		{
			// change color
			var selected = getSelected();
			if (selected != null)
				selected.color = colorInputText.text;
		};
		tab_group.add(colorInputText);
		characterAppearanceUI.push(colorInputText);

		function updateScale()
		{
			// scale
			var selected = getSelected();
			if (selected != null)
				selected.setScale(scaleStepperX.value, scaleStepperY.value);
		}

		objY += 45;
		var scaleLabel = new FlxText(objX, objY - 18, 100, 'Scale (X/Y):');
		tab_group.add(scaleLabel);
		characterAppearanceUI.push(scaleLabel);
		scaleStepperX = new PsychUINumericStepper(objX, objY, 0.05, 1, 0.05, 10, 2);
		scaleStepperY = new PsychUINumericStepper(objX + 70, objY, 0.05, 1, 0.05, 10, 2);
		scaleStepperX.onValueChange = scaleStepperY.onValueChange = updateScale;
		tab_group.add(scaleStepperX);
		tab_group.add(scaleStepperY);
		characterAppearanceUI.push(scaleStepperX);
		characterAppearanceUI.push(scaleStepperY);

		function updateScroll()
		{
			// scroll factor
			var selected = getSelected();
			if (selected != null)
				selected.setScrollFactor(scrollStepperX.value, scrollStepperY.value);
		}

		objY += 40;
		var scrollLabel = new FlxText(objX, objY - 18, 150, 'Scroll Factor (X/Y):');
		tab_group.add(scrollLabel);
		characterAppearanceUI.push(scrollLabel);
		scrollStepperX = new PsychUINumericStepper(objX, objY, 0.05, 1, 0, 10, 2);
		scrollStepperY = new PsychUINumericStepper(objX + 70, objY, 0.05, 1, 0, 10, 2);
		scrollStepperX.onValueChange = scrollStepperY.onValueChange = updateScroll;
		tab_group.add(scrollStepperX);
		tab_group.add(scrollStepperY);
		characterAppearanceUI.push(scrollStepperX);
		characterAppearanceUI.push(scrollStepperY);

		objY += 40;
		var alphaLabel = new FlxText(objX, objY - 18, 80, 'Opacity:');
		tab_group.add(alphaLabel);
		characterAppearanceUI.push(alphaLabel);
		alphaStepper = new PsychUINumericStepper(objX, objY, 0.1, 1, 0, 1, 2, true);
		alphaStepper.onValueChange = function()
		{
			// alpha/opacity
			var selected = getSelected();
			if (selected != null)
				selected.alpha = alphaStepper.value;
		};
		tab_group.add(alphaStepper);
		characterAppearanceUI.push(alphaStepper);

		antialiasingCheckbox = new PsychUICheckBox(objX + 90, objY, 'Anti-Aliasing', 80);
		antialiasingCheckbox.onClick = function()
		{
			// antialiasing
			var selected = getSelected();
			if (selected != null)
			{
				if (selected.type != 'square')
					selected.antialiasing = antialiasingCheckbox.checked;
				else
				{
					antialiasingCheckbox.checked = false;
					selected.antialiasing = false;
				}
			}
		};
		tab_group.add(antialiasingCheckbox);
		characterAppearanceUI.push(antialiasingCheckbox);

		objY += 40;
		var angleLabel = new FlxText(objX, objY - 18, 80, 'Angle:');
		tab_group.add(angleLabel);
		characterAppearanceUI.push(angleLabel);
		angleStepper = new PsychUINumericStepper(objX, objY, 10, 0, 0, 360, 0);
		angleStepper.onValueChange = function()
		{
			// alpha/opacity
			var selected = getSelected();
			if (selected != null)
				selected.angle = angleStepper.value;
		};
		tab_group.add(angleStepper);
		characterAppearanceUI.push(angleStepper);

		function updateFlip()
		{
			// flip X and flip Y
			var selected = getSelected();
			if (selected != null)
			{
				if (selected.type != 'square')
				{
					selected.flipX = flipXCheckBox.checked;
					selected.flipY = flipYCheckBox.checked;
				}
				else
				{
					flipXCheckBox.checked = flipYCheckBox.checked = false;
					selected.flipX = selected.flipY = false;
				}
			}
		}

		objY += 25;
		flipXCheckBox = new PsychUICheckBox(objX, objY, 'Flip X', 60);
		flipXCheckBox.onClick = updateFlip;
		flipYCheckBox = new PsychUICheckBox(objX + 90, objY, 'Flip Y', 60);
		flipYCheckBox.onClick = updateFlip;
		tab_group.add(flipXCheckBox);
		tab_group.add(flipYCheckBox);

		objY += 45;
		function recalcFilter()
		{
			// low and/or high quality
			var selected = getSelected();
			if (selected != null)
			{
				var filt = 0;
				if (lowQualityCheckbox.checked)
					filt |= LOW_QUALITY;
				if (highQualityCheckbox.checked)
					filt |= HIGH_QUALITY;
				selected.filters = filt;
			}
		};
		tab_group.add(new FlxText(objX + 60, objY - 18, 100, 'Visible in:'));
		lowQualityCheckbox = new PsychUICheckBox(objX, objY, 'Low Quality', 70);
		highQualityCheckbox = new PsychUICheckBox(objX + 90, objY, 'High Quality', 70);
		lowQualityCheckbox.onClick = recalcFilter;
		highQualityCheckbox.onClick = recalcFilter;
		tab_group.add(lowQualityCheckbox);
		tab_group.add(highQualityCheckbox);

		// Keep the Character selector at the bottom of the Object options.
		objY += 25;
		characterLabel.y = objY - 15;
		characterDropdown.y = objY;
		tab_group.add(characterLabel);
		tab_group.add(characterDropdown);

		noteTypeMenu = getTab('Note Types').menu;
		var noteX = noteTypeBaseX;
		var noteY = noteTypeBaseY;
		noteTypeLabel = new FlxText(noteX, noteY - 18, 180, 'Custom Note Types (10/page):', 8);
		noteTypeMenu.add(noteTypeLabel);
		var availableNoteTypes:Array<String> = getStageNoteTypeChoices();
		noteTypeEmptyText = new FlxText(noteX, noteY, 175, 'No custom Note Types found.', 8);
		noteTypeEmptyText.visible = false;
		noteTypeMenu.add(noteTypeEmptyText);
		for (noteType in availableNoteTypes)
		{
			var check:PsychUICheckBox = new PsychUICheckBox(noteX, noteY, noteType, 175);
			check.visible = false;
			check.onClick = onStageNoteTypeToggle.bind(noteType, check);
			noteTypeCheckboxes.push(check);
			noteTypeMenu.add(check);
		}
		noteTypeListTop = noteY + 4;
		noteTypeScrollLabel = new FlxText(noteX + 35, noteTypeListTop + noteTypeVisibleCount * 24 + 8, 120, '', 8);
		noteTypeMenu.add(noteTypeScrollLabel);
		noteTypePagePrevious = new PsychUIButton(noteX, noteTypeListTop + noteTypeVisibleCount * 24 + 4, '< Prev', function()
		{
			setNoteTypeScroll(noteTypePageIndex - 1);
		}, 48, 20);
		noteTypePageNext = new PsychUIButton(noteX + 145, noteTypeListTop + noteTypeVisibleCount * 24 + 4, 'Next >', function()
		{
			setNoteTypeScroll(noteTypePageIndex + 1);
		}, 45, 20);
		noteTypeMenu.add(noteTypePagePrevious);
		noteTypeMenu.add(noteTypePageNext);
		refreshNoteTypePage();

	}


	function setNoteTypeScroll(nextPage:Int):Void
	{
		var pageCount:Int = Std.int(Math.ceil(noteTypeCheckboxes.length / noteTypeVisibleCount));
		var maxPage:Int = Std.int(Math.max(0, pageCount - 1));
		noteTypePageIndex = Std.int(Math.max(0, Math.min(maxPage, nextPage)));
		refreshNoteTypePage();
	}

	function refreshNoteTypePage():Void
	{
		var selected = getSelected();
		var isCharacter:Bool = selected != null && selected.type == 'stageCharacter';
		var pageCount:Int = Std.int(Math.ceil(noteTypeCheckboxes.length / noteTypeVisibleCount));
		if (pageCount <= 0) noteTypePageIndex = 0;
		else noteTypePageIndex = Std.int(Math.max(0, Math.min(pageCount - 1, noteTypePageIndex)));
		var startIndex:Int = noteTypePageIndex * noteTypeVisibleCount;
		var endIndex:Int = Std.int(Math.min(noteTypeCheckboxes.length, startIndex + noteTypeVisibleCount));
		for (i in 0...noteTypeCheckboxes.length)
		{
			var check = noteTypeCheckboxes[i];
			var onPage:Bool = i >= startIndex && i < endIndex;
			// PsychUIBox moves its tab menu (and its members) in screen space.
			// Re-anchor controls against the menu's current position; using only
			// local coordinates here resets them toward (0, 0) after paging.
			var row:Int = onPage ? i - startIndex : 0;
			check.setPosition(noteTypeMenu.x + noteTypeBaseX,
				noteTypeMenu.y + noteTypeListTop + row * 24);
			check.visible = onPage && isCharacter;
			check.active = onPage && isCharacter;
			check.checked = isCharacter && selected.noteTypes != null && selected.noteTypes.contains(check.label);
		}
		if (noteTypeScrollLabel != null)
			noteTypeScrollLabel.text = noteTypeCheckboxes.length == 0 ? '0 / 0' : (startIndex + 1) + '-' + endIndex + ' / ' + noteTypeCheckboxes.length;
		if (noteTypePagePrevious != null)
		{
			noteTypePagePrevious.visible = isCharacter && pageCount > 1;
			noteTypePagePrevious.active = isCharacter && pageCount > 1 && noteTypePageIndex > 0;
		}
		if (noteTypePageNext != null)
		{
			noteTypePageNext.visible = isCharacter && pageCount > 1;
			noteTypePageNext.active = isCharacter && pageCount > 1 && noteTypePageIndex < pageCount - 1;
		}
		if (noteTypeEmptyText != null) noteTypeEmptyText.visible = isCharacter && noteTypeCheckboxes.length == 0;
		if (noteTypeLabel != null) noteTypeLabel.visible = isCharacter;
	}


	function onStageNoteTypeToggle(noteType:String, check:PsychUICheckBox):Void
	{
		var selected = getSelected();
		if (selected == null || selected.type != 'stageCharacter') return;
		if (selected.noteTypes == null) selected.noteTypes = [];
		if (check.checked)
		{
			if (!selected.noteTypes.contains(noteType)) selected.noteTypes.push(noteType);
		}
		else selected.noteTypes.remove(noteType);
		host.unsavedProgress = true;
	}

	function getCharacterChoices():Array<String>
	{
		var list:Array<String> = Mods.mergeAllTextsNamed('data/characterList.txt');
		var folders:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'characters/');
		for (folder in folders)
			for (file in NativeFileSystem.readDirectory(folder))
				if (file.toLowerCase().endsWith('.json'))
				{
					var id:String = file.substr(0, file.length - 5);
					if (!list.contains(id)) list.push(id);
				}
		if (list.length < 1) list.push('bf');
		return list;
	}

	function getStageNoteTypeChoices():Array<String>
	{
		var list:Array<String> = [];
		var extensions:Array<String> = ['.txt'];
		#if LUA_ALLOWED extensions.push('.lua'); #end
		#if HSCRIPT_ALLOWED extensions.push('.hx'); #end
		#if MODS_ALLOWED
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'custom_notetypes/'))
			for (file in NativeFileSystem.readDirectory(folder))
			{
				var path:String = haxe.io.Path.join([folder, file]);
				if (NativeFileSystem.isDirectory(path) || file.startsWith('readme.')) continue;
				for (ext in extensions)
					if (file.toLowerCase().endsWith(ext))
					{
						var id:String = file.substr(0, file.length - ext.length);
						if (id.length > 0 && !list.contains(id)) list.push(id);
						break;
					}
			}
		#end
		return list;
	}

	var oppDropdown:PsychUIDropDownMenu;
	var gfDropdown:PsychUIDropDownMenu;
	var plDropdown:PsychUIDropDownMenu;

	function addMetaTab()
	{
		var tab_group = getTab('Meta').menu;

		var characterList = Mods.mergeAllTextsNamed('data/characterList.txt');
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'characters/');
		for (folder in foldersToCheck)
			for (file in NativeFileSystem.readDirectory(folder))
				if(file.toLowerCase().endsWith('.json'))
				{
					var charToCheck:String = file.substr(0, file.length - 5);
					if (!characterList.contains(charToCheck))
						characterList.push(charToCheck);
				}

		if (characterList.length < 1)
			characterList.push(''); // Prevents crash

		var objX = 10;
		var objY = 20;

		var openPreloadButton:PsychUIButton = new PsychUIButton(objX, objY, 'Preload List', function()
		{
			var lockedList:Array<String> = [];
			var currentMap:Map<String, LoadFilters> = [];
			for (spr in host.stageSprites)
			{
				if (spr == null || StageData.reservedNames.contains(spr.type))
					continue;

				switch (spr.type)
				{
					case 'sprite', 'animatedSprite':
						if (spr.image != null && spr.image.length > 0 && !lockedList.contains(spr.image))
							lockedList.push(spr.image);
				}
			}

            var stageJson = host.stageJson;
			if (stageJson.preload != null)
			{
				for (field in Reflect.fields(stageJson.preload))
				{
					if (!currentMap.exists(field) && !lockedList.contains(field))
						currentMap.set(field, Reflect.field(stageJson.preload, field));
				}
			}

			host.destroySubStates = true;
			host.openSubState(new PreloadListSubState(function(newSave:Map<String, LoadFilters>)
			{
				var len:Int = 0;
				for (name in newSave.keys())
					len++;

				stageJson.preload = {};
				for (key => value in newSave)
				{
					Reflect.setField(stageJson.preload, key, value);
				}
				host.unsavedProgress = true;
				host.showOutput('Saved new Preload List with $len files/folders!');
			}, lockedList, currentMap));
		});

		function setMetaData(data:String, char:String)
		{
			if (host.stageJson._editorMeta == null)
				host.stageJson._editorMeta = {dad: 'dad', gf: 'gf', boyfriend: 'bf'};
			Reflect.setField(host.stageJson._editorMeta, data, char);
		}

		objY += 60;
		oppDropdown = new PsychUIDropDownMenu(objX, objY, characterList, function(sel:Int, selected:String)
		{
			if (selected == null || selected.length < 1)
				return;
			host.dad.changeCharacter(selected);
			setMetaData('dad', selected);
			host.repositionDad();
		});
		oppDropdown.selectedLabel = host.dad.curCharacter;

		objY += 60;
		gfDropdown = new PsychUIDropDownMenu(objX, objY, characterList, function(sel:Int, selected:String)
		{
			if (selected == null || selected.length < 1)
				return;
			host.gf.changeCharacter(selected);
			setMetaData('gf', selected);
			host.repositionGirlfriend();
		});
		gfDropdown.selectedLabel = host.gf.curCharacter;

		objY += 60;
		plDropdown = new PsychUIDropDownMenu(objX, objY, characterList, function(sel:Int, selected:String)
		{
			if (selected == null || selected.length < 1)
				return;
			host.boyfriend.changeCharacter(selected);
			setMetaData('boyfriend', selected);
			host.repositionBoyfriend();
		});
		plDropdown.selectedLabel = host.boyfriend.curCharacter;

		tab_group.add(openPreloadButton);
		tab_group.add(new FlxText(plDropdown.x, plDropdown.y - 18, 100, 'Player:'));
		tab_group.add(plDropdown);
		tab_group.add(new FlxText(gfDropdown.x, gfDropdown.y - 18, 100, 'Girlfriend:'));
		tab_group.add(gfDropdown);
		tab_group.add(new FlxText(oppDropdown.x, oppDropdown.y - 18, 100, 'Opponent:'));
		tab_group.add(oppDropdown);
	}

    	public function updateStageDataUI()
	{
        var stageJson = host.stageJson;
		// input texts
		uiInputText.text = (stageJson.stageUI != null ? stageJson.stageUI : '');
		// checkboxes
		hideGirlfriendCheckbox.checked = (stageJson.hide_girlfriend);
		host.gf.visible = !hideGirlfriendCheckbox.checked;
		// steppers
		zoomStepper.value = FlxG.camera.zoom = stageJson.defaultZoom;

		if (stageJson.camera_speed != null)
			cameraSpeedStepper.value = stageJson.camera_speed;
		else
			cameraSpeedStepper.value = 1;
		FlxG.camera.followLerp = 0.04 * cameraSpeedStepper.value;

		if (stageJson.camera_opponent != null && stageJson.camera_opponent.length > 1)
		{
			camDadStepperX.value = stageJson.camera_opponent[0];
			camDadStepperY.value = stageJson.camera_opponent[1];
		}
		else
			camDadStepperX.value = camDadStepperY.value = 0;

		if (stageJson.camera_girlfriend != null && stageJson.camera_girlfriend.length > 1)
		{
			camGfStepperX.value = stageJson.camera_girlfriend[0];
			camGfStepperY.value = stageJson.camera_girlfriend[1];
		}
		else
			camGfStepperX.value = camGfStepperY.value = 0;

		if (stageJson.camera_boyfriend != null && stageJson.camera_boyfriend.length > 1)
		{
			camBfStepperX.value = stageJson.camera_boyfriend[0];
			camBfStepperY.value = stageJson.camera_boyfriend[1];
		}
		else
			camBfStepperX.value = camBfStepperY.value = 0;

		if (host.focusRadioGroup.checked > -1)
		{
			var point = host.focusOnTarget(host.focusRadioGroup.labels[host.focusRadioGroup.checked]);
			host.camFollow.setPosition(point.x, point.y);
		}
		host.loadJsonAssetDirectory();
	}
    public function updateSelectedUI(){
        var selected = getSelected();
		if (selected == null)
			return;
        		// Texts/Input Texts
		colorInputText.text = selected.color;
		nameInputText.text = selected.name;
		imgTxt.text = 'Image: ' + selected.image;
		imgButton.visible = animationsButton.visible = imgTxt.visible = (selected.type != 'stageCharacter');
		characterLabel.visible = (selected.type == 'stageCharacter');
		characterDropdown.visible = (selected.type == 'stageCharacter');
		characterDropdown.selectedLabel = selected.characterID;
		var isStageCharacter:Bool = selected.type == 'stageCharacter';
		for (control in characterAppearanceUI)
		{
			control.visible = !isStageCharacter;
			control.active = !isStageCharacter;
		}
		refreshNoteTypePage();

		// Steppers
		if (selected.type != 'square')
		{
			scaleStepperX.decimals = scaleStepperY.decimals = 2;
			scaleStepperX.max = scaleStepperY.max = 10;
			scaleStepperX.min = scaleStepperY.min = 0.05;
			scaleStepperX.step = scaleStepperY.step = 0.05;
		}
		else
		{
			scaleStepperX.decimals = scaleStepperY.decimals = 0;
			scaleStepperX.max = scaleStepperY.max = 10000;
			scaleStepperX.min = scaleStepperY.min = 50;
			scaleStepperX.step = scaleStepperY.step = 50;
		}
		scaleStepperX.value = selected.scale[0];
		scaleStepperY.value = selected.scale[1];
		scrollStepperX.value = selected.scroll[0];
		scrollStepperY.value = selected.scroll[1];
		angleStepper.value = selected.angle;
		alphaStepper.value = selected.alpha;

		// Checkboxes
		antialiasingCheckbox.visible = (selected.type != 'square' && !isStageCharacter);
		// Flip controls remain available for Custom Character stage objects.
		flipXCheckBox.visible = (selected.type != 'square');
		flipYCheckBox.visible = (selected.type != 'square');

		antialiasingCheckbox.checked = selected.antialiasing;
		flipXCheckBox.checked = selected.flipX;
		flipYCheckBox.checked = selected.flipY;
		lowQualityCheckbox.checked = (selected.filters & LOW_QUALITY) == LOW_QUALITY;
		highQualityCheckbox.checked = (selected.filters & HIGH_QUALITY) == HIGH_QUALITY;
    }

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		var isNoteTypesSelected:Bool = selectedTab != null && selectedTab.name == 'Note Types' && !isMinimized;
		if (isNoteTypesSelected && !noteTypesTabWasSelected)
			refreshNoteTypePage();
		noteTypesTabWasSelected = isNoteTypesSelected;
	}
}