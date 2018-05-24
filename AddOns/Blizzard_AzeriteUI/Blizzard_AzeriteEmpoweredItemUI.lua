AzeriteEmpoweredItemUIMixin = CreateFromMixins(CallbackRegistryBaseMixin);

AzeriteEmpoweredItemUIMixin:GenerateCallbackEvents(
{
    "OnShow",
});

local AZERITE_EMPOWERED_FRAME_EVENTS = {
	"AZERITE_ITEM_POWER_LEVEL_CHANGED",
	"AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED",
	"PLAYER_EQUIPMENT_CHANGED",
};

AZERITE_EMPOWERED_ITEM_MAX_TIERS = 4;

function AzeriteEmpoweredItemUIMixin:OnLoad()
	CallbackRegistryBaseMixin.OnLoad(self);

	UIPanelWindows[self:GetName()] = { area = "left", pushable = 0, xoffset = 35, yoffset = -9, bottomClampOverride = 100, showFailedFunc = function() self:OnShowFailed(); end, };

	self.BorderFrame.Bg:SetParent(self);
	self.BorderFrame.TopTileStreaks:Hide();

	self.transformTree = CreateFromMixins(TransformTreeMixin);
	self.transformTree:OnLoad();

	local root = self.transformTree:GetRoot();
	root:SetLocalScale(.5855);
	
	self.BackgroundFrame.Rank2Gear.transformNode = root:CreateNodeFromTexture(self.BackgroundFrame.Rank2Gear);
	self.BackgroundFrame.Rank3Gear.transformNode = root:CreateNodeFromTexture(self.BackgroundFrame.Rank3Gear);
	self.BackgroundFrame.Rank4Gear.transformNode = root:CreateNodeFromTexture(self.BackgroundFrame.Rank4Gear);

	self.BackgroundFrame.Rank2Gear.transformNode:SetLocalScale(1.05);
	self.BackgroundFrame.Rank3Gear.transformNode:SetLocalScale(1.05);
	self.BackgroundFrame.Rank4Gear.transformNode:SetLocalScale(1.05);

	self.BackgroundFrame.Rank2RingBg.transformNode = root:CreateNodeFromTexture(self.BackgroundFrame.Rank2RingBg);
	self.BackgroundFrame.Rank3RingBg.transformNode = root:CreateNodeFromTexture(self.BackgroundFrame.Rank3RingBg);
	self.BackgroundFrame.Rank4RingBg.transformNode = root:CreateNodeFromTexture(self.BackgroundFrame.Rank4RingBg);

	self.BackgroundFrame.Rank2GearBg.transformNode = self.BackgroundFrame.Rank2RingBg.transformNode:CreateNodeFromTexture(self.BackgroundFrame.Rank2GearBg);
	self.BackgroundFrame.Rank3GearBg.transformNode = self.BackgroundFrame.Rank3RingBg.transformNode:CreateNodeFromTexture(self.BackgroundFrame.Rank3GearBg);
	self.BackgroundFrame.Rank4GearBg.transformNode = self.BackgroundFrame.Rank4RingBg.transformNode:CreateNodeFromTexture(self.BackgroundFrame.Rank4GearBg);

	self.BackgroundFrame.Rank2RingBgGlow.SelectedAnim = self.SelectRank2Anim;
	self.BackgroundFrame.Rank3RingBgGlow.SelectedAnim = self.SelectRank3Anim;
	self.BackgroundFrame.Rank4RingBgGlow.SelectedAnim = self.SelectRank4Anim;

	self.BackgroundFrame.Rank2RingBgGlow.FadeAnim = self.FadeRank2Anim;
	self.BackgroundFrame.Rank3RingBgGlow.FadeAnim = self.FadeRank3Anim;
	self.BackgroundFrame.Rank4RingBgGlow.FadeAnim = self.FadeRank4Anim;

	self.tierPool = CreateFramePool("FRAME", self, "AzeriteEmpoweredItemTierTemplate");
	self.powerPool = CreateTransformFrameNodePool("BUTTON", self.BackgroundFrame, "AzeriteEmpoweredItemPowerTemplate");
	self.azeriteItemDataSource = AzeriteEmpowedItemDataSource:CreateEmpty();
end

