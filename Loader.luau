-- Loader.luau: run this in your executor. It checks the key with Junkie, then runs
-- the protected script (Example.luau pasted into the script's Original Code on Junkie).
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/longtokaiikari-source/HawkTokaiLib/refs/heads/main/Source.luau"))()

Library:RunProtected({
    Title = "Key required",
    UNC = { Fail = 70, Warn = 80 },   -- below 70 stops the load; 70 to 79 loads with a banner
    Junkie = {
        Service = 89502,
        Identifier = "1030951",
        Provider = 15341,
        ScriptId = "2f090698dee2ec0efff78046d9ac9522097c54e534b203fa185db6bc4464b512",
    },
})
