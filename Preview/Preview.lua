local O = OneCrosshair
O.Preview = {}
function O.Preview.Initialize(panel, settings)
    local self = O.Preview
    self.settings, self.examples = settings, {}
    self.root = O.Control(panel)
    self.root:SetAnchor(TOPLEFT, panel, TOPLEFT, 0, 0)
    self.root:SetDimensions(300, 65)
    for i, state in ipairs({ "normal", "target", "block" }) do
        local crosshair = O.CrosshairController.New(self.root)
        crosshair.root:SetAnchor(TOPLEFT, self.root, TOPLEFT, 45 + (i - 1) * 95, 20)
        local label = O.Control(self.root, CT_LABEL)
        label:SetFont("ZoFontGameSmall")
        label:SetAnchor(TOP, crosshair.root, CENTER, 0, 17)
        label:SetText(GetString(_G["SI_ONECROSSHAIR_" .. string.upper(state)]))
        self.examples[i] = { crosshair = crosshair, state = state }
    end
    self.root:SetHidden(not self.open)
    O.Preview.Refresh()
end
function O.Preview.Refresh()
    local self = O.Preview
    if not self.root then return end
    for _, example in ipairs(self.examples) do
        O.CrosshairController.SetPreset(example.crosshair, self.settings.preset, example.state)
        O.CrosshairController.Update(example.crosshair, { geometry = example.state },
            self.settings.crosshairOpacity, GetFrameTimeMilliseconds(), true)
    end
end
function O.Preview.Show(show)
    O.Preview.open = show
    if not O.Preview.root then return end
    O.Preview.root:SetHidden(not show)
    if show then O.Preview.Refresh() end
end
