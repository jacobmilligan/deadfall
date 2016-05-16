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

	procedure MenuInit(var newState: ActiveState);

	procedure MenuHandleInput(var thisState: ActiveState; var inputs: InputMap);

	procedure MenuUpdate(var thisState: ActiveState);

	procedure MenuDraw(var thisState: ActiveState);

implementation
	uses SwinGame, Map, GameUI, SysUtils, typinfo;

	function GetState(manager: StateArrayPtr; stateIndex: Integer): StatePtr;
	begin
		stateIndex := High(manager^) - stateIndex;
		result := @manager^[stateIndex];
	end;

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

	function CreateInventoryUI(constref inventory: InventoryCollection): UI;
	var
		currItemIndex, i: Integer;
		itemNames: DynamicStringArray;
		itemAmts: array of Integer;
		itemStr: String;
	begin

		SetLength(itemNames, 0);
		SetLength(itemAmts, 0);

		for i := 0 to High(inventory) do
		begin
			currItemIndex := ItemIndex(itemNames, inventory[i].name);

			if currItemIndex < 0 then
			begin
				SetLength(itemNames, Length(itemNames) + 1);
				SetLength(itemAmts, Length(itemAmts) + 1);
				itemNames[High(itemNames)] := inventory[i].name;
				itemAmts[High(itemAmts)] := 1;
			end
			else
			begin
				itemAmts[currItemIndex] += 1;
			end;

		end;

		if Length(itemNames) < 0 then
		begin
			result.items[0] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_blue'), 100, 50,  'No Items', 'PrStartSmall');
		end
		else
		begin
			InitUI(result, Length(itemNames));

			for i := 0 to High(result.items) do
			begin
				itemStr := itemNames[i] + ': ' + IntToStr(itemAmts[i]);
				result.items[i] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_blue'), 100, (50 + (50 * i)), itemStr, 'PrStartSmall');
			end;
		end;

		SetLength(result.items, Length(result.items) + 1);
		result.items[High(result.items)] := CreateUIElement(BitmapNamed('hidden'), BitmapNamed('hidden'), -100, 50,  'Inventory List', 'PrStartSmall');

		result.currentItem := High(result.items);
	end;

	function CreateMenuUI(): UI;
	var
		horizontalCenter: Single;
	begin
		horizontalCenter := ( ScreenWidth() - BitmapWidth(BitmapNamed('ui_blue')) ) / 2;

		InitUI(result, 3);
		result.items[0] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), horizontalCenter, 100, 'Inventory');
		result.items[1] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), horizontalCenter, 250, 'Settings');
		result.items[2] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), horizontalCenter, 400, 'Exit');
		result.currentItem := 0;
	end;

	procedure MenuInit(var newState: ActiveState);
	begin
		newState.HandleInput := @MenuHandleInput;
		newState.Update := @MenuUpdate;
		newState.Draw := @MenuDraw;
		newState.displayedUI := CreateMenuUI();
	end;

	procedure MenuHandleInput(var thisState: ActiveState; var inputs: InputMap);
	var
		lastLevelState: StatePtr;
		// For some reason the game crashes if I remove this redundant variable declaration
		newUI: UI;
	begin
		lastLevelState := GetState(thisState.manager, 1);

		if UISelectedID(thisState.displayedUI) = 'Inventory List' then
		begin
			if KeyTyped(inputs.Menu) then
			begin
				thisState.displayedUI := CreateMenuUI();
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
