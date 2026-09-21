_G[ModPath] = _G[ModPath] or {}
if _G[ModPath][RequiredScript] then return end
_G[ModPath][RequiredScript] = true

--Save crafted reference for validation.
--In vanilla, different reference means that attachments were changed when applying a skin.
--OSA v5.0.1 respects this.
local function save_old_crafted_ref(cache)
	local crafted = managers.blackmarket:get_crafted_category_slot(cache.category, cache.slot)
	cache._old_crafted_ref = crafted.blueprint
end

--Saving an old preview for validation.
--Base game must use a copy because the reference is always changed when previewing a skin.
--When clearing a preview, copy also need to be used because the reference changes.
--Only OSA can use a reference when previewing a skin.
local function save_old_preview(cache, use_ref)
	local blueprint = managers.blackmarket:get_preview_blueprint(cache.category, cache.slot)
	if not use_ref then
		cache._old_preview_copy = deep_clone(blueprint)
	else
		cache._old_preview_ref = blueprint
	end
end

--Strict verification, order matters.
--If a blueprint was modified at all it probably doesn't have the same order.
local function verify(old_bp, new_bp)
	for i, part_id in ipairs(old_bp) do
		if new_bp[i] ~= part_id then
			return false
		end
	end
	return #old_bp == #new_bp
end

Hooks:PreHook(BlackMarketGui, "_setup", "FastBlackMarketReload-PreHook-BlackMarketGui:_setup", function(self, is_start_page, component_data)
	local node = self._node
	local node_name = node and node._parameters and node._parameters.name
	if node_name ~= "blackmarket_crafting_node" then
		return
	end

	local prev_node_data = component_data and component_data.prev_node_data
	local category = prev_node_data and prev_node_data.category
	if category ~= "primaries" and category ~= "secondaries" then
		return
	end
	local slot = prev_node_data and prev_node_data.slot
	if not slot then
		return
	end

	local crafted = managers.blackmarket:get_crafted_category_slot(category, slot)
	if not crafted then
		return
	end

	local cache = _G.WeaponCraftingCache
	if cache and (cache.category ~= category or cache.slot ~= slot) then
		log("FastBlackMarketReload: bad cache.")
		_G.WeaponCraftingCache = nil
		cache = nil
	end

	if cache then
		--Always clear these
		cache.bmm_once = nil

		--Invalidate crafted cache if crafted reference changed.
		--Reference change means parts change in vanilla. OSA v5.0.1 complies.
		if cache._old_crafted_ref then
			if cache._old_crafted_ref ~= crafted.blueprint then
				cache.bmm_crafted = nil
			end
			cache._old_crafted_ref = nil
		end

		--Preview copy and reference are mutually exclusive.
		local preview_blueprint = managers.blackmarket:get_preview_blueprint(category, slot)
		--Copy is always used by base game.
		--Copy needs to be used if we want to verify after a BMM:clear_preview_blueprint.
		if cache._old_preview_copy then
			if not verify(cache._old_preview_copy, preview_blueprint) then
				cache.bmm_preview = nil
			end
			cache._old_preview_copy = nil
		end

		--Ref can only be used by OSA for previewing skins, because OSA only clears the skin blueprint if attachments are changed.
		if cache._old_preview_ref then
			if cache._old_preview_ref ~= preview_blueprint then
				cache.bmm_preview = nil
			end
			cache._old_preview_ref = nil
		end
	else
		cache = {
			category = category,
			slot = slot,
		}
	end

	cache._reloading = true
	_G.WeaponCraftingCache = cache
end)

Hooks:PreHook(BlackMarketGuiTabItem, "init", "FastBlackMarketReload-PreHook-BlackMarketGuiTabItem:init", function(self, main_panel, data, ...)
	local cache = _G.WeaponCraftingCache
	if not cache or not cache._reloading then
		return
	end

	cache._current_tab = data.name
end)

Hooks:PostHook(BlackMarketGuiTabItem, "init", "FastBlackMarketReload-PostHook-BlackMarketGuiTabItem:init", function(self, main_panel, data, ...)
	local cache = _G.WeaponCraftingCache
	if not cache or not cache._reloading then
		return
	end

	cache._current_tab = nil
end)

Hooks:PostHook(BlackMarketGui, "_setup", "FastBlackMarketReload-PostHook-BlackMarketGui:_setup", function(self, is_start_page, component_data)
	local node = self._node
	local node_name = node and node._parameters and node._parameters.name
	if node_name ~= "blackmarket_crafting_node" then
		return
	end

	local cache = _G.WeaponCraftingCache
	if cache then
		cache._reloading = false
	end
end)

