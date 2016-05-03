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
        Path = array of Point2D;
        
        NodePtr = ^Node;
        
        Node = record
            id: Integer;
            pos: Point2D;
            f, g, h: Integer;
            previous: NodePtr;
            hasPrevious: Boolean;
            collidable: Boolean;
	    end;
        
        Nodes = array of Node;
        
    procedure UpdateSpawns(var map: MapData);
    
    procedure UpdateNPCS(var map: MapData);
    
    procedure UpdateNPCAI(var map: MapData; var npc: Entity);
    
    function AStar(var map: MapData; start, goal: Point2D): Path;

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
        map.npcs[High(map.npcs)] := newNPC;
        DrawSprite(newNPC.sprite);
    end;
    
    function FindNodeInList(var nodeList: Nodes; const id: Integer): Integer;
    var
        i: Integer;
    begin
        result := -1;
        
        for i := 0 to High(nodeList) do
        begin
            if nodeList[i].id = id then
            begin
                result := i;
                break;
            end;
        end;
    end;
    
    procedure AddNode(var currentSet: Nodes; var toAdd: Node);
    begin
        SetLength(currentSet, Length(currentSet) + 1);
        currentSet[High(currentSet)] := toAdd;
    end;
    
    procedure RemoveNode(var currentSet: Nodes; var toRemove: Node);
    var
        i, j: Integer;
    begin
        for i := 0 to High(currentSet) do
        begin
            if currentSet[i].id = toRemove.id then
            begin
                for j := i + 1 to High(currentSet) do
                begin
                    currentSet[j - 1] := currentSet[j];
                end;
                SetLength(currentSet, Length(currentSet) - 1);
            end;
        end;
    end;
    
    procedure AddNeighbour(var map: MapData; var currList: Nodes; x, y: Single; var id: Integer);
    var
        toAdd: Node;
    begin
        if not OutOfBounds(map.tiles, Round(x), Round(y)) then
        begin
            id += 1;
            
            toAdd.pos.x := x;
            toAdd.pos.y := y;
            toAdd.f := 0;
            toAdd.g := 0;
            toAdd.h := 0;
            toAdd.hasPrevious := false;
            toAdd.id := id;
            toAdd.collidable := map.tiles[Round(x), Round(y)].collidable;
            AddNode(currList, toAdd);
        end;
    end;
            
    function GetNeighbours(var map: MapData; var current: Node; var id: Integer): Nodes;
    var
        x, y: Single;
        neighbour: Node;
        nList: Nodes;
    begin
        x := current.pos.x;
        y := current.pos.y;
        SetLength(nList, 0);
        
        AddNeighbour(map, nList, x - 1, y, id);
        AddNeighbour(map, nList, x + 1, y, id);
        AddNeighbour(map, nList, x, y + 1, id);
        AddNeighbour(map, nList, x, y - 1, id);
        
        result := nList;
    end;

    function FindLowestCost(var openSet: Nodes): Integer;
    var
        lowest, i: Integer;
    begin
        lowest := 0;
        for i := 0 to High(openSet) do
        begin
            if openSet[i].f < openSet[lowest].f then
            begin
                lowest := i;
            end;
        end;
        result := lowest;
    end;
    
    function GetHeuristic(var current, goal: Point2D): Integer;
    begin
        result := Round(Abs(goal.x - current.x) + Abs(goal.y - current.y));
    end;
    
    function AStar(var map: MapData; start, goal: Point2D): Path;
    var
        openSet, closedSet, neighbours: Nodes;
        current: Node;
        nextId, i, currentG: Integer; 
        isBestNeighbour: Boolean;
        finalPath: Path;
    begin
        SetLength(result, 0);
        SetLength(closedSet, 0);
        SetLength(openSet, 1);
        
        nextId := 1;
        
        current.pos := start;
        current.f := 0;
        current.g := 0;
        current.h := 0;
        current.hasPrevious := false;
        current.id := nextId;

        openSet[0] := current;

        while Length(openSet) > 0 do
        begin
            current := openSet[FindLowestCost(openSet)];
            
            if PointPointDistance(current.pos, goal) < 100 then
            begin
                while current.hasPrevious do
                begin
                    SetLength(finalPath, Length(finalPath) + 1);
                    finalPath[High(finalPath)] := current.pos;
                    current := current.previous^;
                end;
            end;
            
            RemoveNode(openSet, current);
            AddNode(closedSet, current);
            
            neighbours := GetNeighbours(map, current, nextId);
            
            for i := 0 to High(neighbours) do
            begin
                currentG := current.g + 1;
                isBestNeighbour := false;
                
                if (FindNodeInList(closedSet, neighbours[i].id) < 0) or not (neighbours[i].collidable) then
                begin
                    
                    if FindNodeInList(openSet, neighbours[i].id) >= 0 then
                    begin
                        isBestNeighbour := true;
                        neighbours[i].h := GetHeuristic(neighbours[i].pos, goal);
                        AddNode(openSet, neighbours[i]);
                    end
                    else if ( currentG < neighbours[i].g ) then
                    begin
                        isBestNeighbour := true;
                    end;
                    
                    if isBestNeighbour then
                    begin
                        New(neighbours[i].previous);
                        neighbours[i].previous^ := current;
                        neighbours[i].g := currentG;
                        neighbours[i].f := neighbours[i].g + neighbours[i].h;
                    end;
                end;
                
            end;
        end;
    end;

    
    procedure UpdateNPCAI(var map: MapData; var npc: Entity);
    var
        pathTo: Path;
        i: Integer;
    begin
        pathTo := AStar(map, PointAt(SpriteX(npc.sprite), SpriteY(npc.sprite)), PointAt(SpriteX(map.player.sprite), SpriteY(map.player.sprite)));
        
        for i := 0 to High(pathTo) do
        begin
            MoveSpriteTo(npc.sprite, Round(pathTo[i].x * 32), Round(pathTo[i].y * 32));
        end;  
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