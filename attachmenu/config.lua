Config = {}

-- Chat command that opens the menu. Set to false to disable the command
-- (you can still open it with exports['attachmenu']:openMenu()).
Config.Command = 'attachments'

-- Who can use the menu. Leave empty ({}) to allow everyone.
-- Format: [jobName] = minimumGrade
-- Example: { gunsmith = 0, police = 3 }
Config.AllowedJobs = {}

-- false = attachments are free (click to add / click again to remove).
-- true  = the attachment ITEM must be in the player's inventory. It is consumed
--         when installed and handed back when removed or replaced.
Config.ConsumeItems = false

-- Order the categories appear in. Any type not listed here is added afterwards
-- in alphabetical order, so new attachment types still show up automatically.
Config.CategoryOrder = {
    'magazine', 'scope', 'muzzle', 'barrel', 'grip', 'stock',
    'flashlight', 'laser', 'frame', 'slide', 'clip', 'base', 'misc',
}

-- Menu titles per attachment `type` from ox_inventory's data/weapons.lua
Config.CategoryLabels = {
    magazine   = 'Magazines',
    scope      = 'Scopes & Sights',
    muzzle     = 'Muzzles & Suppressors',
    barrel     = 'Barrels',
    grip       = 'Grips & Handguards',
    stock      = 'Stocks',
    flashlight = 'Lights',
    laser      = 'Lasers',
    frame      = 'Frames & Bodies',
    slide      = 'Slides',
    clip       = 'Rails, Covers & Bipods',
    base       = 'Base Parts',
    misc       = 'Miscellaneous',
}

-- Font Awesome icon names per attachment type
Config.CategoryIcons = {
    magazine   = 'battery-full',
    scope      = 'crosshairs',
    muzzle     = 'volume-xmark',
    barrel     = 'ruler-horizontal',
    grip       = 'hand',
    stock      = 'gun',
    flashlight = 'lightbulb',
    laser      = 'bullseye',
    frame      = 'cube',
    slide      = 'arrows-left-right',
    clip       = 'screwdriver-wrench',
    base       = 'layer-group',
    misc       = 'wrench',
}