--Equip/remove skins/colors
Hooks:PreHook(BlackMarketGui, "_equip_weapon_cosmetics_callback", "FastBlackMarketReload-PreHook-BlackMarketGui:_equip_weapon_cosmetics_callback", function()
	local cache = _G.WeaponCraftingCache
	if not cache then
		return
	end

	save_old_crafted_ref(cache)
	--OSA can clear previews when changing skins. Need to validate using a copy.
	if _G.OSA and OSA.settings and OSA.settings.auto_clear_preview then
		save_old_preview(cache, false)
	end
end)
Hooks:PreHook(BlackMarketGui, "_equip_weapon_color_callback", "FastBlackMarketReload-PreHook-BlackMarketGui:_equip_weapon_color_callback", function()
	local cache = _G.WeaponCraftingCache
	if not cache then
		return
	end

	save_old_crafted_ref(cache)
	if _G.OSA and OSA.settings and OSA.settings.auto_clear_preview then
		save_old_preview(cache, false)
	end
end)
Hooks:PreHook(BlackMarketGui, "_remove_weapon_cosmetics_callback", "FastBlackMarketReload-PreHook-BlackMarketGui:_remove_weapon_cosmetics_callback", function()
	local cache = _G.WeaponCraftingCache
	if not cache then
		return
	end

	save_old_crafted_ref(cache)
	if _G.OSA and OSA.settings and OSA.settings.auto_clear_preview then
		save_old_preview(cache, false)
	end
end)

--Preview/unpreview skins.
Hooks:PreHook(BlackMarketGui, "preview_cosmetic_on_weapon_callback", "FastBlackMarketReload-PreHook-BlackMarketGui:preview_cosmetic_on_weapon_callback", function()
	local cache = _G.WeaponCraftingCache
	if not cache then
		return
	end

	local use_ref = _G.OSA and true or false
	save_old_preview(cache, use_ref)
end)
--Okay so this button does nothing actually. It just makes you view your current weapon.
--The preview is not changed. If you later preview a part, the old skin shows up again.
--This button never shows up in OSA because we don't set last previewed cosmetic ID.
--[[
Hooks:PreHook(BlackMarketGui, "cancel_preview_cosmetic_on_weapon_callback", "FastBlackMarketReload-PreHook-BlackMarketGui:cancel_preview_cosmetic_on_weapon_callback", function()
	local cache = _G.WeaponCraftingCache
	if not cache then
		return
	end

	local use_ref = _G.OSA and true or false
	save_old_preview(cache, use_ref)
end)
]]

--Clear preview
Hooks:PreHook(BlackMarketGui, "clear_weapon_mod_preview_callback", "FastBlackMarketReload-PreHook-BlackMarketGui:clear_weapon_mod_preview_callback", function()
	local cache = _G.WeaponCraftingCache
	if not cache then
		return
	end

	--Must use a copy for validation when clearing preview.
	save_old_preview(cache, false)
end)

--Equip/remove mods
Hooks:PreHook(BlackMarketGui, "_buy_mod_callback", "FastBlackMarketReload-PreHook-BlackMarketGui:_buy_mod_callback", function()
	local cache = _G.WeaponCraftingCache
	if cache then
		cache.bmm_crafted = nil
	end
end)
Hooks:PreHook(BlackMarketGui, "_remove_mod_callback", "FastBlackMarketReload-PreHook-BlackMarketGui:_remove_mod_callback", function()
	local cache = _G.WeaponCraftingCache
	if cache then
		cache.bmm_crafted = nil
	end
end)

--Preview/unpreview mods
Hooks:PreHook(BlackMarketGui, "preview_weapon_with_mod_callback", "FastBlackMarketReload-PreHook-BlackMarketGui:preview_weapon_with_mod_callback", function()
	local cache = _G.WeaponCraftingCache
	if cache then
		cache.bmm_preview = nil
	end
end)
Hooks:PreHook(BlackMarketGui, "preview_weapon_without_mod_callback", "FastBlackMarketReload-PreHook-BlackMarketGui:preview_weapon_without_mod_callback", function()
	local cache = _G.WeaponCraftingCache
	if cache then
		cache.bmm_preview = nil
	end
end)

--Clear cache when leaving weapon customization UI.
--Note: this detection is not perfect. Also triggered when:
	--Opening weapon color customization.
	--Closing gadget customization.
	--Closing reticle customization.
Hooks:PreHook(BlackMarketGui, "close", "FastBlackMarketReload-PreHook-BlackMarketGui:close", function(self)
	local node = self._node
	local node_name = node and node._parameters and node._parameters.name
	if node_name ~= "blackmarket_crafting_node" then
		return
	end

	--Set this flag if cache should not be cleared.
	if _G.WeaponCraftingCache and WeaponCraftingCache._do_not_clear then
		WeaponCraftingCache._do_not_clear = nil
		return
	end

	_G.WeaponCraftingCache = nil
end)

--Entering weapon color customization.
Hooks:PreHook(BlackMarketGui, "open_customize_weapon_color_menu", "FastBlackMarketReload-PreHook-BlackMarketGui:open_customize_weapon_color_menu", function()
	if _G.WeaponCraftingCache then
		WeaponCraftingCache._do_not_clear = true
	end
end)

--Customize reticle.
Hooks:PreHook(BlackMarketGui, "open_reticle_switch_menu", "FastBlackMarketReload-PreHook-BlackMarketGui:open_reticle_switch_menu", function()
	if _G.WeaponCraftingCache then
		WeaponCraftingCache._do_not_clear = true
	end
end)

--Customize gadget.
Hooks:PreHook(BlackMarketGui, "open_customize_gadget_menu", "FastBlackMarketReload-PreHook-BlackMarketGui:open_customize_gadget_menu", function()
	if _G.WeaponCraftingCache then
		WeaponCraftingCache._do_not_clear = true
	end
end)