function AzeriteEmpoweredItemUIMixin:OnUpdate(elapsed)
	if self.dirty then
		self.dirty = nil;
		self:Refresh();
	end

	for tierIndex, tierFrame in ipairs(self.tiersByIndex) do
		tierFrame:PerformAnimations();
	end

	self.transformTree:ResolveTransforms();
end

function AzeriteEmpoweredItemUIMixin:OnShow()
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN);

	self:TriggerEvent(AzeriteEmpoweredItemUIMixin.Event.OnShow);
end

function AzeriteEmpoweredItemUIMixin:OnHide()
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE);
	self:Clear();
end

function AzeriteEmpoweredItemUIMixin:OnEvent(event, ...)
	if event == "AZERITE_ITEM_POWER_LEVEL_CHANGED" then
		local azeriteItemLocation, oldPowerLevel, newPowerLevel = ...;
		self:MarkDirty();
	elseif event == "AZERITE_EMPOWERED_ITEM_SELECTION_UPDATED" then
		local item = ...;
		self:MarkDirty();
	elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
		self:MarkDirty();
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		local equipmentSlot, hasCurrent = ...;
		if self.azeriteItemDataSource:DidEquippedItemChange(equipmentSlot) then
			self:Clear();
		end
	end
end

function AzeriteEmpoweredItemUIMixin:OnShowFailed()
	self:Clear();
end

function AzeriteEmpoweredItemUIMixin:OnTierAnimationStateChanged(tierFrame)
	self:MarkDirty();
end

function AzeriteEmpoweredItemUIMixin:IsItemValid()
	return self.azeriteItemDataSource:IsValid();
end

local function HideAll(widgets)
	for i, widget in ipairs(widgets) do
		widget:Hide();
	end
end

function AzeriteEmpoweredItemUIMixin:Clear()
	StaticPopup_Hide("CONFIRM_AZERITE_EMPOWERED_BIND");

	local azeriteEmpoweredItem = self.azeriteItemDataSource:GetItem();
	if azeriteEmpoweredItem then
		azeriteEmpoweredItem:UnlockItem();
	end

	if self.itemDataLoadedCancelFunc then
		self.itemDataLoadedCancelFunc();
		self.itemDataLoadedCancelFunc = nil;
	end

	self.azeriteItemDataSource:Clear();

	self.tierPool:ReleaseAll();
	self.tiersByIndex = {};
	self.powerPool:ReleaseAll();

	HideAll(self.BackgroundFrame.RingBackgrounds);
	HideAll(self.BackgroundFrame.GearBackgrounds);
	HideAll(self.BackgroundFrame.Gears);
	HideAll(self.BackgroundFrame.RingBorders);
	HideAll(self.BackgroundFrame.RingGlows);
	HideAll(self.BackgroundFrame.PlugBackgrounds);

	HideAll(self.BackgroundFrame.KeyOverlay.Slots);
	HideAll(self.BackgroundFrame.KeyOverlay.Plugs);

	self:MarkDirty();

	FrameUtil.UnregisterFrameForEvents(self, AZERITE_EMPOWERED_FRAME_EVENTS);
	self:UnregisterEvent("PLAYER_SPECIALIZATION_CHANGED");
end

function AzeriteEmpoweredItemUIMixin:SetToItemAtLocation(itemLocation)
	self:Clear();
	self.azeriteItemDataSource:SetSourceFromItemLocation(itemLocation);
	self:OnItemSet();
end

function AzeriteEmpoweredItemUIMixin:SetToItemLink(itemLink)
	self:Clear();
	self.azeriteItemDataSource:SetSourceFromItemLink(itemLink);
	self:OnItemSet();
end

function AzeriteEmpoweredItemUIMixin:OnItemSet()
	if not self:IsItemValid() then
		HideUIPanel(self);
		return;
	end

	self.PreviewItemOverlayFrame:SetShown(self.azeriteItemDataSource:IsPreviewSource());

	self.BorderFrame.TitleText:SetText("");

	local azeriteEmpoweredItem = self.azeriteItemDataSource:GetItem();
	azeriteEmpoweredItem:LockItem();
	self.itemDataLoadedCancelFunc = azeriteEmpoweredItem:ContinueWithCancelOnItemLoad(function()
		SetPortraitToTexture(self.BorderFrame.portrait, azeriteEmpoweredItem:GetItemIcon());
		self.BorderFrame.TitleText:SetText(azeriteEmpoweredItem:GetItemName());
	end);

	FrameUtil.RegisterFrameForEvents(self, AZERITE_EMPOWERED_FRAME_EVENTS);
	self:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player");

	self:RebuildTiers();

	self:MarkDirty();
