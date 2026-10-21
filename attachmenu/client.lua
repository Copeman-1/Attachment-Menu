local ox = exports.ox_inventory

local attachments = nil -- [itemName] = item definition (every ox_inventory item that is a weapon component)
local fitCache = {}     -- [weaponName] = { byType = { [type] = { itemName, ... } }, total = n }

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function toHash(component)
    if type(component) == 'string' then return joaat(component) end
    return component
end

local function titleCase(str)
    return (str:gsub('^%l', string.upper))
end

--- Every ox_inventory item that carries a weapon component hash (built once).
local function getAttachments()
    if attachments then return attachments end

    attachments = {}
    for name, item in pairs(ox:Items()) do
        if item.client and item.client.component then
            attachments[name] = item
        end
    end

    return attachments
end

local function isWeapon(slot)
    if not slot or not slot.name then return false end
    local def = ox:Items(slot.name)
    if def and def.throwable then return false end
    return (def and def.weapon) or slot.name:upper():find('^WEAPON_') ~= nil
end

local function getSlot(slotNumber)
    for _, slot in pairs(ox:GetPlayerItems()) do
        if slot.slot == slotNumber then return slot end
    end
end

local function installedSet(slot)
    local set = {}
    local components = slot.metadata and slot.metadata.components
    if components then
        for i = 1, #components do set[components[i]] = true end
    end
    return set
end

--- Which attachments fit a weapon, grouped by type. The game itself answers this
--- through DoesWeaponTakeWeaponComponent, so there is no hand-written
--- weapon -> attachment list to maintain when you add new weapons.
local function getFit(weaponName)
    if fitCache[weaponName] then return fitCache[weaponName] end

    local weaponHash = joaat(weaponName)
    local byType, total = {}, 0

    for name, item in pairs(getAttachments()) do
        local components = item.client.component
        for i = 1, #components do
            if DoesWeaponTakeWeaponComponent(weaponHash, toHash(components[i])) then
                local t = item.type or 'misc'
                byType[t] = byType[t] or {}
                byType[t][#byType[t] + 1] = name
                total = total + 1
                break
            end
        end
    end

    for _, list in pairs(byType) do
        table.sort(list, function(a, b)
            return (attachments[a].label or a) < (attachments[b].label or b)
        end)
    end

    fitCache[weaponName] = { byType = byType, total = total }
    return fitCache[weaponName]
end

local function sortedTypes(byType)
    local ordered, seen = {}, {}

    for _, t in ipairs(Config.CategoryOrder) do
        if byType[t] then
            ordered[#ordered + 1] = t
            seen[t] = true
        end
    end

    local extra = {}
    for t in pairs(byType) do
        if not seen[t] then extra[#extra + 1] = t end
    end
    table.sort(extra)

    for _, t in ipairs(extra) do ordered[#ordered + 1] = t end
    return ordered
end

--- If the weapon being changed is the one in the player's hands, update it live.
--- (Holstered weapons pick the change up from their metadata when drawn.)
local function applyToEquippedWeapon(slotNumber, added, removed)
    local ok, current = pcall(function() return ox:getCurrentWeapon() end)
    if not ok or not current or current.slot ~= slotNumber then return end

    local ped = cache.ped
    local weaponHash = current.hash or joaat(current.name)

    if removed then
        local comps = getAttachments()[removed].client.component
        for i = 1, #comps do
            RemoveWeaponComponentFromPed(ped, weaponHash, toHash(comps[i]))
        end
    end

    if added then
        local comps = getAttachments()[added].client.component
        for i = 1, #comps do
            local hash = toHash(comps[i])
            if DoesWeaponTakeWeaponComponent(weaponHash, hash) then
                GiveWeaponComponentToPed(ped, weaponHash, hash)
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Menus
-- ---------------------------------------------------------------------------

local openMain, openCategories, openAttachments

function openAttachments(slotNumber, attType)
    local slot = getSlot(slotNumber)
    if not slot then return end

    local list = getFit(slot.name).byType[attType]
    if not list then return openCategories(slotNumber) end

    local installed = installedSet(slot)
    local options = {}

    for _, name in ipairs(list) do
        local item = getAttachments()[name]
        local isOn = installed[name] == true

        options[#options + 1] = {
            title = item.label or name,
            description = isOn and 'Installed - click to remove' or nil,
            icon = isOn and 'circle-check' or 'circle',
            iconColor = isOn and 'green' or nil,
            onSelect = function()
                local res = lib.callback.await('attachmenu:toggle', false, slotNumber, name)

                if res and res.msg then
                    lib.notify({ type = res.ok and 'success' or 'error', description = res.msg })
                end

                if res and res.ok then
                    applyToEquippedWeapon(slotNumber, res.added, res.removed)
                end

                Wait(150) -- let ox_inventory push the updated slot to us
                openAttachments(slotNumber, attType)
            end,
        }
    end

    lib.registerContext({
        id = 'attachmenu_list',
        title = ('%s - %s'):format(slot.label or slot.name, Config.CategoryLabels[attType] or titleCase(attType)),
        menu = 'attachmenu_categories',
        options = options,
    })
    lib.showContext('attachmenu_list')
end

function openCategories(slotNumber)
    local slot = getSlot(slotNumber)
    if not slot then return end

    local fit = getFit(slot.name)
    local installed = installedSet(slot)
    local options = {}

    for _, attType in ipairs(sortedTypes(fit.byType)) do
        local list = fit.byType[attType]

        local current
        for _, name in ipairs(list) do
            if installed[name] then current = getAttachments()[name].label or name end
        end

        options[#options + 1] = {
            title = Config.CategoryLabels[attType] or titleCase(attType),
            description = current and ('Installed: %s'):format(current) or ('%d available'):format(#list),
            icon = Config.CategoryIcons[attType] or 'wrench',
            arrow = true,
            onSelect = function() openAttachments(slotNumber, attType) end,
        }
    end

    lib.registerContext({
        id = 'attachmenu_categories',
        title = slot.label or slot.name,
        menu = 'attachmenu_main',
        options = options,
    })
    lib.showContext('attachmenu_categories')
end

function openMain()
    if not lib.callback.await('attachmenu:access', false) then
        return lib.notify({ type = 'error', description = 'You cannot use the attachment menu.' })
    end

    local options = {}

    for _, slot in pairs(ox:GetPlayerItems()) do
        if isWeapon(slot) then
            local fit = getFit(slot.name)
            local components = slot.metadata and slot.metadata.components
            local installedCount = components and #components or 0
            local slotNumber = slot.slot

            options[#options + 1] = {
                title = slot.label or slot.name,
                description = fit.total > 0
                    and ('%d attachments available | %d installed'):format(fit.total, installedCount)
                    or 'No attachments available for this weapon',
                icon = 'gun',
                arrow = fit.total > 0,
                disabled = fit.total == 0,
                metadata = slot.metadata and slot.metadata.serial and {
                    { label = 'Serial', value = slot.metadata.serial },
                } or nil,
                onSelect = function() openCategories(slotNumber) end,
            }
        end
    end

    if #options == 0 then
        return lib.notify({ type = 'error', description = 'You have no weapons in your inventory.' })
    end

    lib.registerContext({
        id = 'attachmenu_main',
        title = 'Weapon Attachments',
        options = options,
    })
    lib.showContext('attachmenu_main')
end

-- ---------------------------------------------------------------------------
-- Entry points
-- ---------------------------------------------------------------------------

if Config.Command then
    RegisterCommand(Config.Command, function() openMain() end, false)
end

exports('openMenu', openMain)
