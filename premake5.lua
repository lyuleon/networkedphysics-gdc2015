solution "Protocol"
    includedirs { "src", "external", "tools", "." }
    platforms { "x64" }
    configurations { "Release", "Debug" }
    flags { "Symbols", "ExtraWarnings", "EnableSSE2" }
    rtti "Off"
    configuration "Release"
        flags { "OptimizeSpeed" }
        defines { "NDEBUG" }

project "Core"
    language "C++"
    kind "StaticLib"
    files { "src/Core/*.h", "src/Core/*.cpp" }
    targetdir "lib"

project "Network"
    language "C++"
    kind "StaticLib"
    files { "src/network/*.h", "src/network/*.cpp" }
    links { "Core" }
    targetdir "lib"

project "Protocol"
    language "C++"
    kind "StaticLib"
    files { "src/protocol/*.h", "src/protocol/*.cpp" }
    links { "Core", "Network" }
    targetdir "lib"

project "ClientServer"
    language "C++"
    kind "StaticLib"
    files { "src/ClientServer/*.h", "src/ClientServer/*.cpp" }
    links { "Core", "Network", "Protocol" }
    targetdir "lib"

project "VirtualGo"
    language "C++"
    kind "StaticLib"
    files { "src/VirtualGo/*.h", "src/VirtualGo/*.cpp" }
    links { "Core" }
    targetdir "lib"

project "Cubes"
    language "C++"
    kind "StaticLib"
    files { "src/Cubes/*.h", "src/Cubes/*.cpp" }
    links { "Core" }
    targetdir "lib"

--[[
project "nvImage"
    language "C++"
    kind "StaticLib"
    files { "external/nvImage/*.h", "external/nvImage/*.cpp" }
    targetdir "lib"
--]]

project "tinycthread"
    language "C"
    kind "StaticLib"
    files { "external/tinycthread/*.h", "external/tinycthread/*.c" }
    targetdir "lib"

project "TestCore"
    language "C++"
    kind "ConsoleApp"
    files { "tests/Core/*.cpp" }
    links { "Core" }
    targetdir "bin"

project "TestNetwork"
    language "C++"
    kind "ConsoleApp"
    files { "tests/Network/Test*.cpp" }
    links { "Core", "Network", "Protocol", "ClientServer" }
    targetdir "bin"

project "TestProtocol"
    language "C++"
    kind "ConsoleApp"
    files { "tests/Protocol/Test*.cpp" }
    links { "Core", "Network", "Protocol", "ClientServer" }
    targetdir "bin"

project "TestClientServer"
    language "C++"
    kind "ConsoleApp"
    files { "tests/ClientServer/Test*.cpp" }
    links { "Core", "Network", "Protocol", "ClientServer" }
    targetdir "bin"

project "TestCubes"
    language "C++"
    kind "ConsoleApp"
    files { "tests/Cubes/*.cpp" }
    links { "Core", "Cubes", "ode" }
	configuration "Debug"
		links { "ode-debug" }
	configuration "Release"
		links { "ode" }
    targetdir "bin"

project "TestVirtualGo"
    language "C++"
    kind "ConsoleApp"
    files { "tests/VirtualGo/*.cpp" }
    links { "Core", "VirtualGo" }
	configuration "Debug"
		links { "ode-debug" }
	configuration "Release"
		links { "ode" }
    targetdir "bin"

project "SoakProtocol"
    language "C++"
    kind "ConsoleApp"
    files { "tests/Protocol/SoakProtocol.cpp" }
    links { "Core", "Network", "Protocol", "ClientServer" }
    targetdir "bin"

project "SoakClientServer"
    language "C++"
    kind "ConsoleApp"
    files { "tests/ClientServer/SoakClientServer.cpp" }
    links { "Core", "Network", "Protocol", "ClientServer" }
    targetdir "bin"

project "ProfileProtocol"
    language "C++"
    kind "ConsoleApp"
    files { "tests/Protocol/ProfileProtocol.cpp" }
    links { "Core", "Network", "Protocol", "ClientServer" }
    targetdir "bin"

project "ProfileClientServer"
    language "C++"
    kind "ConsoleApp"
    files { "tests/ClientServer/ProfileClientServer.cpp" }
    links { "Core", "Network", "Protocol", "ClientServer" }
    targetdir "bin"

--[[project "FontTool"
    language "C++"
    kind "ConsoleApp"
    files { "tools/Font/*.cpp" }
    links { "Core", "Freetype", "Jansson" }
    targetdir "bin"
--]]

--[[
project "StoneTool"
    language "C++"
    kind "ConsoleApp"
    files { "tools/Stone/*.cpp" }
    links { "Core", "VirtualGo", "Jansson" }
    targetdir "bin"
--]]

