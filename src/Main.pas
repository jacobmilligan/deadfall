//
//  Deadfall v1.0
//  Main.pas
//
// -------------------------------------------------------
//
//  Created By Jacob Milligan
//  On 21/04/2016
//  Student ID: 100660682
//  

program DeadFall;
uses SwinGame, Game, State, Input;

procedure Main();
var
	states: StateArray;
	inputs: InputMap;
	dtStart: Double;
begin
	
	GameInit('Deadfall', 800, 600, states);
	SetDefaultInput(inputs);

	while not WindowCloseRequested() do
	begin
		GameUpdate(states, inputs);
		GameDraw(states);
	end;
end;

begin
	Main();
end.
