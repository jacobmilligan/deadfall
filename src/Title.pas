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
		SetupUIData(result.items[0], 4, ['Small', 'Medium', 'Big', 'Huge']);

		result.items[1] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 200, 'Max Height', 'PrStartSmall');
		SetupUIData(result.items[1], 1, [NUMBER_DATA], 100);

		result.items[2] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 300, 'Smoothness', 'PrStartSmall');
		SetupUIData(result.items[2], 1, [NUMBER_DATA], 20);

		result.items[3] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 400, 'Seed', 'PrStartSmall');
		SetupUIData(result.items[3], 2, ['Random', NUMBER_DATA]);

		result.items[4] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), HorizontalCenter('ui_blue'), 500, 'Generate', 'PrStartSmall');

		result.currentItem := 0;
		result.previousItem := 0;
		result.previousUI := @CreateTitleUI;
	end;

	procedure ChangeSizeSettings(var elem: UIElement; var map: MapData);
	begin
		case elem.data[elem.currData] of
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
			'Huge':
				begin
					map.maxSpawns := 200000;
					map.size := 2049;
				end;
			end;
	end;

	procedure ChangeMapSettings(var mapUI: UI; var map: MapData);
	var
		i: Integer;
	begin
		for i := 0 to High(mapUI.items) do
		begin
			case mapUI.items[i].id of
				'Size': ChangeSizeSettings(mapUI.items[i], map);
				'Max Height': map.maxHeight := mapUI.items[i].numberData;
				'Smoothness': map.smoothness := mapUI.items[i].numberData;
				'Seed':
					begin
						if mapUI.items[i].data[mapUI.items[i].currData] = 'Random' then
						begin
							mapUI.items[i].numberData := -1;
						end;
						map.seed := mapUI.items[i].numberData;
					end;
			end;

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
							UpdateUIData(inputs, thisState.displayedUI.items[i], thisState.map);
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
			UpdateUIData(inputs, thisState.displayedUI.items[thisState.displayedUI.currentItem], thisState.map);
			ChangeMapSettings(thisState.displayedUI, thisState.map);
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
