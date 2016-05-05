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
	uses SwinGame;
	
	procedure MenuInit(var newState: ActiveState);
	begin
		newState.HandleInput := @MenuHandleInput;
		newState.Update := @MenuUpdate;
		newState.Draw := @MenuDraw;
		
		ShowPanel(PanelNamed('menu'));
		DrawInterface();
	end;

	procedure MenuHandleInput(var thisState: ActiveState; var inputs: InputMap);
	begin
		
	end;

	procedure MenuUpdate(var thisState: ActiveState);
	begin
		
	end;

	procedure MenuDraw(var thisState: ActiveState);
	var
		managerPtr: ^StateArray;
		levelState: ^ActiveState;
		levelIndex: Integer;
	begin
		managerPtr := thisState.manager;
		levelIndex := High(managerPtr^) - 1;
		levelState := @managerPtr^[levelIndex];
		
		levelState^.Draw(levelState^);
		DrawInterface();
	end;

end.
