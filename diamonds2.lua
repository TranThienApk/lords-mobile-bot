-- =========================================================
-- AutoGemStore - PS99 Diamond Stock Sync Bot (Production)
-- Domain: https://autogemstore.online/
-- =========================================================

local CONFIG = {
    API_STOCK = "https://autogemstore.online/api/bot_update_stock.php",
    API_PING = "https://autogemstore.online/api/bot_ping.php",
    BOT_SECRET = "AGS_2026_9fK2xQm7Rz1Lp4Vn8Tw6Yc3Hd0Sb5Ju",
    WEBHOOK = "https://discord.com/api/webhooks/1502609152025952338/9TmUzZ2jRGfdu0tNYMz7lci6s42oYO1Pxj6MvlAU_x8qiMTxcU2awczwsHeYb3SaCDsD",
    PUSH_INTERVAL = 30,
}

local Http = game:GetService("HttpService")
local Players = game:GetService("Players")
local plr = Players.LocalPlayer

-- Detect request function
local req = (request or http_request or syn.request or (http and http.request))
if not req then
    warn("❌ Executor không hỗ trợ gửi HTTP Request!")
end

local function safeRequest(payload)
    if not req then return nil end
    local ok, res = pcall(function()
        return req(payload)
    end)
    return ok and res or nil
end

local function notify(title, text, icon)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title or "AutoGemStore",
            Text = text or "",
            Icon = icon or "rbxassetid://12345678", -- Bạn có thể đổi ID icon nếu muốn
            Duration = 5
        })
    end)
end

local function logToDiscord(msg, color)
    print("📢 Discord Log: " .. msg)
    if not CONFIG.WEBHOOK or CONFIG.WEBHOOK == "" or not req then return end
    pcall(function()
        req({
            Url = CONFIG.WEBHOOK,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = Http:JSONEncode({embeds = {{description = msg, color = color or 0x00ccff, timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")}}})
        })
    end)
end

local function pingBot()
    local res = safeRequest({
        Url = CONFIG.API_PING,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded",
            ["X-Bot-Key"] = CONFIG.BOT_SECRET
        },
        Body = "bot_username=" .. Http:UrlEncode(plr.Name)
    })
    if not res then warn("⚠️ Bot Ping thất bại (Network Error)") end
end

local function updateHostingStock(amount)
    safeRequest({
        Url = CONFIG.API_STOCK,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded",
            ["X-Bot-Key"] = CONFIG.BOT_SECRET
        },
        Body = "bot_username=" .. Http:UrlEncode(plr.Name)
            .. "&stock_gems=" .. Http:UrlEncode(tostring(math.floor(amount or 0)))
    })
end

local function getLeaderstatsDiamondValue()
    local ls = plr:FindFirstChild("leaderstats") or plr:WaitForChild("leaderstats", 8)
    if not ls then
        return nil
    end

    local diamondStat = ls:FindFirstChild("Diamonds")
        or ls:FindFirstChild("Diamond")
        or ls:FindFirstChild("Gems")
        or ls:FindFirstChild("Currency")

    if not diamondStat then
        local biggest, biggestVal = nil, -1
        for _, stat in ipairs(ls:GetChildren()) do
            local v = tonumber(stat.Value) or 0
            if v > biggestVal then
                biggestVal = v
                biggest = stat
            end
        end
        diamondStat = biggest
    end

    return diamondStat
end

local diamondStat = getLeaderstatsDiamondValue()
if not diamondStat then
    warn("❌ Không tìm thấy giá trị Kim Cương trong leaderstats! Kiểm tra F9.")
    notify("Lỗi Hệ Thống", "Không tìm thấy chỉ số Kim Cương!", "rbxassetid://11419713314")
    logToDiscord("❌ Bot `" .. plr.Name .. "` không tìm thấy chỉ số Kim Cương!", 0xff0000)
    return
end

print("✅ Đã tìm thấy chỉ số Kim Cương: " .. diamondStat.Name)
notify("Khởi Động", "Bot đồng bộ tồn kho đang chạy...", "rbxassetid://11419719547")

local lastValue = math.floor(tonumber(diamondStat.Value) or 0)
pingBot()
updateHostingStock(lastValue)

logToDiscord("🤖 **Bot Cập Nhật Tồn Kho Đã Bắt Đầu:** `" .. plr.Name .. "`", 0x00ff00)

diamondStat:GetPropertyChangedSignal("Value"):Connect(function()
    local currentValue = math.floor(tonumber(diamondStat.Value) or 0)
    if currentValue ~= lastValue then
        lastValue = currentValue
        updateHostingStock(currentValue)
    end
end)

while true do
    pingBot()
    updateHostingStock(lastValue)
    task.wait(CONFIG.PUSH_INTERVAL)
end
