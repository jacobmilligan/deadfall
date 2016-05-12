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
	
	procedure MenuInit(var newState: ActiveState);

	procedure MenuHandleInput(var thisState: ActiveState; var inputs: InputMap);

	procedure MenuUpdate(var thisState: ActiveState);

	procedure MenuDraw(var thisState: ActiveState);

implementation
	uses SwinGame, Map, GameUI, typinfo;
	
	function GetState(manager: StateArrayPtr; stateIndex: Integer): StatePtr;
	begin
		stateIndex := High(manager^) - stateIndex;
		result := @manager^[stateIndex];
	end;
	
	function CreateInventoryUI(): UI;
	var
		horizontalCenter: Single;
		newUI: UI;
	begin
		horizontalCenter := ( ScreenWidth() - BitmapWidth(BitmapNamed('ui_blue')) ) / 2;		
		
		InitUI(newUI, 1);
		newUI.items[0] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), horizontalCenter, 500, 'List');
		
		result.items := newUI.items;
		result.currentItem := 0;
	end;
	
	function CreateMenuUI(): UI;
	var
		horizontalCenter: Single;
		newUI: UI;
	begin
		horizontalCenter := ( ScreenWidth() - BitmapWidth(BitmapNamed('ui_blue')) ) / 2;		
		
		InitUI(newUI, 3);
		newUI.items[0] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), horizontalCenter, 100, 'Inventory');
		newUI.items[1] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), horizontalCenter, 250, 'Settings');
		newUI.items[2] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), horizontalCenter, 400, 'Exit');
		
		result.items := newUI.items;
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
		i: Integer;
		lastLevelState: StatePtr;
	begin
		lastLevelState := GetState(thisState.manager, 1);
		
		if KeyDown(inputs.MoveUp) then 
		begin
			ChangeElement(thisState.displayedUI, UI_PREV);
		end
		else if KeyDown(inputs.MoveDown) then 
		begin
			ChangeElement(thisState.displayedUI, UI_NEXT);
		end
		else if KeyDown(inputs.Select) then
		begin
			if UISelectedID(thisState.displayedUI) = 'Exit' then
			begin
				StateChange(thisState.manager^, QuitState);
			end
			else if UISelectedID(thisState.displayedUI) = 'Inventory' then
			begin
				thisState.displayedUI := CreateInventoryUI();
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
	begin
		lastLevelState := GetState(thisState.manager, 1);

		lastLevelState^.Draw(lastLevelState^);		
		DrawUI(thisState.displayedUI);
	end;

end.