--[[
project "Client"
    language "C++"
    kind "ConsoleApp"
    files { "src/game/*.cpp" }
    links { "Core", "Network", "Protocol", "ClientServer", "VirtualGo", "Cubes", "nvImage", "tinycthread", "ode", "glew", "glfw3", "GLUT.framework", "OpenGL.framework", "Cocoa.framework", "CoreVideo.framework", "IOKit.framework" }
    targetdir "bin"
    defines { "CLIENT" }
--]]

project "Server"
    language "C++"
    kind "ConsoleApp"
    files { "src/game/*.cpp" }
    links { "Core", "Network", "Protocol", "ClientServer", "Cubes" }
	configuration "Debug"
		links { "ode-debug" }
	configuration "Release"
		links { "ode" }
    targetdir "bin"

if _ACTION == "clean" then
    os.rmdir "bin"
    os.rmdir "lib"
    os.rmdir "obj"
    if not os.is "windows" then
        os.execute "rm -rf bin"
        os.execute "rm -rf obj"
        os.execute "rm -f Makefile"
        os.execute "rm -f *.zip"
        os.execute "rm -f *.make"
        os.execute "rm -f replay.bin"
        os.execute "rm -rf output"
        os.execute "find . -name .DS_Store -delete"
        os.execute "cd external/ode; make clean > /dev/null 2>&1"
    else
        os.rmdir "ipch"
		os.rmdir "bin"
		os.rmdir ".vs"
        os.rmdir "Debug"
        os.rmdir "Release"
        os.execute "del /F /Q Makefile"
        os.execute "del /F /Q *.make"
        os.execute "del /F /Q *.zip"
        os.execute "del /F /Q *.db"
        os.execute "del /F /Q *.opendb"
        os.execute "del /F /Q *.vcproj"
        os.execute "del /F /Q *.vcxproj"
        os.execute "del /F /Q *.vcxproj.user"
        os.execute "del /F /Q *.sln"
    end
end

if not os.is "windows" then

    newaction 
    {
        trigger     = "loc",
        description = "Count lines of code",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,

        execute = function ()
            os.execute "find . -name *.h -o -name *.cpp | xargs wc -l"
        end
    }

    newaction
    {
        trigger     = "zip",
        description = "Zip up archive of this project",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            _ACTION = "clean"
            premake.action.call( "clean" )
            os.execute "zip -9r Protocol.zip *"
        end
    }

    newaction
    {
        trigger     = "core",
        description = "Build core library",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            os.execute "make -j4 Core"
        end
    }

    newaction
    {
        trigger     = "network",
        description = "Build network library",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            os.execute "make -j4 Network"
        end
    }

    newaction
    {
        trigger     = "protocol",
        description = "Build protocol library",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            os.execute "make -j4 Protocol"
        end
    }

    newaction
    {
        trigger     = "client_server",
        description = "Build client/server library",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            os.execute "make -j4 ClientServer"
        end
    }

    newaction
    {
        trigger     = "virtualgo",
        description = "Build virtualgo library",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            os.execute "make -j4 VirtualGo"
        end
    }

    newaction
    {
        trigger     = "test",
        description = "Build and run all unit tests",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "make -j4 TestCore; make -j4 TestNetwork; make -j4 TestProtocol; make -j4 TestClientServer; make -j4 TestCubes; make -j4 TestVirtualGo" == 0 then
                os.execute "./bin/TestCore; ./bin/TestNetwork; ./bin/TestProtocol; ./bin/TestClientServer; ./bin/TestCubes; ./bin/TestVirtualGo"
            end
        end
    }

    newaction
    {
        trigger     = "test_core",
        description = "Build and run core unit tests",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "make -j4 TestCore" == 0 then
                os.execute "./bin/TestCore"
            end
        end
    }

    newaction
    {
        trigger     = "test_network",
        description = "Build and run network unit tests",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "make -j4 TestNetwork" == 0 then
                os.execute "./bin/TestNetwork"
            end
        end
    }

    newaction
    {
        trigger     = "test_protocol",
        description = "Build and run protocol unit tests",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "make -j4 TestProtocol" == 0 then
                os.execute "./bin/TestProtocol"
            end
        end
    }

    newaction
    {
        trigger     = "test_client_server",
        description = "Build and run client/server unit tests",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "make -j4 TestClientServer" == 0 then
                os.execute "./bin/TestClientServer"
            end
        end
    }

    newaction
    {
        trigger     = "test_cubes",
        description = "Build and run cubes unit tests",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "make -j4 TestCubes" == 0 then
                os.execute "./bin/TestCubes"
            end
        end
    }

    newaction
    {
        trigger     = "test_virtualgo",
        description = "Build and run virtualgo unit tests",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "make -j4 TestVirtualGo" == 0 then
                os.execute "./bin/TestVirtualGo"
            end
        end
    }

