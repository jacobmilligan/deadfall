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
        InputMap = record
            MoveUp, MoveRight, MoveDown, MoveLeft: KeyCode;
        end;

    function GetKeyCode(): KeyCode;
    
    procedure SetDefaultInput(var inputs: InputMap);
    
implementation
    
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
                Exit;
            end;
        end;
    end;
    
    procedure SetDefaultInput(var inputs: InputMap);
    begin
        inputs.MoveUp := UpKey;
        inputs.MoveRight := RightKey;
        inputs.MoveDown := DownKey;
        inputs.MoveLeft := LeftKey;
    end;
    
end.