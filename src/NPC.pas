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
    
    type        
        Path = record
            dir: Direction;
            cost: Single;
        end;
        
    procedure UpdateSpawns(var map: MapData);
    
    procedure UpdateNPCS(var map: MapData);
    
    procedure UpdateNPCAI(var map: MapData; var npc: Entity);
    

implementation
    uses Input, Math;
    
    procedure SpawnNPC(var map: MapData; x, y: LongInt);
    var
        newNPC: Entity;
        newGoal: Point2D;
    begin
        SetLength(map.npcs, Length(map.npcs) + 1);
        newNPC.sprite := CreateSprite(BitmapNamed('bunny'), AnimationScriptNamed('player'));
        SpriteSetPosition(newNPC.sprite, PointAt(x, y));
        newNPC.direction := Down;
        SwitchAnimation(newNPC.sprite, 'entity_down_idle');
        newNPC.nextUpdate := 1;
        newNPC.hp := 100;
        
        newGoal := PointAt(Random(513) * 32, Random(513) * 32);        
        
        newNPC.currentGoal := newGoal;
        
        map.npcs[High(map.npcs)] := newNPC;
        DrawSprite(newNPC.sprite);
    end;
    
    function GetDir(x, y: Integer): Direction;
    begin
        result := Down;
        
        if (x = 0) and (y = 1) then
        begin
            result := Left;
        end
        else if (x = 1) and (y = 0) then
        begin
            result := Up;
        end
        else if (x = 1) and (y = 2) then
        begin
            result := Down;
        end
        else if (x = 2) and (y = 1) then
        begin
            result := Right;
        end;
    end;

    procedure FindOpenPath(var map: MapData; var npc: Entity);
    var
        localX, localY, x, y, i, j: Integer;
        currentPath, bestPath: Single;
        dir: Direction;
        newPath: Path;
        hasCollision: Boolean;
    begin
        x := Trunc(SpriteX(npc.sprite) / 32);
        y := Trunc(SpriteY(npc.sprite) / 32);
        bestPath := 0;
        newPath.dir := Down;
        newPath.cost := PointPointDistance(PointAt(x * 32, y * 32), npc.currentGoal);
        
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
                        CheckCollision(map, npc.sprite, GetDir(localX, localY), hasCollision);

                        if (hasCollision = false) and (currentPath < newPath.cost) then
                        begin
                            newPath.dir := GetDir(localX, localY);
                            newPath.cost := currentPath;
                        end
                    end;
                end;
                localY += 1;
            end;
            localX += 1;
        end;   
        
        npc.direction := newPath.dir;
    end;
    
    procedure UpdateNPCAI(var map: MapData; var npc: Entity);
    var
        i: Integer;
        canMove: Boolean;
        playerPos, npcPos: Point2D;
    begin
        FindOpenPath(map, npc);
        if PointPointDistance(npc.currentGoal, PointAt(SpriteX(npc.sprite), SpriteY(npc.sprite))) <= 64 then
        begin
            MoveEntity(map, npc, npc.direction, 0);
        end
        else
        begin
            MoveEntity(map, npc, npc.direction, 1);
        end;
        UpdateSprite(npc.sprite);
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
    
    procedure RemoveNPC(deleteIndex: Integer; var npcs: EntityCollection);
    var
        i: Integer;
    begin
        for i := deleteIndex to High(npcs) do
        begin
            npcs[i] := npcs[i + 1];
        end;
        SetLength(npcs, Length(npcs) - 1);
    end;
    
    procedure UpdateNPCS(var map: MapData);
    var 
        toRemove, i: Integer;
        playerPos, npcPos: Point2D;
        attackRect: Rectangle;
    begin
        toRemove := 0;
        playerPos := PointAt(SpriteX(map.player.sprite), SpriteY(map.player.sprite));
        
        // Iterate in reverse to allow for removal of items from the array
        for i := High(map.npcs) downto 0 do
        begin
            npcPos := PointAt(SpriteX(map.npcs[i].sprite), SpriteY(map.npcs[i].sprite));
            
            if map.npcs[i].hp > 0 then
            begin
                map.npcs[i].nextUpdate -= 100 / PointPointDistance(playerPos, npcPos);
                
                if map.npcs[i].nextUpdate < 0 then
                begin
                    map.npcs[i].nextUpdate := 1;
                    UpdateNPCAI(map, map.npcs[i]);
                end;
                if SpriteCollision(map.npcs[i].sprite, map.player.sprite) then
                begin
                    case map.player.direction of
                        Up: SpriteSetDY(map.player.sprite, 2); 
                        Right: SpriteSetDX(map.player.sprite, -2);
                        Down: SpriteSetDY(map.player.sprite, -2);
                        Left: SpriteSetDX(map.player.sprite, 2);
                    end;
                end;
                
                if (map.player.attackTimeout > 0) then
                begin
                    case map.player.direction of
                        Up: attackRect := CreateRectangle(SpriteX(map.player.sprite), SpriteY(map.player.sprite) - 16, 28, 28); 
                        Right:attackRect := CreateRectangle(SpriteX(map.player.sprite) + 16, SpriteY(map.player.sprite), 28, 28);
                        Down: attackRect := CreateRectangle(SpriteX(map.player.sprite), SpriteY(map.player.sprite) + 16, 28, 28);
                        Left: attackRect := CreateRectangle(SpriteX(map.player.sprite) - 16, SpriteY(map.player.sprite), 28, 28);
                    end;
                    
                    if SpriteRectCollision(map.npcs[i].sprite, attackRect) then
                    begin
                        map.npcs[i].hp -= 10;                                            
                    end;
                end;
            end
            else
            begin
                RemoveNPC(i, map.npcs);
                if map.tiles[Floor(npcPos.x / 32), Floor(npcPos.y / 32)].feature = None then
                begin
                    map.tiles[Floor(npcPos.x / 32), Floor(npcPos.y / 32)].feature := Food;
                end
                else if map.tiles[Ceil(npcPos.x / 32), Ceil(npcPos.y / 32)].feature = None then
                begin
                    map.tiles[Ceil(npcPos.x / 32), Ceil(npcPos.y / 32)].feature := Food;
                end
                else
                begin
                    AddToInventory(map.inventory, Food, 'Rabbit leg');
                end;
            end;
        end;        
    end;
    
end.