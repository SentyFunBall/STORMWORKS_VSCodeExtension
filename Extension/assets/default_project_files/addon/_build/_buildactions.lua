--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey

-- Callbacks for handling the build process
-- Allows for running external processes, or customising the build output to how you prefer
-- Recommend using LifeBoatAPI.Tools.FileSystemUtils to simplify life

require("LifeBoatAPI")

--- Runs when the build process is triggered, before any file has been built
--- Provides an opportunity for any code-generation etc.
---@param builder Builder           builder object that will be used to build each file
---@param params MinimizerParams    params that the build process usees to control minification settings
---@param workspaceRoot Filepath    filepath to the root folder of the project
function onLBBuildStarted(builder, params, workspaceRoot)
    print("Build started - see the build actions in _build/_buildactions.lua")
end

--- Runs just before each file is built
---@param builder Builder           builder object that will be used to build each file
---@param params MinimizerParams    params that the build process usees to control minification settings
---@param workspaceRoot Filepath    filepath to the root folder of the project
---@param name string               "require"-style name of the script that's about to be built
---@param inputFile Filepath        filepath to the file that is about to be built
function onLBBuildFileStarted(builder, params, workspaceRoot, name, inputFile)

end

--- Runs after each file has been combined and minimized
--- Provides a chance to use the output, e.g. sending files into vehicle XML or similar
---@param builder Builder           builder object that will be used to build each file
---@param params MinimizerParams    params that the build process usees to control minification settings
---@param workspaceRoot Filepath    filepath to the root folder of the project
---@param name string               "require"-style name of the script that's been built
---@param inputFile Filepath        filepath to the file that was just built
---@param outputFile Filepath       filepath to the output minimized file
---@param combinedText string       text generated by the require-resolution process (pre-minified)
---@param minimizedText string      final text output by the process, ready to go in game (post-minified)
function onLBBuildFileComplete(builder, params, workspaceRoot, name, inputFile, outputFile, originalText, combinedText, minimizedText)
    -- Example: copy MyScript.lua into the game addon folder
    -- if name == "MyScript" then
    --     local missionScriptPath = LifeBoatAPI.Tools.Filepath:new("C:/Users/.../Stormworks/missions/MyMission/script.lua")
    --     LifeBoatAPI.Tools.FileSystemUtils.writeAllText(missionScriptPath, minimizedText)
    -- end
end

--- Runs after the build process has finished for this project 
--- Provides a chance to do any final build steps, such as moving files around
---@param builder Builder           builder object that will be used to build each file
---@param params MinimizerParams    params that the build process usees to control minification settings
---@param workspaceRoot Filepath    filepath to the root folder of the project
function onLBBuildComplete(builder, params, workspaceRoot)
    print("Build Success")
    print("See the /out/release/ folder for your minimized code")
end


