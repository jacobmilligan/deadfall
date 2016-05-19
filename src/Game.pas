//
//  Deadfall v1.0
//  Game.pas
//
// -------------------------------------------------------
//
//  Created By Jacob Milligan
//  On 21/04/2016
//  Student ID: 100660682
//

unit Game;

interface
	uses State, Input;

	//
	// Opens graphics window and sets up game core & resources
	//
	procedure GameInit(caption: String; width, height: Integer; var states: StateArray);

	//
	// Updates the game, calling the current game_state's Update & HandleInput function
	// pointers as well, delegating responsibility to the state for non-game-scope tasks
	//
	procedure GameUpdate(var states: StateArray; var inputs: InputMap);

	//
	// Updates the game, calling the current game_state's own draw function
	// as well, delegating responsibility for drawing state-local objects (sprites, shapes etc.)
	//
	procedure GameDraw(var states: StateArray);

	procedure RequestQuit(var states: StateArray);

	procedure QuitGame(var states: StateArray);

	//
	// Loads all resources needed by the game
	//
	procedure LoadResources();


implementation
	uses Swingame;

	procedure LoadResources();
	begin
		LoadBitmapNamed('water', 'water.png');
		LoadBitmapNamed('dark water', 'dark_water.png');
		LoadBitmapNamed('dirt', 'dirt.png');
		LoadBitmapNamed('grass', 'grass.png');
		LoadBitmapNamed('dark grass', 'dark_grass.png');
		LoadBitmapNamed('darkest grass', 'super_dark_grass.png');
		LoadBitmapNamed('sand', 'sand.png');
		LoadBitmapNamed('mountain', 'mountain.png');
		LoadBitmapNamed('snowy grass', 'snowy_grass.png');
		LoadBitmapNamed('tree', 'tree.png');
		LoadBitmapNamed('pine tree', 'pine_tree.png');
		LoadBitmapNamed('palm tree', 'palm_tree.png');
		LoadBitmapNamed('snowy tree', 'snowy_tree.png');

		LoadBitmapNamed('meat', 'meat.png');

		LoadBitmapNamed('empty bar', 'empty_bar.png');
		LoadBitmapNamed('health bar', 'health_bar.png');

		LoadResourceBundle('md.txt');
	end;

	procedure GameInit(caption: String; width, height: Integer; var states: StateArray);
	begin
		OpenGraphicsWindow(caption, width, height);

		LoadResources();

		SetLength(states, 0);
		StateChange(states, TitleState);
	end;

	procedure GameUpdate(var states: StateArray; var inputs: InputMap);
	begin

		ProcessEvents();

		if Length(states) > 0 then
		begin
			// Current state handles input
			states[High(states)].HandleInput(states[High(states)], inputs);

			// Current state updates the game
			states[High(states)].Update(states[High(states)]);
		end;

	end;

	procedure GameDraw(var states: StateArray);
	begin
		if Length(states) > 0 then
		begin
			ClearScreen(ColorBlack);

			// Current state draws itself to the window
			states[High(states)].Draw(states[High(states)]);

			RefreshScreen(60);
		end;
	end;

	procedure RequestQuit(var states: StateArray);
	begin
		states[High(states)].quitRequested := true;
	end;

	procedure QuitGame(var states: StateArray);
	var
		i, j: Integer;
	begin
		ReleaseAllResources();
	end;

end.