end

function AzeriteEmpoweredItemUIMixin:MarkDirty()
	self.dirty = true;
end

function AzeriteEmpoweredItemUIMixin:Refresh()
	if not self:IsItemValid() then
		HideUIPanel(self);
		return;
	end

	self:UpdateTiers();
end

function AzeriteEmpoweredItemUIMixin:UpdateTiers()
	local azeriteItemLocation = C_AzeriteItem.FindActiveAzeriteItem();
	local azeriteItemPowerLevel = azeriteItemLocation and C_AzeriteItem.GetPowerLevel(azeriteItemLocation) or 0;

	for tierIndex, tierFrame in ipairs(self.tiersByIndex) do
		tierFrame:Update(azeriteItemPowerLevel);
	end
end

function AzeriteEmpoweredItemUIMixin:AdjustSizeForTiers(numTiers)
	if numTiers == 3 then
		self.BackgroundFrame.KeyOverlay.Texture:SetAtlas("Azerite-CenterBG-3Ranks", true);
		self.BackgroundFrame.KeyOverlay.Texture:SetPoint("CENTER", 3, 125);
		self.BackgroundFrame.Bg:SetAtlas("Azerite-Background-3Ranks", true);
		
		self:SetSize(474, 484);
	else
		self.BackgroundFrame.KeyOverlay.Texture:SetAtlas("Azerite-CenterBG-4Ranks", true);
		self.BackgroundFrame.KeyOverlay.Texture:SetPoint("CENTER", 0, 187);
		self.BackgroundFrame.Bg:SetAtlas("Azerite-Background", true);
		self:SetSize(615, 628);
	end
	UpdateUIPanelPositions(self);

	self.transformTree:GetRoot():SetLocalPosition(CreateVector2D(self.BackgroundFrame:GetWidth() * .5, self.BackgroundFrame:GetHeight() * .5));
end

function AzeriteEmpoweredItemUIMixin:RebuildTiers()
	-- This list goes from the first selectable tier to the last (outer to inner ring)
	local allTierInfo = self.azeriteItemDataSource:GetAllTierInfo();
	local numTiers = #allTierInfo;

	self:AdjustSizeForTiers(numTiers);

	for tierIndex, tierInfo in ipairs(allTierInfo) do
		local tierFrame = self.tierPool:Acquire();
		table.insert(self.tiersByIndex, tierFrame);

		local tierArtIndex = tierIndex + (AZERITE_EMPOWERED_ITEM_MAX_TIERS - numTiers);
		local tierRingBackground = self.BackgroundFrame.RingBackgrounds[tierArtIndex];
		local tierRingBackgroundNode = nil;
		if tierRingBackground then
			tierRingBackground:Show();
			self.BackgroundFrame.GearBackgrounds[tierArtIndex]:Show();
			tierRingBackgroundNode = tierRingBackground.transformNode;
		end

		local tierGear = self.BackgroundFrame.Gears[tierArtIndex];
		local tierGearNode = nil;
		if tierGear then
			tierGear:Show();
			tierGearNode = tierGear.transformNode;
		end

		local tierRingGlow = self.BackgroundFrame.RingGlows[tierArtIndex];
		local tierPlug = self.BackgroundFrame.KeyOverlay.Plugs[tierArtIndex];
		local tierPlugBackground = self.BackgroundFrame.PlugBackgrounds[tierArtIndex];
		local tierSlot = self.BackgroundFrame.KeyOverlay.Slots[tierArtIndex];

		tierFrame:Reset();
		tierFrame:SetOwner(self, self.azeriteItemDataSource);
		tierFrame:SetVisuals(tierSlot, tierRingGlow, tierPlug, tierPlugBackground, tierRingBackgroundNode or self.transformTree:GetRoot(), tierGearNode);

		local prereqTier = self.tiersByIndex[tierIndex - 1];
		tierFrame:SetTierInfo(tierIndex, numTiers, tierInfo, prereqTier);
		tierFrame:CreatePowers(self.powerPool);

		local tierRingBorder = self.BackgroundFrame.RingBorders[tierArtIndex];
		if tierRingBorder then
			tierRingBorder:Show();
		end
	end
end