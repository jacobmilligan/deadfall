//
//  Deadfall v1.0
//  GameUI.pas
//
// -------------------------------------------------------
//
//  Created By Jacob Milligan
//  On 30/04/2016
//  Student ID: 100660682
//

unit GameUI;

interface
	uses Swingame, Input, Map;

	// Special constants for changing UI elements
	const
		UI_NEXT 		= 	'UI_NEXT_ELEMENT';
		UI_PREV 		= 	'UI_PREV_ELEMENT';
		UI_CURRENT 	= 	'UI_CURRENT_ELEMENT';

  type

		StringArray = array of String;

		//
		//	Represents a single element (button etc.) in a UI group.
		//	Holds Bitmap, position, and different data items (number, strings, pointer
		//	to an attached inventory item)
		//
		UIElement = record
			inactiveBmp: Bitmap;
			activeBmp: Bitmap;
			currentBmp: Bitmap;
			x: Single;
			y: Single;
			id: String;
			data: Integer;
			dataStrings: StringArray;
			currentDataString: Integer;
			setFont: Font;
			attachedInventory: ItemPtr;
		end;

		UICollection = array of UIElement;

		//
		//	Represents a single UI screen. Any time the player triggers an event,
		//	the attached nextUI or previousUI functions are called.
		//
		UI = record
			name: String;
			items: UICollection;
			currentItem: Integer;
			previousItem: Integer;

			// Called when going to the previous UI screen
			previousUI: function(var map: MapData; var inputs: InputMap): UI;

			// Called when going to the next UI screen
			nextUI: function(var map: MapData; var inputs: InputMap): UI;

			// Position of the market ticker in the inventory menu
			tickerPos: Single;
		end;

	//
	//	Initializes a new UI screen with default values
	//
	procedure InitUI(var newUI: UI; numElements: Integer; name: String);

	//
	//	Creates a new UI element on the current UI screen with default values
	//
	function CreateUIElement(inactiveBmp, activeBmp: Bitmap; x, y: Single; id: String = ''; setFont: String = 'PrStart'): UIElement;

	//
	//	Handles the input for each UI screen and updates the position of the
	//	active UIElement or UI screen depending on what has been input by the user
	//
	procedure UINavigate(var currentUI: UI; var inputs: InputMap; var map: MapData);

	//
	//	Updates the current UI screens active/inactive Bitmaps
	//
	procedure UpdateUI(var currentUI: UI; currentItem, previousItem: Integer);

	//
	//	Draws the current UI and its elements to the screen alongside the market ticker tape
	//	if on the inventory screen
	//
	procedure DrawUI(var currentUI: UI);

	//
	//	Changes the active element. If the user doesn't pass in one of the above
	//	special UI constants, the procedure will search for the passed in ID in the
	//	current UI
	//
	procedure ChangeElement(var currentUI: UI; id: String);

	//
	//	Returns the ID of the currently selected UIElement
	//
	function UISelectedID(var currentUI: UI): String;

	//
	//	Reduces the count of the attached inventory item
	//
	procedure ReduceItemCount(var itemToReduce: UIElement);

	//
	//	Handles purchasing a new item on the inventory screen
	//
	procedure BuyItem(var itemToBuy: UIElement; var dollars: Single);

	//
	//	Returns the calculated horizontal center for the passed in bitmap string. Uses
	//	BitmapNamed to get the bitmap
	//
	function HorizontalCenter(bmp: String): Single;

	//
	//	Returns the UI for the settings screen and assigns a previousUI based on the
	//	passed-in MapData
	//
	function CreateSettingsUI(var map: MapData; var inputs: InputMap): UI;

	//
	// Creates the change controls UI screen
	//
	function CreateChangeControlsUI(var map: MapData; var inputs: InputMap): UI;

