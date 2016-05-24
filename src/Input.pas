//
//  Deadfall v1.0
//  Input.pas
//
// -------------------------------------------------------
//
//  Created By Jacob Milligan
//  On 21/04/2016
//  Student ID: 100660682
//

unit Input;

interface
    uses SwinGame, sgTypes, Map;

    type

        //
        //  Defines all of the keys assigned to each game action.
        //  Is set to default keys in GameInit() using SetDefaultInput()
        //
        InputMap = record
            MoveUp, MoveRight, MoveDown, MoveLeft, Attack, Special, Menu, Select: KeyCode;
        end;

    //
    //  Gets the key code of whatever key the user last pressed down
    //
    function GetKeyCode(): KeyCode;

    //
    //  Sets input map to default settings
    //
    procedure SetDefaultInput(var inputs: InputMap);

    //
	//	Checks if the sprite is already using the passed in animation string
	//	and if not, starts a new animation using that string
	//
	procedure SwitchAnimation(var sprite: Sprite; ani: String);

    //
    //  Moves an entity around the passed in map in a given direction at a given speed.
    //  Updates sprite animations, velocity, and collision. If the speed is set to anything
    //  less thanzero, it will automatically play an idle animation based off the passed in
    //  direction.
    //
    procedure MoveEntity(var map: MapData; var toMove: Entity; dir: Direction; speed: Single; pickup: Boolean);

    procedure ChangeKeyTo(var inputs: InputMap; var keyToChange: String);

implementation
  uses GameUI, typinfo, SysUtils;

    function GetKeyCode(): KeyCode;
    var
        i: KeyCode;
    begin
      result := UnknownKey;

      for i := Low(KeyCode) to High(KeyCode) do
      begin
        if KeyDown(i) then
        begin
          result := i;
          break;
        end;
      end;
    end;

    procedure ChangeKeyTo(var inputs: InputMap; var keyToChange: String);
    var
      keyPos: Integer;
      keyStr, controlStr: String;
      newKey: KeyCode;
    begin
      WriteLn(keyStr);
      keyStr := keyToChange;
			keyPos := Pos(': ', keyStr);
			keyStr := Copy(keyStr, 0, keyPos - 1);
			keyStr := StringReplace(keyStr, ' ', '', [rfReplaceAll]);
      newKey := GetKeyCode();
      case keyStr of
        'MoveUp': inputs.MoveUp := newKey;
        'MoveRight': inputs.MoveRight := newKey;
        'MoveDown': inputs.MoveDown := newKey;
        'MoveLeft': inputs. MoveLeft := newKey;
        'Attack': inputs.Attack := newKey;
        'Menu': inputs.Menu := newKey;
        'Select': inputs.Select := newKey;
        'Special': inputs.Special := newKey;
      end;

      WriteStr(controlStr, newKey);
			keyStr := Copy(keyToChange, keyPos + 2, Length(keyToChange));
      keyStr := StringReplace(keyToChange, keyStr, controlStr, [rfReplaceAll]);
      keyToChange := StringReplace(keyStr, 'Key', ' Key' ,[rfReplaceAll]);
      WriteLn(keyToChange);
    end;

    procedure SetDefaultInput(var inputs: InputMap);
    begin
        inputs.MoveUp := UpKey;
        inputs.MoveRight := RightKey;
        inputs.MoveDown := DownKey;
        inputs.MoveLeft := LeftKey;
        inputs.Attack := XKey;
        inputs.Menu := EscapeKey;
        inputs.Select := SpaceKey;
        inputs.Special := ZKey;
    end;

    procedure SwitchAnimation(var sprite: Sprite; ani: String);
	begin
	  	if not (SpriteAnimationName(sprite) = ani) then
		begin
			SpriteStartAnimation(sprite, ani);
		end;
	end;

    procedure MoveEntity(var map: MapData; var toMove: Entity; dir: Direction; speed: Single; pickup: Boolean);
    var
        velocity: Vector;
        hasCollision: Boolean;
    begin
      toMove.direction := dir;
      velocity.x := 0;
      velocity.y := 0;

      if speed > 0 then
      begin
          if dir = DirUp then
          begin
              velocity.y -= speed;
              SwitchAnimation(toMove.sprite, 'entity_up');
          end
          else if dir = DirRight then
          begin
              velocity.x += speed;
              SwitchAnimation(toMove.sprite, 'entity_right');
          end
          else if dir = DirDown then
          begin
              velocity.y += speed;
              SwitchAnimation(toMove.sprite, 'entity_down');
          end
          else if dir = DirLeft then
          begin
              velocity.x -= speed;
              SwitchAnimation(toMove.sprite, 'entity_left');
          end;
      end
      else
      begin
        case toMove.direction of
  				DirUp: SwitchAnimation(toMove.sprite, 'entity_up_idle');
  				DirRight: SwitchAnimation(toMove.sprite, 'entity_right_idle');
  				DirDown: SwitchAnimation(toMove.sprite, 'entity_down_idle');
  				DirLeft: SwitchAnimation(toMove.sprite, 'entity_left_idle');
			  end;
      end;

      SpriteSetDX(toMove.sprite, velocity.x);
	    SpriteSetDY(toMove.sprite, velocity.y);

      CheckCollision(map, toMove.sprite, dir, hasCollision, pickup);

      if toMove.attackTimeout > 0 then
      begin
        SpriteSetDX(toMove.sprite, 0);
  	    SpriteSetDY(toMove.sprite, 0);
      end;
    end;

end.
