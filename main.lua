TCUR = RegisterMod("Tainted Cain Uncrafting Rebalance", 1);
local rng = RNG();

local EIDEnabled = true;

local failsafeOnItemUncraft = false;

local lastTouchedItemId = 0;
local lastTouchedItemPosition = Vector(-1,-1);

local recipesToCalculatePerFrame = 10;
local failsafeRecipesToCalculatePerFrame = 1000;

local calculatedRecipes = {}

local usedRecipes = {}

local amountRecipePickups = { 2, 5 }
local amountRoomPickups = { 1, 3 }

-- CONSTS
local maxVelX = 3.0;
local maxVelY = 3.0;

local affectedPickups = {
    10, -- Hearts
    20, -- Coins
    30, -- Keys
    40, -- Bombs
    70, -- Pills
    90, -- Batteries
    300 -- Cards
}

local itemPoolsComponents = {
    [3] = 3, -- devil = black heart
    [4] = 4, -- angel = eternal heart
    [8] = 5, -- golden chest = golden heart
    [5] = 6, -- secret room = bone heart
    [12] = 7, -- curse room = rotten heart
    [26] = 23, -- planetarium = rune
    [9] = 25, -- red chest = cracked key
    [7] = 29, -- shell game = poop nugget
}

local componentToPickups = {
	[1]  = {{10,1}, {10,2}, {10,5}, {10,9}, {10,10}}, -- red heart / half heart / double heart / scared heart / blended heart
	[2]  = {{10,3}, {10,8}, {10,10}}, -- soul heart / half soul heart / blended heart
	[3]  = {{10,6}}, -- black heart
	[4]  = {{10,4}}, -- eternal heart
	[5]  = {{10,7}}, -- gold heart
	[6]  = {{10,11}}, -- bone heart
	[7]  = {{10,12}}, -- rotten heart
	[8]  = {{20,1}, {20,4}}, -- penny / double penny
	[9]  = {{20,2}, {20,6}}, -- nickel / sticky nickel
	[10] = {{20,3}}, -- dime
	[11] = {{20,5}}, -- lucky penny
	[12] = {{30,1}, {30,3}}, -- key / double key
	[13] = {{30,2}}, -- golden key
	[14] = {{30,4}}, -- charged key
	[15] = {{40,1}, {40,2}}, -- bomb / double bomb
	[16] = {{40,4}}, -- golden bomb
	[17] = {{40,7}}, -- giga bomb
	[18] = {{90,2}}, -- micro battery
	[19] = {{90,1}}, -- lil battery
	[20] = {{90,3}}, -- mega battery
    [21] = {{300,0}}, -- card / rune
    [22] = {{70,0}}, -- pill
    [23] = {{300,0}}, -- card / rune
    [24] = {{300,49}}, -- dice shard
    [25] = {{300,78}}, -- cracked key
	[26] = {{20,7}}, -- golden penny
    [27] = {{70,14}, {70,2062}}, -- golden pill
    [28] = {{90,4}}, -- golden battery
	[29] = {{42,0}, {42,1}}, -- poop nugget / big poop nugget
}

-- FUNCTIONS
function TCUR:onGameStarted()
    print("new game started")
    failsafeOnItemUncraft = false
    lastTouchedItemId = 0;
    lastTouchedItemPosition = Vector(-1,-1);
    calculatedRecipes = { -- set as the fixed recipes and modified as we calculate recipes
        [36] = {{29,29,29,29,29,29,29,29}},
        [177] = {{8,8,8,8,8,8,8,8}},
        [45] = {{1,1,1,1,1,1,1,1}},
        [686] = {{2,2,2,2,2,2,2,2}},
        [118] = {{3,3,3,3,3,3,3,3}},
        [343] = {{12,12,12,12,12,12,12,12}},
        [37] = {{15,15,15,15,15,15,15,15}},
        [85] = {{21,21,21,21,21,21,21,21}},
        [331] = {{1,2,4,4,4,4,4,5}},
        [182] = {{4,4,4,4,4,4,4,4}},
        [75] = {{22,22,22,22,22,22,22,22}},
        [654] = {{3,22,22,22,22,22,22,22}},
        [639] = {{1,1,1,1,1,1,7,7}},
        [175] = {{12,12,12,12,12,12,13,13}},
        [483] = {{17,17,17,17,17,17,17,17},{15,15,15,15,15,15,16,16}},
        [628] = {{6,6,6,6,6,6,6,6}},
        [489] = {{24,24,24,24,24,24,24,24}},
        [580] = {{25,25,25,25,25,25,25,25}}
    }
    usedRecipes = {}
