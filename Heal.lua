-- Tải và thực thi cả ba script cùng lúc
local scripts = {
    "https://raw.githubusercontent.com/Azuraseller/Azuraseller/main/Aim.lua",
    "https://raw.githubusercontent.com/Azuraseller/Azuraseller/main/Clip.lua",
    "https://raw.githubusercontent.com/thiennrb7/Script/refs/heads/main/Bringall"
}

for _, url in ipairs(scripts) do
    loadstring(game:HttpGet(url))()
end
