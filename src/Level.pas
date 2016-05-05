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
	uses sgTypes, State, Map, Input;
	
	//
	//	Updates the camera position relative to the players
	//	position. Moves the offset according to how close the player
	//	is to the edge of the map, ensuring the player never sees outside
	//	the map bounds.
	//
	procedure UpdateCamera(constref map: MapData);
	
	//
	//	Initializes the playing map state, using 
	//	a new active state
	//
	procedure LevelInit(var newState: ActiveState);

	//
	//	Handles input from the player, moving and taking actions 
	//	on the current map. Checks collision on tiles and the edge
	//	of the screen.
	//
	procedure LevelHandleInput(var thisState: ActiveState; var inputs: InputMap);

	//
	//	Moves the camera, checks camera collision, and is responsible
	//	for updating and calculating enemy actions within the game
	//
	procedure LevelUpdate(var thisState: ActiveState);

	//
	// 	Draws only the area of the current map that's within the bounds
	//	of the camera
	//
	procedure LevelDraw(var thisState: ActiveState);


implementation
	uses SwinGame, NPC;
	
	procedure UpdateCamera(constref map: MapData);
	var
		offsetX, offsetY, rightEdgeDistance, bottomEdgeDistance: Single;
		mapSizeToPixel, halfSprite: Integer;
	begin
		mapSizeToPixel := High(map.tiles) * 32;
		rightEdgeDistance := mapSizeToPixel - SpriteX(map.player.sprite);
		bottomEdgeDistance := mapSizeToPixel - SpriteY(map.player.sprite);
		halfSprite := Round(SpriteWidth(map.player.sprite) / 2);
		
		offsetX := 0;
		offsetY := 0;

		if CameraX() < (ScreenWidth() / 2) + halfSprite then
		begin
			// Left edge of the map
			offsetX := ( ScreenWidth() - SpriteX(map.player.sprite) ) / 2;
		end;
		if ( SpriteX(map.player.sprite) + (ScreenWidth() / 2) ) > mapSizeToPixel then
		begin
			// Right edge of map
			offsetX := -( (ScreenWidth() / 2) - rightEdgeDistance);
		end;
		if CameraY() < (ScreenHeight() / 2) + halfSprite then
		begin
			// Top edge of map
			offsetY := ( ScreenHeight() - SpriteY(map.player.sprite) ) / 2;
		end;
		if ( SpriteY(map.player.sprite) + (ScreenHeight() / 2) ) > mapSizeToPixel then
		begin
			// Bottom edge of map
			offsetY := -( (ScreenHeight() / 2) - bottomEdgeDistance);
		end;

		CenterCameraOn(map.player.sprite, offsetX, offsetY);
	end;

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
		newState.map := GenerateNewMap(513);
		
		// Setup player stats
		newState.map.player.hp := 100;
		newState.map.player.attackTimeout := 0;
		SetLength(newState.map.inventory, 0);

		// Setup player sprite and animation
		newState.map.player.sprite := CreateSprite('player', BitmapNamed('eng'), AnimationScriptNamed('player'));
		SwitchAnimation(newState.map.player.sprite, 'entity_down_idle');
		
		//
		//	Search for the first sand tile without a feature on it,
		//	thus spawning the player on a beach
		//
		spawnFound := false;
		i := 0;
		while ( i < High(newState.map.tiles) ) and not spawnFound do
		begin

			j := 0;
			while j < High(newState.map.tiles) do
			begin
				if (i > 1) and (newState.map.tiles[i, j].flag = Sand) and (newState.map.tiles[i, j].feature = None) then
				begin
					SpriteSetX(newState.map.player.sprite, i * 32);
					SpriteSetY(newState.map.player.sprite, j * 32);
					spawnFound := true;
				end;
				j += 1;
			end;

			i += 1;
		end;

		CenterCameraOn(newState.map.player.sprite, ScreenWidth() / 2, ScreenHeight() / 2);
	end;

	procedure LevelHandleInput(var thisState: ActiveState; var inputs: InputMap);
	begin
		
		if KeyDown(inputs.Menu) then
		begin
			StateChange(thisState.manager^, MenuState);
		end;
		
		if KeyDown(inputs.MoveUp) then 
		begin
			MoveEntity(thisState.map, thisState.map.player, Up, 3);
		end
		else if KeyDown(inputs.MoveRight) then 
		begin
			MoveEntity(thisState.map, thisState.map.player, Right, 3);
		end
		else if KeyDown(inputs.MoveDown) then 
		begin
			MoveEntity(thisState.map, thisState.map.player, Down, 3);
		end
		else if KeyDown(inputs.MoveLeft) then 
		begin
			MoveEntity(thisState.map, thisState.map.player, Left, 3);
		end
		else
		begin
			//
			//	Move with 0 speed based off previously assigned direction 
			//	(i.e. whatever way the player was facing last)
			//
			MoveEntity(thisState.map, thisState.map.player, thisState.map.player.direction, 0);
		end;
		
		if KeyDown(inputs.Attack) then
		begin
			thisState.map.player.attackTimeout := 3;
		end;
	end;		

	procedure LevelUpdate(var thisState: ActiveState);
	var
		i: Integer;
	begin
		if thisState.map.player.attackTimeout > 0 then
		begin
			thisState.map.player.attackTimeout -= 1;
		end;
		
		UpdateCamera(thisState.map);
		UpdateSpawns(thisState.map);
		UpdateNPCS(thisState.map);
		UpdateSprite(thisState.map.player.sprite);      
	end;

	procedure LevelDraw(var thisState: ActiveState);
	var
		x, y: LongInt;
		tileScreenWidth, tileScreenHeight: Integer;
		barRect: Rectangle;
		currentTileView: TileView;
	const
		X_TEST = 100;
		Y_TEST = 100;
	begin
		
		// Translate pixel values into tilemap values
		tileScreenWidth := Round(ScreenWidth() / 32);
		tileScreenHeight := Round(ScreenHeight() / 32);
		x := Round(CameraPos.x / 32);
		y := Round(CameraPos.y / 32);
		
		currentTileView := CreateTileView();
		
		for x := currentTileView.x to currentTileView.right do
		begin
			for y := currentTileView.y to currentTileView.bottom do
			begin
				// Only draw tile if y and x index are within map bounds
				if not OutOfBounds(thisState.map.tiles, x, y) then
				begin
					DrawTile(thisState.map.tiles[x, y], x * 32, y * 32);
				end;
			end;
		end;

		DrawSprite(thisState.map.player.sprite);
		
		for x := 0 to High(thisState.map.npcs) do
        begin
            DrawSprite(thisState.map.npcs[x].sprite);
        end;
		
		// Handle health, hunger, and money UI elements
		DrawBitmap(BitmapNamed('empty bar'), CameraX() + 10, CameraY() + 10);
		FillRectangle(RGBAColor(224, 51, 51, 150), CameraX() + 15, CameraY() + 15, Round(thisState.map.player.hp * 2) - 8, 23);
	end;

end.
