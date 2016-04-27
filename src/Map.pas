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
		Direction = (Up, Right, Down, Left);

		//
		// Valid tile types for building maps with.
		// Used as a terrain flag for different logic.
		//
		TileType = (Water, Sand, Dirt, Grass, MediumGrass, HighGrass, SnowyGrass, Mountain);
		
		FeatureType = (None, Tree);

		// Each tile has a terrain flag, elevation and bitmap
		Tile = record
			flag: TileType;
			feature: FeatureType;
			collidable: Boolean;

			//
			// Represents the tiles elevation - zero represents sea
			// level.
			//
			elevation: Double;
			bmp: Bitmap;
		end;

		TileGrid = array of array of Tile;
		
		Entity = record
			sprite: Sprite;
			direction: Direction;
			hp: Single;
			hunger: Single;
		end;

		//
		// Main representation of a current level. Holds a tile grid.
		//
		MapData = record
			tiles: TileGrid;
			player: Entity;
		end;

		MapPtr = ^MapData;

	//
	// Takes a new 2D tile grid, sets the size to the passed in
	// parameter, and initializes the elevation of each tile to zero.
	//
	procedure SetGridLength(var tiles: TileGrid; size: Integer);

	function GenerateNewMap(size: Integer): MapData;

	procedure CheckCollision(var map: MapData; var entity: Sprite; dir: Direction);


