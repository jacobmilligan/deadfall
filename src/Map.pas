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

unit Map;

interface
	uses sgTypes;

	type

		//
		//	Valid entity directions on the map. Used in movement and
		//	collision detection
		//
		Direction = (DirUp, DirRight, DirDown, DirLeft);

		//
		//	Valid tile types for building maps with.
		//	Used as a terrain flag for different logic.
		//
		TileType = (Water, Sand, Dirt, Grass, MediumGrass, HighGrass, SnowyGrass, Mountain);

		//
		//	Represents a feature on top of a tile that can have a bitmap,
		//	collision, and be interactive
		//
		FeatureType = (NoFeature, Tree, Food, Treasure, MediumTreasure, RareTreasure);

		//
		//	Represents a defined item available to the player, each one is stored in the InventoryCollection
		//	and has hunger, health, dollar, rarity bonuses and a name. Can be attached to a UIElement via
		//	ItemPtr
		//
		Item = record
			category: FeatureType;
			hungerPlus: Single;
			healthPlus: Single;
			// Base dollar value
			dollarValue: Single;
			// Actual current dollar value based off market changes
			adjustedDollarValue: Single;
			demand: Single;
			rarity: Single;
			deltaDollarValue: Single;
			name: String;
			// How many the player has
			count: Integer;
			// How many the player has listed on the market
			listed: Integer;
		end;

		ItemArray = array of Item;

		ItemPtr = ^Item;

		// Represents the current inventory state - holds the players money amount
		InventoryCollection = record
			items: ItemArray;
			dollars: Single;
		end;

		//
		//	Represents a tile on the map - has a terrain flag,
		//	elevation and bitmap
		//
		Tile = record
			// terrain type
			flag: TileType;

			isOcean: Boolean;

			// type of feature if any
			feature: FeatureType;

			// uses collision detection
			collidable: Boolean;

			//
			//	Represents the tiles elevation - zero represents sea
			//	level.
			//
			elevation: Integer;

			// tiles base bitmap
			bmp: Bitmap;
			// bitmap for whatever feature is on top of the tiles
			featureBmp: Bitmap;
		end;

		//
		//	Array used to hold a a tilemap
		//
		TileGrid = array of array of Tile;

		//
		//	Any moving, interactive, collidable entity on the map
		//	that possesses some sort of action logic
		//
		Entity = record
			stuckCounter: Integer;
			sprite: Sprite;
			direction: Direction;
			currentGoal: Point2D;
			hp: Single;
			hunger: Single;
			nextUpdate: Single;
			attackTimeout: Single;
			maxAttackSpeed: Single;
		end;

		EntityCollection = array of Entity;

		//
		//	Main representation of a current level. Holds a tile grid.
		//
		MapData = record
			tiles: TileGrid;
			player: Entity;
			inventory: InventoryCollection;
			npcs: EntityCollection;
			blank: Boolean;
			size, smoothness, maxHeight, seed, maxSpawns: Integer;
		end;

		//
		//	Represents the current camera position in tile-based sizing, i.e.
		//	32px = a single tile.
		//
		TileView = record
			x, y, right, bottom: LongInt;
		end;

	//
	//	Takes a new 2D tile grid, sets the size to the passed in
	//	parameter, and initializes the elevation of each tile to zero.
	//
	procedure SetGridLength(var tiles: TileGrid; size: Integer);

	//
	//	Fills a MapData's TileGrid with generated heightmap data
	//	using the Diamond-Square fractal generation algorithm
	//	(for details, see: Computer Rendering of Stochastic Models - Alain Fournier et. al.).
	//	This heightmap data gets used later on to generate terrain realistically
	//
	function GenerateNewMap(size, smoothness, maxHeight: Integer; seed: Integer): MapData;

	//
	//	Checks if a given entity is about to collide with anything on the
	//	given map based off its projected delta movement
	//
	procedure CheckCollision(var map: MapData; var toCheck: Sprite; dir: Direction; var hasCollision: Boolean; pickup: Boolean);

	//
	//	Checks to see if a given point is out of the bounds of the passed in TileGrid. Returns
	//	true or false
	//
	function IsInMap(var map: MapData; x, y: Integer): Boolean;

	//
	//	Draws a given tiles bitmap and any features it contains to the screen.
	//
	procedure DrawTile(var currTile: Tile; x, y: Integer);

	//
	//	Creates a new TileView record from the view currently within the
	//	games camera bounds.
	//
	function CreateTileView(): TileView;

	//
	//	Sets up a feature on a given tile. Sets treasure or tree depending on FeatureType
	//
	procedure SetFeature(var tile: Tile; feature: FeatureType; collidable: Boolean);

	// Initializes the inventory with default types and values
	function InitInventory(): InventoryCollection;

	// Restores a players stat, handles error checking
	procedure RestoreStat(var stat: Single; plus: Single);

	// Increases players dollars and decreases item count
	procedure SellItem(var toSell: Item; var inventory: InventoryCollection);

