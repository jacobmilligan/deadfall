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
    uses SwinGame, Map;
                
    procedure UpdateSpawns(var map: MapData);
    
    procedure UpdateNPCS(var map: MapData);
    
    procedure UpdateNPCAI(var map: MapData; var npc: Entity);
    

implementation
    uses Input;
    
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
        newNPC.currentGoal := PointAt(SpriteX(map.player.sprite), SpriteY(map.player.sprite));
        map.npcs[High(map.npcs)] := newNPC;
        DrawSprite(newNPC.sprite);
    end;
    
    
    
    procedure FindOpenPath(var map: MapData; var npc: Entity);
    var
        localX, localY, x, y, i, j, bestX, bestY: Integer;
        currentPath, bestPath: Single;
    begin
        x := Trunc(SpriteX(npc.sprite) / 32);
        y := Trunc(SpriteY(npc.sprite) / 32);
        
        localX := 0;
        for i := x - 1 to x + 1 do
        begin
            
            localY := 0;
            for j := y - 1 to y + 1 do
            begin
            
                if not OutOfBounds(map.tiles, i, j) then
                begin
                    if (localX = 1) or (localY = 1) then
                    begin
                        currentPath := PointPointDistance(PointAt(i * 32, j * 32), npc.currentGoal);
                        
                        if (currentPath > bestPath) then
                        begin
                            bestPath := currentPath;
                            
                            if (localX = 0) and (localY = 1) then
                            begin
                                npc.direction := Right;
                            end
                            else if (localX = 1) and (localY = 0) then
                            begin
                                npc.direction := Down;
                            end
                            else if (localX = 1) and (localY = 2) then
                            begin
                                npc.direction := Up;
                            end
                            else if (localX = 2) and (localY = 1) then
                            begin
                                npc.direction := Left;
                            end;
                            
                            if map.tiles[i, j].collidable then
                            begin
                                case npc.direction of
                                    Up: SpriteSetDY(npc.sprite, 5); 
                                    Right: SpriteSetDX(npc.sprite, -5);
                                    Down: SpriteSetDY(npc.sprite, -5);
                                    Left: SpriteSetDX(npc.sprite, 5);
                                end;
                            end; 
                            
                        end;
                    end;
                end;
                localY += 1;
            end;
            localX += 1;
        end;
       
    end;
    
    procedure UpdateNPCAI(var map: MapData; var npc: Entity);
    var
        i: Integer;
        canMove: Boolean;
    begin
        npc.currentGoal := PointAt(SpriteX(map.player.sprite), SpriteY(map.player.sprite));
        //DrawLine(ColorRed, PointAt(SpriteX(npc.sprite), SpriteY(npc.sprite)), npc.currentGoal);
        //RefreshScreen(60);
        if Random(10) > 5 then
        begin
            FindOpenPath(map, npc);
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
                if not (map.tiles[x, y].collidable) and (Random(1000) > 995) and (Length(map.npcs) < 1) then
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