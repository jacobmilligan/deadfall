//
//  Deadfall v1.0
//  Title.pas
//
// -------------------------------------------------------
//
//  Created By Jacob Milligan
//  On 22/04/2016
//  Student ID: 100660682
//  

unit Title;

interface
	uses State, Game, Input;

	procedure TitleInit(var newState: ActiveState);

	procedure TitleHandleInput(var thisState: ActiveState; var inputs: InputMap);

	procedure TitleUpdate(var thisState: ActiveState);

	procedure TitleDraw(var thisState: ActiveState);


implementation
	
	procedure TitleInit(var newState: ActiveState);
	begin
		newState.HandleInput := @TitleHandleInput;
		newState.Update := @TitleUpdate;
		newState.Draw := @TitleDraw;
	end;

	procedure TitleHandleInput(var thisState: ActiveState; var inputs: InputMap);
	begin
		
	end;

	procedure TitleUpdate(var thisState: ActiveState);
	begin
		WriteLn('Title State');
	end;

	procedure TitleDraw(var thisState: ActiveState);
	begin
		
	end;

end.
