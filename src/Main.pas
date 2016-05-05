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
	core: GameCore;
	inputs: InputMap;
	dtStart: Double;
begin
	
	GameInit('Deadfall', 800, 600, core);
	SetDefaultInput(inputs);

	while core^.active do
	begin
		GameUpdate(core, inputs);
		GameDraw(core);
	end;
end;

begin
	Main();
end.
