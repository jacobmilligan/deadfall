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
		// Valid tile types for building maps with.
		// Used as a terrain flag for different logic.
		//
		TileType = (Water, Dirt, Grass, Stone, Wall);

		// Each tile has a terrain flag, elevation and bitmap
		Tile = record
			flag: TileType;

			//
			// Represents the tiles elevation - zero represents sea
			// level.
			//
			elevation: Double;
			bmp: Bitmap;
		end;

		TileGrid = array of array of Tile;

		//
		// Main representation of a current level. Holds a tile grid.
		//
		MapData = record
			tiles: TileGrid;
		end;

	//
	// Takes a new 2D tile grid, sets the size to the passed in
	// parameter, and initializes the elevation of each tile to zero.
	//
	procedure SetGridLength(var tiles: TileGrid; size: Integer);

	function GenerateNewMap(size: Integer): MapData;


implementation
	uses SwinGame;
	
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
	procedure GetHeightMap(var map: MapData; maxHeight: Integer);
	var
		x, y: Integer;
		midpointVal: Double;
		nextStep: Integer;
		cornerCount: Integer;
		loadingStr: String;
	begin
		loadingStr := 'Generating height map.';
		ClearScreen(ColorBlack);

		x := 0;
		y := 0;
		midpointVal := 0;
		nextStep := Round(Length(map.tiles) / 2 ); // Center of the tile grid

		// Seed right corner with random value
		map.tiles[x, y].elevation := Random(maxHeight);

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
			// Check surrounding points in a diamond for a given midpoint, i.e.:
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
					map.tiles[x, y].elevation := Round( (midpointVal / 4) + Random(maxHeight) );
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
						map.tiles[x, y].elevation := Round( (midpointVal / cornerCount) + Random(maxHeight) );
					end;

					y += 2 * nextStep;
				end;

				x += nextStep;
			end;

			nextStep := Round(nextStep / 2); // Make the next space smaller

			DrawText(loadingStr, ColorWhite, 300, 200);
			loadingStr += '.';
			RefreshScreen(60);
		end;
	end;

	procedure GenerateTerrain(var map: MapData);
	begin
		
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
			end;
		end;
	end;
	
	function GenerateNewMap(size: Integer): MapData;
	var
		newMap: MapData;
	begin

		if ( (size - 1) mod 2 = 0 ) then 
		begin
			SetGridLength(newMap.tiles, size);
			GetHeightMap(newMap, 1024);
			GenerateTerrain(newMap);
		end
		else 
		begin
			WriteLn('Deadfall error: Cannot initialize map with size ', size, '! Map must be of size 2^n + 1.');
		end;

	end;

end.