end

function TCUR:postUpdate()
    -- print("we have " .. #calculatedRecipes .. " recipes")

    local calculationCount = recipesToCalculatePerFrame;

    if failsafeOnItemUncraft then
        calculationCount = failsafeRecipesToCalculatePerFrame
    end

    for i = 1, calculationCount, 1 do
        -- Calculate recipes
        local components = {
            rng:RandomInt(29)+1,
            rng:RandomInt(29)+1,
            rng:RandomInt(29)+1,
            rng:RandomInt(29)+1,
            rng:RandomInt(29)+1,
            rng:RandomInt(29)+1,
            rng:RandomInt(29)+1,
            rng:RandomInt(29)+1
        };

        local itemId = EID:calculateBagOfCrafting(components);
        local calculatedRecipesOfItemId = calculatedRecipes[itemId]
        if (calculatedRecipesOfItemId == nil) then
            table.insert(calculatedRecipes, {[itemId] = {components}}); 
        else
            local alreadySaved = false
            for i = 1, #calculatedRecipesOfItemId, 1 do
                local savedComponents = calculatedRecipesOfItemId[i]

                if calculatedRecipesOfItemId == components then
                    alreadySaved = true
                end
            end

            if alreadySaved == false then
                table.insert(calculatedRecipesOfItemId, components);
            end
        end
    end

    if failsafeOnItemUncraft then
        failsafeOnItemUncraft = false;
        TCUR:onItemUncraft();
    end
end

-- Item pick post update
function TCUR:postPickupUpdate(item)
    local itemId = item.SubType;

    for i = 1, Game():GetNumPlayers() do
        local player = Isaac.GetPlayer(i-1);
        
        -- Detect if the player is Tainted Cain
        local isTaintedCain = false;
        if (player:GetPlayerType() == 23) then
            isTaintedCain = true;
        end
        
        -- Detect if external item descriptions is enabled
        if (isTaintedCain and EIDEnabled) then
            -- Detect if the item is touched by player. Two different conditions for failsafe 
            if (((player.Position - item.Position):Length() < player.Size + item.Size or item.Touched)) then
                if (itemId > 0) then
                    lastTouchedItemId = itemId;
                    lastTouchedItemPosition = item.Position;
                end
            end
            
            if (lastTouchedItemId > 0 and not item:Exists()) then
                TCUR.onItemUncraft();
            end
        end
    end
end

-- On pickup spawn
function TCUR:postPickupInit(pickup)
    -- Pickup spawned by uncrafting (theorically)
    if (TCUR:isPickupPartOfRecipe(pickup.Variant) and pickup.Position.X == lastTouchedItemPosition.X and pickup.Position.Y == lastTouchedItemPosition.Y) then
        pickup:Remove();
    end
end

-- Return whether the pickup is part of the craftable pickups
function TCUR:isPickupPartOfRecipe(pickupId)
    for i = 1, #affectedPickups do
        if (affectedPickups[i] == pickupId) then
            return true;
        end
    end

    return false;
end

function TCUR:onItemUncraft()
    -- look up if this item's recipe was already calculated
    local itemRecipes = calculatedRecipes[lastTouchedItemId];
    if (itemRecipes ~= nil and itemRecipes[1] ~= nil) then
        -- Get a random recipe among the calculated recipes for the item
        local recipeIdx = rng:RandomInt(#itemRecipes) + 1;
        local recipe = itemRecipes[recipeIdx];
        
        -- Get the item pool of the current room and check if we have special pickups for it
        local room = Game():GetRoom():GetType();
        local roomItemPool = Game():GetItemPool():GetPoolForRoom(room, rng:GetSeed());
        
        local roomComponentId = -1;
        for key, value in pairs(itemPoolsComponents) do
            if (key == roomItemPool) then
                roomComponentId = value;
                break;
            end
        end
        
        -- Get count of each pickup
        local itemQuality = Isaac.GetItemConfig():GetCollectible(lastTouchedItemId).Quality;
        print("itemQuality: " .. itemQuality)
        local recipeOffset = 0;
        local roomOffset = 0;
        if (itemQuality >= 2) then
            roomOffset = 1;
        end
        if (itemQuality >= 4) then
            recipeOffset = 1;
        end
        print("recipeOffset: " .. recipeOffset)
        print("roomOffset: " .. roomOffset)

        local minRecipePickups = amountRecipePickups[1] + recipeOffset;
        local maxRecipePickups = amountRecipePickups[2];
        local recipePickupsCount = minRecipePickups + rng:RandomInt(maxRecipePickups - minRecipePickups + 1);
        print("recipePickupsCount: " .. recipePickupsCount)
        
        local minRoomPickups = amountRoomPickups[1] + roomOffset;
        local maxRoomPickups = amountRoomPickups[2];
        local roomPickupsCount = minRoomPickups + rng:RandomInt(maxRoomPickups - minRoomPickups + 1);
        print("roomPickupsCount: " .. roomPickupsCount)

        local amountPickupSpawned = 0

        -- Spawn recipe pickups
        for i = 1, recipePickupsCount, 1 do
            local componentId = recipe[i];

            TCUR:spawnComponent(componentId, amountPickupSpawned);
            amountPickupSpawned = amountPickupSpawned + 1;
        end

        -- Spawn room pickups
        for i = 1, roomPickupsCount, 1 do   
            local componentId = 0
            if (roomComponentId ~= -1) then
                componentId = roomComponentId
            else
                local normalComponents = {1, 8, 12, 15}
                local index = rng:RandomInt(#normalComponents) + 1
                componentId = normalComponents[index]
            end

            TCUR:spawnComponent(componentId, amountPickupSpawned);
            amountPickupSpawned = amountPickupSpawned + 1;
        end

        table.insert(usedRecipes, recipe)
    else
        failsafeOnItemUncraft = true;
        return;
    end

    lastTouchedItemId = 0;
    lastTouchedItemPosition = Vector(-1,-1);
end

function TCUR:spawnComponent(componentId, amountPickupSpawned)
    local corrPickups = componentToPickups[componentId];
    local i = rng:RandomInt(#corrPickups) + 1;
    local chosenPickup = corrPickups[i];

    -- very very slight offset to prevent the pickup from being deleted and prevent overlapping pickups
    local posX = lastTouchedItemPosition.X + 0.001 * (amountPickupSpawned + 1);
    local posY = lastTouchedItemPosition.Y;

    local velX = rng:RandomInt(maxVelX*2+1) - maxVelX;
    local velY = rng:RandomInt(maxVelY*2+1) - maxVelY;

    Isaac.Spawn(5, chosenPickup[1], chosenPickup[2], Vector(posX,posY), Vector(velX,velY), nil)
end

TCUR:AddCallback(ModCallbacks.MC_POST_UPDATE, TCUR.postUpdate);
TCUR:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, TCUR.postPickupUpdate, PickupVariant.PICKUP_COLLECTIBLE);
TCUR:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT , TCUR.postPickupInit);
TCUR:AddCallback(ModCallbacks.MC_POST_GAME_STARTED , TCUR.onGameStarted);

if (EID == nil) then
    Isaac.DebugString("TAINTED CAIN UNCRAFTING REBALANCE - WARNING: External Item Descriptions must be installed and enabled for this mod to work.");
    print("TAINTED CAIN UNCRAFTING REBALANCE - WARNING: External Item Descriptions must be installed and enabled for this mod to work.");
    EIDEnabled = false;
end