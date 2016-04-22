//
//  Deadfall v1.0
//  State.pas
//
// -------------------------------------------------------
//
//  Created By Jacob Milligan
//  On 21/04/2016
//  Student ID: 100660682
//  

unit State;

interface
	uses Map;

	type
		//
		// All possible gamestates are set as an enum, used in choosing
		// which state to switch to
		//
		GameState = (TitleState, MapState, MenuState, QuitState);

		StateManager = ^TStateManager;

		GameCore = record
			//
		    // Represents an active game, if this is set to false, the game shuts down
		    //
			active: Boolean;

			deltaTime: Double;

			stateManager: StateManager;
		end;

		//
		// Each function pointer (input, update, draw) is called once per frame
		// and is assigned via each states init function
		//
		ActiveState = record
			//
		    // Checks input and modifies the states data accordingly
		    //
			HandleInput: procedure(var core: GameCore);

			//
		    // Uses the states current data to update and change the game
		    //
			Update: procedure(var core: GameCore);

			// 
		    // Draws state-local data to the window
		    //
			Draw: procedure(var core: GameCore);

			currentMap: MapData;
		end;

		StateArray = array of ActiveState;

		TStateManager = record
			//
		    // Defines the size of each tile grid cell on a level
		    //
			tilesize: Integer;

			states: StateArray;
		end;

	procedure StateChange(manager: StateManager; newState: GameState);


implementation
	uses Title, Level;
	
	procedure StateChange(manager: StateManager; newState: GameState);
	var
		newActiveState: ActiveState;
	begin
		case newState of
			TitleState: TitleInit(newActiveState);
			MapState: MapInit(newActiveState);
			else 
				WriteLn('Invalid state');
		end;

		SetLength(manager^.states, Length(manager^.states) + 1);
		manager^.states[High(manager^.states)] := newActiveState;
	end;


end.
