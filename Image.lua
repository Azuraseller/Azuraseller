local screenGui = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui")) local canvas = Instance.new("Frame", screenGui) canvas.Size = UDim2.new(0, 500, 0, 500) -- Kích thước tổng thể canvas.Position = UDim2.new(0.5, -250, 0.5, -250) canvas.BackgroundColor3 = Color3.new(1,1,1)

local pixelSize = 10 -- Kích thước mỗi pixel local width, height = 50, 50 -- Kích thước ảnh pixel hóa local pixelData = { {{60,54,48}, {129,85,85}, {239,99,120}, {205,54,78}, {127,58,62}, {91,68,65}, {92,71,68}, {93,69,69}, {96,73,76}, {115,91,98}, {126,102,110}, {128,103,112}, {130,106,115}, {143,121,133}, {140,117,130}, {154,131,147}, {195,168,187}, {206,180,197}, {198,170,188}, {168,140,157}, {131,110,128}, {141,122,139}, {110,91,107}, {103,84,101}, {110,93,108}, {110,95,108}, {105,91,105}, {129,115,130}, {133,119,134}, {90,81,93}, {41,37,43}, {58,51,58}, {55,49,56}, {36,34,39}, {28,27,33}, {20,20,25}, {25,26,29}, {37,38,42}, {35,36,39}, {32,34,36}, {39,36,37}, {78,67,60}, {88,78,69}, {87,77,68}, {87,77,68}, {87,77,68}, {87,77,68}, {87,77,68}, {85,75,66}, {82,72,63}}, {{84,58,57}, {225,95,115}, {203,59,80}, {111,66,65}, {85,73,64}, {85,71,64}, {90,73,68}, {84,66,64}, {90,71,72}, {103,82,85}, {108,87,91}, {108,85,92}, {113,92,98}, {122,101,109}, {117,96,107}, {139,117,131}, {171,145,164}, {183,160,177}, {204,180,196}, {178,150,167}, {155,133,152}, {152,130,149}, {119,98,115}, {117,99,115}}, }

for y = 1, height do for x = 1, width do local r, g, b = unpack(pixelData[y][x]) local pixel = Instance.new("Frame", canvas) pixel.Size = UDim2.new(0, pixelSize, 0, pixelSize) pixel.Position = UDim2.new(0, (x-1) * pixelSize, 0, (y-1) * pixelSize) pixel.BackgroundColor3 = Color3.fromRGB(r, g, b) end end

