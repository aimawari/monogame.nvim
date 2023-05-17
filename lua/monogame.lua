-- monogame.nvim - A Neovim plugin for MonoGame development
local uv = vim.loop
local api = vim.api

local M = {}

-- Define function to open MonoGame content builder GUI
function M.OpenMonogameMGCB()
    local project_path = vim.fn.expand("%:p:h")
    local content_path = project_path .. "/Content/Content.mgcb"

    uv.spawn("dotnet", {
            args = { "mgcb-editor", content_path }
        },
        function()
            print("MGCB Editor opened successfully!")
        end
    )
end

-- Define function to create a new MonoGame project with the DesktopGL target platform
function M.new_project(project_name)
    uv.spawn("dotnet", {
            args = { "new", 'mgdesktopgl', '-o', project_name },
        },
        function(code, _)
            if code ~= 0 then
                print("Monogame" .. project_name .. " created failed!")
            else
                print("Monogame" .. project_name .. " created successfully!")
            end
        end
    )
end

-- Define function to run a MonoGame project
-- Android, iOS will be implement later
local runtimeIdentifiers = {
    DesktopGL = {
        Windows = 'win-x64',
        OSX = 'osx-x64',
        Linux = 'linux-x64'
    },
    Android = 'android-arm64',
    iOS = 'ios-arm64'
}

local function buildProject(projectDir, platform, configuration)
    local runtimeIdentifier = runtimeIdentifiers[platform][jit.os] or runtimeIdentifiers[platform]

    if not runtimeIdentifier then
        print("Invalid platform.")
        return
    end

    local outputDir = ("%s/bin/%s/%s/publish/"):format(projectDir, configuration, runtimeIdentifier)
    uv.spawn('dotnet', {
            args = {
                'publish',
                '--self-contained',
                '-r',
                runtimeIdentifier,
                '-c',
                configuration,
                '-o',
                outputDir
            }
        },
        function(code, _)
            if code ~= 0 then
                print("Build Failed!")
            else
                print("Build Successfully!")
            end
        end
    )
end

local function getProjectName(projectDir)
    local csprojFile = vim.fn.glob(projectDir .. '/*.csproj')
    if csprojFile == '' then
        print('No .csproj file found in ' .. projectDir)
        return ''
    end
    local output = vim.fn.system('dotnet list "' .. csprojFile .. '" package')
    if vim.v.shell_error ~= 0 then
        print('Error running dotnet list command')
        return ''
    end
    local projectName = string.match(output, "^Project '(.*)'")
    if not projectName then
        print('Error: could not extract project name from dotnet output')
        return ''
    end
    return projectName
end

local function runExecutable(projectDir, platform, configuration, projectName)
    local runtimeIdentifier = runtimeIdentifiers[platform][jit.os] or runtimeIdentifiers[platform]
    if not runtimeIdentifier then
        print("Invalid platform.")
        return
    end

    local exeExtension = jit.os == "Windows" and ".exe" or ""
    local executablePath = ("%s/bin/%s/%s/publish/%s%s"):format(projectDir, configuration, runtimeIdentifier, projectName,
        exeExtension)

    uv.spawn(executablePath, {},
        function(code, _)
            if code ~= 0 then
                print("Failed to open project.")
            else
                print(projectName .. " opened successfully!")
            end
        end
    )
end

function M.BuildMonoGameProject(mode)
    local projectDir = vim.fn.expand("%:p:h")
    local platform = 'DesktopGL'

    local configuration = mode == 'Debug' and 'Debug' or 'Release'

    buildProject(projectDir, platform, configuration)
end

function M.RunMonoGameProject(mode)
    local projectDir = vim.fn.expand("%:p:h")
    local platform = 'DesktopGL'

    local configuration = mode == 'Debug' and 'Debug' or 'Release'

    local projectName = getProjectName(projectDir)
    if not projectName then
        print('No Project Name')
        return
    end

    runExecutable(projectDir, platform, configuration, projectName)
end

-- Define command setup function
function M.setup()
    api.nvim_command("command! MonogameOpenMGCB lua require('monogame').OpenMonogameMGCB()")
    api.nvim_command("command! MonogameBuild lua require('monogame').BuildMonoGameProject('Debug')")
    api.nvim_command("command! MonogameBuildRelease lua require('monogame').BuildMonoGameProject('Release')")
    api.nvim_command("command! MonogameRun lua require('monogame').RunMonoGameProject('Debug')")
    api.nvim_command("command! MonogameRunRelease lua require('monogame').RunMonoGameProject('Release')")
    api.nvim_command("command! -nargs=1 MonogameNewProject lua require('monogame').new_project(<f-args>)")
end

return M
