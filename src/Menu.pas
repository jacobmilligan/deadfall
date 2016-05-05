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
	uses SwinGame, Map, typinfo;
	
	function GetState(manager: StateArrayPtr; stateIndex: Integer): StatePtr;
	begin
		stateIndex := High(manager^) - stateIndex;
		result := @manager^[stateIndex];
	end;
	
	procedure MenuInit(var newState: ActiveState);
	begin
		newState.HandleInput := @MenuHandleInput;
		newState.Update := @MenuUpdate;
		newState.Draw := @MenuDraw;
		
		ShowPanel(PanelNamed('menu'));
		GUISetBackgroundColor(ColorBlack);
		GUISetForegroundColor(RGBColor(105, 123, 224));
	end;

	procedure MenuHandleInput(var thisState: ActiveState; var inputs: InputMap);
	var
		i: Integer;
		lastLevelState: StatePtr;
	begin
		UpdateInterface();
		
		lastLevelState := GetState(thisState.manager, 1);
		
		if RegionClickedID() = 'InventoryBtn' then
		begin
			ShowPanel(PanelNamed('inventory'));
			//ListClearItems('InventoryList');
			
			for i := 0 to High(lastLevelState^.map.inventory) do
			begin
				WriteLn(lastLevelState^.map.inventory[i].category);
				ListAddItem('InventoryList', 'food');
			end;
		end;
		if RegionClickedID() = 'ContinueBtn' then
		begin
			StateChange(thisState.manager^, LevelState);
		end;
		
		UpdateInterface();
	end;

	procedure MenuUpdate(var thisState: ActiveState);
	begin
		
	end;

	procedure MenuDraw(var thisState: ActiveState);
	var
		managerPtr: ^StateArray;
		lastLevelState: ^ActiveState;
		levelIndex: Integer;
		horizontalCenter: Single;
	begin
		managerPtr := thisState.manager;
		levelIndex := High(managerPtr^) - 1;
		lastLevelState := @managerPtr^[levelIndex];
		
		horizontalCenter := ( ScreenWidth() - BitmapWidth(BitmapNamed('ui_blue')) ) / 2;
		
		lastLevelState^.Draw(lastLevelState^);
		
		DrawInterface();
		//DrawBitmap(BitmapNamed('ui_blue'), CameraX() + horizontalCenter, CameraY() + 100);		
	end;

end.
