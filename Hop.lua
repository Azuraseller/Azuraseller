local Http = game:GetService("HttpService")
local TPS = game:GetService("TeleportService")
local Api = "https://games.roblox.com/v1/games/"

local _place = game.PlaceId
local _servers = Api.._place.."/servers/Public?sortOrder=Asc&limit=100"

-- Hàm lấy danh sách các server
function ListServers(cursor)
   local url = _servers .. (cursor and "&cursor="..cursor or "")
   local success, result = pcall(function()
       return Http:JSONDecode(game:HttpGet(url))
   end)
   if success then
       return result
   else
       warn("Không thể lấy danh sách server: " .. result)
       return nil
   end
end

-- Hàm kiểm tra và tham gia vào server
function JoinServer()
   local Server, Next
   repeat
       local Servers = ListServers(Next)
       if Servers and Servers.data then
           for _, server in ipairs(Servers.data) do
               -- Kiểm tra xem server có thể tham gia hay không
               if server.playing < server.maxPlayers then
                   Server = server
                   break
               end
           end
           Next = Servers.nextPageCursor
       end
   until Server

   if Server then
       -- Tham gia vào server nếu tìm thấy server hợp lệ
       local success, errorMsg = pcall(function()
           TPS:TeleportToPlaceInstance(_place, Server.id, game.Players.LocalPlayer)
       end)
       if not success then
           warn("Không thể tham gia vào server: " .. errorMsg)
       end
   else
       warn("Không tìm thấy server hợp lệ để tham gia.")
   end
end

-- Hàm kiểm tra khung giờ hiện tại
function IsAllowedTime()
   local currentTime = os.date("*t")
   local hour = currentTime.hour
   local minute = currentTime.min
   local totalMinutes = hour * 60 + minute

   -- Danh sách các khung giờ cho phép (đơn vị phút)
   local allowedTimeRanges = {
       {247, 260}, -- 4:07 đến 4:20
       {526, 537}, -- 8:46 đến 8:57
       {790, 808}, -- 13:10 đến 13:28
       {1060, 1077}, -- 17:40 đến 17:57
       {1330, 1346}, -- 22:10 đến 22:26
   }

   for _, range in ipairs(allowedTimeRanges) do
       if totalMinutes >= range[1] and totalMinutes <= range[2] then
           return true
       end
   end

   return false
end

-- Kiểm tra thời gian trước khi gọi JoinServer
if IsAllowedTime() then
   JoinServer()
else
   warn("Hiện không nằm trong khung giờ được phép.")
end
