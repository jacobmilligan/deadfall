unit GameUI;

interface
	uses Swingame, Input, Map;

	const
		UI_NEXT 		= 	'UI_NEXT_ELEMENT';
		UI_PREV 		= 	'UI_PREV_ELEMENT';
		UI_CURRENT 	= 	'UI_CURRENT_ELEMENT';

  type

		UIElement = record
			inactiveBmp: Bitmap;
			activeBmp: Bitmap;
			currentBmp: Bitmap;
			x: Single;
			y: Single;
			id: String;
			setFont: Font;
			attachedInventory: ItemPtr;
		end;

		UICollection = array of UIElement;

		UI = record
			name: String;
			items: UICollection;
			currentItem: Integer;
			previousItem: Integer;
			previousUI: function(var map: MapData; var inputs: InputMap): UI;
			nextUI: function(var map: MapData; var inputs: InputMap): UI;
		end;

	procedure InitUI(var newUI: UI; numElements: Integer; name: String);

	function CreateUIElement(inactiveBmp, activeBmp: Bitmap; x, y: Single; id: String = ''; setFont: String = 'PrStart'): UIElement;

	procedure UINavigate(var currentUI: UI; var inputs: InputMap; var map: MapData);

	procedure UpdateUI(var currentUI: UI; currentItem, previousItem: Integer);

	procedure DrawUI(var currentUI: UI);

	procedure ChangeElement(var currentUI: UI; id: String);

	function UISelectedID(var currentUI: UI): String;

	procedure ReduceItemCount(var itemToReduce: UIElement);

	function HorizontalCenter(bmp: String): Single;

	function CreateSettingsUI(var map: MapData; var inputs: InputMap): UI;

	function CreateChangeControlsUI(var map: MapData; var inputs: InputMap): UI;

