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

		LoadBitmapNamed('player', 'player.png');
	end;

	procedure GameInit(caption: String; x, y: Integer; var core: GameCore);
	begin
		OpenGraphicsWindow(caption, x, y);

		core.active := true;
		core.deltaTime := 0;

		SetLength(core.stateManager^.states, 0);

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
			core.stateManager^.states[High(core.stateManager^.states)].HandleInput(core);
			core.stateManager^.states[High(core.stateManager^.states)].Update(core);
		end;
	end;

	procedure GameDraw(var core: GameCore);
	begin
		ClearScreen(ColorBlack);
		
		core.stateManager^.states[High(core.stateManager^.states)].Draw(core);
		
		RefreshScreen(60);
	end;



end.