implementation
	uses SwinGame, Game, Input, Math, SysUtils;

	const
		TILESIZE = 32;

	// Adds a new item to the inventory collection with default and passed in values
	function NewItem(name: String; hungerPlus, healthPlus, dollarValue, rarity: Single): Item;
	begin
		result.name := name;
		result.hungerPlus := hungerPlus;
		result.healthPlus := healthPlus;
		result.dollarValue := dollarValue;
		result.count := 0;
		result.listed := 0;
		result.rarity := rarity;
		result.demand := Random() * rarity;
		result.adjustedDollarValue := dollarValue * result.demand;
		result.deltaDollarValue := 0;
	end;

	function InitInventory(): InventoryCollection;
	var
		i: Integer;
	begin
		result.dollars := 0;

		SetLength(result.items, 5);

		// Add all available items to the collection
		result.items[0] := NewItem('Rabbit Leg', 7, 1, 5, 0.1);
		result.items[1] := NewItem('Bandage', 0, 10, 10, 0.2);
		result.items[2] := NewItem('Trinket', 1, -15, 30, 0.4);
		result.items[3] := NewItem('Silver', 1, -15, 50, 0.6);
		result.items[4] := NewItem('Diamond', 1, -30, 400, 0.85);

		// Sort the inventory based off ID
		QuickSort(result.items, 0, Length(result.items) - 1);
	end;

	procedure RestoreStat(var stat: Single; plus: Single);
	begin
		// Add limit to 100
		if stat + plus > 100 then
		begin
			stat := 100;
		end
		else
		begin
			stat += plus;
		end;
	end;

	procedure SellItem(var toSell: Item; var inventory: InventoryCollection);
	begin
		PlaySoundEffect(SoundEffectNamed('sell'), 0.5);
		toSell.listed += 1;
	end;

	function CreateTileView(): TileView;
	var
		x, y: Integer;
		width, height: LongInt;
		newView: TileView;
	begin
		// Translate camera view to tile-based values
		newView.x := Round(CameraPos.x / 32) - 1;
		newView.y := Round(CameraPos.y / 32) - 1;
		newView.right := Round( (CameraPos.x / 32) + (ScreenWidth() / 32) );
		newView.bottom := Round( (CameraPos.y / 32) + (ScreenHeight() / 32) );

		result := newView;
	end;

	procedure DrawTile(var currTile: Tile; x, y: Integer);
	begin
		// Draw base then feature
		DrawBitmap(currTile.bmp, x, y);
		DrawBitmap(currTile.featureBmp, x, y);
	end;

	procedure GetHeightMap(var map: MapData; maxHeight, smoothness: Integer);
	var
		x, y: Integer;
		midpointVal: Double;
		nextStep, cornerCount: Integer;
	begin
		x := 0;
		y := 0;
		midpointVal := 0;
		nextStep := Round(Length(map.tiles) / 2 ); // Center of the tile grid

		// Seed upper-left corner with random value
		map.tiles[x, y].elevation := -1500;

		// Initialize four corners of map with the same value as above
		while x < Length(map.tiles) do
		begin
			while y < Length(map.tiles) do
			begin
				map.tiles[x, y].elevation := map.tiles[0, 0].elevation;
				y += 2 * nextStep;
			end;

			x += 2 * nextStep;
			y := 0;
		end;

		x := 0;
		y := 0;

		//
		// Generate the rest of the heightmap now that the first square
		// has been generated. Keep iterating until the next step in the
		// grid is less than zero, i.e. the whole grid has been generated.
		//
		while nextStep > 0 do
		begin
			midpointVal := 0;

			//
			// Diamond step.
			// Check surrounding points in a diamond around a given midpoint, i.e.:
			//  	  x
			//  	x o x
			//   	  x
			// The circle represents the midpoint. Checks if they're within the bounds
			// of the map
			//
			x := nextStep;
			while x < Length(map.tiles) do
			begin

				y := nextStep;
				while y < Length(map.tiles) do
				begin

					//
					// Sum the surrounding points equidistant from the current
					// midpoint, checking in a diamond shape, then calculating their
					// average and adding a random amount less than the max elevation
					//
					midpointVal := map.tiles[x - nextStep, y - nextStep].elevation
								 + map.tiles[x - nextStep, y + nextStep].elevation
								 + map.tiles[x + nextStep, y - nextStep].elevation
								 + map.tiles[x + nextStep, y + nextStep].elevation;

					// Set midpoint to the average + Random value and multiply by smoothing factor
					map.tiles[x, y].elevation := Round( (midpointVal / 4) + (Random(maxHeight) * smoothness) );
					y += 2 * nextStep;
				end;

				x += 2 * nextStep;
				y := 0;
			end;

			//
			// Square step - from the midpoint of the previous square
			// sum the values of the corners, calculate their average
			// and add a random value less than the max elevation
			// to the total result to give the midpoint square an elevation.
			//
			x := 0;
			while x < Length(map.tiles) do
			begin

				y := nextStep * ( 1 - Round(x / nextStep) mod 2);
				while y < Length(map.tiles) do
				begin
					midpointVal := 0;
					cornerCount := 0;

					//
					// Sum surrounding points equidistant from the midpoint
					// in a square shape only if they're within the bounds
					// of the map.
					//
					if ( y - nextStep >= 0 ) then
					begin
						midpointVal += map.tiles[x, y - nextStep].elevation;
						cornerCount += 1;
					end;
					if ( x + nextStep < Length(map.tiles) ) then
					begin
						midpointVal += map.tiles[x + nextStep, y].elevation;
						cornerCount += 1;
					end;
					if ( y + nextStep < Length(map.tiles) ) then
					begin
						midpointVal += map.tiles[x, y + nextStep].elevation;
						cornerCount += 1;
					end;
					if ( x - nextStep >= 0 ) then
					begin
						midpointVal += map.tiles[x - nextStep, y].elevation;
						cornerCount += 1;
					end;

					//
					// If at least one corner is within the map bounds, calculate average plus
					// a random amount less than the map size.
					//
					if cornerCount > 0 then
					begin
						// Set midpoint to the average of corner amt + Random value and multiply by smoothing factor
						map.tiles[x, y].elevation := Round( (midpointVal / cornerCount) + Random(maxHeight) * smoothness );
					end;

					y += 2 * nextStep;
				end;

				x += nextStep;
			end;

			nextStep := Round(nextStep / 2); // Make the next space smaller

			//
			//	Increase smoothness for every iteration, allowing
			//	less difference in height the more iterations that are completed
			//
			smoothness := Round(smoothness / 2);
		end;
	end;

	procedure SetTile(var newTile: Tile; flag: TileType; bmp: String; collidable: Boolean);
	begin
		newTile.flag := flag;
		newTile.bmp := BitmapNamed(bmp);
		newTile.collidable := collidable;
	end;

	procedure GenerateTerrain(var map: MapData);
	var
		x, y: Integer;
	begin
		// Iterate all tiles and change their bitmap and data depending on their
		// pre-generated altitude
		for x := 0 to High(map.tiles) do
		begin
			for y := 0 to High(map.tiles) do
			begin

				// Setup the tiles
				case map.tiles[x, y].elevation of
					0..199: SetTile(map.tiles[x, y], Water, 'water', true);
					200..299: SetTile(map.tiles[x, y], Sand, 'sand', false);
					300..399: SetTile(map.tiles[x, y], Grass, 'grass', false);
					400..599: SetTile(map.tiles[x, y], MediumGrass, 'dark grass', false);
					600..799: SetTile(map.tiles[x, y], HighGrass, 'darkest grass', false);
					800..999: if Random(10) > 6 then
											SetTile(map.tiles[x, y], SnowyGrass, 'snowy grass', false)
										else
											SetTile(map.tiles[x, y], HighGrass, 'darkest grass', false);
					1000..1499: SetTile(map.tiles[x, y], SnowyGrass, 'snowy grass', false);
					else
						if map.tiles[x, y].elevation  < 0 then
							SetTile(map.tiles[x, y], Water, 'dark water', true)
						else
							SetTile(map.tiles[x, y], Mountain, 'mountain', true)
				end;

				// Used for drawing the pixels to a bitmap later - if isOcean is true
				// then the entire vertical line in the map is water and we don't need
				// to draw pixels
				if (map.tiles[x, y].flag <> Water) then
				begin
					map.tiles[x, 0].isOcean := false;
				end;

			end;
		end;
	end;

	function IsInMap(var map: MapData; x, y: Integer): Boolean;
	begin
		result := false;
		// Check map bounds
		if (x > 0) and (x < High(map.tiles)) and (y > 0) and (y < High(map.tiles)) then
		begin
			result := true;
		end;
	end;

	// Gets the amount of neighbouring trees to a specific tree
	function NeighbourCount(var map: MapData; x, y: Integer): Integer;
	var
		i, j, count: Integer;
	begin
		count := 0;
		// Search for neighbours
		for i := x - 1 to x + 1 do
		begin
			for j := y - 1 to y + 1 do
			begin

				if map.tiles[i, j].feature = Tree then
				begin
					count += 1;
				end;

			end;
		end;

		result := count;
	end;

	procedure SetFeature(var tile: Tile; feature: FeatureType; collidable: Boolean);
	begin
		tile.feature := feature;
		tile.collidable := collidable;

		if feature = Tree then
		begin
			case tile.flag of
				Water: tile.featureBmp := BitmapNamed('hidden');
				Sand: tile.featureBmp := BitmapNamed('palm tree');
				Dirt: tile.featureBmp := BitmapNamed('tree');
				Grass: tile.featureBmp := BitmapNamed('tree');
				MediumGrass: tile.featureBmp := BitmapNamed('pine tree');
				HighGrass: tile.featureBmp := BitmapNamed('pine tree');
				SnowyGrass: tile.featureBmp := BitmapNamed('snowy tree');
				Mountain: tile.featureBmp := BitmapNamed('hidden');
			end;
		end
		else
		begin
			case feature of
				Treasure: tile.featureBmp := BitmapNamed('treasure');
				MediumTreasure: tile.featureBmp := BitmapNamed('medium_treasure');
				RareTreasure: tile.featureBmp := BitmapNamed('diamond');
				Food: tile.featureBmp := BitmapNamed('meat');
				NoFeature: tile.featureBmp := BitmapNamed('hidden');
			end;
		end;
	end;

	procedure SeedFeatures(var map: MapData);
	var
		treeCount, x, y: Integer;
		hasTree: Boolean;
	begin

		for x := 0 to High(map.tiles) do
		begin
			for y := 0 to High(map.tiles) do
			begin
				// Generate trees
				case map.tiles[x, y].flag of
					Sand: hasTree := (Random(100) > 90);
					Grass: hasTree := (Random(100) > 80);
					MediumGrass: hasTree := (Random(100) > 75);
					HighGrass: hasTree := (Random(100) > 70);
					SnowyGrass: hasTree := (Random(100) > 85);
					else
						hasTree := false;
				end;
				// If the tile has a tree, add a tree feature and bitmap, otherwise
				// generate treasure in the tile
				if hasTree then
				begin
					SetFeature(map.tiles[x, y], Tree, true);
				end
				else
				begin
					// Do treasure gen
					if (Random(1000) > 990) and ( not map.tiles[x, y].collidable ) then
					begin
						case Random(1000) of
							0..799: SetFeature(map.tiles[x, y], Treasure, true);
							800..974: SetFeature(map.tiles[x, y], MediumTreasure, true);
							975..1000: SetFeature(map.tiles[x, y], RareTreasure, true);
						end;
					end;

				end;
			end;
		end;

		// Creates groups of trees based of the previous random seed
		for x := 0 to High(map.tiles) do
		begin
			for y := 0 to High(map.tiles) do
			begin

				// If there's a tree on the current tile, add neighbours and generate small forests
				if (map.tiles[x, y].feature = Tree) and IsInMap(map, x, y) then
				begin

					treeCount := NeighbourCount(map, x, y);

					// Check if there's enough neighbours to generate a new tree
					if (treeCount > 1) and (treeCount <= 2) and (Random(100) > 50) then
					begin
						SetFeature(map.tiles[x - 1, y], Tree, true);
						SetFeature(map.tiles[x + 1, y], Tree, true);
						SetFeature(map.tiles[x, y + 1], Tree, true);
						SetFeature(map.tiles[x, y - 1], Tree, true);
					end
					else
					begin
						SetFeature(map.tiles[x, y], NoFeature, false);
					end;

				end;

			end;
		end;
	end;

	// Initializes the 2D map grid with the given size and sets the default values for each tile
	procedure SetGridLength(var tiles: TileGrid; size: Integer);
	var
		column: Integer;
		x, y: Integer;
	begin

		for column := 0 to size do
		begin
			SetLength(tiles, column, size);
		end;

		for x := 0 to High(tiles) do
		begin
			for y := 0 to High(tiles) do
			begin
				// Setup default values
				tiles[x, y].elevation := 0;
				tiles[x, y].collidable := false;
				tiles[x, y].feature := NoFeature;
				tiles[x, y].isOcean := true;
			end;
		end;
	end;

	procedure CheckCollision(var map: MapData; var toCheck: Sprite; dir: Direction; var hasCollision: Boolean; pickup: Boolean);
	var
		tileX, tileY, i, j, startX, finishX, startY, finishY: Integer;
		x, y: Single;
		spriteRect: Rectangle;
	begin
		hasCollision := false;

		x := SpriteX(toCheck);
		y := SpriteY(toCheck);

		// Get the x & y values to start scanning in a three-tile radius
		// in front of the entity
		startX := tileX - 1;
		finishX := tileX + 1;
		startY := tileY - 1;
		finishY := tileY + 1;

		// Change the values to scan depending on what direction the entity is facing
		case dir of
			DirUp: y -= TILESIZE / 2;
			DirRight: x += TILESIZE / 2;
			DirDown: y += TILESIZE;
			DirLeft: x -= TILESIZE / 2;
		end;

		// Convert current xpos & ypos to tile x & y
		tileX := Trunc(x / TILESIZE);
		tileY := Trunc(y / TILESIZE);

		if dir = DirUp then
		begin
			startX := tileX - 1;
			finishX := tileX + 1;
			startY := Floor(y / TILESIZE);
			finishY := startY;
		end
		else if dir = DirRight then
		begin
		  startX := Ceil(x / TILESIZE);
			finishX := startX;
			startY := tileY - 1;
			finishY := tileY + 1;
		end
		else if dir = DirDown then
		begin
		  startX := tileX - 1;
			finishX := tileX + 1;
			startY := Floor(y / TILESIZE);
			finishY := startY;
		end
		else if dir = DirLeft then
		begin
		  startX := Floor(x / TILESIZE);
			finishX := startX;
			startY := tileY - 1;
			finishY := tileY + 1;
		end;

		if (startX < 1) or (startX > High(map.tiles)) then
		begin
			startX := tileX;
		end;
		if (startY < 1) or (startY > High(map.tiles)) then
		begin
			startY := tileY;
		end;

		for i := startX to finishX do
		begin
			for j := startY to finishY do
			begin

				if SpriteBitmapCollision(toCheck, map.tiles[i, j].bmp, i * TILESIZE, j * TILESIZE) then
				begin

					if ( not IsInMap(map, i, j) ) or ( map.tiles[i, j].collidable ) then
					begin
						hasCollision := true;
						case dir of
							DirUp: SpriteSetDY(toCheck, 0);
							DirRight: SpriteSetDX(toCheck, 0);
							DirDown: SpriteSetDY(toCheck, 0);
							DirLeft: SpriteSetDX(toCheck, 0);
						end;
					end;

					if not ( not IsInMap(map, i, j) ) and ( map.tiles[i, j].feature = Food ) then
					begin
						PlaySoundEffect(SoundEffectNamed('pickup'), 0.5);
						map.inventory.items[SearchInventory(map.inventory.items, 'Rabbit Leg')].count += 1;
						SetFeature(map.tiles[i, j], NoFeature, false);
					end;

					if not ( not IsInMap(map, i, j) ) and ( map.tiles[i, j].feature >= Treasure ) then
					begin
						if pickup then
						begin
							PlaySoundEffect(SoundEffectNamed('pickup'), 0.5);
							case map.tiles[i, j].feature of
								Treasure: map.inventory.items[SearchInventory(map.inventory.items, 'Trinket')].count += 1;
								MediumTreasure: map.inventory.items[SearchInventory(map.inventory.items, 'Silver')].count += 1;
								RareTreasure: map.inventory.items[SearchInventory(map.inventory.items, 'Diamond')].count += 1;
							end;
							SetFeature(map.tiles[i, j], NoFeature, false);
						end;
					end;
				end;

			end;
		end;

	end;

	procedure DrawMapCartography(var newMap: MapData; size: Integer);
	var
		mapBmp: Bitmap;
		opts: DrawingOptions;
		clr, grassClr: Color;
		x, y: Integer;
		loadingGuy: Sprite;
		textStr: String;
	begin
		loadingGuy := CreateSprite('player', BitmapNamed('player'), AnimationScriptNamed('player'));
		SpriteStartAnimation(loadingGuy, 'entity_down');
