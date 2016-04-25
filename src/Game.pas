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
	uses State;

	//
	// Opens graphics window and sets up game core & resources
	//
	procedure GameInit(caption: String; x, y: Integer; var core: GameCore);

	//
	// Updates the game, calling the current game_state's Update & HandleInput function
	// pointers as well, delegating responsibility to the state for non-game-scope tasks
	//
	procedure GameUpdate(var core: GameCore);

	//
	// Updates the game, calling the current game_state's own draw function
	// as well, delegating responsibility for drawing state-local objects (sprites, shapes etc.)
	//
	procedure GameDraw(var core: GameCore);

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
		LoadBitmapNamed('palm tree', 'palm_tree.png');

		LoadBitmapNamed('player', 'player.png');

		LoadBitmapNamed('empty bar', 'empty_bar.png');
		LoadBitmapNamed('health bar', 'health_bar.png');
	end;

	procedure GameInit(caption: String; x, y: Integer; var core: GameCore);
	begin
		OpenGraphicsWindow(caption, x, y);

		core.active := true; // game is active now
		core.deltaTime := 0;

		SetLength(core.stateManager^.states, 0);

		core.playerStats.HP := 100;

		StateChange(core.stateManager, LevelState);
	end;

	procedure GameUpdate(var core: GameCore);
	begin

		ProcessEvents();

		if WindowCloseRequested() then
		begin
			core.active := false;
		end
		else
		begin
			// Current state handles input
			core.stateManager^.states[High(core.stateManager^.states)].HandleInput(core);

			// Current state updates the game
			core.stateManager^.states[High(core.stateManager^.states)].Update(core);
		end;
	end;

	procedure GameDraw(var core: GameCore);
	begin
		ClearScreen(ColorBlack);
		
		// Current state draws itself to the window
		core.stateManager^.states[High(core.stateManager^.states)].Draw(core);
		
		RefreshScreen(60);
	end;



end.
