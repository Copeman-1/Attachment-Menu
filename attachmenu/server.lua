local QBCore = exports['qb-core']:GetCoreObject()
local ox = exports.ox_inventory

local function hasAccess(src)
    if not next(Config.AllowedJobs) then return true end

    local player = QBCore.Functions.GetPlayer(src)
    if not player then return false end

    local job = player.PlayerData.job
    local minGrade = job and Config.AllowedJobs[job.name]
    if minGrade == nil then return false end

    return ((job.grade and job.grade.level) or 0) >= minGrade
end

local function fail(msg)
    return { ok = false, msg = msg }
end

-- The server's copy of an ox_inventory item has no `client` table, so the list of
-- valid attachments (and their type/label) is read straight from ox_inventory's
-- data/weapons.lua instead.
local attachmentData = {} -- [itemName] = { label = ..., type = ... }

local function loadComponents()
    local raw = LoadResourceFile('ox_inventory', 'data/weapons.lua')
    if not raw then
        return lib.print.error('attachmenu: could not read ox_inventory/data/weapons.lua')
    end

    local chunk, err = load(raw, '@ox_inventory/data/weapons.lua', 't')
    if not chunk then
        return lib.print.error(('attachmenu: could not parse data/weapons.lua: %s'):format(err))
    end

    local ok, data = pcall(chunk)
    if not ok or type(data) ~= 'table' or type(data.Components) ~= 'table' then
        return lib.print.error('attachmenu: data/weapons.lua has no Components table')
    end

    local count = 0
    for name, def in pairs(data.Components) do
        attachmentData[name] = { label = def.label, type = def.type }
        count = count + 1
    end

    lib.print.info(('attachmenu: loaded %d attachments'):format(count))
end

loadComponents()

lib.callback.register('attachmenu:access', function(src)
    return hasAccess(src)
end)

--- Click an attachment: installs it, or removes it if it is already installed.
--- Installing a part of the same `type` as one already on the weapon replaces it
--- (same rule ox_inventory uses: one attachment per type).
lib.callback.register('attachmenu:toggle', function(src, slotNumber, componentName)
    if not hasAccess(src) then return fail('You cannot use the attachment menu.') end
    if type(slotNumber) ~= 'number' or type(componentName) ~= 'string' then return fail('Invalid request.') end

    local slot = ox:GetSlot(src, slotNumber)
    if not slot then return fail('Weapon not found.') end

    local weaponDef = ox:Items(slot.name)
    if not (weaponDef and (weaponDef.weapon or slot.name:upper():find('^WEAPON_'))) then
        return fail('That item is not a weapon.')
    end

    local comp = attachmentData[componentName]
    if not comp then
        return fail('Invalid attachment.')
    end

    -- Work on copies so we never mutate ox_inventory's live tables
    local metadata = {}
    for k, v in pairs(slot.metadata or {}) do metadata[k] = v end

    local components = {}
    for i, name in ipairs(metadata.components or {}) do components[i] = name end

    local exactIndex, sameTypeIndex
    for i, name in ipairs(components) do
        if name == componentName then
            exactIndex = i
        else
            local other = attachmentData[name]
            if other and other.type and other.type == comp.type then sameTypeIndex = i end
        end
    end

    local removeIndex = exactIndex or sameTypeIndex
    local installing = not exactIndex
    local removedName = removeIndex and components[removeIndex] or nil

    -- Item checks happen before anything is changed
    if Config.ConsumeItems then
        if installing and (ox:GetItemCount(src, componentName) or 0) < 1 then
            return fail(('You do not have: %s'):format(comp.label or componentName))
        end

        if removedName and not ox:CanCarryItem(src, removedName, 1) then
            return fail('Not enough inventory space to take the old attachment back.')
        end

        if installing and not ox:RemoveItem(src, componentName, 1) then
            return fail('Could not take the attachment from your inventory.')
        end

        if removedName then ox:AddItem(src, removedName, 1) end
    end

    if removeIndex then table.remove(components, removeIndex) end
    if installing then components[#components + 1] = componentName end

    metadata.components = components
    ox:SetMetadata(src, slotNumber, metadata)

    return {
        ok = true,
        msg = installing and ('Installed: %s'):format(comp.label or componentName)
            or ('Removed: %s'):format(comp.label or componentName),
        added = installing and componentName or nil,
        removed = removedName,
    }
end)
