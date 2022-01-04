-- Author: Nameous Changey
-- GitHub: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension
-- Workshop: https://steamcommunity.com/id/Bilkokuya/myworkshopfiles/?appid=573090
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey

require("LifeBoatAPI.Tools.Utils.Base")

---@class SimulatorInputHelpers
LifeBoatAPI.Tools.SimulatorInputHelpers = {

    ---Sets this input to a specific value constantly
    ---@param value boolean
    ---@return fun():boolean
    constantBool = function(value)
        return function() return value and true or false end
    end;

    ---Sets the input to a constant number value
    ---@param value boolean
    ---@return fun():number
    constantNumber = function(value)
        return function() return value end
    end;

    ---Sets the input to a bool that toggles on and off every so many ticks
    ---@param togglePeriod number number of ticks between each toggle
    ---@return fun():boolean
    togglingBool = function(initialValue, togglePeriod)
        local ticks = 0
        local value = initialValue
        togglePeriod = math.floor(togglePeriod)
        return function()
            ticks = ticks + 1
            if ticks % togglePeriod == 0 then
                value = not value
            end
            return value
        end
    end;

    ---@deprecated 
    touchScreenIsQTouched = function (simulator, screenNumber)
        return LifeBoatAPI.Tools.SimulatorInputHelpers.touchScreenIsTouched(simulator, screenNumber)
    end;

    ---@deprecated 
    touchScreenIsETouched = function (simulator, screenNumber)
        return LifeBoatAPI.Tools.SimulatorInputHelpers.touchScreenIsTouched(simulator, screenNumber)
    end;

    ---Connect the "is the screen being touched" input (normally input.getBool(1))
    ---@param simulator Simulator
    ---@param screenNumber number 
    ---@return boolean
    touchScreenIsTouched = function (simulator, screenNumber)
        screenNumber = screenNumber or 1
        return function()
            return simulator._screens[screenNumber] and (simulator._screens[screenNumber].isTouchedL or simulator._screens[screenNumber].isTouchedR) or false
        end
    end;

    ---@param simulator Simulator
    ---@param screenNumber number futureproofing, for now there's only 1 
    ---@return number
    touchScreenWidth = function (simulator, screenNumber)
        screenNumber = screenNumber or 1
        return function() return simulator._screens[screenNumber] and simulator._screens[screenNumber].width or 0 end
    end;

    ---@param simulator Simulator
    ---@param screenNumber number futureproofing, for now there's only 1 
    ---@return number
    touchScreenHeight = function (simulator, screenNumber)
        screenNumber = screenNumber or 1
        return function() return simulator._screens[screenNumber] and simulator._screens[screenNumber].height or 0 end
    end;

    ---@param simulator Simulator
    ---@param screenNumber number futureproofing, for now there's only 1 
    ---@return number
    touchScreenXPosition = function (simulator, screenNumber)
        screenNumber = screenNumber or 1
        return function() return simulator._screens[screenNumber] and simulator._screens[screenNumber].touchX or 0 end
    end;

    ---@param simulator Simulator
    ---@param screenNumber number futureproofing, for now there's only 1 
    ---@return number
    touchScreenYPosition = function (simulator, screenNumber)
        screenNumber = screenNumber or 1
        return function() return simulator._screens[screenNumber] and simulator._screens[screenNumber].touchY or 0 end
    end;

    ---Sets the input to a number that wraps around a fixed range
    ---@param min number min value to wrap at
    ---@param max number max value to wrap at
    ---@param increment number amount to increase/decrease each tick
    ---@param initial number initial value (optional)
    ---@return fun():number
    wrappingNumber = function(min, max, increment, initial)
        initial = initial or min
        if min > max then
            min,max = max,min
        end
        local value = initial
        return function ()
            value = value + increment
            if value > max then
                value = min
            end
            if value < min then
                value = max
            end
            return value
        end
    end;

    ---Increments the current value by an unpredictable amount each tick
    ---Noise that accumulates
    ---@param noiseAmount number noise will be produced in the range [0, noiseAmount]
    ---@param initial number initial value
    ---@param noiseOffset number constant value to offset by (e.g. to allow something that "constantly rises at a random rate")
    ---@return fun():number
    noiseyIncrement = function(noiseAmount, initial, noiseOffset)
        initial = initial or 0
        noiseOffset = noiseOffset or 0
        local value = initial
        return function ()
            value = value + ((math.random()-0.5) * noiseAmount) + noiseOffset
            return value
        end
    end;

    ---Gives a value that oscillates around the given point, noise does not accumulate
    ---@param noiseAmount number noise will be produced in the range [0, noiseAmount]
    ---@param initial number initial value
    ---@return fun():number
    noiseyOscillation = function(noiseAmount, initial)
        initial = initial or 0
        local value = initial
        return function ()
            return value + ((math.random()-0.5) * noiseAmount)
        end
    end;

    ---Gives a value that oscillates steadily between two values
    ---@param min number min value to wrap at
    ---@param max number max value to wrap at
    ---@param increment number amount to increase/decrease each tick
    ---@param initial number initial value (optional)
    ---@return fun():number
    oscillatingNumber = function(min, max, increment, initial)
        initial = initial or 0
        if min > max then
            min,max = max,min
        end
        local value = initial
        local direction = increment >= 0 and 1 or -1
        increment = increment >= 0 and increment or (-1 * increment)
        return function ()
            value = value + (increment * direction)
            if value > max then
                local difference = value - max
                value = max
                direction = direction * -1
                value = value + (difference * direction) -- re-add the amount we overshot the edge, to keep it accurate
            end
            if value < min then
                local difference = min - value
                value = min
                direction = direction * -1
                value = value + (difference * direction) -- re-add the amount we overshot the edge, to keep it accurate
            end
            return value
        end
    end;
}