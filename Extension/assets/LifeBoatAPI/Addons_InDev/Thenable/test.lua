-- developed by nameouschangey (Gordon Mckendrick) for use with LifeBoat Modding framework
-- please see: https://github.com/nameouschangey/STORMWORKS for updates

------------------------------------------------------------------------------------------------------------------
--- Copies data from (from) to (to)
--- underwrites values copied (leaves original if it exists)
--- Can be used to instantiate classes, or inherit from classes
--- @generic T
--- @overload fun(from:T):T
--- @param from T source to copy from
--- @param to any destination to copy into
--- @param overwrite boolean true if all keys should be overwritten
--- @return T true if the current instance, is a type that inherits from the given class
function LBCopy(from,to,overwrite)
    to=to or {}
    for k,v in pairs(from) do
        to[k] = (overwrite and v) or to[k] or v --underwrites, so the original values are kept if they existed
    end
    return to
end

------------------------------------------------------------------------------------------------------------------
--- Global class base that all classes should inherit from
--- @class LBBaseClass
--- @field __c any
LBBaseClass = {
    ---@generic T
    ---@param cls T
    ---@return T
    new = function(cls)
        return LBClass(cls,{})
    end;

    --- Checks whether this instance, is of the given class type at runtime
    --- @generic ParentType
    --- @param this ParentType
    --- @param object any class to see if this is an instance of, or inherits from
    --- @return boolean true if the current instance, is a type that inherits from the given class
    is = function(this, object)
        if this == nil or object == nil then
            return false
        end

        return (this == object)
            or (type(object) == "table" and this:is(object.__c))
    end;

    --- shallow clone of this instance
    ---@generic T
    ---@param this T
    ---@return T
    clone = function(this)
        return LBCopy(this)
    end;
};

--- @generic T,P
--- @overload fun(child:T):T
--- @param parent T source to copy from
--- @param child T destination to copy into
--- @return T new instance or class created
function LBClass(parent, child)
    if(not child) then
        child = parent
        parent = LBBaseClass
    end
    child.__c = parent
    return LBCopy(parent, child)
end


--- adds the given values to the specified namespace
--- @generic T
--- @param new T dot-separated namespace to add to
--- @param current table data to add to the namespace
--- @return T new
function LBNamespace(new, current)
    if current then
        for k,v in pairs(current) do
            new[k] = v
        end
    end
    return new
end


---@class Awaitable : LBBaseClass
Awaitable = {

    ---@return Awaitable this
    new = function (this)
        this = LBBaseClass.new(this)
        this.onComplete = nil -- benefits of this being an array? can queue multiple things to one trigger easily. but deregistering is hard
        return this
    end;
    
    trigger = function (this, ...)
        if this.onComplete then
            return this.onComplete(...)
        end
    end;

    andThen = function (this, callback)
        local awaitable = Awaitable:new()

        this.onComplete =function(...)
            local result = callback(...) -- for the standard, this should be stateful

            if not result
            or not Awaitable:is(result) then
                -- plain value (including nil) result
                awaitable:trigger(result)
            else
                -- result is an awaitable, so we chain onto that
                result.onComplete = function(...)
                    awaitable:trigger(...)
                end
            end
        end

        return awaitable
    end;
};
LBClass(Awaitable)

a = Awaitable:new()
b = Awaitable:new()

a:andThen(function(param)
        print("called first " .. param)
        return b:andThen(function(bbb)
            print("inner: " .. tostring(bbb))
            return bbb .. "dot"
        end)
    end)
    :andThen(function(param)
        print("called 2nd " .. param)
    end)

a:trigger("banana")

print("waiting after a")

b:trigger("pajama")