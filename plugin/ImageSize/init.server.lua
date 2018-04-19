local AlwaysDisableClasses = {"Sound", "LuaSourceContainer", "KeyframeSequence", "Animation"}
local AlwaysIgnoreProperties = {MeshId = true}
local READY_TEXT = "Ready"

local Http = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local PaperRipple = require(script.Parent.PaperRipple)
local ContentInstances = {}
local PropertyButtons = {}
local SizeCache = {}
local LoadedContentInstances = false
local SelectedInstance, SelectedProperty

local Gui
local GuiContainer = script.Parent.ImageSizeGui
local Content = GuiContainer.Content
local Output = Content.Output
local PropertySelection = GuiContainer:FindFirstChild("PropertySelection", true)
local Highlight = PropertySelection.Highlight
local PropertyButtonTemplate = PropertySelection.TextButton
local ButtonTemplate = Content.TextButton

function Print(...)
	print("[ImageSize]", ...)
end

function GetContentInstances()
	local data = Http:JSONDecode(Http:GetAsync("https://anaminus.github.io/rbx/json/api/latest.json"))
	for _, entry in pairs(data) do
		if entry.type == "Property" and entry.ValueType == "Content" and entry.Class and AlwaysIgnoreProperties[entry.Name] == nil then
			if ContentInstances[entry.Class] == nil then
				ContentInstances[entry.Class] = {}
			end

			ContentInstances[entry.Class][#ContentInstances[entry.Class] + 1] = entry.Name
		end
	end

	LoadedContentInstances = true
end

function GetImageSize(id)
	if not id then
		error("No ID")
	end
	if id:sub(1, 11) == "rbxasset://" then
		error("Cannot get the size of local assets")
	end

	id = id:gsub("[^%d]", "")

	if #id == 0 then
		error("Invalid texture id")
	end

	if SizeCache[id] then
		return SizeCache[id].width, SizeCache[id].height
	end

	Output.Text = "Fetching size..."

	local data = Http:JSONDecode(Http:GetAsync("https://image-size.eryn.io/image-size/" .. id))

	if data.error then
		error("Web API returned an error: probably because selected property content is not an Image")
	end

	SizeCache[id] = data

	return data.width, data.height
end

function HasContent(instance)
	for _, class in pairs(AlwaysDisableClasses) do
		if instance:IsA(class) then
			return false
		end
	end
	return ContentInstances[instance.ClassName] ~= nil
end

function UpdatePropertySelection(instance)
	local properties = ContentInstances[instance.ClassName]
	SelectedProperty = properties[1]

	for _, button in pairs(PropertyButtons) do
		button:Destroy()
	end

	PropertyButtons = {}

	Highlight.Size = UDim2.new(1/#properties, 0, 0, 2)
	Highlight.Position = UDim2.new(0, 0, 1, -2)

	for i, property in pairs(properties) do
		local button = PropertyButtonTemplate:Clone()
		button.Text = property
		button.Size = UDim2.new(1/#properties, 0, 1, 0)
		button.Position = UDim2.new(1/#properties * (i-1), 0, 0, 0)
		button.Visible = true
		button.Parent = PropertySelection

		ApplyButtonHoverEffect(button)
		PaperRipple.FromParent(button)

		button.MouseButton1Click:Connect(function()
			SelectedProperty = property
			Output.Text = READY_TEXT
			Highlight:TweenPosition(UDim2.new(button.Position.X.Scale, 0, 1, -2), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
		end)

		PropertyButtons[#PropertyButtons + 1] = button
	end
end

function ApplyButtonHoverEffect(button)
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
	end)

	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	end)
end

function GetSize(target)
	local target = SelectedInstance
	if target:IsA("FaceInstance") and target.Parent:IsA("BasePart") then
		target = target.Parent
	end

	if typeof(target.Size) == "Vector3" then
		return target.Size.X, target.Size.Z
	elseif typeof(target.Size) == "Vector2" then
		return target.Size.X, target.Size.Y
	elseif typeof(target.Size) == "UDim2" then
		return target.Size.X.Offset, target.Size.Y.Offset
	else
		error("Unknown size property")
	end
end

function SetSize(target, x, y)
	local target = SelectedInstance
	if target:IsA("FaceInstance") and target.Parent:IsA("BasePart") then
		target = target.Parent
	end

	if typeof(target.Size) == "Vector3" then
		target.Size = Vector3.new(x, 1, y)
	elseif typeof(target.Size) == "Vector2" then
		target.Size = Vector3.new(x, y)
	elseif typeof(target.Size) == "UDim2" then
		target.Size = UDim2.new(0, x, 0, y)
	else
		return Print("Unknown Size property type")
	end

	ChangeHistoryService:SetWaypoint("ImageSize SetSize")
end

function CreateDockWidget()
	Gui = plugin:CreateDockWidgetPluginGui("ImageSize", DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false, false,
		250, 300,
		250, 300
	))

	Gui.Title = "ImageSize"

	for _, child in pairs(GuiContainer:GetChildren()) do
		child.Parent = Gui
	end
end

CreateDockWidget()

local Buttons = {
	{
		Name = "Get image size";
		Click = function()
			local worked, width, height = pcall(GetImageSize, SelectedInstance[SelectedProperty])
			if worked then
				Output.Text = string.format("Width: %d, Height: %d", width, height)
				Print(string.format("%d, %d", width, height))
			else
				Output.Text = "Error"
				Print("Error", width)
			end
		end
	};
	{
		Name = "Set size to image size";
		Click = function()
			local worked, x, y = pcall(GetImageSize, SelectedInstance[SelectedProperty])
			if not worked then return Print("Error", x) end
			pcall(function()
				SetSize(SelectedInstance, x, y)
			end)
		end
	};
	{
		Name = "Set size, maintain width";
		Click = function()
			local worked, x, y = pcall(GetImageSize, SelectedInstance[SelectedProperty])
			if not worked then return Print("Error", x) end
			pcall(function()
				local cx, cy = GetSize(SelectedInstance)
				SetSize(SelectedInstance, cx, (cx * y) / x)
			end)
		end
	};
	{
		Name = "Set size, maintain height";
		Click = function()
			local worked, x, y = pcall(GetImageSize, SelectedInstance[SelectedProperty])
			if not worked then return Print("Error", x) end
			pcall(function()
				local cx, cy = GetSize(SelectedInstance)
				SetSize(SelectedInstance, (x * cy) / y, cy)
			end)
		end
	};
}

for i, info in pairs(Buttons) do
	local button = ButtonTemplate:Clone()
	button.Text = string.rep(" ", 10) .. info.Name
	button.MouseButton1Click:Connect(info.Click)
	button.LayoutOrder = 3 + i
	button.Visible = true
	button.Parent = Content

	ApplyButtonHoverEffect(button)
	PaperRipple.FromParent(button)
end

Selection.SelectionChanged:Connect(function()
	Output.Text = READY_TEXT

	SelectedInstance = Selection:Get()[1]

	if not SelectedInstance then
		Gui.Enabled = false
		return
	end

	Gui.Enabled = HasContent(SelectedInstance)

	if Gui.Enabled then
		UpdatePropertySelection(SelectedInstance)
	end
end)

game.StarterGui.DescendantAdded:Connect(function(child)
	if _G.ImageSizeDisableAutoDecal then return end
	if child:IsA("Decal") and (child.Parent:IsA("ImageLabel") or child.Parent:IsA("ImageButton")) then
		local parent = child.Parent
		parent.Image = child.Texture
		wait()
		child:Destroy()
		Selection:Set({parent})
		Print("Automatically set Image to the Decal you just inserted. Disable this behavior with _G.ImageSizeDisableAutoDecal = true")
	end
end)

local worked, msg = pcall(GetContentInstances)

if worked then
	wait(4)
	Print("ImageSize is enabled. Select an object with an image to view image options.")
else
	plugin:CreateToolbar("ImageSize"):CreateButton("Enable ImageSize", "Use this button to enable ImageSize after you've enabled HTTP requests in game settings.", "").Click:Connect(function()
		if not LoadedContentInstances then
			local worked, msg = pcall(GetContentInstances)

			if worked then
				Print("Enabled ImageSize. Select an object with an image to get started.")
			else
				Selection:Set({Http})
				Print(msg)
			end
		end
	end)
	wait(4)
	Print("Enable HTTP requests in Game Settings to use ImageSize in this game, then press the ImageSize button to enable.")
end
