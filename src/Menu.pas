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

	function CreateMenuUI(var map: MapData): UI;
	function CreateInventoryUI(var map: MapData): UI;

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

	function TestUI(var map: MapData): UI;
	begin
		InitUI(result, 1);
		result.items[0] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), 100, (50 + (50 * 0)), 'Test', 'PrStartSmall');
		result.currentItem := 0;
		result.previousItem := 0;
		result.previousUI := @CreateInventoryUI;
	end;
	//
	//	Creates the inventory UI elements and returns it to replace the currently
	//	displayed UI on the menu state
	//
	function CreateInventoryUI(var map: MapData): UI;
	const
		UI_SIZE = 3;
	var
		itemStr: String;
		horizontalCenter: Single;
	begin
		horizontalCenter := ( ScreenWidth() - BitmapWidth(BitmapNamed('ui_blue')) ) / 2;
		InitUI(result, map.inventory.numItems);

		itemStr := map.inventory.rabbitLeg.name + ': ' + IntToStr(map.inventory.rabbitLeg.count);
		result.items[0] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), horizontalCenter, 50, itemStr, 'PrStartSmall');
		result.items[0].attachedInventory := @map.inventory.rabbitLeg;

		itemStr := map.inventory.bandage.name + ': ' + IntToStr(map.inventory.bandage.count);
		result.items[1] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), horizontalCenter, 200, itemStr, 'PrStartSmall');
		result.items[1].attachedInventory := @map.inventory.bandage;

		itemStr := map.inventory.trinket.name + ': ' + IntToStr(map.inventory.trinket.count);
		result.items[2] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), horizontalCenter, 350, itemStr, 'PrStartSmall');
		result.items[2].attachedInventory := @map.inventory.trinket;

		result.currentItem := 0;
		result.previousItem := 0;
		result.previousUI := @CreateMenuUI;
		result.name := 'Inventory';
	end;

	//
	//	Creates the menu UI elements and returns it to replace the currently
	//	displayed UI on the menu state
	//
	function CreateMenuUI(var map: MapData): UI;
	const
		UI_SIZE = 3;
	var
		horizontalCenter: Single;
	begin
		horizontalCenter := ( ScreenWidth() - BitmapWidth(BitmapNamed('ui_blue')) ) / 2;

		InitUI(result, UI_SIZE);
		result.items[0] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), horizontalCenter, 100, 'Inventory');
		result.nextUI := @CreateInventoryUI;
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
		newState.displayedUI := CreateMenuUI( GetState(newState.manager, 1)^.map );
	end;

	procedure MenuHandleInput(var thisState: ActiveState; var inputs: InputMap);
	var
		lastLevelState: StatePtr;
		currItem: ^UIElement;
	begin
		lastLevelState := GetState(thisState.manager, 1);
		currItem := @thisState.displayedUI.items[thisState.displayedUI.currentItem];

		if ( KeyTyped(inputs.Menu) ) and ( thisState.displayedUI.name = 'Main Menu' ) then
		begin
			PlaySoundEffect(SoundEffectNamed('back'), 0.8);
			StateChange(thisState.manager^, LevelState);
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
