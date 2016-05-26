//
//  Deadfall v1.0
//  Title.pas
//
// -------------------------------------------------------
//
//  Created By Jacob Milligan
//  On 22/04/2016
//  Student ID: 100660682
//

unit Title;

interface
	uses State, Game, Input, GameUI, Map;

	procedure TitleInit(var newState: ActiveState);

	procedure TitleHandleInput(var thisState: ActiveState; var inputs: InputMap);

	procedure TitleUpdate(var thisState: ActiveState);

	procedure TitleDraw(var thisState: ActiveState);

	function CreateTitleUI(var map: MapData; var inputs: InputMap): UI;

implementation
	uses SwinGame;

	function CreateTitleUI(var map: MapData; var inputs: InputMap): UI;
	begin
		InitUI(result, 4, 'Title');

		result.items[0] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 150, 'New Map', 'PrStartSmall');
		result.items[1] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 260, 'Load Map', 'PrStartSmall');
		result.items[2] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 370, 'Settings', 'PrStartSmall');
		result.items[3] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 480, 'Quit', 'PrStartSmall');

		result.currentItem := 0;
		result.previousItem := 0;
	end;

	function CreateInitMapUI(var map: MapData; var inputs: InputMap): UI;
	begin
		InitUI(result, 5, 'New Map');

		result.items[0] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 100, 'Size', 'PrStartSmall');
		SetLength(result.items[0].dataStrings, 3);
		result.items[0].dataStrings[0] := 'Small';
		result.items[0].dataStrings[1] := 'Medium';
		result.items[0].dataStrings[2] := 'Big';
		result.items[0].currentDataString := 0;

		result.items[1] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 200, 'Max Height', 'PrStartSmall');
		result.items[1].data := 100;
		result.items[2] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 300, 'Smoothness', 'PrStartSmall');
		result.items[2].data := 20;

		result.items[3] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 400, 'Seed', 'PrStartSmall');
		SetLength(result.items[3].dataStrings, 1);
		result.items[3].dataStrings[0] := 'Random';
		result.items[3].data := -1;

		result.items[4] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 500, 'Generate', 'PrStartSmall');


		result.currentItem := 0;
		result.previousItem := 0;
		result.previousUI := @CreateTitleUI;
	end;

	procedure UpdateNewMapInput(var inputs: InputMap; var currElement: UIElement; var map: MapData);
	begin
		if currElement.id = 'Size' then
		begin
			if KeyTyped(inputs.MoveRight) then
			begin
				currElement.currentDataString += 1;
				if currElement.currentDataString > 2 then
				begin
					currElement.currentDataString := 0;
				end;

				case currElement.dataStrings[currElement.currentDataString] of
					'Small':
						begin
							map.maxSpawns := 500;
							map.size := 257;
						end;
					'Medium':
						begin
							map.maxSpawns := 1000;
							map.size := 513;
						end;
					'Big':
						begin
							map.maxSpawns := 100000;
							map.size := 1025;
						end;
					end;
			end
			else if KeyTyped(inputs.MoveLeft) then
			begin
				currElement.currentDataString -= 1;
				if currElement.currentDataString < 0 then
				begin
					currElement.currentDataString := 2;
				end;

				case currElement.dataStrings[currElement.currentDataString] of
					'Small':
						begin
							map.maxSpawns := 500;
							map.size := 257;
						end;
					'Medium':
						begin
							map.maxSpawns := 1000;
							map.size := 513;
						end;
					'Big':
						begin
							map.maxSpawns := 100000;
							map.size := 1025;
						end;
				end;
			end
		end
		else if KeyDown(inputs.MoveRight) then
		begin
 			if currElement.id = 'Seed' then
			begin
				if currElement.currentDataString = -1 then
				begin
					currElement.data += 1;
				end
				else
				begin
					currElement.currentDataString := -1;
					currElement.data := 0;
				end;
				map.seed := currElement.data;
			end
			else
			begin
				currElement.data += 1;

				case currElement.id of
					'Max Height': map.maxHeight := currElement.data;
					'Smoothness': map.smoothness := currElement.data;
				end;

			end;

		end
		else if KeyDown(inputs.MoveLeft) then
		begin
			if currElement.id = 'Seed' then
			begin
				if currElement.currentDataString = -1 then
				begin
					currElement.data -= 1;
					if currElement.data < 0 then
					begin
						currElement.data := -1;
						currElement.currentDataString := 0;
					end;
				end;
				map.seed := currElement.data;
			end
			else
			begin
				currElement.data -= 1;
				if currElement.data < 0 then
				begin
					currElement.data := 0;
				end;

				case currElement.id of
					'Max Height': map.maxHeight := currElement.data;
					'Smoothness': map.smoothness := currElement.data;
				end;
			end;
		end;

		if currElement.id = 'Size' then
		begin
			case currElement.dataStrings[currElement.currentDataString] of
				'Small':
					begin
						map.maxSpawns := 1000;
						map.size := 257;
					end;
				'Medium':
					begin
						map.maxSpawns := 1000;
						map.size := 513;
					end;
				'Big':
					begin
						map.maxSpawns := 100000;
						map.size := 1025;
					end;
			end;
		end
		else if currElement.id = 'Seed' then
		begin
			map.seed := currElement.data;
		end
		else
		begin
			case currElement.id of
				'Max Height': map.maxHeight := currElement.data;
				'Smoothness': map.smoothness := currElement.data;
			end;
		end;

		if KeyTyped(inputs.Attack) and ( currElement.id = 'Seed' ) then
		begin
			currElement.data := -1;
			currElement.currentDataString := 0;
		end;

	end;

	procedure TitleInit(var newState: ActiveState);
	var
		tempInputs: InputMap;
	begin
		SetCameraPos(PointAt(0, 0));
		newState.HandleInput := @TitleHandleInput;
		newState.Update := @TitleUpdate;
		newState.Draw := @TitleDraw;

		newState.displayedUI := CreateTitleUI(newState.map, tempInputs);

		SetMusicVolume(1);
		PlayMusic(MusicNamed('baws'));
	end;


	procedure TitleHandleInput(var thisState: ActiveState; var inputs: InputMap);
	var
		i: Integer;
	begin

		if ( KeyTyped(inputs.Select) ) and ( thisState.displayedUI.name = 'Controls' ) then
		begin
			PlaySoundEffect(SoundEffectNamed('confirm'), 0.8);
			Delay(50);
			while not AnyKeyPressed() do
			begin
				ProcessEvents();
				ClearScreen(ColorBlack);
				TitleDraw(thisState);
				DrawText('Press the new key to change control', ColorWhite, FontNamed('PrStartSmall'), CameraX() + HorizontalCenter('ui_blue'), CameraY() + 10);
				RefreshScreen(60);
			end;

			ChangeKeyTo(inputs, thisState.displayedUI.items[thisState.displayedUI.currentItem].id);
		end;

		UINavigate(thisState.displayedUI, inputs, thisState.map);
		if KeyTyped(inputs.Select) and ( thisState.displayedUI.name = 'Title' ) then
		begin
			PlaySoundEffect(SoundEffectNamed('confirm'), 0.5);
			case UISelectedID(thisState.displayedUI) of
				'Quit': StateChange(thisState.manager^, QuitState);
				'New Map':
					begin
						thisState.displayedUI.nextUI := @CreateInitMapUI;
						for i := 0 to High(thisState.displayedUI.items) do
						begin
							UINavigate(thisState.displayedUI, inputs, thisState.map);
							UpdateNewMapInput(inputs, thisState.displayedUI.items[i], thisState.map);
						end;
					end;
				'Settings':
					begin
						thisState.displayedUI.nextUI := @CreateSettingsUI;
						UINavigate(thisState.displayedUI, inputs, thisState.map);
					end;
				'Load Map': WriteLn('Load Map');
			end;
		end;

		if thisState.displayedUI.name = 'Settings' then
		begin
			thisState.displayedUI.previousUI := @CreateTitleUI;
			case UISelectedID(thisState.displayedUI) of
				'Change Controls': thisState.displayedUI.nextUI := @CreateChangeControlsUI;
			end;
		end;

		if thisState.displayedUI.name = 'New Map' then
		begin
			UpdateNewMapInput(inputs, thisState.displayedUI.items[thisState.displayedUI.currentItem], thisState.map);
			if KeyTyped(inputs.Select) and ( UISelectedID(thisState.displayedUI) = 'Generate' ) then
			begin
				StateChange(thisState.manager^, LevelState);
			end;
		end;

	end;

	procedure TitleUpdate(var thisState: ActiveState);
	begin
		UpdateUI(thisState.displayedUI, thisState.displayedUI.currentItem, thisState.displayedUI.previousItem);
	end;

	procedure TitleDraw(var thisState: ActiveState);
	var
		titleTxt: String;
		titleWidth: Single;
	begin
		titleTxt := 'Deadfall';
		titleWidth := TextWidth(FontNamed('Vermin'), titleTxt) / 2;

		DrawBitmap(BitmapNamed('title_back'), CameraX(), CameraY());
		DrawUI(thisState.displayedUI);
		DrawText(titleTxt, ColorYellow, FontNamed('Vermin'), (CameraX() + HorizontalCenter('ui_blue')) - (titleWidth / 4), CameraY() + 10);
	end;

end.
