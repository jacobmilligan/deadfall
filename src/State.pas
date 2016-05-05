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
		//	Each function pointer (input, update, draw) is called once per frame
		//	and is assigned via each states init function
		//
		ActiveState = record
			stateName: GameState;
			
			manager: ^StateArray;
		
			//
		    //	Checks input and modifies the states data accordingly
		    //
			HandleInput: procedure(var thisState: ActiveState; var inputs: InputMap);

			//
		    //	Uses the states current data to update and change the game
		    //
			Update: procedure(var thisState: ActiveState);

			// 
		    //	Draws state-local data to the window
		    //
			Draw: procedure(var thisState: ActiveState);
			
			//
			//	Represents the current map containing tile and entity information
			//
			map: MapData;
		end;
		
		StatePtr = ^ActiveState;
		
		//	Active states. States can be layered, i.e. Menu can go over the top of Level
		StateArray = array of ActiveState;
		
		StateArrayPtr = ^StateArray;

	procedure StateChange(var states: StateArray; newState: GameState);


implementation
	uses Title, Level, Menu;
	
	procedure StateChange(var states: StateArray; newState: GameState);
	var
		newActiveState: ActiveState;
	begin
		
		newActiveState.stateName := newState;
		newActiveState.manager := @states;
				
		if newState = TitleState then
		begin
			TitleInit(newActiveState);
			
			SetLength(states, 1);
			states[High(states)] := newActiveState;
		end
		else if newState = LevelState then
		begin
		
			if (Length(states) > 0) and (states[High(states)].stateName = MenuState) then
			begin
				SetLength(states, 1);
			end
			else
			begin
				LevelInit(newActiveState);
				SetLength(states, 1);			
				states[High(states)] := newActiveState;
			end;
			
		end
		else if newState = MenuState then
		begin
			MenuInit(newActiveState);
			
			SetLength(states, Length(states) + 1);
			states[High(states)] := newActiveState;
		end
		else
		begin
			WriteLn('Invalid state');	
		end;
		
	end;


end.
