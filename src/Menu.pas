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
	uses State, Game, Input;

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

implementation
	uses SwinGame, Map, GameUI, SysUtils, typinfo;

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
	function CreateInventoryUI(constref inventory: InventoryTemp): UI;
	const
		UI_SIZE = 3;
	var
		itemStr: String;
	begin
		InitUI(result, inventory.numItems);

		itemStr := inventory.rabbitLeg.name + ': ' + IntToStr(inventory.rabbitLeg.count);
		result.items[0] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), 100, (50 + (50 * 0)), itemStr, 'PrStartSmall');
		result.items[0].attachedInventory := @inventory.rabbitLeg;

		itemStr := inventory.bandage.name + ': ' + IntToStr(inventory.bandage.count);
		result.items[1] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), 100, (50 + (50 * 2)), itemStr, 'PrStartSmall');
		result.items[1].attachedInventory := @inventory.bandage;

		itemStr := inventory.trinket.name + ': ' + IntToStr(inventory.trinket.count);
		result.items[2] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), 100, (50 + (50 * 3)), itemStr, 'PrStartSmall');
		result.items[2].attachedInventory := @inventory.trinket;

		result.currentItem := 0;
		result.previousItem := 0;
		result.name := 'Inventory';
	end;

	//
	//	Creates the menu UI elements and returns it to replace the currently
	//	displayed UI on the menu state
	//
	function CreateMenuUI(): UI;
	const
		UI_SIZE = 3;
	var
		horizontalCenter: Single;
	begin
		horizontalCenter := ( ScreenWidth() - BitmapWidth(BitmapNamed('ui_blue')) ) / 2;

		InitUI(result, UI_SIZE);
		result.items[0] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), horizontalCenter, 100, 'Inventory');
		result.items[1] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), horizontalCenter, 250, 'Settings');
		result.items[2] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), horizontalCenter, 400, 'Exit');
		result.currentItem := 0;
		result.previousItem := 0;
		result.name := 'Main Menu';
	end;

	procedure MenuInit(var newState: ActiveState);
	begin
		newState.HandleInput := @MenuHandleInput;
		newState.Update := @MenuUpdate;
		newState.Draw := @MenuDraw;
		newState.displayedUI := CreateMenuUI();
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

	procedure MenuHandleInput(var thisState: ActiveState; var inputs: InputMap);
	var
		lastLevelState: StatePtr;
		currItem: ^UIElement;
	begin
		lastLevelState := GetState(thisState.manager, 1);

		if thisState.displayedUI.name = 'Inventory' then
		begin
			if KeyTyped(inputs.Menu) then
			begin
				InitUI(thisState.displayedUI, 0);
				thisState.displayedUI := CreateMenuUI();
			end
			else if KeyTyped(inputs.MoveUp) then
			begin
				ChangeElement(thisState.displayedUI, UI_PREV);
			end
			else if KeyTyped(inputs.MoveDown) then
			begin
				ChangeElement(thisState.displayedUI, UI_NEXT);
			end
			else if KeyTyped(inputs.Select) then
			begin
				currItem := @thisState.displayedUI.items[thisState.displayedUI.currentItem];

				if currItem^.attachedInventory^.count > 0 then
				begin
					RestoreHunger(lastLevelState^.map.player.hunger, currItem^.attachedInventory^.hungerPlus);
					RestoreHealth(lastLevelState^.map.player.hp, currItem^.attachedInventory^.healthPlus);
					//ListOnEbay(lastLevelState^.map.player.hunger, currItem^.attachedInventory^.hungerPlus);

					ReduceItemCount(currItem^);
				end;

			end;
		end
		else
		begin

			if KeyTyped(inputs.MoveUp) then
			begin
				ChangeElement(thisState.displayedUI, UI_PREV);
			end
			else if KeyTyped(inputs.MoveDown) then
			begin
				ChangeElement(thisState.displayedUI, UI_NEXT);
			end
			else if KeyTyped(inputs.Menu) then
			begin
				StateChange(thisState.manager^, LevelState);
			end
			else if KeyTyped(inputs.Select) then
			begin

				if UISelectedID(thisState.displayedUI) = 'Exit' then
				begin
					StateChange(thisState.manager^, QuitState);
				end
				else if UISelectedID(thisState.displayedUI) = 'Inventory' then
				begin
					InitUI(thisState.displayedUI, 0);
					thisState.displayedUI := CreateInventoryUI(lastLevelState^.map.inventory);
				end;

			end;

		end;

	end;

	procedure MenuUpdate(var thisState: ActiveState);
	begin
		UpdateUI(thisState.displayedUI);
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
