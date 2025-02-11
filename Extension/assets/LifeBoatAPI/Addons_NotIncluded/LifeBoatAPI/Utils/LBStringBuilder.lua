-- developed by nameouschangey (Gordon Mckendrick) for use with LifeBoat Modding framework
-- please see: https://github.com/nameouschangey/STORMWORKS for updates

require("LifeBoatAPI.Missions.Utils.LBTable")
require("LifeBoatAPI.Missions.Utils.LBBase")

---@class LBStringBuilder : LBBaseClass
---@field stringData string[] string being built
LBStringBuilder = {
    ---@overload fun() : LBStringBuilder default constructor, no initial string value
    ---@param cls LBStringBuilder
    ---@param text string initial value for the string
    new = function(cls, text)
        local this = LBBaseClass.new(cls)
        this.stringData = {};
        if(text) then
            this:add(text)
        end
        return this;
    end;

    --- Adds the given string to the front of the string being build
    ---@param this LBStringBuilder
    ---@vararg any values to add to the string
    addFront = function(this, value)
        LBTable_add(this.stringData, tostring(value), 1)
    end;

    ---Adds the given string to the current string being built
    ---@param this LBStringBuilder
    ---@vararg any values to add to the string
    add = function(this, ...)
        for i, v in ipairs({...}) do
            LBTable_add(this.stringData, tostring(v))
        end
    end;

    ---Adds the given string and ends with a new line added
    ---@param this LBStringBuilder
    ---@vararg any values to add. A newline will be generated to the end
    addLine = function(this, ...)
        this:add(..., "\n")
    end;

    ---Gets the completed string
    ---@overload fun():string
    ---@param this LBStringBuilder
    ---@param separator string optional separator, if provided is inserted between each entry 
    ---@return string completed string that has been built
    getString = function(this, separator)
        return LBTable_concat(this.stringData, separator)
    end;
}
LBClass(LBStringBuilder)
