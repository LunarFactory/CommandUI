mods["ReturnsAPI-ReturnsAPI"].auto({
	namespace = "commandUI",
	mp = true,
})

local function log(msg)
	print("[CommandHelper] " .. tostring(msg))
end

Initialize.add_hotloadable(Callback.Priority.AFTER, function()
	log("Mod Initialized! Command Tooltips Active.")

	-- object_id 를 key로 하여 Item/Equipment wrapper를 빠르게 찾기 위한 캐시
	local object_to_wrapper = {}

	pcall(function()
		local class_item = gm.variable_global_get("class_item")
		if class_item then
			for id = 0, gm.array_length(class_item) - 1 do
				local wrapper = Item.wrap(id)
				if wrapper and wrapper.object_id then
					object_to_wrapper[wrapper.object_id] = wrapper
				end
			end
		end
	end)

	pcall(function()
		local class_equip = gm.variable_global_get("class_equipment")
		if class_equip then
			for id = 0, gm.array_length(class_equip) - 1 do
				local wrapper = Equipment.wrap(id)
				if wrapper and wrapper.object_id then
					object_to_wrapper[wrapper.object_id] = wrapper
				end
			end
		end
	end)

	local function command_ui_on_hud_draw(self, other, result, args)
		-- 알려진 바닐라 지휘 상자 ID (흰, 초, 빨, 보스, 장비)
		local test_ids = { 415, 416, 417, 418, 419 }
		pcall(function()
			table.insert(test_ids, gm.constants.oCustomObject_pInteractableCrate)
		end)
		pcall(function()
			table.insert(test_ids, gm.constants.oItemChestMulti)
		end)

		for _, obj_id in ipairs(test_ids) do
			local crates = {}
			if obj_id then
				pcall(function()
					crates = Instance.find_all(obj_id)
				end)
			end

			if type(crates) == "table" then
				for _, inst in ipairs(crates) do
					if inst and Instance.exists(inst) then
						-- inst.active 값이 1 이상일 때가 UI 창이 켜진 상태
						if inst.active and inst.active >= 1.0 then
							local sel_idx = inst.selection
							local contents = inst.contents

							if sel_idx and contents then
								local raw_id = nil
								pcall(function()
									raw_id = contents[sel_idx + 1]
									if raw_id == nil then
										raw_id = gm.array_get(contents, sel_idx)
									end
								end)

								if raw_id then
									local wrapper = object_to_wrapper[raw_id]

									if wrapper then
										-- 이름 및 설명 번역
										local name = "???"
										local desc = ""
										pcall(function()
											local t_name = gm.translate(wrapper.token_name)
											local t_desc = gm.translate(wrapper.token_text)
											if t_name then
												name = tostring(t_name)
											end
											if t_desc then
												desc = tostring(t_desc)
											end
										end)

										-- 등급 색상
										local color = 16777215 -- 기본 흰색
										pcall(function()
											local tier_wrap = ItemTier.wrap(wrapper.tier)
											if
												tier_wrap
												and type(tier_wrap) == "table"
												and tier_wrap.value ~= ItemTier.INVALID
											then
												local tr_color = tonumber(tier_wrap.pickup_color)
												if tr_color then
													color = tr_color
												end
											end
										end)

										-- 마우스 좌표 (gui)
										local tx = 0
										pcall(function()
											tx = math.floor(tonumber(gm.device_mouse_x_to_gui(0)) or 0) + 15
											ty = math.floor(tonumber(gm.device_mouse_y_to_gui(0)) or 0) + 15
										end)

										-- 텍스트 정렬 초기화 (다른 UI가 중앙 정렬로 바꿨을 수 있으므로 좌/상단 정렬 강제)
										pcall(function()
											gm.draw_set_halign(0) -- fa_left
											gm.draw_set_valign(0) -- fa_top
											-- Scribble 전용 정렬 초기화
											gm.scribble_set_box_align(0, 0)
										end)

										-- Scribble 캐싱 및 크기 계산
										local name_str = "<fa_left><fa_top><fntNormal>" .. tostring(name)
										local desc_str = "<fa_left><fa_top><fntNormal>" .. tostring(desc)

										local desc_width = 300
										local desc_height = 40
										pcall(function()
											-- For Scribble, width/height calculation is more complex with wrapping.
											-- For now, we'll use a fixed width for description and let Scribble handle newlines.
											-- If wrapping is needed, "[wrap,width]" tag can be added to desc_str.
											-- Assuming desc already contains newlines for formatting.
											desc_width = gm.scribble_get_width(desc_str)
											desc_height = gm.scribble_get_height(desc_str)
										end)

										local box_width = math.max(300, desc_width + 20)
										local box_height = 35 + desc_height + 10

										-- 마우스 위치 툴팁 배경 및 텍스트
										pcall(function()
											gm.draw_set_alpha(0.85)
											gm.draw_rectangle_colour(
												tx,
												ty,
												tx + box_width,
												ty + box_height,
												0,
												0,
												0,
												0,
												false
											)
											gm.draw_set_alpha(1.0)

											-- 아이템 이름 (Scribble)
											gm.scribble_set_starting_format("fntLarge", color, 1)
											gm.scribble_draw(tx + 10, ty + 10, name_str)

											-- 아이템 설명 (Scribble)
											gm.scribble_set_starting_format("fntNormal", 16777215, 1) -- White color for description
											gm.scribble_draw(tx + 10, ty + 35, desc_str)

											gm.scribble_reset()
										end)
									end
								end
							end
						end
					end
				end
			end
		end
	end

	Callback.add(Callback.ON_HUD_DRAW, command_ui_on_hud_draw)
end)

mods.on_all_mods_loaded(function()
	if Language and Language.register_autoload then
		Language.register_autoload(_ENV)
		if mods["Klehrik-Better_Crates"] then
			log("Klehrik-Better_Crates 모드가 감지되었습니다. 전용 번역을 덮어씌웁니다!")
		end
	end
end)
