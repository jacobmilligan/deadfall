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
	uses sgTypes, Map, Input;

	type
		//
		//	All possible gamestates are set as an enum, used in choosing
		//	which state to switch to
		//
		GameState = (TitleState, LevelState, MenuState, QuitState);

		//
		//	Forward declaration of pointer to GameCore type to avoid 
		//	circular reference in ActiveState
		//
		GameCore = ^TGameCore;

		//
		//	Each function pointer (input, update, draw) is called once per frame
		//	and is assigned via each states init function
		//
		ActiveState = record
			stateName: GameState;
		
			//
		    //	Checks input and modifies the states data accordingly
		    //
			HandleInput: procedure(core: GameCore; var inputs: InputMap);

			//
		    //	Uses the states current data to update and change the game
		    //
			Update: procedure(core: GameCore);

			// 
		    //	Draws state-local data to the window
		    //
			Draw: procedure(core: GameCore);
			
			//
			//	Represents the current map containing tile and entity information
			//
			currentMap: MapData;
		end;
		
		//	Active states. States can be layered, i.e. Menu can go over the top of Level
		StateArray = array of ActiveState;
		
		TGameCore = record
			//
		    // Represents an active game, if this is set to false, the game shuts down
		    //
			active: Boolean;
			
			//	Active states
			states: StateArray;
		end;

	procedure StateChange(core: GameCore; newState: GameState);


implementation
	uses Title, Level, Menu;
	
	procedure StateChange(core: GameCore; newState: GameState);
	var
		newActiveState: ActiveState;
	begin
		
		newActiveState.stateName := newState;
				
		if newState = TitleState then
		begin
			TitleInit(newActiveState);
		end
		else if newState = LevelState then
		begin
			LevelInit(newActiveState);
		end
		else if newState = MenuState then
		begin
			MenuInit(newActiveState);
		end
		else
		begin
			WriteLn('Invalid state');			
		end;
		
		SetLength(core^.states, Length(core^.states) + 1);
		core^.states[High(core^.states)] := newActiveState;
	end;


end.
