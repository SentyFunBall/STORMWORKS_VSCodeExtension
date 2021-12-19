
-- think of this in terms of functions with callbacks
-- 1) we're registering against the callback of something else
-- 2) when that callback is done, we then call the function that's registered against us

LifeBoatAPI = LifeBoatAPI or {}
LifeBoatAPI.Async = LifeBoatAPI.Async or {}

missionManager:createNewMission()
            :andThen(function(mission)
                playerTracker:awaitPlayerRespawn()
            end)
            :andThen(function(player)
                local marker = player.setMarker("Get to the island")
                return timers:awaitFor(10)
                                :andThen(marker:remove())
                                , player
            end)
            :andThen(function(player)
                return playerTracker:awaitPlayerAtLocation(myIslandLocation), player
            end)
            :andThen(function(island, player, player)
                local popup = player:setPopup("Congratulations kiddo, you've beaten this mission")
                progressTracker:setComplete("ABC")
            end)



---@class LifeBoat.Async.Awaitable : LBBaseClass
LifeBoatAPI.Async.Awaitable = {
    new = function (this, parent)
        this = LifeBoatAPI.Base.BaseClass.new(this)
        this.parent = parent
        this.chainedCallbacks = {}
        return this
    end;
    
    trigger = function (this, ...)
        for _, callback in ipairs(this.chainedCallbacks) do
            callback(...)
        end
    end;

    andThen = function (this, callback)
        local awaitable = LifeBoatAPI.Async.Awaitable:new(this)

        table.insert(
            this.chainedCallbacks,
            function(...)
                local result = {callback(...)}
                -- slightly harder because Lua allows multi-returns

                if #result == 0 then
                    result = {nil}    
                end

                local firstResult = result[0]

                if LifeBoatAPI.Async.Awaitable:is(firstResult) then
                    -- if the function returned an awaitable
                    -- we're meant to wait for that to continue, then chain everything from it
                    -- but I'm not sure how that works
                    -- it's necessary for handling it like a diamond

                    -- is this method of chaining the right way?
                    -- possibly?
                else
                    
                end

                awaitable:trigger(table.unpack(result))
            end
        )

        return awaitable
    end;
};
LifeBoatAPI.Base.Class(LifeBoatAPI.Async.Awaitable)



---@class LifeBoat.Async.Awaitable2 : LBBaseClass
LifeBoatAPI.Async.Awaitable2 = {
    new = function (this, parent)
        this = LifeBoatAPI.Base.BaseClass.new(this)
        this.onComplete = nil
        return this
    end;
    
    trigger = function (this, ...)
        if this.onComplete then
            return this.onComplete(...)
        end
    end;

    andThen = function (this, callback)
        local awaitable = LifeBoatAPI.Async.Awaitable:new(this)

        this.onComplete =function(...)
            local result = callback(...)

            awaitable:trigger(result)
        end

        return awaitable
    end;
};
LifeBoatAPI.Base.Class(LifeBoatAPI.Async.Awaitable2)

-- 1) get thenable working as designed
-- THEN, 2) see if there's a stateful approach that'd work with g_savedata
-- not sure there is unless every operation is entirely atomic?

-- maybe thenable is a horrendous way to do this


---@class LifeBoat.Async.AwaitAll : LifeBoat.Async.Awaitable
LifeBoatAPI.Async.AwaitAll = {
    --- overwrites parent
    trigger = function (this, ...)
        if(this.onComplete) then
            this.onComplete(...)
        end
    end;

    andThen = function (this, callback)
        local awaitable = LifeBoatAPI.Async.Awaitable:new(this)

        this.onComplete = function(...)
            local result = callback(...)
            awaitable:trigger(result)
        end

        return awaitable
    end;
};
LifeBoatAPI.Base.Class(LifeBoatAPI.Async.Awaitable, LifeBoatAPI.Async.AwaitAll)



--[[

---@class LBAwaitable
LBAwaitable = {

    trigger = function (this, ...)
        if(this.onComplete) then
            this.onComplete(...)
        end
    end;

    ---@return LBAwaitable
    -- when this is a collection of awaitables, we await all of them
    -- when this is one awaitable, we await just that one
    andThen = function (this, callback)
        local awaitable = LBAwaitable:new(this)

        this.onComplete = function(...)
            local result = callback(...)
            awaitable:trigger(result)
        end

        return awaitable
    end;

    -- when there is a collection of awaitables, we do the relevant type of await
    -- otherwise a single awaitable, is treated like andThen (we effectively wrap it in a list {[1]=awaitable})
    waitForAllAndThen = function (this, callback)
        local awaitable = LBAwaitable:new(this)

        this.onComplete = function(...)
            local args = {...}

            for i,v in ipairs(args) do
                
            end
            local result = callback(...)
            awaitable:trigger(result)
        end

        return awaitable
    end;

    waitForAnyAndThen = function()
    end;
    
    waitForSomeAndThen = function()
    end;
    
    whenEachFinishesThen = function()
    end;
    

    -- possibly this is just syntax sugar, not clear whether we want it or not really
    -- maybe it makes life easier, but it might also make it harder to understand
    whilstWaiting = function()
    end;


    -- control functions
    -- we need to be able to say "hey, actually, repeat that last step"
    --  or "hey, repeat the entire chain please"
    -- for example, the mission ends - ok, repeat it all

    -- resets the awaitable chain, so it can be run again?
    -- does that work?
    -- what would that even look like?
    repeatFromStart = function ()
        
    end;

    -- go back one in the chain?
    repeatLast = function ()
        
    end;

    
    -- cancels this specific awaitable chain, stopping it from processing any further
    cancel = function ()
    end;

    -- cancels all awaitables that spawned from the same parent
    cancelAll = function ()
    end;
}
LBClass(LBAwaitable);

]]