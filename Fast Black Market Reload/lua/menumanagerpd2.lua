_G[ModPath] = _G[ModPath] or {}
if _G[ModPath][RequiredScript] then return end
_G[ModPath][RequiredScript] = true

--Clear cache when leaving weapon customization UI.
Hooks:PreHook(MenuCallbackHandler, "_left_blackmarket", "FastBlackMarketReload-PreHook-MenuCallbackHandler:_left_blackmarket", function()
	_G.WeaponCraftingCache = nil
end)
