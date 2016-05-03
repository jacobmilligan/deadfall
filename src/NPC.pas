//
//  Deadfall v1.0
//  NPC.pas
//
// -------------------------------------------------------
//
//  Created By Jacob Milligan
//  On 03/05/2016
//  Student ID: 100660682
//

unit NPC;

interface
    uses Map;
    
    
    procedure SpawnNPC(var map: MapData);

implementation
    uses SwinGame;
    
    procedure SpawnNPC(var map: MapData);
    var
        currentView: TileView;
        x, y: LongInt
    begin
        currentView := CreateTileView();
        
        for x := 0 to High(map.tiles) do
        begin
            for y := 0 to High(map.tiles) do
            begin
                if not map.tiles[x, y].collidable and Random(10) > 5 then
                begin
                    
                end;
            end;
        end;
    end;

end.