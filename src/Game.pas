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
	uses State, Input, Map;

	//
	// Opens graphics window and sets up game core & resources
	//
	procedure GameInit(caption: String; width, height: Integer; var states: StateArray);

	//
	// Updates the game, calling the current game_state's Update & HandleInput function
	// pointers as well, delegating responsibility to the state for non-game-scope tasks
	//
	procedure GameUpdate(var states: StateArray; var inputs: InputMap);

	//
	// Updates the game, calling the current game_state's own draw function
	// as well, delegating responsibility for drawing state-local objects (sprites, shapes etc.)
	//
	procedure GameDraw(var states: StateArray);

	procedure QuitGame(var states: StateArray);

	//
	// Loads all resources needed by the game
	//
	procedure LoadResources();

	procedure QuickSort(var inventory: ItemArray; bottom, top: Integer);

	function SearchInventory(var inventory: ItemArray; itemName: String): Integer;


implementation
	uses Swingame;

	// Swaps two integers
	procedure Swap(var itemA: Item; var itemB: Item);
	var
		temp: Item;
	begin
		temp := itemA;
		itemA := itemB;
		itemB := temp;
	end;

	// Uses a binary search through a sorted inventory collection to find a given inventory item
	function SearchInventory(var inventory: ItemArray; itemName: String): Integer;
	var
		left, right, middle: Integer;
	begin
		left := 0;
		right := High(inventory);
		result := -1;

		while left <= right do
		begin
			middle := Round( (left + right) / 2 );
			if inventory[middle].name = itemName then
			begin
				result := middle;
				break;
			end
			else if (inventory[middle].name > itemName) then
			begin
				right := middle - 1;
			end
			else
			begin
				left := middle + 1;
			end;
		end;

	end;

	// The partition function used in Quicksort.
	function QSortPartition(var inventory: ItemArray; bottom, top: Integer): Integer;
	var
		left, i: Integer;
		pivot: String;
	begin
		pivot := inventory[bottom].name;
		left := bottom;

		i := bottom + 1;

		// Use a while loop to ensure the user can cancel the algorithm
		// and exit the window at any time
		while ( i <= top ) and ( not WindowCloseRequested() ) do
		begin
			if inventory[i].name < pivot then
			begin
				left += 1;
				Swap(inventory[i], inventory[left]);
			end;

			i += 1
		end;

		Swap(inventory[bottom], inventory[left]);

		result := left;
	end;


	// Executes recursive Quicksort. Partitions an array into two sub-arrays at a chosen
	// 'pivot' point where everything smaller than the pivot is on its left, and eveything larger than
	// or equal to it is on its right. Once this is done, quicksort is recursively called on each
	// partition, and so on until the list is sorted.
	procedure QuickSort(var inventory: ItemArray; bottom, top: Integer);
	var
		pivotIndex: Integer;
	begin
		if bottom < top then
		begin
			pivotIndex := QSortPartition(inventory, bottom, top);
			QuickSort(inventory, bottom, pivotIndex);
			QuickSort(inventory, pivotIndex + 1, top);
		end;
	end;

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
		LoadBitmapNamed('tree', 'tree.png');
		LoadBitmapNamed('pine tree', 'pine_tree.png');
		LoadBitmapNamed('palm tree', 'palm_tree.png');
		LoadBitmapNamed('snowy tree', 'snowy_tree.png');
		LoadBitmapNamed('title_back', 'title_back.png');
		LoadBitmapNamed('meat', 'meat.png');
		LoadBitmapNamed('treasure', 'treasure.png');
		LoadBitmapNamed('empty bar', 'empty_bar.png');
		LoadBitmapNamed('health bar', 'health_bar.png');
		LoadBitmapNamed('dollars', 'dollars.png');

		LoadMusicNamed('baws', 'baws.wav');
		LoadMusicNamed('main', 'main.wav');

		LoadSoundEffectNamed('throw', 'throw.wav');
		LoadSoundEffectNamed('sell', 'sell.wav');
		LoadSoundEffectNamed('bunny', 'bunny.wav');
		LoadSoundEffectNamed('pickup', 'pickup.wav');
		LoadSoundEffectNamed('punch', 'punch.wav');
		LoadSoundEffectNamed('back', 'back.wav');
		LoadSoundEffectNamed('click', 'click.wav');
		LoadSoundEffectNamed('confirm', 'confirm.wav');

		LoadResourceBundle('md.txt');
	end;

	procedure GameInit(caption: String; width, height: Integer; var states: StateArray);
	begin
		OpenGraphicsWindow(caption, width, height);

		LoadResources();

		SetLength(states, 0);
		StateChange(states, TitleState);
	end;

	procedure GameUpdate(var states: StateArray; var inputs: InputMap);
	begin

		ProcessEvents();

		if Length(states) > 0 then
		begin
			// Current state handles input
			states[High(states)].HandleInput( states[High(states)], inputs );

			// Current state updates the game
			states[High(states)].Update( states[High(states)] );
		end;

	end;

	procedure GameDraw(var states: StateArray);
	begin
		if Length(states) > 0 then
		begin
			ClearScreen(ColorBlack);

			// Current state draws itself to the window
			states[High(states)].Draw( states[High(states)] );

			RefreshScreen(60);
		end;
	end;

	procedure QuitGame(var states: StateArray);
	var
		i, j: Integer;
	begin
		ReleaseAllResources();
		Delay(1000);
	end;

end.
