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
	uses SwinGame, Map, Input, GameUI;

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

			displayedUI: UI;

			quitRequested: Boolean;

		end;

		StatePtr = ^ActiveState;

		//	Active states. States can be layered, i.e. Menu can go over the top of Level
		StateArray = array of ActiveState;

		StateArrayPtr = ^StateArray;

	procedure StateChange(var states: StateArray; newState: GameState);

	function GetState(manager: StateArrayPtr; stateIndex: Integer): StatePtr;

implementation
	uses Title, Level, Menu, Game;

	function GetState(manager: StateArrayPtr; stateIndex: Integer): StatePtr;
	begin
		stateIndex := High(manager^) - stateIndex;
		result := @manager^[stateIndex];
	end;

	procedure StateChange(var states: StateArray; newState: GameState);
	var
		newActiveState: ActiveState;
	begin

		newActiveState.stateName := newState;
		newActiveState.manager := @states;
		newActiveState.quitRequested := false;

		if (newState = LevelState) and ( states[High(states)].stateName = TitleState ) then
		begin
			FadeMusicOut(1000);
		end;

		// Transition to title state - release all previously loaded sprites to allow
		// names etc. to reset themselves
		if newState = TitleState then
		begin
			ReleaseAllSprites();

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
				LevelInit(newActiveState, states[High(states)].map);
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
		else if newState = QuitState then
		begin
			FadeMusicOut(800);
			states[High(states)].quitRequested := true;
		end
		else
		begin
			WriteLn('Invalid state');
		end;

	end;

end.