implementation
	uses State, SysUtils, Menu, Title;

	function CreateSettingsUI(var map: MapData; var inputs: InputMap): UI;
	begin
		InitUI(result, 1, 'Settings');
		result.items[0] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 150, 'Change Controls', 'PrStartSmall');
		result.currentItem := 0;
		result.previousItem := 0;

		// The map will only be blank coming from the title screen
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
		negCenter, posCenter: Single;
	begin
		InitUI(result, 8, 'Controls');
		negCenter := HorizontalCenter('ui_blue') - (BitmapWidth(BitmapNamed('ui_blue')) / 2);
		posCenter := HorizontalCenter('ui_blue') + (BitmapWidth(BitmapNamed('ui_blue')) / 2);

		// Write the enum name directly to a string rather than using GetEnumName() because weird swingame KeyCode ordering
		WriteStr(controlStr, inputs.MoveUp);
		controlStr := StringReplace(controlStr, 'Key', ' Key' ,[rfReplaceAll]); // Isolate the name of the KeyCode
		result.items[0] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), negCenter, 150, 'Move Up: ' + controlStr, 'PrStartSmall');

		WriteStr(controlStr, inputs.MoveRight);
		controlStr := StringReplace(controlStr, 'Key', ' Key' ,[rfReplaceAll]); // Isolate the name of the KeyCode
		result.items[1] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), negCenter, 250, 'Move Right: ' + controlStr, 'PrStartSmall');

		WriteStr(controlStr, inputs.MoveDown);
		controlStr := StringReplace(controlStr, 'Key', ' Key' ,[rfReplaceAll]); // Isolate the name of the KeyCode
		result.items[2] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), negCenter, 350, 'Move Down: ' + controlStr, 'PrStartSmall');

		WriteStr(controlStr, inputs.MoveLeft);
		controlStr := StringReplace(controlStr, 'Key', ' Key' ,[rfReplaceAll]); // Isolate the name of the KeyCode
		result.items[3] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), negCenter, 450, 'Move Left: ' + controlStr, 'PrStartSmall');

		WriteStr(controlStr, inputs.Attack);
		controlStr := StringReplace(controlStr, 'Key', ' Key' ,[rfReplaceAll]); // Isolate the name of the KeyCode
		result.items[4] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), posCenter, 150, 'Attack: ' + controlStr, 'PrStartSmall');

		WriteStr(controlStr, inputs.Special);
		controlStr := StringReplace(controlStr, 'Key', ' Key' ,[rfReplaceAll]); // Isolate the name of the KeyCode
		result.items[5] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), posCenter, 250, 'Special: ' + controlStr, 'PrStartSmall');

		WriteStr(controlStr, inputs.Select);
		controlStr := StringReplace(controlStr, 'Key', ' Key' ,[rfReplaceAll]); // Isolate the name of the KeyCode
		result.items[6] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), posCenter, 350, 'Select: ' + controlStr, 'PrStartSmall');

		WriteStr(controlStr, inputs.Menu);
		controlStr := StringReplace(controlStr, 'Key', ' Key' ,[rfReplaceAll]);
		result.items[7] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), posCenter, 450, 'Menu: ' + controlStr, 'PrStartSmall');

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
		// Set default values for UIElement
		result.inactiveBmp := inactiveBmp;
		result.activeBmp := activeBmp;
		result.currentBmp := inactiveBmp;
		result.x := x;
		result.y := y;
		result.id := id;
		result.setFont := FontNamed(setFont);
		result.attachedInventory := nil;
		result.data := -1;
		SetLength(result.dataStrings, 0);
	end;

	function FindUIElement(var currentUI: UI; id: String): Integer;
	var
		i: Integer;
	begin
		result := -1;
		// Search the items list
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

		// Select different UI items if special const is passed in
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
			// No const used, search for passed-in ID in list
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
		itemToReduce.id := 	itemToReduce.attachedInventory^.name + ' (Stocked: ' + IntToStr(itemToReduce.attachedInventory^.count) +
								', For Sale: ' + IntToStr(itemToReduce.attachedInventory^.listed) + ')';
	end;

	procedure BuyItem(var itemToBuy: UIElement; var dollars: Single);
	begin
		// Only buy the item if the player has enough dollars
		if (dollars - itemToBuy.attachedInventory^.adjustedDollarValue) >= 0 then
		begin
			PlaySoundEffect(SoundEffectNamed('buy'), 0.5);
			itemToBuy.attachedInventory^.count += 1;
			dollars -= itemToBuy.attachedInventory^.adjustedDollarValue;
			itemToBuy.id := 	itemToBuy.attachedInventory^.name + ' (Stocked: ' + IntToStr(itemToBuy.attachedInventory^.count) +
									', For Sale: ' + IntToStr(itemToBuy.attachedInventory^.listed) + ')';
		end
		else
		begin
			PlaySoundEffect(SoundEffectNamed('deny'), 0.5);
		end;
	end;

	procedure UINavigate(var currentUI: UI; var inputs: InputMap; var map: MapData);
	var
		currItem: ^UIElement;
	begin
		currItem := @currentUI.items[currentUI.currentItem];

		// Go to previous if Up, next if Down, next UI if select
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

			// If the element has an attached inventory item, increase the players
			// stats according to the items stats
			if currItem^.attachedInventory <> nil then
			begin
				// Increase stats if you have any
				if currItem^.attachedInventory^.count > 0 then
				begin
					RestoreStat(map.player.hunger, currItem^.attachedInventory^.hungerPlus);
					RestoreStat(map.player.hp, currItem^.attachedInventory^.healthPlus);

					ReduceItemCount(currItem^);
				end;
			end;
			// Only go to the next UI screen if one has been assigned
			if currentUI.nextUI <> nil then
			begin
				currentUI := currentUI.nextUI(map, inputs);
			end;
		end
		// Only go to the previous UI screen if one has been assigned
		else if ( KeyTyped(inputs.Menu) ) and ( currentUI.previousUI <> nil ) then
		begin
			PlaySoundEffect(SoundEffectNamed('back'), 0.8);
			currentUI := currentUI.previousUI(map, inputs);
		end

	end;

	procedure UpdateUI(var currentUI: UI; currentItem, previousItem: Integer);
	begin
		// Switch bitmaps
		currentUI.items[previousItem].currentBmp := currentUI.items[previousItem].inactiveBmp;
		currentUI.items[currentItem].currentBmp := currentUI.items[currentItem].activeBmp;
	end;

	procedure DrawUI(var currentUI: UI);
	var
		i: Integer;
		itemCenterX, itemCenterY, tickerOffset: Single;
		textToDraw, marketStr: String;
	begin
		// This will be the ticker tape string
		marketStr := '';

		// Draw all the UIElements
		for i := 0 to High(currentUI.items) do
		begin
			// Set the item @ i's current bitmap to active if it is the currently selected UIElement
			if i = currentUI.currentItem then
			begin
				currentUI.items[i].currentBmp := currentUI.items[i].activeBmp;
			end;

			// Draw the UIElement to the screen
			DrawBitmap(currentUI.items[i].currentBmp, CameraX() + currentUI.items[i].x, CameraY() + currentUI.items[i].y);

			textToDraw := currentUI.items[i].id;
			// Draw the id + data num if it has any
			if currentUI.items[i].data > -1 then
			begin
				textToDraw := currentUI.items[i].id + ': ' + IntToStr(currentUI.items[i].data);
			end
			// No data num but if it has a data string then concat that with the ID
			else if Length(currentUI.items[i].dataStrings) > 0 then
			begin
				textToDraw := currentUI.items[i].id + ': ' + currentUI.items[i].dataStrings[currentUI.items[i].currentDataString];
			end;

			// Get the horizontal center of the element
			itemCenterX := currentUI.items[i].x + (BitmapWidth(currentUI.items[i].currentBmp) / 2);
			itemCenterX := itemCenterX - ( TextWidth(currentUI.items[i].setFont, textToDraw) / 2 );
			itemCenterX := CameraX() + itemCenterX;

			// Get the vertical center of the element
			itemCenterY := currentUI.items[i].y + (BitmapHeight(currentUI.items[i].currentBmp) / 2);
			itemCenterY := itemCenterY - ( TextHeight(currentUI.items[i].setFont, textToDraw) / 2 );
			itemCenterY := CameraY() + itemCenterY;

			// Draw the UIElements attached text to the screen on top of its bitmap
			DrawText(textToDraw, ColorBlack, currentUI.items[i].setFont, itemCenterX, itemCenterY);

			// If current UI is Inventory, add the elements id to the ticker tape
			if (currentUI.name = 'Inventory') and (currentUI.items[i].attachedInventory <> nil) then
			begin
				// Add the items adjusted dollar value to the ticker tape
				marketStr += currentUI.items[i].attachedInventory^.name + ': $' + FloatToStrF(currentUI.items[i].attachedInventory^.adjustedDollarValue, ffFixed, 8, 2);
				// Prices are DOWN!
				if currentUI.items[i].attachedInventory^.deltaDollarValue < 0 then
				begin
					marketStr += ' V';
				end
				// Prices are UP!
				else if currentUI.items[i].attachedInventory^.deltaDollarValue > 0 then
				begin
					marketStr += ' ^';
				end;
				// Add the dollar changed value to the ticker tape
				marketStr += ' ' + FloatToStrF(currentUI.items[i].attachedInventory^.deltaDollarValue, ffFixed, 8, 2);

				// Add hyphen between items
				if i < High(currentUI.items) then
				begin
					marketStr += '  -  ';
				end;
			end;
		end;
		// Only render ticket tape if it's been generated
		if marketStr <> '' then
		begin
			// Size of the ticker tape
			tickerOffset := TextWidth(FontNamed('PrStartSmall'), marketStr);
			currentUI.tickerPos -= 2;

			// Ticker tape is completely off screen, so reset its pos
			if CameraX() + currentUI.tickerPos <= CameraX() - tickerOffset then
			begin
				currentUI.tickerPos := 120;
			end;

			// Draw the ticker tape
			DrawText(marketStr, ColorWhite, 'PrStartSmall', CameraX() + currentUI.tickerPos, CameraY() + ScreenHeight() - 50);

			// If the ticker tape is off the screen start drawing a second ticker off the right side of the screen to emulate a loop
			if CameraX() + currentUI.tickerPos < CameraX() then
			begin
				DrawText(marketStr, ColorWhite, 'PrStartSmall', (CameraX() + ScreenWidth() * 2) + currentUI.tickerPos + 50, CameraY() + ScreenHeight() - 50);
			end;
		end;

		if (currentUI.name = 'Inventory') then
		begin
			// Print control instructions
			DrawText('Select - Eat Item | Attack - List Item on eBay', ColorWhite, 'PrStartSmall', CameraX(), CameraY() + 10);
			DrawText('Special - Buy item at current market price', ColorWhite, 'PrStartSmall', CameraX(), CameraY() + 25);
		end;

	end;

end.
