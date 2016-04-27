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
	
	SetDefaultInput(inputs);
	GameInit('Deadfall', 800, 600, core);

	while core^.active do
	begin
		dtStart := GetTicks();
		
		GameUpdate(core, inputs);
		GameDraw(core);

		core^.deltaTime := (GetTicks() - dtStart) / 1000;
	end;
end;

begin
	Main();
end.
