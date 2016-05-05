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

	procedure MenuHandleInput(core: GameCore; var inputs: InputMap);

	procedure MenuUpdate(core: GameCore);

	procedure MenuDraw(core: GameCore);


implementation
	
	procedure MenuInit(var newState: ActiveState);
	begin
		newState.HandleInput := @MenuHandleInput;
		newState.Update := @MenuUpdate;
		newState.Draw := @MenuDraw;
	end;

	procedure MenuHandleInput(core: GameCore; var inputs: InputMap);
	begin
		
	end;

	procedure MenuUpdate(core: GameCore);
	begin
		WriteLn('Menu State');
	end;

	procedure MenuDraw(core: GameCore);
	begin
		
	end;

end.
