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
	procedure LevelInit(var newState: ActiveState);

	procedure LevelHandleInput(var core: GameCore);

	procedure LevelUpdate(var core: GameCore);

	procedure LevelDraw(var core: GameCore);


implementation
	uses Map, SwinGame, Math;

	procedure LevelInit(var newState: ActiveState);
	var
		i, j: Integer;
		spawnFound: Boolean;
	begin
		newState.HandleInput := @LevelHandleInput;
		newState.Update := @LevelUpdate;
		newState.Draw := @LevelDraw;

		newState.currentMap := GenerateNewMap(2049);
		newState.currentMap.player := CreateSprite(LoadBitmapNamed('player', 'player.png'));


		spawnFound := false;
		i := 0;
		while ( i < High(newState.currentMap.tiles) ) and not spawnFound do
		begin

			j := 0;
			while j < High(newState.currentMap.tiles) do
			begin
				if newState.currentMap.tiles[i, j].flag = Sand then
				begin
					SpriteSetX(newState.currentMap.player, (i + 1) * 32);
					SpriteSetY(newState.currentMap.player, (j - 1) * 32);
					spawnFound := true;
				end;
				j += 1;
			end;

			i += 1;
		end;

		MoveCameraTo(100, 100);
	end;

	procedure LevelHandleInput(var core: GameCore);
	const
		SPEED = 2;
	var
		map: MapPtr;
		velocity: Vector; 
	begin
		map := @core.stateManager^.states[High(core.stateManager^.states)].currentMap;
		
		velocity.x := 0;
		velocity.y := 0;

		if KeyDown(RightKey) and not HasCollision(map^, SpriteX(map^.player) + 16, SpriteY(map^.player)) then 
		begin
			velocity.x += 2 * SPEED;
		end;
		if KeyDown(LeftKey) and not HasCollision(map^, SpriteX(map^.player) - 16, SpriteY(map^.player)) then 
		begin
			velocity.x -= 2 * SPEED;
		end;
		if KeyDown(UpKey) and not HasCollision(map^, SpriteX(map^.player), SpriteY(map^.player) - 16) then 
		begin
			velocity.y -= 2 * SPEED;
		end;
		if KeyDown(DownKey) and not HasCollision(map^, SpriteX(map^.player), SpriteY(map^.player) + 16) then 
		begin
			velocity.y += 2 * SPEED;
		end;

		SpriteSetDX(map^.player, velocity.x);
		SpriteSetDY(map^.player, velocity.y);

		MoveSprite(map^.player);
	end;

	procedure LevelUpdate(var core: GameCore);
	begin
		CenterCameraOn(core.stateManager^.states[High(core.stateManager^.states)].currentMap.player, 0, 0);
	end;

	procedure LevelDraw(var core: GameCore);
	var
		x, y: Integer;
		tileScreenWidth, tileScreenHeight: Integer;
		map: MapPtr;  
	const
		X_TEST = 100;
		Y_TEST = 100;
	begin
		map := @core.stateManager^.states[High(core.stateManager^.states)].currentMap;
		tileScreenWidth := Round(ScreenWidth() / 32);
		tileScreenHeight := Round(ScreenHeight() / 32);

		x := Round(CameraPos.x / 32);
		y := Round(CameraPos.y / 32);

		for x := Round(CameraPos.x / 32) - 1 to Round( (CameraPos.x / 32) + tileScreenWidth ) do
		begin
			if ( x >= 0 ) and ( x < Length(map^.tiles) ) then
			begin
				for y := Round(CameraPos.y / 32) - 1 to Round((CameraPos.y / 32) + tileScreenHeight) do
				begin
					if ( y >= 0 ) and ( y < Length(map^.tiles) ) then
					begin
						DrawBitmap(map^.tiles[x, y].bmp, x * 32, y * 32);
					end;
				end;
			end;
		end;

		DrawSprite(map^.player);

	end;

end.
