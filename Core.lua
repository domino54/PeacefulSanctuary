local PeacefulSanctuary = LibStub("AceAddon-3.0"):NewAddon("PeacefulSanctuary")

--- Name of the CVar of interest.
local ENEMY_PLATES_CVAR = "nameplateShowEnemies"

--- Events to register and watch.
local WATCHED_EVENTS = {
  "PLAYER_REGEN_DISABLED",  -- Enter combat
  "PLAYER_REGEN_ENABLED",   -- Leave combat
  "ZONE_CHANGED_NEW_AREA",  -- Entering or leaving a city
}

--- Default values of the database.
local DATABASE_DEFAULTS = {
  ShowEnemiesInWorld      = 1,
  ShowEnemiesInSanctuary  = 0,
}

--- Combat status, because PLAYER_REGEN_DISABLED is fired right before InCombatLockdown() becomes true.
local IsInCombat = InCombatLockdown()

--- Get if the player is in a sanctuary.
-- @return - In sanctuary or not.
local function IsInSanctuary()
  local pvpType, isFFA, faction = GetZonePVPInfo()
  return pvpType == "sanctuary"
end

--- Updates the enemy nameplates visibility based on combat and sanctuary status.
local function UpdateVisibility()
  if (IsInSanctuary() and not IsInCombat) then
    SetCVar(ENEMY_PLATES_CVAR, PeacefulSanctuary.db.profile.ShowEnemiesInSanctuary)
  else
    SetCVar(ENEMY_PLATES_CVAR, PeacefulSanctuary.db.profile.ShowEnemiesInWorld)
  end
end

--- Called when one of the registered events is fired.
-- @tparam table self - Event handling frame.
-- @tparam string Event - Name of the caught event.
local function OnEvent(self, Event)
  if (Event == "PLAYER_REGEN_DISABLED") then
    IsInCombat = true
  elseif (Event == "PLAYER_REGEN_ENABLED") then
    IsInCombat = false
  end

  UpdateVisibility()
end

--- Called whenever UIErrorsFrame displays a new message.
local function OnUIErrorsFrameMessage()
  local nameplateShowEnemies = GetCVar(ENEMY_PLATES_CVAR)

  if (IsInSanctuary() and not IsInCombat) then
    PeacefulSanctuary.db.profile.ShowEnemiesInSanctuary = GetCVar(ENEMY_PLATES_CVAR)
  else
    PeacefulSanctuary.db.profile.ShowEnemiesInWorld = GetCVar(ENEMY_PLATES_CVAR)
  end
end

--- Initialize the Peaceful Sanctuary addon.
function PeacefulSanctuary:OnInitialize()
  -- Use a global profile.
  self.db = LibStub("AceDB-3.0"):New("PeacefulSanctuaryDB", { profile = DATABASE_DEFAULTS }, true)

  -- Register events.
  self.DummyFrame = CreateFrame("Frame", "PeacefulSanctuaryDummyFrame", UIParent)
  for i, EventName in pairs(WATCHED_EVENTS) do
    self.DummyFrame:RegisterEvent(EventName)
  end
  self.DummyFrame:SetScript("OnEvent", OnEvent)

  -- Workaround for not having an explicit event when enemy nameplates are toggled.
  hooksecurefunc(UIErrorsFrame, "AddMessage", OnUIErrorsFrameMessage)

  -- Initial update.
  UpdateVisibility()
end
