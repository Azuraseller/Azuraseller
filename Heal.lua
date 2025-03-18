-- Tải và thực thi cả ba script cùng lúc
local scripts = {
    "https://raw.githubusercontent.com/Azuraseller/Azuraseller/main/Aim.lua",
    "https://raw.githubusercontent.com/Azuraseller/Azuraseller/main/Clip.lua",
    "https://rawscripts.net/raw/Dead-Rails-Alpha-New-Update-SpiderXHub-30420"
}

for _, url in ipairs(scripts) do
    loadstring(game:HttpGet(url))()
end
