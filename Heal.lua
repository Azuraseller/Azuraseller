-- Tải và thực thi cả ba script cùng lúc
local scripts = {
    "https://rawscripts.net/raw/Dead-Rails-Alpha-Alpha-Aimbot-with-bind-30004",
    "https://raw.githubusercontent.com/Azuraseller/Azuraseller/main/Clip.lua",
    "https://raw.githubusercontent.com/Azuraseller/Azuraseller/main/Drail.lua"
}

for _, url in ipairs(scripts) do
    loadstring(game:HttpGet(url))()
end
