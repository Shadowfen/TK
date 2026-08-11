internal = internal or {}
internal.guilds = internal.guilds or {}  -- index  = {id, guildname, num_members, guildmaster}


_G["d"] = print

ZOS ={}
ZO_SAVED_VARS_CHARACTER_NAME_KEY = 1
ZO_SAVED_VARS_CHARACTER_ID_KEY = 2

INVENTORY_BACKPACK = 1
INVENTORY_CRAFT_BAG = 2
INVENTORY_GUILD_BANK = 3
INVENTORY_HOUSE_BANK = 4
INVENTORY_BANK = 5
INVENTORY_FURNITURE_VAULT = 6
INVENTORY_VENGEANCE = 7

SMITHING = { deconstructionPanel = {inventory = {}}, improvementPanel = {inventory = {}} }
UNIVERSAL_DECONSTRUCTION = { deconstructionPanel = {inventory = {}}, inventory = {} }

SLASH_COMMANDS = {}


zo_floor = math.floor


-- ------------------------------------------------------------
-- addonManager
local addonManager = { lst = {} }
function addonManager:GetNumAddOns()
  return #self.lst
end

function GetAddOnManager()
    return addonManager
end

function addonManager:GetAddOnInfo(ndx)
    if self.lst[ndx] then
        return unpack(self.lst[ndx])
    end
    return
end

function addonManager:AddAddOnInfo(name, title, author, description, enabled, state, isOutOfDate, isLibrary)
    local ndx = #self.lst
    self.lst[ndx+1] = {name, title, author, description, enabled, state, isOutOfDate, isLibrary}
    return
end

-- ------------------------------------------------------------
-- Strings and localization
function zo_plainstrfind(text, pat)
  return string.find(text, pat)
end

function zo_strlen(str)
    return #str
end

function zo_strsub(str, i, j)
    return string.sub(str, i, j)
end

-- Enhanced zo_strformat for ESO-style string formatting
-- Supports <<1>>, <<2>>, etc. placeholders that map to varargs
function zo_strformat(formatString, ...)
    if formatString == nil then return "" end
    
    -- Capture varargs in a table first
    local args = {...}
    local numArgs = select('#', ...)
    
    -- Replace <<N>> placeholders with corresponding arguments
    return string.gsub(formatString, "<<(%d+)>>", function(match)
        local idx = tonumber(match)
        if idx and idx >= 1 and idx <= numArgs then
            local val = args[idx]  -- Use the captured table, not ...
            if val == nil then
                return "nil"
            else
                return tostring(val)
            end
        else
            -- Out of range placeholder - keep as-is
            return "<<" .. match .. ">>"
        end
    end)
end

-- localization functions
EsoStrings = {}
EsoStringNames = {}
EsoStringVersions = {}
ZOS.nextCustomId = 12108


function testZO_ResetStringTables()
    for k,v in pairs(EsoStringNames) do
        _G[k] = nil
    end
    EsoStrings = {}
    EsoStringVersions = {}
    ZOS.nextCustomId = 12108
end

function SafeAddVersion(stringId, stringVersion)
    if(stringId) then
        EsoStringVersions[stringId] = stringVersion
    end
end

function SafeAddString(stringId, stringValue, stringVersion)
    if stringId then
        local existingVersion = EsoStringVersions[stringId]
        if (existingVersion == nil) or (existingVersion <= stringVersion) then
            EsoStrings[stringId] = stringValue
        end
    end
end

function GetString(id)
    return EsoStrings[id]
end

function ZO_CreateStringId(stringName, stringToAdd)
    _G[stringName] = ZOS.nextCustomId
    EsoStringNames[stringName] = ZOS.nextCustomId
    EsoStrings[ZOS.nextCustomId] = stringToAdd
    ZOS.nextCustomId = ZOS.nextCustomId + 1
end

-- end localization functions


local zos_locale = "en"
function GetCVar(var)
    if var == "language.2" then
        return zos_locale
    end
    return nil
end

function SetCVar(aspect, value)
    if aspect == "language.2" then
        zos_locale = value
    end
