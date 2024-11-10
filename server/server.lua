-- Cette partie ne fait pas grand-chose dans ce cas, mais on l'utilise pour transmettre l'information du client à tous les autres clients
RegisterNetEvent('pointing:update')
AddEventHandler('pointing:update', function(isPointing, pos, rot)
    local _source = source
    TriggerClientEvent('pointing:sync', -1, _source, isPointing, pos, rot)
end)