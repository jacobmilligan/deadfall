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
	// Initializes the playing map state, using 
	// a new active state
	//
	procedure LevelInit(var newState: ActiveState);

	//
	// Handles input from the player, moving and taking actions 
	// on the current map. Checks collision on tiles and the edge
	// of the screen.
	//
	procedure LevelHandleInput(core: GameCore);

	//
	// Moves the camera, checks camera collision, and is responsible
	// for updating and calculating enemy actions within the game
	//
	procedure LevelUpdate(core: GameCore);

	//
	// Draws the area of the current map that's 
	procedure LevelDraw(core: GameCore);


implementation
	uses Map, SwinGame;

	procedure LevelInit(var newState: ActiveState);
	var
		i, j: Integer;
		spawnFound: Boolean;
	begin
		// Assign functions for state
		newState.HandleInput := @LevelHandleInput;
		newState.Update := @LevelUpdate;
		newState.Draw := @LevelDraw;

		// Generate a new map with the passed-in size
		newState.currentMap := GenerateNewMap(257);
		newState.currentMap.player.hp := 100;

		//		
		newState.currentMap.player.sprite := CreateSprite(BitmapNamed('eng'), AnimationScriptNamed('player'));
		SpriteStartAnimation(newState.currentMap.player.sprite, 'player_up');

		spawnFound := false;
		i := 0;
		while ( i < High(newState.currentMap.tiles) ) and not spawnFound do
		begin

			j := 0;
			while j < High(newState.currentMap.tiles) do
			begin
				if (i > 1) and (newState.currentMap.tiles[i, j].flag = Sand) and (newState.currentMap.tiles[i, j].feature = None) then
				begin
					SpriteSetX(newState.currentMap.player.sprite, i * 32);
					SpriteSetY(newState.currentMap.player.sprite, j * 32);
					spawnFound := true;
				end;
				j += 1;
			end;

			i += 1;
		end;

		CenterCameraOn(newState.currentMap.player.sprite, ScreenWidth() / 2, ScreenHeight() / 2);
	end;

	procedure LevelHandleInput(core: GameCore);
	const
		SPEED = 2;
	var
		map: MapPtr;
		velocity: Vector;
		dir: Direction;
	begin
		map := @core^.states[High(core^.states)].currentMap;
		
		velocity.x := 0;
		velocity.y := 0;

		if KeyDown(RightKey) then 
		begin
			map^.player.direction := Right;
			velocity.x += 2 * SPEED;
			if not (SpriteAnimationName(map^.player.sprite) = 'player_right') then
			begin
				SpriteStartAnimation(map^.player.sprite, 'player_right');
			end;
		end
		else if KeyDown(LeftKey) then 
		begin
			map^.player.direction := Left;
			velocity.x -= 2 * SPEED;
			if not (SpriteAnimationName(map^.player.sprite) = 'player_left') then
			begin
				SpriteStartAnimation(map^.player.sprite, 'player_left');
			end;
		end
		else if KeyDown(UpKey) then 
		begin
			map^.player.direction := Up;
			velocity.y -= 2 * SPEED;
			if not (SpriteAnimationName(map^.player.sprite) = 'player_up') then
			begin
				SpriteStartAnimation(map^.player.sprite, 'player_up');
			end;
		end
		else if KeyDown(DownKey) then 
		begin
			map^.player.direction := Down;
			velocity.y += 2 * SPEED;
			if not (SpriteAnimationName(map^.player.sprite) = 'player_down') then
			begin
				SpriteStartAnimation(map^.player.sprite, 'player_down');
			end;
		end;
		
		SpriteSetDX(map^.player.sprite, velocity.x);
		SpriteSetDY(map^.player.sprite, velocity.y);
		
		CheckCollision(map^, map^.player.sprite, map^.player.direction);	
		
		UpdateSprite(map^.player.sprite);
	end;
	
	procedure UpdateCamera(map: MapPtr);
	var
		offsetX, offsetY, rightEdgeDistance, bottomEdgeDistance: Single;
		mapSizeToPixel, halfSprite: Integer;
	begin
	 	offsetX := 0;
		offsetY := 0;
		mapSizeToPixel := High(map^.tiles) * 32;
		rightEdgeDistance := mapSizeToPixel - SpriteX(map^.player.sprite);
		bottomEdgeDistance := mapSizeToPixel - SpriteY(map^.player.sprite);
		halfSprite := Round(SpriteWidth(map^.player.sprite) / 2);

		if CameraX() < (ScreenWidth() / 2) + halfSprite then
		begin
			offsetX := ( ScreenWidth() - SpriteX(map^.player.sprite) ) / 2;
		end;
		if ( SpriteX(map^.player.sprite) + (ScreenWidth() / 2) ) > mapSizeToPixel then
		begin
			offsetX := -( (ScreenWidth() / 2) - rightEdgeDistance);
		end;
		if CameraY() < (ScreenHeight() / 2) + halfSprite then
		begin
			offsetY := ( ScreenHeight() - SpriteY(map^.player.sprite) ) / 2;
		end;
		if ( SpriteY(map^.player.sprite) + (ScreenHeight() / 2) ) > mapSizeToPixel then
		begin
			offsetY := -( (ScreenHeight() / 2) - bottomEdgeDistance);
		end;

		CenterCameraOn(map^.player.sprite, offsetX, offsetY);
	end;		

	procedure LevelUpdate(core: GameCore);
	begin
		UpdateCamera(@core^.states[High(core^.states)].currentMap);
	end;

	procedure LevelDraw(core: GameCore);
	var
		x, y: Integer;
		tileScreenWidth, tileScreenHeight: Integer;
		map: MapPtr;  
		barRect: Rectangle;
	const
		X_TEST = 100;
		Y_TEST = 100;
	begin
		map := @core^.states[High(core^.states)].currentMap;
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

						if map^.tiles[x, y].feature = Tree then
						begin
							if (map^.tiles[x, y].flag = Grass) then
							begin
								DrawBitmap(BitmapNamed('tree'), x * 32, y * 32);
							end
							else if (map^.tiles[x, y].flag = Sand) then
							begin
								DrawBitmap(BitmapNamed('palm tree'), x * 32, y * 32);
							end
							else if (map^.tiles[x, y].flag > Grass) and (map^.tiles[x, y].flag < SnowyGrass) then
							begin
								DrawBitmap(BitmapNamed('pine tree'), x * 32, y * 32);
							end
							else
							begin
							  	DrawBitmap(BitmapNamed('snowy tree'), x * 32, y * 32);
							end;
						end;
					end;

				end;

			end;
			
		end;

		DrawSprite(map^.player.sprite);

		barRect := RectangleFrom(0, 0, map^.player.hp, 32);

		DrawBitmap(BitmapNamed('empty bar'), CameraX() + 10, CameraY() + 10);
		FillRectangle(RGBAColor(224, 51, 51, 150), CameraX() + 15, CameraY() + 15, (map^.player.hp * 2) - 8, 23);

	end;

end.
