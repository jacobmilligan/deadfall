//
//  Deadfall v1.0
//  Level.pas
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

	type
		Buyer = record
			itemToBuy: Item;
			itemInterest: Single;
		end;

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
	procedure LevelInit(var newState: ActiveState; constref mapSettings: MapData);

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

	procedure LevelInit(var newState: ActiveState; constref mapSettings: MapData);
	var
		i, j: Integer;
		spawnFound: Boolean;
	begin
		//WriteLn(mapSettings.size, ', ', mapSettings.smoothness, ', ', mapSettings.maxHeight);
		// Assign functions for state
		newState.HandleInput := @LevelHandleInput;
		newState.Update := @LevelUpdate;
		newState.Draw := @LevelDraw;

		// Generate a new map with the passed-in size
		newState.map := GenerateNewMap(mapSettings.size, mapSettings.smoothness, mapSettings.maxHeight, mapSettings.seed);
		newState.map.blank := false;

		// Setup player stats
		newState.map.player.hp := 100;
		newState.map.player.hunger := 100;
		newState.map.player.attackTimeout := 0;
		newState.map.player.maxAttackSpeed := 10;

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

				if (i > 1) and (newState.map.tiles[i, j].flag = Sand) and (newState.map.tiles[i, j].feature = NoFeature) then
				begin
					SpriteSetX(newState.map.player.sprite, i * 32);
					SpriteSetY(newState.map.player.sprite, j * 32);
					spawnFound := true;
				end;
			end;
		end;

		CenterCameraOn(newState.map.player.sprite, ScreenWidth() / 2, ScreenHeight() / 2);
		SeedSpawns(newState.map);
	end;

	procedure LevelHandleInput(var thisState: ActiveState; var inputs: InputMap);
	var
		isPickup: Boolean;
		speed: Integer;
	begin
		isPickup := false;

		// Do pickup calculations if the player presses select
		if KeyTyped(inputs.Select) then
		begin
			isPickup := true;
		end;

		// Go to menu
		if KeyTyped(inputs.Menu) then
		begin
			PlaySoundEffect(SoundEffectNamed('confirm'), 0.5);
			StateChange(thisState.manager^, MenuState);
		end;

		// Move the player if they're not attacking
		if thisState.map.player.attackTimeout = 0 then
		begin
			speed := 3;
			
			if KeyDown(inputs.Special) then
			begin
				speed := 6;
			end;

			if KeyDown(inputs.MoveUp) then
			begin
				MoveEntity(thisState.map, thisState.map.player, DirUp, speed, isPickup);
			end
			else if KeyDown(inputs.MoveRight) then
			begin
				MoveEntity(thisState.map, thisState.map.player, DirRight, speed, isPickup);
			end
			else if KeyDown(inputs.MoveDown) then
			begin
				MoveEntity(thisState.map, thisState.map.player, DirDown, speed, isPickup);
			end
			else if KeyDown(inputs.MoveLeft) then
			begin
				MoveEntity(thisState.map, thisState.map.player, DirLeft, speed, isPickup);
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

		// Do attack calculations based on the players facing direction
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

	procedure UpdateListings(var items: ItemArray; var dollars: Single);
	var
		newBuyer: Buyer;
		i, listedAmt, randItemIndex: Integer;
		deltaDollarValue: Single;
	begin
		// Do buyer calculations for each item in the inventory
		for i := 0 to High(items) do
		begin
			if Random(1000) > 997 then
			begin
				// Change the demand of a given item alongside its adjusted dollar values
				deltaDollarValue := items[i].adjustedDollarValue;
				items[i].demand := (Random() / 2) + items[i].rarity;
				if items[i].demand > 1 then
				begin
					items[i].demand := 1;
				end;
				items[i].adjustedDollarValue := items[i].dollarValue * items[i].demand;
				items[i].deltaDollarValue := items[i].adjustedDollarValue - deltaDollarValue;
			end;

			//
			if items[i].listed = 0 then
			begin
				listedAmt := 1;
			end
			else
			begin
				listedAmt := items[i].listed;
			end;

			randItemIndex := Random(Length(items)); // Get a random item from the inventory
			// Set new buyers stats
			newBuyer.itemToBuy := items[randItemIndex];
			newBuyer.itemInterest := Random() * newBuyer.itemToBuy.demand;

			if newBuyer.itemInterest > 1 then
			begin
				newBuyer.itemInterest := 1;
			end;

			// The buyer is interested in the current iterated item
			if ( items[i].name = newBuyer.itemToBuy.name ) and ( newBuyer.itemInterest >= 0.4 ) then
			begin
				// Buyers will only buy an item if random is high enough and an item is listed
				if (items[i].listed > 0) and (Random() > 0.9) then
				begin
					PlaySoundEffect(SoundEffectNamed('buy'), 0.5);
					items[i].listed -= 1;
					if items[i].listed < 0 then
					begin
						items[i].listed := 0;
					end;

					// Generate a random caret and adjust price based off that
					if items[i].name = 'Diamond' then
					begin
						dollars += items[i].adjustedDollarValue * Random();
					end
					else
					begin
						dollars += items[i].adjustedDollarValue;
					end;
				end;

			end;

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

		// Decreases the players hunger and hp each tick
		thisState.map.player.hunger -= 0.02;
		if thisState.map.player.hunger < 0 then
		begin
			thisState.map.player.hunger := 0;
			thisState.map.player.hp -= 0.05;
		end;

		// Kill the player
		if thisState.map.player.hp <= 0 then
		begin
			thisState.map.player.hp := 0;
			PlaySoundEffect(SoundEffectNamed('confirm'), 0.5);
			StateChange(thisState.manager^, TitleState);
		end;

		UpdateListings(thisState.map.inventory.items, thisState.map.inventory.dollars);

	end;

	procedure DrawHUD(var player: Entity; dollars: Double);
	var
		emptyWidth, emptyHeight: Single;
		dollarStr: String;
	begin
		emptyWidth := BitmapWidth(BitmapNamed('empty bar'));
		emptyHeight := BitmapHeight(BitmapNamed('empty bar'));
		dollarStr := FloatToStrF(dollars, ffFixed, 8, 2);
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

		// Only draw tiles that are visible in the current tile view
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

		// Draw all NPC's to the map
		for x := 0 to High(thisState.map.npcs) do
    begin
        DrawSprite(thisState.map.npcs[x].sprite);
    end;

		DrawHUD(thisState.map.player, thisState.map.inventory.dollars);
	end;

end.
