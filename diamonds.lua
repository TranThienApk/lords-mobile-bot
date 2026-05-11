-- =========================================================
-- PS99 DIAMOND TRACKER & MONITORING
-- Phiên bản: Premium V2
-- =========================================================

local WEBHOOK = "https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN" -- SỬA LẠI WEBHOOK CỦA BẠN
local WEB_URL = "http://127.0.0.1/ps99shop" -- Sửa thành Website thật
local SECRET_BOT_KEY = "MUA_KIM_CUONG_SIEU_BAO_MAT_2026"

local Http = game:GetService("HttpService")
local plr = game:GetService("Players").LocalPlayer

local function updateHostingStock(amount)
    pcall(function()
        request({
            Url = WEB_URL .. "/api/bot_update_stock.php",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/x-www-form-urlencoded",
                ["X-Bot-Key"] = SECRET_BOT_KEY
            },
            Body = "bot_username=" .. Http:UrlEncode(plr.Name) .. "&stock_kc=" .. Http:UrlEncode(tostring(math.floor(amount)))
        })
    end)
end

local function log(msg, color)
    pcall(function()
        request({
            Url = WEBHOOK,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = Http:JSONEncode({embeds = {{description = msg, color = color or 0x00ccff}}})
        })
    end)
end

local function formatCompact(n)
    n = math.floor(n or 0)
    if n >= 1e9 then return string.format("%.2fB", n / 1e9)
    elseif n >= 1e6 then return string.format("%.2fM", n / 1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n / 1e3)
    else return tostring(n) end
end

local function formatComma(n)
    local s = tostring(math.floor(n or 0))
    local result = ""
    for i = 1, #s do
        if i > 1 and (#s - i + 1) % 3 == 0 then result = result .. "," end
        result = result .. s:sub(i, i)
    end
    return result
end

-- Tìm Leaderstats
local ls = plr:FindFirstChild("leaderstats") or plr:WaitForChild("leaderstats", 5)
if not ls then
    log("❌ [Monitor Lỗi] Không tìm thấy bảng Leaderstats!", 0xff0000)
    return
end

-- Tìm Cột Kim Cương
local diamondStat = ls:FindFirstChild("Diamonds") or ls:FindFirstChild("Diamond") or ls:FindFirstChild("Gems") or ls:FindFirstChild("Currency")

if not diamondStat then
    local biggest, biggestVal = nil, 0
    for _, stat in ipairs(ls:GetChildren()) do
        local v = tonumber(stat.Value) or 0
        if v > biggestVal then biggestVal = v; biggest = stat end
    end
    diamondStat = biggest
end

if not diamondStat then
    log("❌ [Monitor Lỗi] Không xác định được cột Kim Cương trên bảng điểm!", 0xff0000)
    return
end

-- Hàm tóm tắt nhanh trạng thái account
local function dumpStats()
    local text = ""
    for _, stat in ipairs(ls:GetChildren()) do
        text = text .. stat.Name .. ": **" .. formatCompact(stat.Value) .. "**\n"
    end
    return text
end

local initialDiamonds = diamondStat.Value
local timeStarted = os.time()

log("💎 **HỆ THỐNG GIÁM SÁT KÍCH HOẠT**\nTài khoản: `" .. plr.Name .. "`\n\n" .. dumpStats() .. "\n_Đang liên tục theo dõi dòng tiền..._", 0xffaa00)

local lastCheckedValue = diamondStat.Value
updateHostingStock(lastCheckedValue) -- Bắn số liệu lên Web lần đầu tiên

-- Móc nối vào Event thay đổi của cột Kim Cương
diamondStat:GetPropertyChangedSignal("Value"):Connect(function()
    local currentValue = diamondStat.Value
    local diff = currentValue - lastCheckedValue
    
    -- Chỉ báo cáo lên Discord nếu biến động lớn hơn 10.000 (Tránh spam API webhook)
    if math.abs(diff) >= 10000 then
        local icon = diff > 0 and "🟢" or "🔴"
        local sign = diff > 0 and "+" or ""
        
        log(icon .. " **Biến Động Số Dư** | `" .. plr.Name .. "`\n" ..
            "📊 Hiện tại: **" .. formatComma(currentValue) .. "**\n" ..
            "💸 Thay đổi: **" .. sign .. formatComma(diff) .. "**\n" ..
            "📈 Lợi nhuận phiên: **" .. formatComma(currentValue - initialDiamonds) .. "**",
            diff > 0 and 0x00ff88 or 0xff4444)
            
        lastCheckedValue = currentValue
        updateHostingStock(currentValue) -- Cập nhật số liệu mới lên Web Hosting
    end
end)

-- Báo Cáo Tổng Kết Mỗi 15 Phút
while true do
    task.wait(900) -- 15 Phút
    
    local currentValue = diamondStat.Value
    local timeElapsed = os.time() - timeStarted
    local totalGained = currentValue - initialDiamonds
    
    -- Tính tốc độ farm 1 giờ
    local ratePerHour = timeElapsed > 0 and (totalGained / timeElapsed * 3600) or 0
    
    log("📋 **BÁO CÁO 15 PHÚT** | `" .. plr.Name .. "`\n" ..
        "🕒 Đã hoạt động: **" .. math.floor(timeElapsed / 60) .. " phút**\n" ..
        "▲ Tổng thu nhập từ lúc bật: **" .. formatComma(totalGained) .. "**\n" ..
        "⚡ Tốc độ trung bình: **" .. formatCompact(ratePerHour) .. "/giờ**\n\n" ..
        dumpStats(), 0x00ccff)
end