implementation
	uses SwinGame, Game, Math;
	
	const
		TILESIZE = 32;
	
	procedure PrintGrid(var grid: TileGrid);
	var
		x, y: Integer;
	begin
		for x := 0 to High(grid) do
		begin
			for y := 0 to High(grid) do
			begin
				Write(grid[x, y].elevation:0:4, ' ');
			end;
			WriteLn();
		end;

		WriteLn('------------------------');
	end;

	//
	// Fills a MapData's TileGrid with generated heightmap data
	// using the Diamond-Square fractal generation algorithm 
	// (for details, see: Computer Rendering of Stochastic Models - Alain Fournier et. al.).
	// This heightmap data gets used later on to generate terrain realistically
	//
	procedure GetHeightMap(var map: MapData; maxHeight, smoothness: Integer);
	var
		x, y: Integer;
		midpointVal: Double;
		nextStep, cornerCount: Integer;
		loadingStr: String;
	begin
		loadingStr := 'Generating height map.';
		ClearScreen(ColorBlack);

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

		// Show loading text
		DrawText(loadingStr, ColorWhite, 300, 200);
		RefreshScreen(60);

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
						map.tiles[x, y].elevation := Round( (midpointVal / cornerCount) + Random(maxHeight) * smoothness );
					end;

					y += 2 * nextStep;
				end;

				x += nextStep;
			end;

			nextStep := Round(nextStep / 2); // Make the next space smaller
			smoothness := Round(smoothness / 2);

			DrawText(loadingStr, ColorWhite, 300, 200);
			loadingStr += '.';
			RefreshScreen(60);
		end;
	end;

	procedure GenerateTerrain(var map: MapData);
	var
		x, y: Integer;
		loadingStr: String;
	begin
		LoadResources();
		ClearScreen(ColorBlack);
		loadingStr := 'Generating Terrain.';

		for x := 0 to High(map.tiles) do
		begin
			for y := 0 to High(map.tiles) do
			begin
				
				if ( map.tiles[x, y].elevation < 0 ) then
				begin
					map.tiles[x, y].flag := Water;
					map.tiles[x, y].bmp := BitmapNamed('dark water');
					map.tiles[x, y].collidable := true;
				end
				else if ( map.tiles[x, y].elevation >= 0 ) and ( map.tiles[x, y].elevation < 200 ) then 
				begin
					map.tiles[x, y].flag := Water;
					map.tiles[x, y].bmp := BitmapNamed('water');
					map.tiles[x, y].collidable := true;
				end
				else if ( map.tiles[x, y].elevation >= 200 ) and ( map.tiles[x, y].elevation < 300 ) then
				begin
					map.tiles[x, y].flag := Sand;
					map.tiles[x, y].bmp := BitmapNamed('sand');
				end
				else
				begin

					map.tiles[x, y].flag := Grass;
					map.tiles[x, y].bmp := BitmapNamed('grass');

					if ( map.tiles[x, y].elevation > 400 ) and ( map.tiles[x, y].elevation < 600 ) then
					begin
						map.tiles[x, y].flag := MediumGrass;
						map.tiles[x, y].bmp := BitmapNamed('dark grass');
					end;

					if ( map.tiles[x, y].elevation >= 600 ) and ( map.tiles[x, y].elevation < 800 ) then
					begin
						map.tiles[x, y].flag := HighGrass;
						map.tiles[x, y].bmp := BitmapNamed('darkest grass');
					end;

					if ( map.tiles[x, y].elevation >= 800 ) and ( map.tiles[x, y].elevation < 1000 ) then
					begin

						if Random(10) > 6 then
						begin
							map.tiles[x, y].flag := SnowyGrass;
							map.tiles[x, y].bmp := BitmapNamed('snowy grass');
						end
						else
						begin
							map.tiles[x, y].flag := HighGrass;
							map.tiles[x, y].bmp := BitmapNamed('darkest grass');
						end;
					end;

					if ( map.tiles[x, y].elevation >= 1000 ) and ( map.tiles[x, y].elevation < 1500 ) then
					begin
						map.tiles[x, y].flag := SnowyGrass;
						map.tiles[x, y].bmp := BitmapNamed('snowy grass');
					end;

					if ( map.tiles[x, y].elevation >= 1500 ) then
					begin
						map.tiles[x, y].flag := Mountain;
						map.tiles[x, y].bmp := BitmapNamed('mountain');
						map.tiles[x, y].collidable := true;
					end;

				end;

			end;
		end;
		loadingStr += '.';
		DrawText(loadingStr, ColorWhite, 300, 200);
		RefreshScreen(60);
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
	
	procedure CheckCollision(var map: MapData; var entity: Sprite; dir: Direction);
	var
		tileX, tileY, i, j, startX, finishX, startY, finishY: Integer;
		x, y: Single;
	begin
		x := SpriteX(entity);
		y := SpriteY(entity);
		
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
				
				if SpriteBitmapCollision(entity, map.tiles[i, j].bmp, i * TILESIZE, j * TILESIZE) then
				begin
					if (i < 1) or (j < 1) or (i > High(map.tiles)) or (j > High(map.tiles)) or (map.tiles[i, j].collidable) then
					begin
						case dir of
							Up: SpriteSetDY(entity, 2); 
							Right: SpriteSetDX(entity, -2);
							Down: SpriteSetDY(entity, -2);
							Left: SpriteSetDX(entity, 2);
						end;
					end;
				end;
							
			end;
		end;
		
	end;

	function GenerateNewMap(size: Integer): MapData;
	var
		newMap: MapData;
		x, y: Integer;
	begin
		if ( (size - 1) mod 2 = 0 ) then 
		begin
			SetGridLength(newMap.tiles, size);
			GetHeightMap(newMap, 110, 20);
			GenerateTerrain(newMap);
			SeedTrees(newMap);

			for x := 0 to High(newMap.tiles) do
			begin
				for y := 0 to High(newMap.tiles) do
				begin
					case newMap.tiles[x, y].flag of
						Water: DrawPixel(ColorBlue, Round(x / 1.3), Round(y / 1.5));
						Sand: DrawPixel(ColorYellow, Round(x / 1.3), Round(y / 1.5));
						Grass: DrawPixel(ColorLawnGreen, Round(x / 1.3), Round(y / 1.5));
						Dirt: DrawPixel(ColorBrown, Round(x / 1.3), Round(y / 1.5));
						MediumGrass: DrawPixel(ColorGreen, Round(x / 1.3), Round(y / 1.5));
						HighGrass: DrawPixel(ColorOlive, Round(x / 1.3), Round(y / 1.5));
						SnowyGrass: DrawPixel(ColorWhite, Round(x / 1.3), Round(y / 1.5));
						Mountain: DrawPixel(ColorBlack, Round(x / 1.3), Round(y / 1.5));
					end;
				end;
			end;
			TakeScreenshot('map');
			RefreshScreen(60);

		end
		else 
		begin
			WriteLn('Deadfall error: Cannot initialize map with size ', size, '! Map must be of size 2^n + 1.');
		end;
		result := newMap;

	end;

end.
