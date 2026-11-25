--!strict
-- Single server entry point. Lives in ServerScriptService.
-- Require every service first, then start them, so no module runs before its dependencies exist.

local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService.Services
local DataService = require(Services.DataService)
local ShopService = require(Services.ShopService)

DataService.start()
ShopService.start()
