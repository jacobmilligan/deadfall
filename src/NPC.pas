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

  //
  //  Sets up the initial spawns for the map based off the passed-in
  //  maps default data i.e. size, spawnrate etc.
  //
  procedure SeedSpawns(var map: MapData);

  //
  //  Keeps searching for a random, non-collidable tile on the map to spawn
  //  an NPC. Only actually spawns if a second random value is high enough.
  //
  procedure UpdateSpawns(var map: MapData);

  //
  //  Handles collision-detection, interactions with the player (i.e. attack results) and
  //  delegates to pathfinding functions. Only updates AI if the NPC is close enough to the
  //  player to be more efficient
  //
  procedure UpdateNPCS(var map: MapData);

  //
  //  Handles NPC pathfinding. Uses a super basic wall tracing method, i.e. if the NPC hits
  //  a wall, it then searches four tiles around it for an open path with the least cost (distance)
  //  to its current goal (a random point on the map)
  //
  procedure UpdateNPCAI(var map: MapData; var npc: Entity; npcIndex: Integer; const playerDistance: Single);

  //
  //  Turns the entity in the opposite direction to what it's currently facing
  //
  procedure TurnAround(var toTurn: Entity);

implementation
  uses Game, Input, Math, sgTypes;

  procedure SpawnNPC(var map: MapData; x, y: LongInt);
  var
    newNPC: Entity;
    newGoal: Point2D;
  begin
    // Only spawn rabbits outside the boundaries of the current camera view
    if ( x < CameraX() ) or ( x > CameraX() + ScreenWidth() ) or ( y < CameraY() ) or ( y > CameraY() + ScreenHeight() ) then
    begin
      SetLength(map.npcs, Length(map.npcs) + 1);

      newNPC.sprite := CreateSprite(BitmapNamed('bunny'), AnimationScriptNamed('player'));
      SpriteAddLayer(newNPC.sprite, BitmapNamed('bunny_hurt'), 'hurt');

      // Setup default NPC stats
      newNPC.dir := DirDown;
      newNPC.nextUpdate := 1;
      newNPC.hp := 100;
      newNPC.stuckCounter := 0;
      newNPC.id := 'Rabbit';
      newNPC.moveSpeed := 1;
      newNPC.attackTimeout := 0;

      // Spawn in the NPC at the random position
      SpriteSetPosition(newNPC.sprite, PointAt(x, y));
      SwitchAnimation(newNPC.sprite, 'entity_down_idle');

      // Give it a new goal to head towards
      newGoal := PointAt(SpriteX(newNPC.sprite) + Random(map.size), SpriteY(newNPC.sprite) + Random(map.size));
      newNPC.currentGoal := newGoal;

      map.npcs[High(map.npcs)] := newNPC;
      DrawSprite(newNPC.sprite);
    end;
  end;

  //
  //  Removes an NPC from the NPC array by copying all higher elements
  //  to one element lower
  //
  procedure RemoveNPC(deleteIndex: Integer; var npcs: EntityCollection);
  var
    i: Integer;
  begin
    for i := deleteIndex to High(npcs) do
    begin
      if i < High(npcs) then
      begin
        npcs[i] := npcs[i + 1];
      end;
    end;
    SetLength(npcs, Length(npcs) - 1);
  end;

  procedure TurnAround(var toTurn: Entity);
  var
    newDir: Direction;
    newDirIndex: Integer;
  begin
    // As directions are clockwise from up, right, down, left in the dir enum
    // you can face the opposite direction by incrementing 2 and wrapping if
    // higher than High(direction)
    newDirIndex := Integer(toTurn.dir);
    newDirIndex += 2;
    if newDirIndex > Integer( High(Direction) ) then
    begin
      newDirIndex -= Integer( High(Direction) ) + 1;
    end;
    toTurn.dir := Direction(newDirIndex);
  end;

  // Converts an x and y tile coordinate relative to the NPC to a dir
  function GetDir(x, y: Integer): Direction;
  begin
    result := DirDown;

    if (x = 0) and (y = 1) then
    begin
      result := DirLeft;
    end
    else if (x = 1) and (y = 0) then
    begin
      result := DirUp;
    end
    else if (x = 1) and (y = 2) then
    begin
      result := DirDown;
    end
    else if (x = 2) and (y = 1) then
    begin
      result := DirRight;
    end;
  end;

  //
  //  Searches in a cross shaped pattern of four tiles around the NPC
  //  for an open path with the lowest cost. If the NPC is stuck it creates a new
  //  goal for the NPC and calls itself recursively
  //
  procedure FindOpenPath(var map: MapData; var npc: Entity; npcIndex: Integer);
  var
    localX, localY, x, y, i, j, collidableCount: Integer;
    currentPath, bestPath: Single;
    dir: Direction;
    newPath: Path;
    hasCollision: Boolean;
  begin
    x := Trunc(SpriteX(npc.sprite) / 32);
    y := Trunc(SpriteY(npc.sprite) / 32);
    bestPath := 0;
    collidableCount := 0;
    newPath.dir := DirDown;
    newPath.cost := PointPointDistance(PointAt(x * 32, y * 32), npc.currentGoal);

    localX := 0;
    for i := x - 1 to x + 1 do
    begin

      localY := 0;
      for j := y - 1 to y + 1 do
      begin

        //
        //  Only look at tiles that surround the entity in a cross-shaped manner:
        //      *
        //    * o *
        //      *
        //
        if IsInMap(map, i, j) and ( (localX = 1) or (localY = 1) ) then
        begin
          currentPath := PointPointDistance(PointAt(i * 32, j * 32), npc.currentGoal);
          CheckCollision(map, npc.sprite, GetDir(localX, localY), hasCollision, false);

          // Check if the current direction is a better path than the current one
          if (hasCollision = false) and (currentPath < newPath.cost) then
          begin
            newPath.dir := GetDir(localX, localY);
            newPath.cost := currentPath;
            collidableCount -= 1;
          end;

          // The NPC may be stuck if there are collisions in the best path, increase stuckCounter
          if hasCollision then
          begin
            npc.stuckCounter += 1;
            collidableCount += 1;
            TurnAround(npc);
          end;

        end;
        localY += 1;
      end;
      localX += 1;
    end;

    // Check if NPC is at the end of an alleyway
    if collidableCount > 3 then
    begin
      TurnAround(npc);
      MoveEntity(map, npc, npc.dir, 2, false);
    end;

    // Check if NPC is stuck
    if npc.stuckCounter > 0 then
    begin
      TurnAround(npc);
      MoveEntity(map, npc, npc.dir, 2, false);
      // Give NPC a new random goal
      npc.currentGoal := PointAt(SpriteX(npc.sprite) - Random(map.size), SpriteY(npc.sprite) - Random(map.size));
      npc.stuckCounter := 0;
    end;

    npc.dir := newPath.dir;
  end;

  procedure UpdateNPCAI(var map: MapData; var npc: Entity; npcIndex: Integer; const playerDistance: Single);
  var
    i: Integer;
    canMove: Boolean;
    playerPos, npcPos: Point2D;
  begin
    // Reset NPC's move speed if they've been punched and outrun the player
    if npc.moveSpeed > 1 then
    begin
      if playerDistance > map.size then
      begin
        npc.moveSpeed := 1;
      end
    end;

    FindOpenPath(map, npc, npcIndex);

    // Reset to new goal if the NPC reached its goal
    if PointPointDistance(npc.currentGoal, PointAt(SpriteX(npc.sprite), SpriteY(npc.sprite))) <= 64 then
    begin
      MoveEntity(map, npc, npc.dir, 0, false);
      npc.currentGoal := PointAt(SpriteX(npc.sprite) + Random(map.size), SpriteY(npc.sprite) + Random(map.size));
    end
    else
    begin
      MoveEntity(map, npc, npc.dir, npc.moveSpeed, false);
    end;

    UpdateSprite(npc.sprite);
  end;

  procedure SeedSpawns(var map: MapData);
  var
    x, y: LongInt;
  begin

    for x := 0 to High(map.tiles) do
    begin

      for y := 0 to High(map.tiles) do
      begin
        // Spawn in a bunch of NPC's
        if not (map.tiles[x, y].collidable) and (Random(1000) > 995) and (Length(map.npcs) < map.maxSpawns) then
        begin
          SpawnNPC(map, x * 32, y * 32);
        end;
      end;

    end;
  end;

  procedure UpdateSpawns(var map: MapData);
  var
    x, y: LongInt;
  begin

    x := Random( Length(map.tiles) - 1 );
    y := Random( Length(map.tiles) - 1 );
    // Keep finding spawns until an appropriate one is found
    while (map.tiles[x, y].collidable) or (map.tiles[x, y].flag = Water) do
    begin
      x := Random( Length(map.tiles) - 1 );
      y := Random( Length(map.tiles) - 1 );
    end;

    if (Random(1000) > 500) and (Length(map.npcs) < map.maxSpawns) then
    begin
      SpawnNPC(map, x * 32, y * 32);
    end;
  end;

  procedure UpdateNPCS(var map: MapData);
  var
    toRemove, i: Integer;
    playerPos, npcPos: Point2D;
    playerDist, updateDist: Single;
    attackRect: Rectangle;
  begin
    toRemove := 0;
    playerPos := PointAt( SpriteX(map.player.sprite), SpriteY(map.player.sprite) );
    updateDist := ScreenWidth() * 3;

    //
    //  Iterate in reverse to allow for removal of items from the array
    //  while still looping as we can safely copy values already iterated due
    //  to our finish condition being zero rather than High(map.npcs)
    //
    //  This also only updates the NPCs if they're close enough to the player
    //
    for i := High(map.npcs) downto 0 do
    begin
      npcPos := PointAt( SpriteX(map.npcs[i].sprite), SpriteY(map.npcs[i].sprite) );
      playerDist := PointPointDistance(playerPos, npcPos);

      // If NPC is still alive, do interactions
      if ( map.npcs[i].hp > 0 ) and ( playerDist < updateDist ) then
      begin
        // Update NPC's less frequently if far away from player to save resources
        map.npcs[i].nextUpdate -= 100 / playerDist;

        if map.npcs[i].nextUpdate < 0 then
        begin
          map.npcs[i].nextUpdate := 1;
          UpdateNPCAI(map, map.npcs[i], i, playerDist);
        end;
        // Check collision with the player
        if SpriteCollision(map.npcs[i].sprite, map.player.sprite) then
        begin
          case map.player.dir of
            DirUp: SpriteSetDY(map.player.sprite, 2);
            DirRight: SpriteSetDX(map.player.sprite, -2);
            DirDown: SpriteSetDY(map.player.sprite, -2);
            DirLeft: SpriteSetDX(map.player.sprite, 2);
          end;
        end;
        // Handle attack interaction with the player
        if (map.player.attackTimeout > map.player.maxAttackSpeed - 3) and (playerDist <= map.tilesize) then
        begin

          //
          //  Uses a collision rectangle placed 16px in front of whatever dir
          //  the player is facing
          //
          case map.player.dir of
            DirUp: attackRect := CreateRectangle(SpriteX(map.player.sprite), SpriteY(map.player.sprite) - 16, 28, 28);
            DirRight: attackRect := CreateRectangle(SpriteX(map.player.sprite) + 16, SpriteY(map.player.sprite), 28, 28);
            DirDown: attackRect := CreateRectangle(SpriteX(map.player.sprite), SpriteY(map.player.sprite) + 16, 28, 28);
            DirLeft: attackRect := CreateRectangle(SpriteX(map.player.sprite) - 16, SpriteY(map.player.sprite), 28, 28);
          end;

          // Player is in contact with the NPC while attacking
          if SpriteRectCollision(map.npcs[i].sprite, attackRect) then
          begin
            PlaySoundEffect(SoundEffectNamed('punch'), 0.2);
            PlaySoundEffect(SoundEffectNamed('bunny'), 0.5);
            SpriteShowLayer(map.npcs[i].sprite, 'hurt');
            map.npcs[i].hp -= 20;
            map.npcs[i].moveSpeed := 2;

            case map.player.dir of
              DirUp: map.npcs[i].currentGoal := PointAt(SpriteX(map.npcs[i].sprite), SpriteY(map.npcs[i].sprite) - map.size);
              DirRight: map.npcs[i].currentGoal := PointAt(SpriteX(map.npcs[i].sprite) + map.size, SpriteY(map.npcs[i].sprite));
              DirDown: map.npcs[i].currentGoal := PointAt(SpriteX(map.npcs[i].sprite), SpriteY(map.npcs[i].sprite) + map.size);
              DirLeft: map.npcs[i].currentGoal := PointAt(SpriteX(map.npcs[i].sprite) - map.size, SpriteY(map.npcs[i].sprite));
            end;
          end
        end
        else if (map.player.attackTimeout = 0) then
        begin
          SpriteHideLayer(map.npcs[i].sprite, 'hurt');
        end;
      end
      //
      //  Otherwise, if NPC is dead, remove from NPC array and spawn new
      //  food feature where they were
      //
      else if playerDist < updateDist then
      begin
        RemoveNPC(i, map.npcs);
        if map.tiles[Floor(npcPos.x / 32), Floor(npcPos.y / 32)].feature = NoFeature then
        begin
          SetFeature(map.tiles[Floor(npcPos.x / 32), Floor(npcPos.y / 32)], Food, false);
        end
        else if map.tiles[Ceil(npcPos.x / 32), Ceil(npcPos.y / 32)].feature = NoFeature then
        begin
          SetFeature(map.tiles[Ceil(npcPos.x / 32), Ceil(npcPos.y / 32)], Food, false);
        end
        else
        begin
          PlaySoundEffect(SoundEffectNamed('pickup'), 0.5);
          map.inventory.items[SearchInventory(map.inventory.items, 'Rabbit Leg')].count += 1;
        end;
      end;
    end;
  end;

end.
