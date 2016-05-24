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
	uses SwinGame, NPC, SysUtils;

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


		// Left edge of the map
		if CameraX() < (ScreenWidth() / 2) + halfSprite then
		begin
			offsetX := ( ScreenWidth() - SpriteX(map.player.sprite) ) / 2;
		end;
		//Right edge of map
		if ( SpriteX(map.player.sprite) + (ScreenWidth() / 2) ) > mapSizeToPixel then
		begin
			offsetX := -( (ScreenWidth() / 2) - rightEdgeDistance);
		end;
		// Top edge of map
		if CameraY() < (ScreenHeight() / 2) + halfSprite then
		begin
			offsetY := ( ScreenHeight() - SpriteY(map.player.sprite) ) / 2;
		end;
		// Bottom edge of map
		if ( SpriteY(map.player.sprite) + (ScreenHeight() / 2) ) > mapSizeToPixel then
		begin
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
		newState.map.player.hunger := 100;
		newState.map.player.attackTimeout := 0;
		newState.map.player.maxAttackSpeed := 10;
		WriteLn(newState.map.player.maxAttackSpeed:0:4);

		newState.map.inventory := InitInventory();

		// Setup player sprite and animation
		newState.map.player.sprite := CreateSprite('player', BitmapNamed('player'), AnimationScriptNamed('player'));
		//SpriteSetCollisionBitmap(newState.map.player.sprite, BitmapNamed('player_collision'));
		SwitchAnimation(newState.map.player.sprite, 'entity_down_idle');

		//
		//	Search for the first sand tile without a feature on it,
		//	thus spawning the player on a beach
		//
		spawnFound := false;
		for i := 0 to High(newState.map.tiles) do
		begin
			if spawnFound then
				break;

			for j := 0 to High(newState.map.tiles) do
			begin
				if spawnFound then
					break;

				if (i > 1) and (newState.map.tiles[i, j].flag = Sand) and (newState.map.tiles[i, j].feature = None) then
				begin
					SpriteSetX(newState.map.player.sprite, i * 32);
					SpriteSetY(newState.map.player.sprite, j * 32);
					spawnFound := true;
				end;
			end;
		end;

		CenterCameraOn(newState.map.player.sprite, ScreenWidth() / 2, ScreenHeight() / 2);
	end;

	procedure LevelHandleInput(var thisState: ActiveState; var inputs: InputMap);
	var
		isPickup: Boolean;
	begin
		isPickup := false;

		if KeyTyped(inputs.Select) then
		begin
			isPickup := true;
		end;

		if KeyTyped(inputs.Menu) then
		begin
			PlaySoundEffect(SoundEffectNamed('confirm'), 0.5);
			StateChange(thisState.manager^, MenuState);
		end;

		if thisState.map.player.attackTimeout = 0 then
		begin
			if KeyDown(inputs.MoveUp) then
			begin
				MoveEntity(thisState.map, thisState.map.player, DirUp, 3, isPickup);
			end
			else if KeyDown(inputs.MoveRight) then
			begin
				MoveEntity(thisState.map, thisState.map.player, DirRight, 3, isPickup);
			end
			else if KeyDown(inputs.MoveDown) then
			begin
				MoveEntity(thisState.map, thisState.map.player, DirDown, 3, isPickup);
			end
			else if KeyDown(inputs.MoveLeft) then
			begin
				MoveEntity(thisState.map, thisState.map.player, DirLeft, 3, isPickup);
			end
			else
			begin
				//
				//	Move with 0 speed based off previously assigned direction
				//	(i.e. whatever way the player was facing last)
				//
				MoveEntity(thisState.map, thisState.map.player, thisState.map.player.direction, 0, isPickup);
			end;
		end;

		if KeyTyped(inputs.Attack) then
		begin
			PlaySoundEffect(SoundEffectNamed('throw'), 0.5);
			MoveEntity(thisState.map, thisState.map.player, thisState.map.player.direction, 0, isPickup);
			case thisState.map.player.direction of
				DirUp: SwitchAnimation(thisState.map.player.sprite, 'entity_up_attack');
				DirRight: SwitchAnimation(thisState.map.player.sprite, 'entity_right_attack');
				DirDown: SwitchAnimation(thisState.map.player.sprite, 'entity_down_attack');
				DirLeft: SwitchAnimation(thisState.map.player.sprite, 'entity_left_attack');
			end;
			thisState.map.player.attackTimeout := thisState.map.player.maxAttackSpeed;
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

		thisState.map.player.hunger -= 0.01;
		if thisState.map.player.hunger < 0 then
		begin
			thisState.map.player.hunger := 0;
			thisState.map.player.hp -= 0.05;
		end;

		if thisState.map.player.hp <= 0 then
		begin
			PlaySoundEffect(SoundEffectNamed('confirm'), 0.5);
			StateChange(thisState.manager^, TitleState);
		end;

	end;

	procedure DrawHUD(var player: Entity; dollars: Double);
	var
		emptyWidth, emptyHeight: Single;
		dollarStr: String;
	begin
		emptyWidth := BitmapWidth(BitmapNamed('empty bar'));
		emptyHeight := BitmapHeight(BitmapNamed('empty bar'));
		dollarStr := FloatToStr(dollars);
		// Handle health, hunger, and money UI elements
		DrawBitmap(BitmapNamed('empty bar'), CameraX() + 10, CameraY() + 10);
		FillRectangle(RGBAColor(224, 51, 51, 150), CameraX() + 10, CameraY() + 10, (player.hp / 100) * emptyWidth, emptyHeight);

		DrawBitmap(BitmapNamed('empty bar'), CameraX() + 10, CameraY() + 40);
		FillRectangle(RGBAColor(99, 203, 97, 150), CameraX() + 10, CameraY() + 40, (player.hunger / 100) * emptyWidth, emptyHeight);

		DrawBitmap(BitmapNamed('dollars'), CameraX() + 10, CameraY() + 75);
		DrawText(dollarStr, ColorWhite, FontNamed('PrStartSmall'), CameraX() + BitmapWidth(BitmapNamed('dollars')) + 15, CameraY() + 85);
	end;

	procedure LevelDraw(var thisState: ActiveState);
	var
		x, y: LongInt;
		currentTileView: TileView;
	begin
		currentTileView := CreateTileView();

		for x := currentTileView.x to currentTileView.right do
		begin
			for y := currentTileView.y to currentTileView.bottom do
			begin
				// Only draw tile if y and x index are within map bounds
				if IsInMap(thisState.map, x, y) then
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

		DrawHUD(thisState.map.player, thisState.map.inventory.dollars);
	end;

end.
