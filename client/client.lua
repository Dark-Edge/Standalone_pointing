local mp_pointing = false
local keyPressed = false
local once = true
local oldval = false
local oldvalped = false

local function RotAnglesToDirection(rotation)
    local adjustedRotation = vector3(math.rad(rotation.x), math.rad(rotation.y), math.rad(rotation.z))
    local direction = vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )
    return direction
end

local function getCoordsFromCam() 
    -- On récupère le joueur
    local playerPed = PlayerPedId()
    
    -- On récupère la position de départ du raycast (la caméra du joueur)
    local camCoords = GetGameplayCamCoord()
    
    -- On récupère la direction vers laquelle le joueur regarde
    local camRot = GetGameplayCamRot(2)
    local camDirection = RotAnglesToDirection(camRot)
    
    -- Définir la portée du raycast (distance maximale)
    local distance = 1000.0
    local destination = camCoords + (camDirection * distance)

    -- On lance un raycast de la position de la caméra vers la destination calculée
    local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, destination.x, destination.y, destination.z, 10, playerPed, 7)
    local _, hit, endCoords, surfaceNormal, materialHash = GetShapeTestResult(rayHandle)

    if hit == 1 then
        return endCoords
    else
        -- Si aucune collision n'est trouvée, renvoyer la destination directement (cela aide à obtenir des coordonnées même quand aucune entité n'est visée)
        return destination
    end
end

local function startPointing()
    local ped = PlayerPedId()
    RequestAnimDict("ai_react@point@base")
    while not HasAnimDictLoaded("ai_react@point@base") do
        Wait(0)
    end
    SetPedCurrentWeaponVisible(ped, 0, 1, 1, 1)
    SetPedConfigFlag(ped, 36, 1)
	TaskPlayAnim( ped,"ai_react@point@base","point_fwd", -1, -1, -1, 30, 0, false, false, false)
    RemoveAnimDict("point_fwd")
end

local function stopPointing()
    local ped = PlayerPedId()
    RequestTaskMoveNetworkStateTransition(ped, "Stop")
    if not IsPedInjured(ped) then
        ClearPedSecondaryTask(ped)
    end
    if not IsPedInAnyVehicle(ped, 1) then
        SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
    end
    SetPedConfigFlag(ped, 36, 0)
    ClearPedSecondaryTask(PlayerPedId())
end

Citizen.CreateThread(function()
    while true do
		local ped = PlayerPedId()
		local coords = getCoordsFromCam()
        Wait(0)
        if once then
            once = false
        end
        if not keyPressed then
            if IsControlPressed(0, 0x80F28E95) and not mp_pointing and IsPedOnFoot(PlayerPedId()) then
                Wait(200)
                if not IsControlPressed(0, 0x80F28E95) then
                    keyPressed = true
                    startPointing()
                    mp_pointing = true
                else
                    keyPressed = true
                    while IsControlPressed(0, 0x80F28E95) do
                        Wait(50)
                    end
                end
            elseif (IsControlPressed(0, 0x80F28E95) and mp_pointing) or (not IsPedOnFoot(PlayerPedId()) and mp_pointing) then
                keyPressed = true
                mp_pointing = false
                stopPointing()
            end
        end
        if keyPressed then
            if not IsControlPressed(0, 0x80F28E95) then
                keyPressed = false
            end
        end
        if IsEntityPlayingAnim(ped,"ai_react@point@base","point_fwd",1) and not mp_pointing then
            stopPointing()
        end
        if IsEntityPlayingAnim(ped,"ai_react@point@base","point_fwd",1) then
            if not IsPedOnFoot(PlayerPedId()) then
                stopPointing()
            else
			if coords then  
				print(coords.x,coords.y,coords.z) --print("Les coordonnées visées par le joueur sont : ", coords)
				SetIkTarget(ped, 4, 0, 0, coords.x, coords.y, coords.z, 0, 0, 0)
				RequestTaskMoveNetworkStateTransition(ped, "Stop")
			end
            end
        end
    end
end)

RegisterNetEvent('pointing:sync')
AddEventHandler('pointing:sync', function(playerId, isPointing, pos, rot)
    local ped = GetPlayerPed(GetPlayerFromServerId(playerId))
	local coords = getCoordsFromCam()
    if isPointing then
        TaskPlayAnim( ped,"ai_react@point@base","point_fwd", -1, -1, -1, 30, 0, false, false, false)
        SetEntityCoords(ped, pos.x, pos.y, pos.z)
		if coords then  
			print(coords.x,coords.y,coords.z) --print("Les coordonnées visées par le joueur sont : ", coords)
			SetIkTarget(ped, 4, 0, 0, coords.x, coords.y, coords.z, 0, 0, 0)
			RequestTaskMoveNetworkStateTransition(ped, "Stop")
		end
    else
        ClearPedTasks(ped)
    end
end)

