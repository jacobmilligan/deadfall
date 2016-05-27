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

  procedure SeedSpawns(var map: MapData);

  procedure UpdateSpawns(var map: MapData);

  procedure UpdateNPCS(var map: MapData);

  procedure UpdateNPCAI(var map: MapData; var npc: Entity);


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

      newNPC.direction := DirDown;
      newNPC.nextUpdate := 1;
      newNPC.hp := 100;
      newNPC.stuckCounter := 0;
      newNPC.id := 'Rabbit';

      SpriteSetPosition(newNPC.sprite, PointAt(x, y));
      SwitchAnimation(newNPC.sprite, 'entity_down_idle');

      newGoal := PointAt(Random(513) * 32, Random(513) * 32);
      newNPC.currentGoal := newGoal;

      map.npcs[High(map.npcs)] := newNPC;
      DrawSprite(newNPC.sprite);
    end;
  end;

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

          if (hasCollision = false) and (currentPath < newPath.cost) then
          begin
            newPath.dir := GetDir(localX, localY);
            newPath.cost := currentPath;
          end;

          if hasCollision then
          begin
            npc.stuckCounter += 1;
          end;

        end;
        localY += 1;
      end;
      localX += 1;
    end;

    if npc.stuckCounter > 4 then
    begin
      npc.currentGoal := PointAt(Random(513) * 32, Random(513) * 32);
      npc.stuckCounter := 0;
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
      MoveEntity(map, npc, npc.direction, 0, false);
    end
    else
    begin
      MoveEntity(map, npc, npc.direction, 1, false);
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
    //Randomize;
    x := Random( Length(map.tiles) - 1 );
    y := Random( Length(map.tiles) - 1 );
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
          UpdateNPCAI(map, map.npcs[i]);
        end;
        // Check collision with the player
        if SpriteCollision(map.npcs[i].sprite, map.player.sprite) then
        begin
          case map.player.direction of
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
          //  Uses a collision rectangle placed 16px in front of whatever direction
          //  the player is facing
          //
          case map.player.direction of
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
            map.npcs[i].hp -= 10;
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
