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
	uses State, Game, Input;

	procedure TitleInit(var newState: ActiveState);

	procedure TitleHandleInput(var thisState: ActiveState; var inputs: InputMap);

	procedure TitleUpdate(var thisState: ActiveState);

	procedure TitleDraw(var thisState: ActiveState);


implementation
	uses SwinGame, GameUI;

	function CreateTitleUI(): UI;
	var
		horizontalCenter: Single;
	begin
		InitUI(result, 4, 'Title');

		horizontalCenter := ( ScreenWidth() - BitmapWidth(BitmapNamed('ui_blue')) ) / 2;

		result.items[0] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), horizontalCenter, 150, 'New Map', 'PrStartSmall');
		result.items[1] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), horizontalCenter, 260, 'Load Map', 'PrStartSmall');
		result.items[2] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), horizontalCenter, 370, 'Settings', 'PrStartSmall');
		result.items[3] := CreateUIElement(BitmapNamed('ui_blue'), BitmapNamed('ui_red'), horizontalCenter, 480, 'Quit', 'PrStartSmall');

		result.currentItem := 0;
		result.previousItem := 0;
	end;

	procedure TitleInit(var newState: ActiveState);
	begin
		newState.HandleInput := @TitleHandleInput;
		newState.Update := @TitleUpdate;
		newState.Draw := @TitleDraw;

		newState.displayedUI := CreateTitleUI();

		SetMusicVolume(1);
		PlayMusic(MusicNamed('baws'));
	end;

	procedure TitleHandleInput(var thisState: ActiveState; var inputs: InputMap);
	begin
		UINavigate(thisState.displayedUI, inputs, thisState.map);
		if KeyTyped(inputs.Select) then
		begin
			PlaySoundEffect(SoundEffectNamed('confirm'), 0.5);
			case UISelectedID(thisState.displayedUI) of
				'Quit': StateChange(thisState.manager^, QuitState);
				'New Map': StateChange(thisState.manager^, LevelState);
				'Settings': WriteLn('Settings');
				'Load Map': WriteLn('Load Map');
			end;
		end;

	end;

	procedure TitleUpdate(var thisState: ActiveState);
	begin
		UpdateUI(thisState.displayedUI, thisState.displayedUI.currentItem, thisState.displayedUI.previousItem);
	end;

	procedure TitleDraw(var thisState: ActiveState);
	var
		horizontalCenter: Single;
		titleTxt: String;
		titleWidth: Single;
	begin
		titleTxt := 'Deadfall';
		titleWidth := TextWidth(FontNamed('Vermin'), titleTxt) / 2;
		horizontalCenter := ScreenWidth() / 2;

		DrawBitmap(BitmapNamed('title_back'), CameraX(), CameraY());
		DrawUI(thisState.displayedUI);
		DrawText(titleTxt, ColorYellow, FontNamed('Vermin'), CameraX() + (horizontalCenter - titleWidth), CameraY() + 10);
	end;

end.
