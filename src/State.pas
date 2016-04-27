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
	uses sgTypes, Map;

	type
		//
		// All possible gamestates are set as an enum, used in choosing
		// which state to switch to
		//
		GameState = (TitleState, LevelState, MenuState, QuitState);

		GameCore = ^TGameCore;

		EntityStats = record
			HP: Integer;
		end;

		//
		// Each function pointer (input, update, draw) is called once per frame
		// and is assigned via each states init function
		//
		ActiveState = record
			//
		    // Checks input and modifies the states data accordingly
		    //
			HandleInput: procedure(core: GameCore);

			//
		    // Uses the states current data to update and change the game
		    //
			Update: procedure(core: GameCore);

			// 
		    // Draws state-local data to the window
		    //
			Draw: procedure(core: GameCore);

			currentMap: MapData;
		end;

		StateArray = array of ActiveState;
		
		TGameCore = record
			//
		    // Represents an active game, if this is set to false, the game shuts down
		    //
			active: Boolean;
			
			states: StateArray;

			deltaTime: Double;
						
		end;

	procedure StateChange(core: GameCore; newState: GameState);


implementation
	uses Title, Level;
	
	procedure StateChange(core: GameCore; newState: GameState);
	var
		newActiveState: ActiveState;
	begin
		case newState of
			TitleState: TitleInit(newActiveState);
			LevelState: LevelInit(newActiveState);
			else 
				WriteLn('Invalid state');
		end;
		
		SetLength(core^.states, Length(core^.states) + 1);
		core^.states[High(core^.states)] := newActiveState;
	end;


end.
