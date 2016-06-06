//
//  Deadfall v1.0
//  Menu.pas
//
// -------------------------------------------------------
//
//  Created By Jacob Milligan
//  On 05/05/2016
//  Student ID: 100660682
//

unit Menu;

interface
	uses State, Game, Input, GameUI, Map;

	type
		DynamicStringArray = array of String;

	//
	//	Initializes the menu state and creates the UI elements
	//
	procedure MenuInit(var newState: ActiveState);

	//
	//	Handles all input in the menu state, handles changing to different
	//	sub-menus, i.e. Inventory. Handles changing state to Quit or Level
	//
	procedure MenuHandleInput(var thisState: ActiveState; var inputs: InputMap);

	//
	//	Updates the menu and UI
	//
	procedure MenuUpdate(var thisState: ActiveState);

	//
	//	Draws the last level state then draws the menu UI over the top.
	//	This way the level is paused underneath the menu.
	//
	procedure MenuDraw(var thisState: ActiveState);

	// Creates the main menu UI
	function CreateMenuUI(var map: MapData; var inputs: InputMap): UI;

	// Creates the main inventory UI
	function CreateInventoryUI(var map: MapData; var inputs: InputMap): UI;

implementation
	uses SwinGame, SysUtils, typinfo;

	//
	//	Retrieves a state at a given offset to the left from the current state in
	//	the state manager. Use in situations with stacked states to access other states
	//	Update, Input, and Draw functions.
	//
	function GetState(manager: StateArrayPtr; stateIndex: Integer): StatePtr;
	begin
		stateIndex := High(manager^) - stateIndex;
		result := @manager^[stateIndex];
	end;

	//
	//	Returns the index of an item searched in the players inventory
	//
	function ItemIndex(var itemNames: DynamicStringArray; name: String): Integer;
	var
		i: Integer;
	begin
		result := -1;
		for i := 0 to High(itemNames) do
		begin
			if itemNames[i] = name then
			begin
				result := i;
				break;
			end;
		end;
	end;

	//
	//	Creates the inventory UI elements and returns it to replace the currently
	//	displayed UI on the menu state
	//
	function CreateInventoryUI(var map: MapData; var inputs: InputMap): UI;
	const
		UI_SIZE = 3;
	var
		itemStr: String;
		i: Integer;
	begin
		InitUI(result, Length(map.inventory.items), 'Inventory');
		result.tickerPos := 100;

		// Iterate items and add each one as an element to the UI
		for i := 0 to High(map.inventory.items) do
		begin
			// "<item_name> (Stocked: <num>, For Sale: <num>)"
			itemStr := 	map.inventory.items[i].name + ' (Stocked: ' + IntToStr(map.inventory.items[i].count) +
									', For Sale: ' + IntToStr(map.inventory.items[i].listed) + ')';
			result.items[i] := CreateUIElement(BitmapNamed('ui_blue_wide'), BitmapNamed('ui_red_wide'), HorizontalCenter('ui_blue_wide'), (100 * i) + 55, itemStr, 'PrStartSmall');
			// Add pointer to the inventory item in the array to alter it directly
			result.items[i].attachedInventory := @map.inventory.items[i];
		end;

		result.currentItem := 0;
		result.previousItem := 0;
		result.previousUI := @CreateMenuUI;
	end;

	function CreateMapUI(var map: MapData; var inputs: InputMap): UI;
	begin
		InitUI(result, 1, 'Map Menu');

		result.items[0] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 500, 'Return');
		map.playerIndicator := 0;

		result.currentItem := 0;
		result.previousItem := 0;
		result.previousUI := @CreateMenuUI;
		result.nextUI := @CreateMenuUI;
	end;

	//
	//	Creates the menu UI elements and returns it to replace the currently
	//	displayed UI on the menu state
	//
	function CreateMenuUI(var map: MapData; var inputs: InputMap): UI;
	const
		UI_SIZE = 4;
	begin
		InitUI(result, UI_SIZE, 'Main Menu');
		result.items[0] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 100, 'Inventory');
		result.items[1] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 210, 'Map');
		result.items[2] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 320, 'Settings');
		result.items[3] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 430, 'Exit');
		result.currentItem := 0;
		result.previousItem := 0;
		result.nextUI := @CreateInventoryUI;
	end;

	procedure MenuInit(var newState: ActiveState);
	var
		tempInputs: InputMap;
	begin
		newState.HandleInput := @MenuHandleInput;
		newState.Update := @MenuUpdate;
		newState.Draw := @MenuDraw;
		newState.displayedUI := CreateMenuUI( GetState(newState.manager, 1)^.map, tempInputs );
	end;

	procedure MenuHandleInput(var thisState: ActiveState; var inputs: InputMap);
	var
		lastLevelState: StatePtr;
		currItem: ^UIElement;
		keyStr: String;
	begin
		lastLevelState := GetState(thisState.manager, 1);
		currItem := @thisState.displayedUI.items[thisState.displayedUI.currentItem];

		// Change next UI dependent on current highlighted UIElement
		if thisState.displayedUI.name = 'Main Menu' then
		begin
			case UISelectedID(thisState.displayedUI) of
				'Map': thisState.displayedUI.nextUI := @CreateMapUI;
				'Inventory': thisState.displayedUI.nextUI := @CreateInventoryUI;
				'Settings': thisState.displayedUI.nextUI := @CreateSettingsUI;
			end;
		end;

		// Change nextUI based on settings submenu highlighted
		if thisState.displayedUI.name = 'Settings' then
		begin
			case UISelectedID(thisState.displayedUI) of
				'Change Controls': thisState.displayedUI.nextUI := @CreateChangeControlsUI;
			end;
		end;

		// Return to the level state if back is pressed on the main menu top level UI
		if ( KeyTyped(inputs.Menu) ) and ( thisState.displayedUI.name = 'Main Menu' ) then
		begin
			PlaySoundEffect(SoundEffectNamed('back'), 0.8);
			StateChange(thisState.manager^, LevelState);
		end
		else if ( KeyTyped(inputs.Select) ) and ( thisState.displayedUI.name = 'Controls' ) then
		begin
			// Handle changing controls
			PlaySoundEffect(SoundEffectNamed('back'), 0.8);
			Delay(50);

			// Wait until the user presses a new button
			while not AnyKeyPressed() do
			begin
				ProcessEvents();
				ClearScreen(ColorBlack);
				MenuDraw(thisState);
				DrawText('Press the new key to change control', ColorWhite, FontNamed('PrStartSmall'), CameraX() + HorizontalCenter('ui_blue'), CameraY() + 10);
				RefreshScreen(60);
			end;

			ChangeKeyTo(inputs, thisState.displayedUI.items[thisState.displayedUI.currentItem].id);
		end
		else if KeyTyped(inputs.Select) and ( UISelectedID(thisState.displayedUI) = 'Exit' ) then
		begin
			// Return to the title screen
			PlaySoundEffect(SoundEffectNamed('confirm'), 0.5);
			StateChange(thisState.manager^, TitleState);
		end
		else if KeyTyped(inputs.Attack) and ( thisState.displayedUI.name = 'Inventory' ) then
		begin
			// Handle selling of items on the inventory screen
			if currItem^.attachedInventory^.count > 0 then
			begin
				SellItem(currItem^.attachedInventory^, lastLevelState^.map.inventory);
				ReduceItemCount(currItem^);
			end;
		end
		else if KeyTyped(inputs.Action) and ( thisState.displayedUI.name = 'Inventory' ) then
		begin
			// Handle buying of items on the inventory screen
			BuyItem(currItem^, lastLevelState^.map.inventory.dollars);
		end
		else
		begin
			// Only navigate the menu if none of the above actions have happened
			UINavigate(thisState.displayedUI, inputs, lastLevelState^.map);
		end;

	end;

	procedure MenuUpdate(var thisState: ActiveState);
	begin
		UpdateUI(thisState.displayedUI, thisState.displayedUI.currentItem, thisState.displayedUI.previousItem);
	end;

	procedure MenuDraw(var thisState: ActiveState);
	var
		lastLevelState: StatePtr;
		i: Integer;
	begin
		lastLevelState := GetState(thisState.manager, 1);

		// Draw the current paused level underneath the menu
		lastLevelState^.Draw(lastLevelState^);

		DrawUI(thisState.displayedUI);

		// Draw the map overview if on the map menu
		if thisState.displayedUI.name = 'Map Menu' then
		begin
			DrawMapCartography(lastLevelState^.map);
		end;

	end;

end.
