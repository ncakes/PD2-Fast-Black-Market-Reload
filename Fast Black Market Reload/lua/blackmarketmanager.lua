_G[ModPath] = _G[ModPath] or {}
if _G[ModPath][RequiredScript] then return end
_G[ModPath][RequiredScript] = true

--If a weapon is modified, clear the crafted cache.
--We already handled the UI elements in BlackMarketGui, but OSA calls this function directly if it can't keep attachments.
Hooks:PreHook(BlackMarketManager, "modify_weapon", "FastBlackMarketReload-PreHook-BlackMarketManager:modify_weapon", function()
	local cache = _G.WeaponCraftingCache
	if cache then
		cache.bmm_crafted = nil
	end
end)

--Immediately invalidate cache.bmm_preview unless cache._old_preview_copy is set.
--Clear preview changes reference so a copy must be used.
--This function should only be called when a reset is actually necessary. Don't waste time validating if cache._old_preview_copy was not already set.
--OSA autoclear:
	--Calls this after attachment changes. Cache clear is necessary, OK.
	--Calls this after skin changes. Cache clear may not be necessary. BMG needs to set cache._old_preview_copy to defer validation.
Hooks:PreHook(BlackMarketManager, "clear_preview_blueprint", "FastBlackMarketReload-PreHook-BlackMarketManager:clear_preview_blueprint", function()
	local cache = _G.WeaponCraftingCache
	if cache and not cache._old_preview_copy then
		cache.bmm_preview = nil
	end
end)

--This function depends on both the crafted and preview blueprint as well as preview cosmetics.
--Put it in the use once cache and refresh it every run.
local orig_BlackMarketManager_is_previewing_any_mod = BlackMarketManager.is_previewing_any_mod
function BlackMarketManager:is_previewing_any_mod(...)
	local cache = _G.WeaponCraftingCache
	if cache and cache._reloading and cache._current_tab then
		cache.bmm_once = cache.bmm_once or {}
		if cache.bmm_once.is_previewing_any_mod == nil then
			cache.bmm_once.is_previewing_any_mod = orig_BlackMarketManager_is_previewing_any_mod(self, ...) or false
		end
		return cache.bmm_once.is_previewing_any_mod
	end

	return orig_BlackMarketManager_is_previewing_any_mod(self, ...)
end

--Optimized, turn blueprint into table.
local orig_BlackMarketManager_is_previewing_mod = BlackMarketManager.is_previewing_mod
function BlackMarketManager:is_previewing_mod(part_id, ...)
	local cache = _G.WeaponCraftingCache
	if cache and cache._reloading and cache._current_tab then
		cache.bmm_preview = cache.bmm_preview or {}
		if not cache.bmm_preview.is_previewing_mod then
			cache.bmm_preview.is_previewing_mod = {}
			local preview_blueprint = self:get_preview_blueprint(cache.category, cache.slot)
			for _, preview_part_id in ipairs(preview_blueprint) do
				cache.bmm_preview.is_previewing_mod[preview_part_id] = true
			end
		end
		return cache.bmm_preview.is_previewing_mod[part_id] or false
	end

	return orig_BlackMarketManager_is_previewing_mod(self, part_id, ...)
end

--Original function calls managers.weapon_factory:can_add_part which returns a part or nil.
--Do the same to be safe.
local orig_BlackMarketManager_preview_mod_forbidden = BlackMarketManager.preview_mod_forbidden
function BlackMarketManager:preview_mod_forbidden(category, slot, part_id, ...)
	local cache = _G.WeaponCraftingCache
	if cache and cache._reloading and cache._current_tab then
		cache.bmm_preview = cache.bmm_preview or {}
		cache.bmm_preview.preview_mod_forbidden = cache.bmm_preview.preview_mod_forbidden or {}

		if cache.bmm_preview.preview_mod_forbidden[part_id] == nil then
			cache.bmm_preview.preview_mod_forbidden[part_id] = orig_BlackMarketManager_preview_mod_forbidden(self, category, slot, part_id, ...) or false
		end
		return cache.bmm_preview.preview_mod_forbidden[part_id] or nil
	end

	return orig_BlackMarketManager_preview_mod_forbidden(self, category, slot, part_id, ...)
