function Localize()
	-- Put all locale specific string adjustments here
end

function LocalizeFrames()
	-- Put all locale specific UI adjustments here
	RealmCharactersSort:SetWidth(RealmCharactersSort:GetWidth() + 8);
	RealmLoadSort:SetWidth(RealmLoadSort:GetWidth() - 8);
end
