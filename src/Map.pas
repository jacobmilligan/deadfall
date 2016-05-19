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

unit Map;

interface
	uses sgTypes;

	type

		//
		//	Valid entity directions on the map. Used in movement and
		//	collision detection
		//
		Direction = (Up, Right, Down, Left);

		//
		//	Valid tile types for building maps with.
		//	Used as a terrain flag for different logic.
		//
		TileType = (Water, Sand, Dirt, Grass, MediumGrass, HighGrass, SnowyGrass, Mountain);

		//
		//	Represents a feature on top of a tile that can have a bitmap,
		//	collision, and be interactive
		//
		FeatureType = (None, Tree, Food, Treasure);

		Item = record
			category: FeatureType;
			hungerPlus: Single;
			healthPlus: Single;
			dollarValue: Double;
			name: String;
			count: Integer;
		end;

		ItemPtr = ^Item;

		InventoryTemp = record
			rabbitLeg: Item;
			bandage: Item;
			trinket: Item;

			numItems: Integer;
		end;

		//
		//	Represents a tile on the map - has a terrain flag,
		//	elevation and bitmap
		//
		Tile = record
			// terrain type
			flag: TileType;

			// type of feature if any
			feature: FeatureType;

			// uses collision detection
			collidable: Boolean;

			//
			//	Represents the tiles elevation - zero represents sea
			//	level.
			//
			elevation: Double;

			// tiles base bitmap
			bmp: Bitmap;
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
			sprite: Sprite;
			direction: Direction;
			currentGoal: Point2D;
			hp: Single;
			hunger: Single;
			nextUpdate: Single;
			attackTimeout: Integer;
		end;

		EntityCollection = array of Entity;

		//
		//	Main representation of a current level. Holds a tile grid.
		//
		MapData = record
			tiles: TileGrid;
			player: Entity;
			inventory: InventoryTemp;
			npcs: EntityCollection;
		end;

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
	function GenerateNewMap(size: Integer): MapData;

	//
	//	Checks if a given entity is about to collide with anything on the
	//	given map based off its projected delta movement
	//
	procedure CheckCollision(var map: MapData; var toCheck: Sprite; dir: Direction; var hasCollision: Boolean);

	//
	//	Checks to see if a given point is out of the bounds of the passed in TileGrid. Returns
	//	true or false
	//
	function OutOfBounds(var tiles: TileGrid; x, y: Integer): Boolean;

	//
	//	Draws a given tiles bitmap and any features it contains to the screen.
	//
	procedure DrawTile(var currTile: Tile; x, y: Integer);

	//
	//	Creates a new TileView record from the view currently within the
	//	games camera bounds
	//
	function CreateTileView(): TileView;

	function InitInventory(): InventoryTemp;

	procedure RestoreHunger(var hunger: Single; plus: Single);
	procedure RestoreHealth(var health: Single; plus: Single);