//	CenterCameraOn(loadingGuy, 0, 0);

		textStr := 'Finalizing Map';

		mapBmp := CreateBitmap(size, size);
		ClearSurface(mapBmp, RGBColor(42, 76, 211));
		opts.dest := mapBmp;

		for x := 0 to High(newMap.tiles) do
		begin
			ClearScreen(ColorBlack);
			UpdateSprite(loadingGuy);
			DrawSprite(loadingGuy);
			DrawText(textStr, ColorWhite, FontNamed('PrStart'), (CameraX() + (ScreenWidth() / 2)) - TextWidth(FontNamed('PrStart'), textStr), CameraY() + 100);

			if not newMap.tiles[x, 0].isOcean then
			begin
				for y := 0 to High(newMap.tiles) do
				begin

					if newMap.tiles[x, y].flag <> Water then
					begin
						ProcessEvents();
						case newMap.tiles[x, y].flag of
							Water: clr := RGBColor(42, 76, 211); // Blue
							Sand: clr := RGBColor(241, 249, 101); // Sandy yellow
							Grass: clr := RGBColor(139, 230, 128); // Light green
							Dirt: clr := RGBColor(148, 92, 53); // Brown
							MediumGrass: clr := RGBColor(57, 167, 63); // darker green
							HighGrass: clr := RGBColor(23, 125, 29); // Dark green
							SnowyGrass: clr := ColorWhite;
							Mountain: clr := RGBColor(119, 119, 119); // Grey
						end;
						if newMap.tiles[x, y].feature = Tree then
						begin
							clr := RGBColor(113, 149, 48);
						end;
						DrawPixel(clr, x, y, opts);
					end;

				end;
			end;

			RefreshScreen(60);
		end;
		SaveBitmap(mapBmp, './maps/map_' + IntToStr(newMap.seed) + '.png');
	end;

	function GenerateNewMap(size, smoothness, maxHeight: Integer; seed: Integer): MapData;
	var
		newMap: MapData;
		x, y: Integer;
	begin

		if seed < 0 then
		begin
			WriteLn('random');
			Randomize;
		end
		else
		begin
			WriteLn('Seed: ', seed);
			RandSeed := 1000 + seed;
		end;

		newMap.seed := RandSeed;

		if ( (size - 1) mod 2 = 0 ) then
		begin
			FadeMusicIn(MusicNamed('main'), 1000);
			SetMusicVolume(0.5);

			ClearScreen(ColorBlack);
			DrawText('Generating Heightmap', ColorWhite, 300, 200);
			RefreshScreen(60);

			SetLength(newMap.npcs, 0);
			SetGridLength(newMap.tiles, size);
			GetHeightMap(newMap, maxHeight, smoothness);

			ClearScreen(ColorBlack);
			DrawText('Generating Terrain', ColorWhite, 300, 200);
			RefreshScreen(60);

			GenerateTerrain(newMap);
			SeedFeatures(newMap);

			//DrawMapCartography(newMap, size);
		end
		else
		begin
			WriteLn('Deadfall error: Cannot initialize map with size ', size, '! Map must be of size 2^n + 1.');
		end;

		// Todo: Return an invalid map and handle this error properly
		result := newMap;
	end;

end.
