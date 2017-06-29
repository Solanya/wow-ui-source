UIPanelWindows["FlightMapFrame"] = { area = "center", pushable = 1, showFailedFunc = CloseTaxiMap, allowOtherPanels = 1 };

FlightMapMixin = {};

function FlightMapMixin:SetupTitle()
	self.BorderFrame.TitleText:SetText(FLIGHT_MAP);
	self.BorderFrame.Bg:SetColorTexture(0, 0, 0, 1);
	self.BorderFrame.Bg:SetParent(self);
	self.BorderFrame.TopTileStreaks:Hide();
	
	SetPortraitToTexture(self.BorderFrame.portrait, [[Interface/Icons/icon_petfamily_flying]]);
end

function FlightMapMixin:OnLoad()
	MapCanvasMixin.OnLoad(self);

	self:RegisterEvent("TAXIMAP_CLOSED");

	self:SetMaxZoom(.85);
	self:SetMinZoom(.275);

	self:SetupTitle();

	self:SetShouldZoomInOnClick(true);
	self:SetShouldPanOnClick(false);
	self:SetTransformFlag(Enum.MapTransform.IsForFlightMap, true);

	self:AddStandardDataProviders();
end

function FlightMapMixin:SetMapID(mapID)
	MapCanvasMixin.SetMapID(self, mapID);
	if self:ShouldShowSubzones() then
		self:AddSubZoneDataProviders();
	else
		self:RemoveSubZoneDataProviders();
	end
end

function FlightMapMixin:AddSubZoneDataProviders()
	if not self.zoneSummaryDataProvider then
		self.zoneSummaryDataProvider = CreateFromMixins(FlightMap_ZoneSummaryDataProvider);
		self:AddDataProvider(self.zoneSummaryDataProvider);
	end
end

function FlightMapMixin:RemoveSubZoneDataProviders()
	if self.zoneSummaryDataProvider then
		self:RemoveDataProvider(self.zoneSummaryDataProvider);
		self.zoneSummaryDataProvider = nil;
	end
end

function FlightMapMixin:AddStandardDataProviders()
	self:AddDataProvider(CreateFromMixins(FlightMap_FlightPathDataProviderMixin));
	self:AddDataProvider(CreateFromMixins(ActiveQuestDataProviderMixin));
	self:AddDataProvider(CreateFromMixins(GroupMembersDataProviderMixin));
	self:AddDataProvider(CreateFromMixins(ClickToZoomDataProviderMixin));
	self:AddDataProvider(CreateFromMixins(ZoneLabelDataProviderMixin));
	
	local worldQuestDataProvider = CreateFromMixins(WorldQuestDataProviderMixin);
	worldQuestDataProvider:SetMatchWorldMapFilters(true);
	self:AddDataProvider(worldQuestDataProvider);
end

function FlightMapMixin:OnShow()
	local continentID = GetTaxiMapID();
	-- This is 'temporarily' hardcoded for Argus. There's a maintenance task in that should include fixing this.
	self:SetShouldShowSubzones(continentID ~= 1184); 
	self:SetMapID(continentID);

	self:ZoomOut();

	MapCanvasMixin.OnShow(self);
end

function FlightMapMixin:OnHide()
	CloseTaxiMap();

	MapCanvasMixin.OnHide(self);
end

function FlightMapMixin:OnEvent(event, ...)
	if event == "TAXIMAP_CLOSED" then
		HideUIPanel(self);
	end

	MapCanvasMixin.OnEvent(self, event, ...);
end
