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
uses SwinGame, Game, State;

procedure Main();
var
	core: GameCore;
	dtStart: Double;
begin

	GameInit('Deadfall', 800, 600, core);

	while core.active do
	begin
		dtStart := GetTicks();

		GameUpdate(core);
		GameDraw(core);

		core.deltaTime := (GetTicks() - dtStart) / 1000;
	end;
end;

begin
	Main();
end.
