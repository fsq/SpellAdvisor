-- Always use current player status.
local kUnit = "player"

-- Following are spell name constants.
local kBladeOfWrath = "Blade of Wrath"
local kBladeOfJustice = "Blade of Justice"
local kConsecration = "Consecration"
local kCrusaderStrike = "Crusader Strike"
local kDivinePurpose = "Divine Purpose"
local kDivineStorm = "Divine Storm"
local kHammerOfWrath = "Hammer of Wrath"
local kJudgment = "Judgment"
local kTemplarsVerdict = "Templar's Verdict"
local kWakeOfAshes = "Wake of Ashes"


-- On-screen textbox showing spell name to cast.
local function CreateFrameAndText()
  local frame=CreateFrame("Frame", "FrameName", UIParent);
  frame:SetPoint("CENTER", 100, 0);
  frame:SetSize(100,25);

  frame.texture = frame:CreateTexture(nil, "BACKGROUND")
  frame.texture:SetAllPoints(true)
  frame.texture:SetColorTexture(0,0,0,0.5)
   
  local text=frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  text:SetPoint("CENTER");
  text:SetText("Sample Text");

  return frame, text
end

-- Return a dict of current active BUFFs, keyed by name.
local function GetCurrentBUFFs() 
  local buff_list, i = {}, 1
  -- name, icon, count, debuffType, duration, expirationTime, source, 
  -- isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, 
  -- castByPlayer, nameplateShowAll, timeMod, ...
  -- = UnitBuff("unit", [index] or ["name", "rank"][, "filter"]) 
  while UnitBuff(kUnit, i) do
    local name, _, _, _, _, expirationTime = UnitBuff(kUnit, i)
    buff_list[name] = expirationTime
    i = i + 1;
  end
  return buff_list
end


-- Global cooldown
local function GCD() 
  _, duration, _ = GetSpellCooldown(61304)
  return duration
end

-- Remaining and duration time of a spell cooldown.
local function CD(spell) 
  start, duration, _ = GetSpellCooldown(spell)
  if start == 0 then
    return 0, 0
  else
    return start+duration - GetTime(), duration
  end
end

-- Check if a spell is ready to use.
-- 1. CD is 0
-- 2. usable, i.e. condition is met(e.g. backstab), sufficient reagents, etc.
local function IsReady(spell)
  cd, duration = CD(spell)
  -- Ignore GCD
  return (cd==0 or duration<=GCD()) and IsUsableSpell(spell)
end

-- Check if a BUFF is active on you.
local function HasBUFF(buff_list, buff_name) 
  return buff_list[buff_name] ~= nil
end

-- Check if a spell is fully charged/stacked
local function FullyCharged(spell)
  currentCharges, maxCharges = GetSpellCharges(spell)
  return currentCharges == maxCharges
end

-- Main function, return the name3 of the next spell.
-- Set your priorities here.
local function GetSpell(holy_power, buff_list)
  -- Remaining holy power slot.
  local slot = 5 - holy_power;

  if IsReady(kWakeOfAshes) and slot>=3 then
    return kWakeOfAshes

  elseif HasBUFF(buff_list, kDivinePurpose) then
    if CD(kJudgment)<=2 and slot>=1 then
      return kJudgment
    else
      return kTemplarsVerdict
    end

  elseif IsReady(kBladeOfJustice) and slot>=2 then
    return kBladeOfJustice

  elseif FullyCharged(kCrusaderStrike) and slot>=1 then
    return kCrusaderStrike

  elseif IsReady(kJudgment) and slot>=1 then
    return kJudgment

  elseif IsReady(kHammerOfWrath) and slot>=1 then
    return kHammerOfWrath

  elseif IsReady(kCrusaderStrike) and slot>=1 then
    return kCrusaderStrike

  elseif holy_power>=3 then
    return kTemplarsVerdict

  elseif IsReady(kConsecration) then
    return kConsecration

  else
    return "NA"

  end
end

local frame, text = CreateFrameAndText()

local function PrintNextSpellName() 
  local holy_power = UnitPower(kUnit, 9) -- enum 9 => holy power
  local buff_list  = GetCurrentBUFFs()
  text:SetText(GetSpell(holy_power, buff_list))
end

-- Refresh every 0.1 second.
local myTicker = C_Timer.NewTicker(0.1, PrintNextSpellName)
