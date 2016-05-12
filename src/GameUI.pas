unit GameUI;

interface
	uses Swingame;
	
    type
		UIElement = record
			inactiveBmp: Bitmap;
			activeBmp: Bitmap;
			currentBmp: Bitmap;
			x: Single;
			y: Single;
			id: String;
			setFont: Font;
		end;
		
		type UICollection = array of UIElement;
		
		UI = record
			items: UICollection;
			currentItem: Integer;
			previousItem: Integer;
			changeTimeOut: Integer;
		end;
	
	const
		UI_NEXT = 'UI_NEXT_ELEMENT';
		UI_PREV = 'UI_PREV_ELEMENT';
		UI_CURRENT = 'UI_CURRENT_ELEMENT';
	
	procedure InitUI(var newUI: UI; numElements: Integer);
	
	function CreateUIElement(inactiveBmp, activeBmp: Bitmap; x, y: Single; id: String = ''; setFont: String = 'PrStart'): UIElement;
	
	procedure UpdateUI(var currentUI: UI);
	
	procedure DrawUI(var currentUI: UI);
	
	procedure ChangeElement(var currentUI: UI; id: String);
	
	function UISelectedID(var currentUI: UI): String;

implementation
	uses State;
		
	const
		CHANGE_FRAMES = 10;

	procedure InitUI(var newUI: UI; numElements: Integer);
	begin
		SetLength(newUI.items, numElements);
		newUI.currentItem := 0;
		newUI.changeTimeOut := 0;
	end;

	function CreateUIElement(inactiveBmp, activeBmp: Bitmap; x, y: Single; id: String = ''; setFont: String = 'PrStart'): UIElement;
	begin
		result.inactiveBmp := inactiveBmp;
		result.activeBmp := activeBmp;
		result.currentBmp := inactiveBmp;
		result.x := x;
		result.y := y;
		result.id := id;
		result.setFont := FontNamed(setFont);
	end;
	
	function FindUIElement(var currentUI: UI; id: String): Integer;
	var
		i: Integer;
	begin
		result := -1;
		for i := 0 to High(currentUI.items) do
		begin
			if currentUI.items[i].id = id then
			begin
				result := i;
				break;
			end;
		end;
	end;
	
	function UISelectedID(var currentUI: UI): String;
	begin
		result := currentUI.items[currentUI.currentItem].id;
	end;
	
	procedure ChangeElement(var currentUI: UI; id: String);
	var
		i: Integer;
	begin
		if currentUI.changeTimeOut = 0 then
		begin
			currentUI.changeTimeOut := CHANGE_FRAMES;
			currentUI.previousItem := currentUI.currentItem;
		 
			if id = UI_NEXT then
			begin
				currentUI.currentItem := currentUI.currentItem + 1;
				if currentUI.currentItem > High(currentUI.items) then
				begin
					currentUI.currentItem := 0;
				end;
			end
			else if id = UI_PREV then
			begin
				currentUI.currentItem := currentUI.currentItem - 1;
				if currentUI.currentItem < 0 then
				begin
					currentUI.currentItem := High(currentUI.items);
				end;
			end
			else
			begin
				currentUI.currentItem := FindUIElement(currentUI, id);
				if currentUI.currentItem < 0 then
				begin
					currentUI.currentItem := currentUI.previousItem;
					WriteLn('Unable to find UI Element "', id, '."'); 
				end;
			end;
		end;
		
	end;
	
	procedure UpdateUI(var currentUI: UI);
	begin
		currentUI.items[currentUI.previousItem].currentBmp := currentUI.items[currentUI.previousItem].inactiveBmp;
		currentUI.items[currentUI.currentItem].currentBmp := currentUI.items[currentUI.currentItem].activeBmp;
		
		currentUI.changeTimeOut -= 1;
		if currentUI.changeTimeOut < 0 then
		begin
			currentUI.changeTimeOut := 0;
		end;
		
	end;

	procedure DrawUI(var currentUI: UI);
	var
		i: Integer;
		itemCenterX, itemCenterY: Single;
	begin
	
		for i := 0 to High(currentUI.items) do
		begin
			if i = currentUI.currentItem then
			begin
				currentUI.items[i].currentBmp := currentUI.items[i].activeBmp;
			end;
			
			DrawBitmap(currentUI.items[i].currentBmp, CameraX() + currentUI.items[i].x, CameraY() + currentUI.items[i].y);
			
			itemCenterX := currentUI.items[i].x + (BitmapWidth(currentUI.items[i].currentBmp) / 2);
			itemCenterX := itemCenterX - ( TextWidth(currentUI.items[i].setFont, currentUI.items[i].id) / 2 );
			
			itemCenterY := currentUI.items[i].y + (BitmapHeight(currentUI.items[i].currentBmp) / 2);
			itemCenterY := itemCenterY - ( TextHeight(currentUI.items[i].setFont, currentUI.items[i].id) / 2 );
			
			DrawText(currentUI.items[i].id, ColorBlack, currentUI.items[i].setFont, CameraX() + itemCenterX, CameraY() + itemCenterY); 
		end;
			
	end;

end.