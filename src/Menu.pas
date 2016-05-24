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

	function CreateMenuUI(var map: MapData; var inputs: InputMap): UI;
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
	begin
		InitUI(result, map.inventory.numItems, 'Inventory');

		itemStr := map.inventory.rabbitLeg.name + ': ' + IntToStr(map.inventory.rabbitLeg.count);
		result.items[0] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 50, itemStr, 'PrStartSmall');
		result.items[0].attachedInventory := @map.inventory.rabbitLeg;

		itemStr := map.inventory.bandage.name + ': ' + IntToStr(map.inventory.bandage.count);
		result.items[1] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 200, itemStr, 'PrStartSmall');
		result.items[1].attachedInventory := @map.inventory.bandage;

		itemStr := map.inventory.trinket.name + ': ' + IntToStr(map.inventory.trinket.count);
		result.items[2] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 350, itemStr, 'PrStartSmall');
		result.items[2].attachedInventory := @map.inventory.trinket;

		result.currentItem := 0;
		result.previousItem := 0;
		result.previousUI := @CreateMenuUI;
	end;

	//
	//	Creates the menu UI elements and returns it to replace the currently
	//	displayed UI on the menu state
	//
	function CreateMenuUI(var map: MapData; var inputs: InputMap): UI;
	const
		UI_SIZE = 3;
	begin
		InitUI(result, UI_SIZE, 'Main Menu');
		result.items[0] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 100, 'Inventory');
		result.nextUI := @CreateInventoryUI;
		result.items[1] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 250, 'Settings');
		result.items[2] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 400, 'Exit');
		result.currentItem := 0;
		result.previousItem := 0;
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

		if thisState.displayedUI.name = 'Main Menu' then
		begin
			case UISelectedID(thisState.displayedUI) of
				'Inventory': thisState.displayedUI.nextUI := @CreateInventoryUI;
				'Settings': thisState.displayedUI.nextUI := @CreateSettingsUI;
			end;
		end;
		if thisState.displayedUI.name = 'Settings' then
		begin
			case UISelectedID(thisState.displayedUI) of
				'Change Controls': thisState.displayedUI.nextUI := @CreateChangeControlsUI;
			end;
		end;

		if ( KeyTyped(inputs.Menu) ) and ( thisState.displayedUI.name = 'Main Menu' ) then
		begin
			PlaySoundEffect(SoundEffectNamed('back'), 0.8);
			StateChange(thisState.manager^, LevelState);
		end
		else if ( KeyTyped(inputs.Select) ) and ( thisState.displayedUI.name = 'Controls' ) then
		begin
			PlaySoundEffect(SoundEffectNamed('back'), 0.8);

			Delay(50);
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
			PlaySoundEffect(SoundEffectNamed('confirm'), 0.5);
			StateChange(thisState.manager^, TitleState);
		end
		else if KeyTyped(inputs.Attack) and ( thisState.displayedUI.name = 'Inventory' ) then
		begin
			if currItem^.attachedInventory^.count > 0 then
			begin
				SellItem(currItem^.attachedInventory^, lastLevelState^.map.inventory);
				ReduceItemCount(currItem^);
			end;
		end
		else
		begin
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

		lastLevelState^.Draw(lastLevelState^);
		DrawUI(thisState.displayedUI);
	end;

end.
