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
        
    procedure UpdateSpawns(var map: MapData);
    
    procedure UpdateNPCS(var map: MapData);
    
    procedure UpdateNPCAI(var map: MapData; var npc: Entity);

implementation
    uses SwinGame, Input;
    
    procedure SpawnNPC(var map: MapData; x, y: LongInt);
    var
        newNPC: Entity;
    begin
        SetLength(map.npcs, Length(map.npcs) + 1);
        newNPC.sprite := CreateSprite(BitmapNamed('hunter'), AnimationScriptNamed('player'));
        SpriteSetPosition(newNPC.sprite, PointAt(x, y));
        newNPC.direction := Down;
        SwitchAnimation(newNPC.sprite, 'entity_down_idle');
        newNPC.nextUpdate := 1;
        newNPC.hp := 100;
        map.npcs[High(map.npcs)] := newNPC;
        DrawSprite(newNPC.sprite);
    end;
    
    procedure UpdateNPCAI(var map: MapData; var npc: Entity);
    begin
        if Random(100) > 95 then
        begin
            npc.direction := Direction(Random(4));
        end;
        if Random(10) > 5 then
        begin
            MoveEntity(map, npc, npc.direction, 3);            
        end;
    end;
    
    procedure UpdateSpawns(var map: MapData);
    var
        x, y: LongInt;
    begin
        for x := 0 to High(map.tiles) do
        begin
            for y := 0 to High(map.tiles) do
            begin
                if not (map.tiles[x, y].collidable) and (Random(1000) > 995) and (Length(map.npcs) < 100) then
                begin
                    SpawnNPC(map, x * 32, y * 32);
                end;
            end;
        end;
    end;
    
    procedure UpdateNPCS(var map: MapData);
    var 
        i: Integer;
        playerPos, npcPos: Point2D;
    begin
        playerPos := PointAt(SpriteX(map.player.sprite), SpriteY(map.player.sprite));
        for i := 0 to High(map.npcs) do
        begin
            npcPos := PointAt(SpriteX(map.npcs[i].sprite), SpriteY(map.npcs[i].sprite));
            map.npcs[i].nextUpdate -= 100 / PointPointDistance(playerPos, npcPos);
            if map.npcs[i].nextUpdate < 0 then
            begin
                map.npcs[i].nextUpdate := 1;
                UpdateNPCAI(map, map.npcs[i]);
            end;               
        end;
    end;

end.