--[[    newaction
    {
        trigger     = "fonts",
        description = "Build fonts",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "make -j4 FontTool" == 0 then
                if os.execute "bin/FontTool assets/fonts/Fonts.json" ~= 0 then
                    os.exit(1)
                end
            end
        end
    }
--]]

    newaction
    {
        trigger     = "stones",
        description = "Build stones",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "make -j4 StoneTool" == 0 then
                if os.execute "rm -rf data/stones; mkdir -p data/stones; bin/StoneTool" ~= 0 then
                    os.exit(1)
                end
            end
        end
    }

    newaction
    {
        trigger     = "client",
        description = "Build and run game client",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "make -j4 Client" ~= 0 then
                os.exit(1)
            end
            os.execute "bin/Client"
        end
    }

    newaction
    {
        trigger     = "server",
        description = "Build and run game server",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "make -j4 Server" ~= 0 then
                os.exit(1)
            end
            os.execute "bin/Server"
        end
    }

    newaction
    {
        trigger     = "stone",
        description = "Build and run stone demo",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "make -j4 Client" ~= 0 then
                os.exit(1)
            end
            os.execute "bin/Client +load stone"
        end
    }

    newaction
    {
        trigger     = "cubes",
        description = "Build and run cubes demo",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "rm -rf output; mkdir -p output" ~= 0 then
                os.exit(1)
            end
            if os.execute "make -j4 Client" ~= 0 then
                os.exit(1)
            end
            os.execute "bin/Client +load cubes"
        end
    }

    newaction
    {
        trigger     = "lockstep",
        description = "Build and run lockstep demo",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "rm -rf output; mkdir -p output" ~= 0 then
                os.exit(1)
            end
            if os.execute "make -j4 Client" ~= 0 then
                os.exit(1)
            end
            os.execute "bin/Client +load lockstep"
        end
    }

    newaction
    {
        trigger     = "snapshot",
        description = "Build and run snapshot demo",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "rm -rf output; mkdir -p output" ~= 0 then
                os.exit(1)
            end
            if os.execute "make -j4 Client" ~= 0 then
                os.exit(1)
            end
            os.execute "bin/Client +load snapshot"
        end
    }

    newaction
    {
        trigger     = "compression",
        description = "Build and run compression demo",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "rm -rf output; mkdir -p output" ~= 0 then
                os.exit(1)
            end
            if os.execute "make -j4 Client" ~= 0 then
                os.exit(1)
            end
            os.execute "bin/Client +load compression"
        end
    }

    newaction
    {
        trigger     = "delta",
        description = "Build and run delta demo",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "rm -rf output; mkdir -p output" ~= 0 then
                os.exit(1)
            end
            if os.execute "make -j4 Client" ~= 0 then
                os.exit(1)
            end
            os.execute "bin/Client +load delta"
        end
    }

    newaction
    {
        trigger     = "sync",
        description = "Build and run state sync demo",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "rm -rf output; mkdir -p output" ~= 0 then
                os.exit(1)
            end
            if os.execute "make -j4 Client" ~= 0 then
                os.exit(1)
            end
            os.execute "bin/Client +load sync"
        end
    }

    newaction
    {
        trigger     = "playback",
        description = "Playback replay recording",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "rm -rf output; mkdir -p output" ~= 0 then
                os.exit(1)
            end
            if os.execute "make -j4 Client" ~= 0 then
                os.exit(1)
            end
            os.execute "bin/Client +playback"
        end
    }

    newaction
    {
        trigger     = "server",
        description = "Build and run game server",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "make -j4 Server" == 0 then
                os.execute "bin/Server"
            end
        end
    }

    newaction
    {
        trigger     = "soak_protocol",
        description = "Build and run protocol soak test",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "make -j4 SoakProtocol" == 0 then
                os.execute "bin/SoakProtocol"
            end
        end
    }

    newaction
    {
        trigger     = "soak_client_server",
        description = "Build and run client/server soak test",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "make -j4 SoakClientServer" == 0 then
                os.execute "bin/SoakClientServer"
            end
        end
    }

    newaction
    {
        trigger     = "profile_protocol",
        description = "Build and run protocol profile",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "make -j4 ProfileProtocol" == 0 then
                os.execute "bin/ProfileProtocol"
            end
        end
    }

    newaction
    {
        trigger     = "profile_client_server",
        description = "Build and run client server profile",
        valid_kinds = premake.action.get("gmake").valid_kinds,
        valid_languages = premake.action.get("gmake").valid_languages,
        valid_tools = premake.action.get("gmake").valid_tools,
     
        execute = function ()
            if os.execute "make -j4 ProfileClientServer" == 0 then
                os.execute "bin/ProfileClientServer"
            end
        end
    }

end