implementation
	uses State, SysUtils, Menu, Title;


	function CreateSettingsUI(var map: MapData; var inputs: InputMap): UI;
	begin
		InitUI(result, 1, 'Settings');
		result.items[0] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 150, 'Change Controls', 'PrStartSmall');
		result.currentItem := 0;
		result.previousItem := 0;

		if map.blank then
		begin
			result.previousUI := @CreateTitleUI;
		end
		else
		begin
			result.previousUI := @CreateMenuUI;
		end;
	end;

	function CreateChangeControlsUI(var map: MapData; var inputs: InputMap): UI;
	var
		controlStr: String;
	begin
		InitUI(result, 7, 'Controls');

		WriteStr(controlStr, inputs.MoveUp);
		controlStr := StringReplace(controlStr, 'Key', ' Key' ,[rfReplaceAll]);
		result.items[0] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue') - (BitmapWidth(BitmapNamed('ui_blue')) / 2), 150, 'Move Up: ' + controlStr, 'PrStartSmall');

		WriteStr(controlStr, inputs.MoveRight);
		controlStr := StringReplace(controlStr, 'Key', ' Key' ,[rfReplaceAll]);
		result.items[1] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue') - (BitmapWidth(BitmapNamed('ui_blue')) / 2), 250, 'Move Right: ' + controlStr, 'PrStartSmall');

		WriteStr(controlStr, inputs.MoveDown);
		controlStr := StringReplace(controlStr, 'Key', ' Key' ,[rfReplaceAll]);
		result.items[2] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue') - (BitmapWidth(BitmapNamed('ui_blue')) / 2), 350, 'Move Down: ' + controlStr, 'PrStartSmall');

		WriteStr(controlStr, inputs.MoveLeft);
		controlStr := StringReplace(controlStr, 'Key', ' Key' ,[rfReplaceAll]);
		result.items[3] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue') + (BitmapWidth(BitmapNamed('ui_blue')) / 2), 150, 'Move Left: ' + controlStr, 'PrStartSmall');

		WriteStr(controlStr, inputs.Attack);
		controlStr := StringReplace(controlStr, 'Key', ' Key' ,[rfReplaceAll]);
		result.items[4] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue') + (BitmapWidth(BitmapNamed('ui_blue')) / 2), 250, 'Attack: ' + controlStr, 'PrStartSmall');

		WriteStr(controlStr, inputs.Select);
		controlStr := StringReplace(controlStr, 'Key', ' Key' ,[rfReplaceAll]);
		result.items[5] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue') + (BitmapWidth(BitmapNamed('ui_blue')) / 2), 350, 'Select: ' + controlStr, 'PrStartSmall');

		WriteStr(controlStr, inputs.Menu);
		controlStr := StringReplace(controlStr, 'Key', ' Key' ,[rfReplaceAll]);
		result.items[6] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue') + (BitmapWidth(BitmapNamed('ui_blue')) / 2), 450, 'Menu: ' + controlStr, 'PrStartSmall');

		result.currentItem := 0;
		result.previousItem := 0;
		result.previousUI := @CreateSettingsUI;
		result.nextUI := nil;
	end;

	function HorizontalCenter(bmp: String): Single;
	begin
		result := ( ScreenWidth() - BitmapWidth(BitmapNamed(bmp)) ) / 2;
	end;

	procedure InitUI(var newUI: UI; numElements: Integer; name: String);
	begin
		SetLength(newUI.items, numElements);
		newUI.currentItem := 0;
		newUI.previousUI := nil;
		newUI.nextUI := nil;
		newUI.name := name;
	end;

	function CreateUIElement(inactiveBmp, activeBmp: Bitmap; x, y: Single; id: String = ''; setFont: String = 'PrStart'): UIElement;
	begin
		result.inactiveBmp := inactiveBmp;
		result.activeBmp := activeBmp;
		result.currentBmp := inactiveBmp;
		result.x := x;
		result.y := y;
		result.id := id;
		result.setFont := FontNamed(setFont);
		result.attachedInventory := nil;
	end;

	function FindUIElement(var currentUI: UI; id: String): Integer;
	var
		i: Integer;
	begin
		result := -1;
		for i := 0 to High(currentUI.items) do
		begin
			if currentUI.items[i].id = id then
			begin
				result := i;
				break;
			end;
		end;
	end;

	function UISelectedID(var currentUI: UI): String;
	begin
		result := currentUI.items[currentUI.currentItem].id;
	end;

	procedure ChangeElement(var currentUI: UI; id: String);
	var
		i: Integer;
	begin
		currentUI.previousItem := currentUI.currentItem;

		if id = UI_NEXT then
		begin
			currentUI.currentItem := currentUI.currentItem + 1;
			if currentUI.currentItem > High(currentUI.items) then
			begin
				currentUI.currentItem := 0;
			end;
		end
		else if id = UI_PREV then
		begin
			currentUI.currentItem := currentUI.currentItem - 1;
			if currentUI.currentItem < 0 then
			begin
				currentUI.currentItem := High(currentUI.items);
			end;
		end
		else
		begin
			currentUI.currentItem := FindUIElement(currentUI, id);
			if currentUI.currentItem < 0 then
			begin
				currentUI.currentItem := currentUI.previousItem;
				WriteLn('Unable to find UI Element "', id, '."');
			end;
		end;

	end;

	procedure ReduceItemCount(var itemToReduce: UIElement);
	begin
		itemToReduce.attachedInventory^.count -= 1;
		if itemToReduce.attachedInventory^.count < 0 then
		begin
			itemToReduce.attachedInventory^.count := 0;
		end;
		itemToReduce.id := itemToReduce.attachedInventory^.name + ': ' + IntToStr(itemToReduce.attachedInventory^.count);
	end;

	procedure UINavigate(var currentUI: UI; var inputs: InputMap; var map: MapData);
	var
		currItem: ^UIElement;
	begin
		currItem := @currentUI.items[currentUI.currentItem];

		if KeyTyped(inputs.MoveUp) then
		begin
			PlaySoundEffect(SoundEffectNamed('click'));
			ChangeElement(currentUI, UI_PREV);
		end
		else if KeyTyped(inputs.MoveDown) then
		begin
			PlaySoundEffect(SoundEffectNamed('click'));
			ChangeElement(currentUI, UI_NEXT);
		end
		else if KeyTyped(inputs.Select) then
		begin
			PlaySoundEffect(SoundEffectNamed('confirm'), 0.5);

			if currItem^.attachedInventory <> nil then
			begin
				if currItem^.attachedInventory^.count > 0 then
				begin
					RestoreStat(map.player.hunger, currItem^.attachedInventory^.hungerPlus);
					RestoreStat(map.player.hp, currItem^.attachedInventory^.healthPlus);

					ReduceItemCount(currItem^);
				end;
			end;
			if currentUI.nextUI <> nil then
			begin
				currentUI := currentUI.nextUI(map, inputs);
			end;
		end
		else if ( KeyTyped(inputs.Menu) ) and ( currentUI.previousUI <> nil ) then
		begin
			PlaySoundEffect(SoundEffectNamed('back'), 0.8);
			currentUI := currentUI.previousUI(map, inputs);
		end

	end;

	procedure UpdateUI(var currentUI: UI; currentItem, previousItem: Integer);
	begin
		currentUI.items[previousItem].currentBmp := currentUI.items[previousItem].inactiveBmp;
		currentUI.items[currentItem].currentBmp := currentUI.items[currentItem].activeBmp;
	end;

	procedure DrawUI(var currentUI: UI);
	var
		i: Integer;
		itemCenterX, itemCenterY: Single;
		textToDraw: String;
	begin

		for i := 0 to High(currentUI.items) do
		begin
			if i = currentUI.currentItem then
			begin
				currentUI.items[i].currentBmp := currentUI.items[i].activeBmp;
			end;

			DrawBitmap(currentUI.items[i].currentBmp, CameraX() + currentUI.items[i].x, CameraY() + currentUI.items[i].y);

			itemCenterX := currentUI.items[i].x + (BitmapWidth(currentUI.items[i].currentBmp) / 2);
			itemCenterX := itemCenterX - ( TextWidth(currentUI.items[i].setFont, currentUI.items[i].id) / 2 );
			itemCenterX := CameraX() + itemCenterX;

			itemCenterY := currentUI.items[i].y + (BitmapHeight(currentUI.items[i].currentBmp) / 2);
			itemCenterY := itemCenterY - ( TextHeight(currentUI.items[i].setFont, currentUI.items[i].id) / 2 );
			itemCenterY := CameraY() + itemCenterY;

			DrawText(currentUI.items[i].id, ColorBlack, currentUI.items[i].setFont, itemCenterX, itemCenterY);
		end;

	end;

end.
