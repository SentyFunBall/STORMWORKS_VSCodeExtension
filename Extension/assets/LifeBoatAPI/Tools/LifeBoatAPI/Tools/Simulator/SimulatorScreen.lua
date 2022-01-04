-- Author: Nameous Changey
-- GitHub: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension
-- Workshop: https://steamcommunity.com/id/Bilkokuya/myworkshopfiles/?appid=573090
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey

require("LifeBoatAPI.Tools.Utils.Base")

---@class SimulatorScreen
---@field width number
---@field height number
---@field touchX number
---@field touchY number
---@field isTouchedL boolean
---@field isTouchedR boolean
---@field poweredOn boolean
---@field screenNumber number
LifeBoatAPI.Tools.SimulatorScreen = {
    ---@param this SimulatorScreen
    ---@return SimulatorScreen
    new = function(this, screenNumber)
        this = LifeBoatAPI.Tools.BaseClass.new(this)
        this.width = 0
        this.height = 0
        this.touchX = 0
        this.touchY = 0
        this.isTouchedL = false
        this.isTouchedR = false
        this.poweredOn = true
        this.screenNumber = screenNumber
        return this
    end;
}
