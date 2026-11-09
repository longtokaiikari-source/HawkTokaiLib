-- JunkieTest.lua: checks the Junkie setup one step at a time and prints each result.
-- Fill in the values below, run this file in your executor, and read the console.

local SERVICE = 89502                       -- service ID or name
local IDENTIFIER = "YOUR_JUNKIE_USER_ID"    -- owner's Junkie user ID (user_id from GET /services/{id})
local PROVIDER = 15341                      -- provider ID or name, used by get_key_link
local TEST_KEY = "PASTE_TEST_KEY"           -- a key for this service. check_key binds it to this device.
local TEST_LINK = false                     -- true also asks for a key link (may be rate limited)
local SDK_URL = "https://jnkie.com/sdk/library.lua"

local MEANING = {
    KEY_INVALID = "the key was not accepted. Check the key and the service.",
    KEY_EXPIRED = "the validity period ended. Get a new key.",
    KEY_INVALIDATED = "the key was disabled. Contact the owner.",
    ALREADY_USED = "a one-time key was already used.",
    HWID_MISMATCH = "the key is bound to another device.",
    HWID_BANNED = "this device is banned.",
    SERVICE_MISMATCH = "the key belongs to another service. Check SERVICE.",
    SERVICE_NOT_FOUND = "the service is unavailable. Check SERVICE and IDENTIFIER.",
    PREMIUM_REQUIRED = "the service requires a Premium key.",
    ERROR = "no response. Check the internet connection.",
    RATE_LIMITTED = "rate limited. Wait before trying again.",
    ["http 429"] = "rate limited. Wait before trying again.",
}

local function report(name, ok, detail)
    print("[JunkieTest] " .. name .. ": " .. (ok and "OK" or "FAIL") .. (detail and detail ~= "" and (" - " .. detail) or ""))
end

local function explain(code)
    return tostring(code) .. " (" .. (MEANING[code] or "see the Junkie error docs") .. ")"
end

-- 1. Settings
local settingsOk = SERVICE ~= nil and IDENTIFIER ~= "YOUR_JUNKIE_USER_ID" and PROVIDER ~= nil
report("settings", settingsOk, settingsOk and "" or "fill in SERVICE, IDENTIFIER and PROVIDER")

-- 2. Test key
local keyOk = TEST_KEY ~= "PASTE_TEST_KEY" and TEST_KEY ~= ""
report("test key", keyOk, keyOk and "" or "paste a key for this service into TEST_KEY")

if settingsOk and keyOk then
    -- 3. SDK
    local loaded, Junkie = pcall(function()
        return loadstring(game:HttpGet(SDK_URL))()
    end)
    local sdkOk = loaded and type(Junkie) == "table" and type(Junkie.check_key) == "function"
    report("sdk", sdkOk, sdkOk and "check_key found" or ("could not load it: " .. tostring(Junkie)))

    if sdkOk then
        Junkie.service = SERVICE
        Junkie.identifier = IDENTIFIER
        Junkie.provider = PROVIDER

        -- 4. check_key
        local ok, result = pcall(Junkie.check_key, TEST_KEY)
        if not ok then
            report("check_key", false, "exception: " .. tostring(result))
        elseif type(result) ~= "table" then
            report("check_key", false, "unexpected result: " .. tostring(result))
        elseif result.valid then
            report("check_key", true, "valid, tier " .. tostring(result.JD_TIER) .. " (" .. tostring(result.JD_TIER_NAME) .. ")")
        else
            report("check_key", false, explain(result.error))
        end

        -- 5. get_key_link (optional)
        if TEST_LINK then
            local okLink, link, err = pcall(Junkie.get_key_link)
            if not okLink then
                report("get_key_link", false, "exception: " .. tostring(link))
            elseif link then
                report("get_key_link", true, link)
            else
                report("get_key_link", false, explain(err))
            end
        end
    end
end

print("[JunkieTest] done. If a step failed, send the [JunkieTest] lines. Never send the key.")