end

-- ------------------------------------------------------------

function GetDisplayName()
    return internal.atname
end

GetWorldName = function()
    return internal.world
end

function GetCurrentCharacterId()
    return internal.charId
end

function GetUnitName(who)
    return internal.toon
end

-- ---------------------------------------------------------------------
-- SavedVariables

ZO_SavedVars = {}

-- [ [ ZOS originals
local CreateExposedInterface, SearchPath, CreatePath, SetPath, CopyPotentialTable

local function SearchPath(t, ...)
    local current = t
    for i = 1, select("#", ...) do
        local key = select(i, ...)
        if key ~= nil then
            if not current[key] then
                return nil
            end
            current = current[key]
        end
    end
    return current
end

local function CopyPotentialTable(sv, key, defaults)
    if not rawget(sv, key) then 
        --SVs have nothing, copy and create a new entry
        rawset(sv, key, CopyDefaults({}, defaults))
    elseif type(sv[key]) == "table" then
        --SV has an entry, and it's a table, set it up for defaults
        CopyDefaults(sv[key], defaults)
    end
    --The SV isn't a table, nothing to do
end


function ZO_SavedVars:New(savedVariableTable, version, namespace, defaults, profile, displayName, characterName, characterId, characterKeyType)
    displayName = displayName or GetDisplayName()
    characterName = characterName or GetUnitName("player")
    characterId = characterId or GetCurrentCharacterId()
    characterKeyType = characterKeyType or ZO_SAVED_VARS_CHARACTER_NAME_KEY
    return GetNewSavedVars(savedVariableTable, version, namespace, defaults, profile, displayName, characterName, characterId, characterKeyType)
end

function ZO_SavedVars:NewCharacterNameSettings(savedVariableTable, version, namespace, defaults, profile)
    return GetNewSavedVars(savedVariableTable, version, namespace, defaults, profile, GetDisplayName(), GetUnitName("player"), GetCurrentCharacterId(), ZO_SAVED_VARS_CHARACTER_NAME_KEY)
end

function ZO_SavedVars:NewCharacterIdSettings(savedVariableTable, version, namespace, defaults, profile)
    return GetNewSavedVars(savedVariableTable, version, namespace, defaults, profile, GetDisplayName(), GetUnitName("player"), GetCurrentCharacterId(), ZO_SAVED_VARS_CHARACTER_ID_KEY)
end

function ZO_SavedVars:NewAccountWide(savedVariableTable, version, namespace, defaults, profile, displayName)
    displayName = displayName or GetDisplayName()
    return GetNewSavedVars(savedVariableTable, version, namespace, defaults, profile, displayName)
end

function GetNewSavedVars(savedVariableTable, version, namespace, defaults, profile, displayName, characterName, characterId, characterKeyType)
    if type(savedVariableTable) ~= "table" then
        if _G[savedVariableTable] == nil then
            _G[savedVariableTable] = {}
        end
        savedVariableTable = _G[savedVariableTable]
    end

    if type(savedVariableTable) ~= "table" then
        error("Can only apply saved variables to a table")
    end

    --namespace is an optional argument
    if defaults == nil and type(namespace) == "table" then
        profile = defaults
        defaults = namespace        
        namespace = nil
    end
    profile = profile or "Default"
    if type(profile) ~= "string" then
        error("Profile must be a string or nil")
    end

    local finalKey
    if characterName == nil then
        finalKey = "$AccountWide"
    else
        --Look for a table matching the opposite key type and if there is, then copy it over. This allows us to preserve the old
        --character name based settings mainly.
        local characterKey = characterKeyType == ZO_SAVED_VARS_CHARACTER_NAME_KEY and characterName or characterId
        local oppositeCharacterKey = characterKeyType == ZO_SAVED_VARS_CHARACTER_NAME_KEY and characterId or characterName

        local oppositeCharacterKeyTable = SearchPath(savedVariableTable, profile, displayName, oppositeCharacterKey, namespace)
        if oppositeCharacterKeyTable then
            SetPath(savedVariableTable, oppositeCharacterKeyTable, profile, displayName, characterKey, namespace)
            SetPath(savedVariableTable, nil, profile, displayName, oppositeCharacterKey, namespace)
        end

        --If an old style name based key is still being used then try to upgrade that based on a name change. Less robust.
        if characterKeyType == ZO_SAVED_VARS_CHARACTER_NAME_KEY and NAME_CHANGE:DidNameChange() then
            local oldCharacterName = NAME_CHANGE:GetOldCharacterName()
            local oldNameTable = SearchPath(savedVariableTable, profile, displayName, oldCharacterName, namespace)
            if oldNameTable then
                SetPath(savedVariableTable, oldNameTable, profile, displayName, characterName, namespace)
                SetPath(savedVariableTable, nil, profile, displayName, oldCharacterName, namespace)
            end
        end

        finalKey = characterKey
    end    

    local finalSavedVar = CreateExposedInterface(savedVariableTable, version, namespace, defaults, profile, displayName, finalKey)
    
    if characterName and characterKeyType == ZO_SAVED_VARS_CHARACTER_ID_KEY then
        savedVariableTable[profile][displayName][finalKey]["$LastCharacterName"] = characterName
    end

    return finalSavedVar
end

local function SetPath(t, value, ...)
    if value ~= nil then
        CreatePath(t, ...)
    end
    local current = t
    local parent
    local lastKey
    for i = 1, select("#", ...) do
        local key = select(i, ...)
        if key ~= nil then
            lastKey = key
            parent = current
            if current == nil then
                return
            end
            current = current[key]
        end
    end
    if parent ~= nil then
        parent[lastKey] = value
    end
end

local function CreatePath(t, ...)
    local current = t
    local container
    local containerKey
    for i=1, select("#", ...) do
        local key = select(i, ...)
        if key ~= nil then
            if not current[key] then
                current[key] = {}
            end
            container = current
            containerKey = key
            current = current[key]
        end
    end

    return current, container, containerKey
end

local function CopyPotentialTable(sv, key, defaults)
    if not rawget(sv, key) then 
        --SVs have nothing, copy and create a new entry
        rawset(sv, key, CopyDefaults({}, defaults))
    elseif type(sv[key]) == "table" then
        --SV has an entry, and it's a table, set it up for defaults
        CopyDefaults(sv[key], defaults)
    end
    --The SV isn't a table, nothing to do
end



function CopyDefaults(sv, defaults)
    for defaultKey, defaultValue in pairs(defaults) do
        if defaultKey == WILD_CARD_KEY then
            if type(defaultValue) == "table" then
                --Wild card value is a subtable, initialize the subtable
                InitializeWildCardFromDefaults(sv, defaultValue)
            else
                --Wild card value is (probably) a primitive, just return a copy when the wild card is indexed
                setmetatable(sv, { __index = function(t, k)
                    if k ~= nil then
                        return defaultValue
                    end
                end,})
            end
        elseif type(defaultValue) == "table" then
            CopyPotentialTable(sv, defaultKey, defaultValue)
        elseif rawget(sv, defaultKey) == nil then
            rawset(sv, defaultKey, defaultValue)
        end
    end

    return sv
end

local function InitializeRawTable(rawSavedTable, profile, namespace, displayName, playerName)
    return CreatePath(rawSavedTable, profile, displayName, playerName, namespace)
end

local function ExposeMethods(interface, namespace, rawSavedTable, defaults, profile, cachedInterfaces)
    --Gets an interface to the same saved variable table, but for a different character and/or world
    interface.GetInterfaceForCharacter = function(self, displayName, playerName)
        if currentDisplayName == displayName and currentPlayerName == playerName then
            return self
        end

        if not cachedInterfaces[displayName] then
            cachedInterfaces[displayName] = {}
        end
        if not cachedInterfaces[displayName][playerName] then
            cachedInterfaces[displayName][playerName] = CreateExposedInterface(rawSavedTable, self.version, namespace, defaults, profile, displayName, playerName, cachedInterfaces)
        end

        return cachedInterfaces[displayName][playerName]
    end
    interface.ResetToDefaults = function(self)
        local sv = getmetatable(self).__index
        if sv then
            local version = sv.version
            ZO_ClearTable(sv)
            sv.version = version
            if self.default then
                CopyDefaults(sv, self.default)
            end
        end
    end
end

function CreateExposedInterface(rawSavedTable, version, namespace, defaults, profile, displayName, playerName, cachedInterfaces)
    local current, container, containerKey = InitializeRawTable(rawSavedTable, profile, namespace, displayName, playerName)

    --if the data is unversioned or out of date, nuke the data first
    if current.version == nil or current.version < version then
        ZO_ClearTable(current)
    end

    current.version = version

    if defaults then
        CopyDefaults(current, defaults)
    end

    local interfaceMT = { 
        __index = current,

        __newindex = function(t, k, v)
            current[k] = v
        end,
    }

    local interface = {
        default = defaults,
    }

    cachedInterfaces = cachedInterfaces or {}

    ExposeMethods(interface, namespace, rawSavedTable, defaults, profile, cachedInterfaces)

    return setmetatable(interface, interfaceMT)
end

-- ---------------------------------------------------------------------


-- ---------------------------------------------------------------------
-- guild functions
function GetNumGuilds()
  if internal.guilds then
    return #internal.guilds
  end
  return 0
end

function GetGuildId(ndx)
    if internal.guilds and internal.guilds[ndx] then
        return internal.guilds[ndx][1] 
    end
    return 0
end

function GetGuildName(id)
    local name
    for k,v in pairs(internal.guilds) do
        if v[1] == id then
            name = v[2]
            break
        end
    end
    return name
end

-- returns number of members, number online, guildmaster
function GetGuildInfo(guildId)
    for k,v in pairs(internal.guilds) do
        if v[1] == guildId then
            return v[3], k, v[4]
        end
    end
    return nil
end

-- ---------------------------------------------------------------------

-- utilities

ZO_SortFilterList = {}
function ZO_SortFilterList:Subclass()
    local rv = {}
    rv.Subclass = ZO_SortFilterList.Subclass
    return rv
end
-- ---------------------------------------------------------------------

EVENT_MANAGER = {}
function EVENT_MANAGER:UnregisterForEvent()
end
function EVENT_MANAGER:RegisterForEvent()
end

-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------

ZO_Object = {}

function ZO_Object:New(template)
    template = template or self
    local newObject = setmetatable ({}, template)
    local mt = getmetatable (newObject)
    mt.__index = template
    
    return newObject
end

function ZO_Object:Subclass()
    return setmetatable({}, {__index = self})
end

-- ---------------------------------------------------------------------

ZO_CallbackObject = {}
function ZO_CallbackObject:New()

end

function ZO_CallbackObject:FireCallbacks()
end

function ZO_CallbackObject:RegisterCallback(name, func)
end

function ZO_CallbackObject:UnregisterCallback(name, func)
end

function ZO_CallbackObject:UnregisterAllCallbacks()
end
CALLBACK_MANAGER = ZO_CallbackObject

-- ---------------------------------------------------------------------
-- Tables
function ZO_IsTableEmpty(t)
    return not t or next(t) == nil
end

function ZO_ClearTable(t)
    for k in pairs(t) do
        t[k] = nil
    end
end

function ZO_IsElementInNumericallyIndexedTable(t, element)
    for index, value in ipairs(t) do
        if value == element then
            return true
        end
    end
    return false
end

function ZO_IndexOfElementInNumericallyIndexedTable(t, element)
    for index, value in ipairs(t) do
        if value == element then
            return index
        end
    end
    return nil
end


function NonContiguousCount(t)
    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

function ZO_ShallowTableCopy(source, dest)
    dest = dest or {}
    for k, v in pairs(source) do
        dest[k] = v
    end
    return dest
end


function ZO_DeepTableCopy(source, dest)
    dest = dest or {}
    setmetatable(dest, getmetatable(source))
    for k, v in pairs(source) do
        if type(v) == "table" then
            dest[k] = ZO_DeepTableCopy(v)
        else
            dest[k] = v
        end
    end
    return dest
end



-- ---------------------------------------------------------------------
function ZO_PreHook(objectTable, existingFunctionName, hookFunction)
    if type(objectTable) == "string" then
        hookFunction = existingFunctionName
        existingFunctionName = objectTable
        objectTable = _G
    end
     
    local existingFn = objectTable[existingFunctionName]
    if existingFn ~= nil and type(existingFn) == "function" then    
        local newFn =   function(...)
                            if not hookFunction(...) then
                                return existingFn(...)
                            end
                        end

        objectTable[existingFunctionName] = newFn
    end
    return existingFn
end

function ZO_PostHook(objectTable, existingFunctionName, hookFunction)
    if type(objectTable) == "string" then
        hookFunction = existingFunctionName
        existingFunctionName = objectTable
        objectTable = _G
    end
     
    local existingFn = objectTable[existingFunctionName]
    if existingFn ~= nil and type(existingFn) == "function" then    
        local newFn =   function(...)
                            local returns = {existingFn(...)}
                            hookFunction(...)
                            return unpack(returns)
                        end

        objectTable[existingFunctionName] = newFn
    end
    return existingFn
end

SecurePostHook = ZO_PostHook

-- ---------------------------------------------------------------------
CHAT_SYSTEM = {}
function CHAT_SYSTEM.AddMessage(message)
    print(message)
end

-- ---------------------------------------------------------------------
-- ESO Mail functions
local mockMailData = {}
MAIL_MANAGER = {}
function MAIL_MANAGER:ShouldDeleteOnClaim() return true end

MAIL_INBOX = {
    masterList = {},

    Add = function(self, entry) 
        self.masterList[#self.masterList+1] = entry
    end,

    GetMailData = function(self, mailId, isFromGuild)
        if self.masterList then
            for i = 1, #self.masterList do
                local data = self.masterList[i]
                if AreId64sEqual(data.mailId, mailId) and data.fromGuild == isFromGuild then
                    return data
                end
            end
        end
    end,

}

AreId64sEqual = function(dmailId, mailId)
    return true
end
-- Stub ESO mail API globals used by Postage
GetMailFlags = function(mailId)
    for _, m in ipairs(mockMailData) do
        if m.mailId == mailId then
            return 0, 0, m.fromSystem, m.fromCS
        end
    end
    return 0, 0, false, false
end

GetMailItemInfo = function(mailId)
    for _, m in ipairs(mockMailData) do
        if m.mailId == mailId then
            return 0, m.senderName, "", "", "", m.fromSystem, m.fromCS, 1
        end
    end
    return nil
end

GetMailAttachmentInfo = function(mailId)
    for _, m in ipairs(mockMailData) do
        if m.mailId == mailId then
            return m.numAttachments, m.attachedMoney, m.codAmount
        end
    end
    return 0, 0, 0
end

IsReadMailInfoReady = function(mailId) return true end
MailExists = function(mailId) return true end
TakeMailAttachments = function() end
DeleteMail = function() end
RequestReadMail = function() end
AreId64sEqual = function(a, b) return a == b end
GetAttachedItemLink = function() return "|Hitem:123|h|h" end
GetAttachedItemInfo = function() return nil, 1 end
function GetMailId64(mailId) return mailId end

-- ----------------------------------------------------
ZO_ColorDef = {}
ZO_ColorDef.__index = ZO_ColorDef

function ZO_ColorDef:New()
    return setmetatable({},ZO_ColorDef)
end

function GetInterfaceColor(colorType, fldvalue)
    return 1,1,1,1
end

-- ---------------------------------------------------
local ZO_CallLaterId = 1

function zo_callLater(func, ms)
    local id = ZO_CallLaterId
    local name = "CallLaterFunction"..id
    ZO_CallLaterId = ZO_CallLaterId + 1

    func()
    return id
end

function zo_removeCallLater(id)
    
end
