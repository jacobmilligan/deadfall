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

	procedure TitleInit(var newState: ActiveState);
	var
		tempInputs: InputMap;
	begin
		newState.HandleInput := @TitleHandleInput;
		newState.Update := @TitleUpdate;
		newState.Draw := @TitleDraw;

		newState.displayedUI := CreateTitleUI(newState.map, tempInputs);

		SetMusicVolume(1);
		PlayMusic(MusicNamed('baws'));
	end;

	procedure TitleHandleInput(var thisState: ActiveState; var inputs: InputMap);
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
				'New Map': StateChange(thisState.manager^, LevelState);
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
