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
		GameState = (TitleState, LevelState, MenuState, QuitState, GameOverState);

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

	//
	//	Used to switch to a new game screen/state. This must be the last procedure called
	//	in a given code block otherwise the game will try to access an out-of-scope code block
	//	(the block calling StateChange()).
	//
	//	Also defines all valid transitions between different states.
	//
	procedure StateChange(var states: StateArray; newState: GameState);

	//
	//	Returns a state in the state manager array at a given negative offset from the
	//	calling state.
	//
	function GetState(manager: StateArrayPtr; stateIndex: Integer): StatePtr;

implementation
	uses Title, Level, Menu, Game, NPC;

	function GetState(manager: StateArrayPtr; stateIndex: Integer): StatePtr;
	begin
		stateIndex := High(manager^) - stateIndex;
		result := @manager^[stateIndex];
	end;

	// Executes the game over sequence, displaying the 'You Died.' screen until
	// the player presses a button
	procedure DoGameOver();
	var
		timeout: Integer;
		returnToTitle: Boolean;
		dieStr, contStr: String;
	begin
		timeout := 0;
		returnToTitle := false;
		dieStr := 'You Died.';
		contStr := 'Press any key to return to the title menu.';
		PlayMusic(MusicNamed('over'));

		// Show title until keypress
		repeat
			ClearScreen(ColorBlack);
			ProcessEvents();

			// Put a timeout so that if the player dies while pressing a key, they
			// won't accidentally skip the game over screen
			if timeout > 50 then
			begin
				if AnyKeyPressed() or WindowCloseRequested() then
				begin
					returnToTitle := true;
				end;
			end;

			// Draw 'You died.'
			DrawText(dieStr, ColorYellow, 'Vermin', CameraX() + ( (ScreenWidth() - TextWidth(FontNamed('Vermin'), dieStr)) / 2), CameraY() + 100);
			// Draw 'Press any key...'
			DrawText(contStr, ColorYellow, 'PrStartSmall', CameraX() + ( (ScreenWidth() - TextWidth(FontNamed('PrStartSmall'), contStr)) / 2), CameraY() + 400);
			RefreshScreen(60);
			timeout += 1;
		until returnToTitle;
	end;

	procedure StateChange(var states: StateArray; newState: GameState);
	var
		newActiveState: ActiveState;
	begin

		newActiveState.stateName := newState;
		newActiveState.manager := @states;
		newActiveState.quitRequested := false;

		// Title to level transition
		if (newState = LevelState) and ( states[High(states)].stateName = TitleState ) then
		begin
			FadeMusicOut(1000);
		end;

		// Any state to game over transition
		if (newState = GameOverState) then
		begin
			DoGameOver();
			PlaySoundEffect(SoundEffectNamed('confirm'), 0.5);
			newState := TitleState;
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
			// Transition from menu to level
			if (Length(states) > 0) and (states[High(states)].stateName = MenuState) then
			begin
				SetLength(states, 1);
			end
			else
			begin
				// Transition from any other state to level
				LevelInit(newActiveState, states[High(states)].map);
				SetLength(states, 1);

				SetMusicVolume(0.5);
				FadeMusicIn(MusicNamed('main'), 1000);

				CenterCameraOn(newActiveState.map.player.sprite, ScreenWidth() / 2, ScreenHeight() / 2);
				SeedSpawns(newActiveState.map);


				states[High(states)] := newActiveState;
			end;

		end
		else if newState = MenuState then
		begin
			// Menu state generic transition
			MenuInit(newActiveState);

			SetLength(states, Length(states) + 1);
			states[High(states)] := newActiveState;
		end
		else if newState = QuitState then
		begin
			// Generic quit transition
			FadeMusicOut(800);
			states[High(states)].quitRequested := true;
		end
		else
		begin
			WriteLn('Invalid state');
		end;

	end;

end.