end

--Original function calls managers.weapon_factory:can_add_part which returns a part or nil.
--Do the same to be safe.
local orig_BlackMarketManager_can_modify_weapon = BlackMarketManager.can_modify_weapon
function BlackMarketManager:can_modify_weapon(category, slot, part_id, ...)
	local cache = _G.WeaponCraftingCache
	if cache and cache._reloading and cache._current_tab then
		cache.bmm_crafted = cache.bmm_crafted or {}
		cache.bmm_crafted.can_modify_weapon = cache.bmm_crafted.can_modify_weapon or {}

		if cache.bmm_crafted.can_modify_weapon[part_id] == nil then
			cache.bmm_crafted.can_modify_weapon[part_id] = orig_BlackMarketManager_can_modify_weapon(self, category, slot, part_id, ...) or false
		end
		return cache.bmm_crafted.can_modify_weapon[part_id] or nil
	end

	return orig_BlackMarketManager_can_modify_weapon(self, category, slot, part_id, ...)
end

--Returns two arguments. Both are guaranteed to be tables.
local orig_BlackMarketManager_get_modify_weapon_consequence = BlackMarketManager.get_modify_weapon_consequence
function BlackMarketManager:get_modify_weapon_consequence(category, slot, part_id, ...)
	local cache = _G.WeaponCraftingCache
	if cache and cache._reloading and cache._current_tab then
		cache.bmm_crafted = cache.bmm_crafted or {}
		cache.bmm_crafted.get_modify_weapon_consequence = cache.bmm_crafted.get_modify_weapon_consequence or {}
		if cache.bmm_crafted.get_modify_weapon_consequence[part_id] == nil then
			local replaces, removes = orig_BlackMarketManager_get_modify_weapon_consequence(self, category, slot, part_id, ...)
			cache.bmm_crafted.get_modify_weapon_consequence[part_id] = {
				replaces,
				removes
			}
		end
		local result = cache.bmm_crafted.get_modify_weapon_consequence[part_id]
		return result[1], result[2]
	end

	return orig_BlackMarketManager_get_modify_weapon_consequence(self, category, slot, part_id, ...)
end

local orig_BlackMarketManager_get_weapon_stats_with_mod = BlackMarketManager.get_weapon_stats_with_mod
function BlackMarketManager:get_weapon_stats_with_mod(category, slot, part_id, ...)
	local cache = _G.WeaponCraftingCache
	if cache and cache._reloading and cache._current_tab then
		cache.bmm_crafted = cache.bmm_crafted or {}
		cache.bmm_crafted.get_weapon_stats_with_mod = cache.bmm_crafted.get_weapon_stats_with_mod or {}
		cache.bmm_crafted.get_weapon_stats_with_mod[part_id] = cache.bmm_crafted.get_weapon_stats_with_mod[part_id] or orig_BlackMarketManager_get_weapon_stats_with_mod(self, category, slot, part_id, ...)
		return cache.bmm_crafted.get_weapon_stats_with_mod[part_id]
	end

	return orig_BlackMarketManager_get_weapon_stats_with_mod(self, category, slot, part_id, ...)
end

--Blueprint is a reference to tweak_data.blackmarket.weapon_skins[cosmetic_id].blueprint
--Does not include special blueprint.
local orig_BlackMarketManager_get_weapon_stats = BlackMarketManager.get_weapon_stats
function BlackMarketManager:get_weapon_stats(category, slot, blueprint, ...)
	local cache = _G.WeaponCraftingCache
	if cache and cache._reloading and cache._current_tab == "weapon_cosmetics" then
		cache.bmm_cosmetics = cache.bmm_cosmetics or {}
		cache.bmm_cosmetics.get_weapon_stats = cache.bmm_cosmetics.get_weapon_stats or {}
		cache.bmm_cosmetics.get_weapon_stats[blueprint] = cache.bmm_cosmetics.get_weapon_stats[blueprint] or orig_BlackMarketManager_get_weapon_stats(self, category, slot, blueprint, ...)
		return cache.bmm_cosmetics.get_weapon_stats[blueprint]
	end
	return orig_BlackMarketManager_get_weapon_stats(self, category, slot, blueprint, ...)
end
