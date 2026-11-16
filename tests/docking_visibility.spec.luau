--!strict

local activated, deactivated = 0, 0
local panel = { OnActivate = Lib.Signal.new(), OnDeactivate = Lib.Signal.new() }
panel.OnActivate:Connect(function()
	activated += 1
end)
panel.OnDeactivate:Connect(function()
	deactivated += 1
end)
rightSide.Windows = { panel }
local veto = static.BeforeSideVisibilityChange:Connect(function(transition)
	assert(
		transition.Side == "right" and transition.Visible == false,
		"transition carries the requested side and state"
	)
	transition.Cancel = true
end)
assert(
	not static.ToggleSide("right") and not rightSide.Hidden and updates == 0 and deactivated == 0,
	"cancelled auto-hide leaves layout and observers untouched"
)
veto:Disconnect()
assert(
	static.ToggleSide("right") and rightSide.Hidden and deactivated == 1 and updates == 1,
	"accepted auto-hide deactivates once"
)
assert(
	static.SetSideVisible("right", false) and deactivated == 1 and updates == 1,
	"redundant visibility change does no work"
)
assert(
	static.SetSideVisible("right", true) and not rightSide.Hidden and activated == 1 and updates == 2,
	"restoring a side activates once"
)
print("PASS: actual sidebar transition veto, no-op suppression and activation/deactivation ordering")