implementation
	uses SwinGame, Game, Math;

	const
		TILESIZE = 32;

	function InitInventory(): InventoryTemp;
	begin
		result.numItems := 3;

		result.rabbitLeg.name := 'Rabbit Leg';
		result.rabbitLeg.count := 0;
		result.rabbitLeg.hungerPlus := 5;
		result.rabbitLeg.healthPlus := 1;
		result.rabbitLeg.dollarValue := 5;

		result.bandage.name := 'Bandage';
		result.bandage.count := 0;
		result.bandage.hungerPlus := 0;
		result.bandage.healthPlus := 10;
		result.bandage.dollarValue := 5;

		result.trinket.name := 'Trinket';
		result.trinket.count := 0;
		result.trinket.hungerPlus := 5;
		result.trinket.healthPlus := -5;
		result.trinket.dollarValue := 5;
	end;

	procedure RestoreHunger(var hunger: Single; plus: Single);
	begin
		if hunger + plus > 100 then
		begin
			hunger := 100;
		end
		else
		begin
			hunger += plus;
		end;
	end;

	procedure RestoreHealth(var health: Single; plus: Single);
	begin
		if health + plus > 100 then
		begin
			health := 100;
		end
		else
		begin
			health += plus;
		end;
	end;

	function OutOfBounds(var tiles: TileGrid; x, y: Integer): Boolean;
	begin
		result := false;

		if (x < 1) or (y < 1) then
		begin
			result := true;
		end;
		if ( x >= High(tiles) ) or ( y >= High(tiles) ) then
		begin
			result := true;
		end;
	end;

	function CreateTileView(): TileView;
	var
		x, y: Integer;
		width, height: LongInt;
		newView: TileView;
	begin
		newView.x := Round(CameraPos.x / 32) - 1;
		newView.y := Round(CameraPos.y / 32) - 1;
		newView.right := Round( (CameraPos.x / 32) + (ScreenWidth() / 32) );
		newView.bottom := Round( (CameraPos.y / 32) + (ScreenHeight() / 32) );

		result := newView;
	end;

	procedure DrawTile(var currTile: Tile; x, y: Integer);
	begin
		DrawBitmap(currTile.bmp, x, y);

		if currTile.feature = Tree then
		begin
			if (currTile.flag = Grass) then
			begin
				DrawBitmap(BitmapNamed('tree'), x, y);
			end
			else if (currTile.flag = Sand) then
			begin
				DrawBitmap(BitmapNamed('palm tree'), x, y);
			end
			else if (currTile.flag > Grass) and (currTile.flag < SnowyGrass) then
			begin
				DrawBitmap(BitmapNamed('pine tree'), x, y);
			end
			else
			begin
				DrawBitmap(BitmapNamed('snowy tree'), x, y);
			end;
		end;
		if currTile.feature = Food then
		begin
			DrawBitmap(BitmapNamed('meat'), x, y);
		end;
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
		map.tiles[x, y].elevation := -1000;

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
		for x := 0 to High(map.tiles) do
		begin
			for y := 0 to High(map.tiles) do
			begin

				if ( map.tiles[x, y].elevation < 0 ) then
				begin
					SetTile(map.tiles[x, y], Water, 'dark water', true);
				end
				else if ( map.tiles[x, y].elevation >= 0 ) and ( map.tiles[x, y].elevation < 200 ) then
				begin
					SetTile(map.tiles[x, y], Water, 'water', true);
				end
				else if ( map.tiles[x, y].elevation >= 200 ) and ( map.tiles[x, y].elevation < 300 ) then
				begin
					SetTile(map.tiles[x, y], Sand, 'sand', false);
				end
				else
				begin
					SetTile(map.tiles[x, y], Grass, 'grass', false);

					if ( map.tiles[x, y].elevation > 400 ) and ( map.tiles[x, y].elevation < 600 ) then
					begin
						SetTile(map.tiles[x, y], MediumGrass, 'dark grass', false);
					end;

					if ( map.tiles[x, y].elevation >= 600 ) and ( map.tiles[x, y].elevation < 800 ) then
					begin
						SetTile(map.tiles[x, y], HighGrass, 'darkest grass', false);
					end;

					if ( map.tiles[x, y].elevation >= 800 ) and ( map.tiles[x, y].elevation < 1000 ) then
					begin

						if Random(10) > 6 then
						begin
							SetTile(map.tiles[x, y], SnowyGrass, 'snowy grass', false);
						end
						else
						begin
							SetTile(map.tiles[x, y], HighGrass, 'darkest grass', false);
						end;
					end;

					if ( map.tiles[x, y].elevation >= 1000 ) and ( map.tiles[x, y].elevation < 1500 ) then
					begin
						SetTile(map.tiles[x, y], SnowyGrass, 'snowy grass', false);
					end;

					if ( map.tiles[x, y].elevation >= 1500 ) then
					begin
						SetTile(map.tiles[x, y], Mountain, 'mountain', true);
					end;

				end;

			end;
		end;
	end;

	function IsInMap(var map: MapData; x, y: Integer): Boolean;
	begin
		result := false;

		if (x > 0) and (x < High(map.tiles)) and (y > 0) and (y < High(map.tiles)) then
		begin
			result := true;
		end;
	end;

	function NeighbourCount(var map: MapData; x, y: Integer): Integer;
	var
		i, j, count: Integer;
	begin
		count := 0;

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
	end;

	procedure SeedTrees(var map: MapData);
	var
		treeCount, x, y: Integer;
		hasTree: Boolean;
	begin
		for x := 0 to High(map.tiles) do
		begin
			for y := 0 to High(map.tiles) do
			begin
				case map.tiles[x, y].flag of
					Sand: hasTree := (Random(100) > 90);
					Grass: hasTree := (Random(100) > 80);
					MediumGrass: hasTree := (Random(100) > 75);
					HighGrass: hasTree := (Random(100) > 70);
					SnowyGrass: hasTree := (Random(100) > 85);
					else
						hasTree := false;
				end;
				if hasTree then
				begin
					SetFeature(map.tiles[x, y], Tree, true);
				end;
			end;
		end;

		for x := 0 to High(map.tiles) do
		begin
			for y := 0 to High(map.tiles) do
			begin

				if (map.tiles[x, y].feature = Tree) and IsInMap(map, x, y) then
				begin

					treeCount := NeighbourCount(map, x, y);

					if (treeCount > 1) and (treeCount <= 2) and (Random(100) > 50) then
					begin
						SetFeature(map.tiles[x - 1, y], Tree, true);
						SetFeature(map.tiles[x + 1, y], Tree, true);
						SetFeature(map.tiles[x, y + 1], Tree, true);
						SetFeature(map.tiles[x, y - 1], Tree, true);
					end
					else
					begin
						SetFeature(map.tiles[x, y], None, false);
					end;

				end;

			end;
		end;
	end;

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
				tiles[x, y].elevation := 0;
				tiles[x, y].collidable := false;
				tiles[x, y].feature := None;
			end;
		end;
	end;

	procedure CheckCollision(var map: MapData; var toCheck: Sprite; dir: Direction; var hasCollision: Boolean);
	var
		tileX, tileY, i, j, startX, finishX, startY, finishY: Integer;
		x, y: Single;
		spriteRect: Rectangle;
	begin
		hasCollision := false;

		x := SpriteX(toCheck);
		y := SpriteY(toCheck);

		startX := tileX - 1;
		finishX := tileX + 1;
		startY := tileY - 1;
		finishY := tileY + 1;

		case dir of
			Up: y -= TILESIZE / 2;
			Right: x += TILESIZE / 2;
			Down: y += TILESIZE;
			Left: x -= TILESIZE / 2;
		end;

		tileX := Trunc(x / TILESIZE);
		tileY := Trunc(y / TILESIZE);

		if dir = Up then
		begin
			startX := tileX - 1;
			finishX := tileX + 1;
			startY := Floor(y / 32);
			finishY := startY;
		end
		else if dir = Right then
		begin
		  	startX := Ceil(x / 32);
			finishX := startX;
			startY := tileY - 1;
			finishY := tileY + 1;
		end
		else if dir = Down then
		begin
		  	startX := tileX - 1;
			finishX := tileX + 1;
			startY := Floor(y / 32);
			finishY := startY;
		end
		else if dir = Left then
		begin
		  	startX := Floor(x / 32);
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
					if OutOfBounds(map.tiles, i, j) or (map.tiles[i, j].collidable) then
					begin
						hasCollision := true;
						case dir of
							Up: SpriteSetDY(toCheck, 0);
							Right: SpriteSetDX(toCheck, 0);
							Down: SpriteSetDY(toCheck, 0);
							Left: SpriteSetDX(toCheck, 0);
						end;
					end;
					if not OutOfBounds(map.tiles, i, j) and (map.tiles[i, j].feature = Food) then
					begin
						map.inventory.rabbitLeg.count += 1;
						map.tiles[i, j].feature := None;
					end;
				end;

			end;
		end;

	end;

	function GenerateNewMap(size: Integer): MapData;
	var
		newMap: MapData;
		x, y: Integer;
		mapBmp: Bitmap;
		opts: DrawingOptions;
		clr: Color;
	begin
		if ( (size - 1) mod 2 = 0 ) then
		begin
			LoadMusicNamed('main', 'main.wav');
			FadeMusicIn(MusicNamed('main'), 1000);
			SetMusicVolume(0.5);

			ClearScreen(ColorBlack);
			DrawText('Generating Heightmap', ColorWhite, 300, 200);
			RefreshScreen(60);

			SetLength(newMap.npcs, 0);
			SetGridLength(newMap.tiles, size);
			GetHeightMap(newMap, 100, 20);

			ClearScreen(ColorBlack);
			DrawText('Generating Terrain', ColorWhite, 300, 200);
			RefreshScreen(60);

			GenerateTerrain(newMap);
			SeedTrees(newMap);

			ClearScreen(ColorBlack);
			DrawText('Finalizing Map', ColorWhite, 300, 200);
			RefreshScreen(60);

			mapBmp := CreateBitmap(size, size);
			opts.dest := mapBmp;

			for x := 0 to High(newMap.tiles) do
			begin
				for y := 0 to High(newMap.tiles) do
				begin
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
			SaveBitmap(mapBmp, 'new_map.png');
		end
		else
		begin
			WriteLn('Deadfall error: Cannot initialize map with size ', size, '! Map must be of size 2^n + 1.');
		end;

		// Todo: Return an invalid map and handle this error properly
		result := newMap;

	end;

end.
