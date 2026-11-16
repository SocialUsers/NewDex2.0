--!strict

-- These are measured-font behavioral tests, not claims about Roblox rasterization.
local originalMeasure = service.TextService.GetTextSize
local measureCalls = 0
service.TextService.GetTextSize = function(_, text, size, font)
	measureCalls += 1
	local width = 0
	for _, code in utf8.codes(text) do
		width += code == 0x754c and 15 or code == 0x1f600 and 19 or 7
	end
	return Vector2.new(width, size)
end
local geometryCF = setmetatable({
	Lines = { "a" .. utf8.char(0x754c) .. utf8.char(0x1f600) .. "b" },
	FontSize = 14,
	ViewX = 0,
	ViewY = 0,
	GuiElems = { LinesFrame = lines },
	CursorX = 0,
	CursorY = 0,
}, { __index = funcs })
assert(funcs.GetColumnPixelX(geometryCF, 1, 0) == 7, "ASCII insertion uses real font advance")
assert(funcs.GetColumnPixelX(geometryCF, 4, 0) == 22, "three-byte wide glyph occupies measured width once")
assert(funcs.GetColumnPixelX(geometryCF, 8, 0) == 41, "four-byte glyph occupies measured width once")
assert(
	funcs.GetColumnPixelX(geometryCF, 3, 0) == 7,
	"invalid interior UTF-8 byte column snaps to legal insertion boundary"
)
assert(
	funcs.GetPixelColumn(geometryCF, 13, 0) == 1 and funcs.GetPixelColumn(geometryCF, 16, 0) == 4,
	"hit-testing chooses nearest measured boundary"
)
assert(funcs.GetPixelColumn(geometryCF, 32, 0) == 8, "mixed glyph hit-testing accounts for emoji width")
local calls = measureCalls
for i = 1, 30 do
	funcs.GetColumnPixelX(geometryCF, 8, 0)
	funcs.GetPixelColumn(geometryCF, 32, 0)
end
assert(measureCalls == calls, "repeated pointer and caret queries reuse row and glyph metrics")
geometryCF.ViewX = 2
local column, row = funcs.ScreenToEditorPoint(geometryCF, lines.AbsolutePosition.X + 8, lines.AbsolutePosition.Y)
assert(column == 4 and row == 0, "horizontal scroll is pixels while cursor remains valid byte position")
for i = 1, 300 do
	geometryCF.Lines = { tostring(i) }
	funcs.LineGeometry(geometryCF, 0)
end
assert(#geometryCF.LineGeometryOrder <= 256, "visited-line cache has bounded retention")
geometryCF.FontSize = 20
funcs.LineGeometry(geometryCF, 0)
assert(#geometryCF.LineGeometryOrder == 1, "font zoom invalidates old row and glyph metrics")
service.TextService.GetTextSize = originalMeasure
print(
	"PASS: measured Unicode insertion positions, nearest pointer hit-testing, UTF-8 boundaries, scroll conversion and bounded geometry cache"
)
