--!strict
-- Single client entry point. Either a Script with RunContext = Client in ReplicatedStorage,
-- or one LocalScript in StarterPlayerScripts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Controllers = ReplicatedStorage.Client.Controllers
local ShopController = require(Controllers.ShopController)

ShopController.start()
