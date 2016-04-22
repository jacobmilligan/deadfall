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

	procedure TitleHandleInput(var manager: GameCore);

	procedure TitleUpdate(var manager: GameCore);

	procedure TitleDraw(var manager: GameCore);


implementation
	
	procedure TitleInit(var newState: ActiveState);
	begin
		newState.HandleInput := @TitleHandleInput;
		newState.Update := @TitleUpdate;
		newState.Draw := @TitleDraw;
	end;

	procedure TitleHandleInput(var manager: GameCore);
	begin
		
	end;

	procedure TitleUpdate(var manager: GameCore);
	begin
		WriteLn('Title State');
	end;

	procedure TitleDraw(var manager: GameCore);
	begin
		
	end;

end.
