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
	uses State, Game;

	procedure TitleInit(var newState: ActiveState);

	procedure TitleHandleInput(core: GameCore);

	procedure TitleUpdate(core: GameCore);

	procedure TitleDraw(core: GameCore);


implementation
	
	procedure TitleInit(var newState: ActiveState);
	begin
		newState.HandleInput := @TitleHandleInput;
		newState.Update := @TitleUpdate;
		newState.Draw := @TitleDraw;
	end;

	procedure TitleHandleInput(core: GameCore);
	begin
		
	end;

	procedure TitleUpdate(core: GameCore);
	begin
		WriteLn('Title State');
	end;

	procedure TitleDraw(core: GameCore);
	begin
		
	end;

end.
