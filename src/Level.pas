//
//  Deadfall v1.0
//  Map.pas
//
// -------------------------------------------------------
//
//  Created By Jacob Milligan
//  On 22/04/2016
//  Student ID: 100660682
//  

unit Level;

interface
	uses State, sgTypes;

	//
	// Initializes the playing map state, intializes using 
	// a new active state
	//
	procedure MapInit(var newState: ActiveState);

	procedure MapHandleInput(var manager: GameCore);

	procedure MapUpdate(var manager: GameCore);

	procedure MapDraw(var manager: GameCore);


implementation
	uses Map;

	procedure MapInit(var newState: ActiveState);
	begin
		newState.HandleInput := @MapHandleInput;
		newState.Update := @MapUpdate;
		newState.Draw := @MapDraw;

		newState.currentMap := GenerateNewMap(513);
	end;

	procedure MapHandleInput(var manager: GameCore);
	begin
		
	end;

	procedure MapUpdate(var manager: GameCore);
	begin
		
	end;

	procedure MapDraw(var manager: GameCore);
	begin
		
	end;

end.
