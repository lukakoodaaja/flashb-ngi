local IsWeakEffectSoundThreadWorking = false

Citizen.CreateThread(function()
	if IsWeaponValid(`WEAPON_FLASHBANG`) then
		AddTextEntry("WT_GNADE_FLSH", Config.WeaponLabel)

		while true do
			local playerPed = PlayerPedId()
			local weapon = GetSelectedPedWeapon(playerPed)
			if weapon == `WEAPON_FLASHBANG` then
				if IsPedShooting(playerPed) then
					local playerPos = GetEntityCoords(playerPed)
					Citizen.CreateThread(function()
						local handle = GetClosestObjectOfType(playerPos.x, playerPos.y, playerPos.z, 10.0, `w_ex_flashbang`, false, false, false)
				
						Citizen.Wait(Config.ExplodeTime)
						
						if DoesEntityExist(handle) then
							local coords = GetEntityCoords(handle)
							SetEntityAsMissionEntity(handle, false, true)
							DeleteEntity(handle)
							AddExplosion(coords.x, coords.y, coords.z, 24, 0.0, true, false, true)
							AddExplosion(coords.x, coords.y, coords.z, 2, 0.0, true, false, true)
							TriggerServerEvent("mmflashbang:Particles", coords)
						end
					end)
				end
			else
				Citizen.Wait(300)
			end
	
			Citizen.Wait(0)
		end
	end
end)

RegisterNetEvent("mmflashbang:Particles", function(pos)
	local playerPed = PlayerPedId()
	local playerCoords = GetEntityCoords(playerPed)

	local type = CanGetFlashed(pos, playerPed, playerCoords)

	if #(playerCoords - pos) < Config.ExplosionEffectVisibilityRange then
		if type == "noeffect" then
			ShakeGameplayCam('MEDIUM_EXPLOSION_SHAKE', 0.2)
		elseif type == "weakeffect" then
			ShakeGameplayCam('MEDIUM_EXPLOSION_SHAKE', 1.0)
			ShakeGameplayCam('DRUNK_SHAKE', 1.0)
			AnimpostfxPlay("Dont_tazeme_bro", 0, false)

			Citizen.CreateThread(function()
				IsWeakEffectSoundThreadWorking = true
				SendNUIMessage({ type = 'play', file = "flashbang", volume = (Config.WeakEffectSoundVolume - (#(GetEntityCoords(playerPed) - pos) * 0.07)) })

				local init = GetGameTimer()
				local s = Config.WeakEffectSoundVolume
				while GetGameTimer() - init < Config.WeakEffectSoundDuration and IsWeakEffectSoundThreadWorking do
					local a  = #(GetEntityCoords(playerPed) - pos)
					local sa = s - (a * 0.07)
					if sa < 0.0 then
						sa = 0.0
					end
				
					SendNUIMessage({ type = 'volume', volume = sa })
					Citizen.Wait(50)
				end
				if IsWeakEffectSoundThreadWorking then
					SendNUIMessage({ type = 'stop' })
				end
			end)

			Citizen.CreateThread(function()
				Citizen.Wait(Config.WeakEffectDuration)
				AnimpostfxStop("Dont_tazeme_bro")
				Citizen.Wait(Config.AfterExplosionCameraReturnDuration)
				StopGameplayCamShaking(false)
			end)
		elseif type == "flash" then
			IsWeakEffectSoundThreadWorking = false
			ShakeGameplayCam('MEDIUM_EXPLOSION_SHAKE', 1.0)
			ShakeGameplayCam('DRUNK_SHAKE', 3.0)
			AnimpostfxPlay("Dont_tazeme_bro", 0, false)
			SendNUIMessage({ type = 'play', file = "flashbang", volume = Config.FlashEffectSoundVolume  })
			SendNUIMessage({ volume = Config.FlashEffectSoundVolume  })
			SetPedToRagdoll(playerPed, Config.FlashEffectWhiteScreenDuration, Config.FlashEffectWhiteScreenDuration, 0, true, true, false)

			if Config.CanCutOutMumble then
				CutOutMumble(Config.MumbleCutOutDuration)
			end

			Citizen.CreateThread(function()
				local init = GetGameTimer()

				while GetGameTimer() - init < Config.FlashEffectWhiteScreenDuration do
					DrawRect(0.0,0.0, 10.0, 10.0, 255, 255, 255, 255)
					Citizen.Wait(0)
				end

				PlayAnim(playerPed, "anim@heists@ornate_bank@thermal_charge", "cover_eyes_intro", 54, Config.FlashEffectDuration)

				local alpha = 255
				init = GetGameTimer()
				local init2 = init
				while alpha ~= 0 do
					local t = GetGameTimer()
					DrawRect(0.0,0.0, 10.0, 10.0, 255, 255, 255, alpha)

					if alpha > 220 then
						if t - init2 > 300 then
							init2 = t
							alpha = alpha - 1
						end
					elseif alpha >= 100 then
						if t - init2 > 180 then
							init2 = t
							alpha = alpha - 1
						end
					else
						if t - init2 >= 80 then
							init2 = t
							alpha = alpha - 1
						end
					end
					Citizen.Wait(0)
				end
			end)

			Citizen.CreateThread(function()
				local init = GetGameTimer()
				local player_ = PlayerId()
				SetPedCanSwitchWeapon(playerPed, false)
				while GetGameTimer() - init < Config.FlashEffectDuration do
					DisablePlayerFiring(player_, true)
					Citizen.Wait(0)
				end
				SetPedCanSwitchWeapon(playerPed, true)
				AnimpostfxStop("Dont_tazeme_bro")
				Citizen.Wait(Config.AfterExplosionCameraReturnDuration)
				StopGameplayCamShaking(false)
			end)
		end
   
		RequestNamedPtfxAsset("core");
		while not HasNamedPtfxAssetLoaded("core") do
			Citizen.Wait(0)
		end
		UseParticleFxAssetNextCall("core")
		StartParticleFxLoopedAtCoord("ent_anim_paparazzi_flash", pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 25.0, false, false, false, false)
	end
end)

function CanGetFlashed(pos, playerped, playerCoords)
	local raycast = StartExpensiveSynchronousShapeTestLosProbe(pos.x, pos.y, pos.z, playerCoords.x, playerCoords.y, playerCoords.z, -1, 0, 4)
	local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(raycast)
	
	if entityHit == playerped then
		local frontCoords = GetOffsetFromEntityInWorldCoords(playerped, 0.0, 0.5, 0.0)
		local backCoords = GetOffsetFromEntityInWorldCoords(playerped, 0.0, -0.5, 0.0)

		local frontDist = #(pos - frontCoords)
		local backDist = #(pos - backCoords)
		local playerOrientation = "front"
		
		if frontDist > backDist then
			playerOrientation = "behind"
		end

		local dist = #(pos - playerCoords)

		if dist > Config.WeakEffectRange.farthest then
			return "noeffect"
		end

		if (dist > Config.WeakEffectRange.nearest and dist <= Config.WeakEffectRange.farthest) and playerOrientation == "front" then
			return "weakeffect"
		end

		if dist < Config.FlashEffectBehindPlayerRange and playerOrientation == "behind" then
			return "flash"
		end

		if dist < Config.FlashEffectInFrontOfPlayerRange and playerOrientation == "front" then
			return "flash"
		end
		
		if dist < Config.FlashEffectInFrontOfPlayerRange and playerOrientation == "behind" then
			return "weakeffect"
		end
	end
	return "noeffect"
end

function PlayAnim(ped, dict, name, flag, time)
	Citizen.CreateThread(function()
		ClearPedTasks(ped)
		ClearPedTasksImmediately(ped)
		SetCurrentPedWeapon(ped, `weapon_unarmed`, true)
		Citizen.Wait(0)

		local init = GetGameTimer()
		RequestAnimDict(dict)
	
		while not HasAnimDictLoaded(dict) and GetGameTimer() - init < 30 do
			Citizen.Wait(0)
		end
		
		TaskPlayAnim(ped, dict, name, 8.0, 8.0, time, flag, 1.0, false, false, false)	

		Citizen.CreateThread(function()
			local init = GetGameTimer()
			while GetGameTimer() - init < time do
				if not IsEntityPlayingAnim(ped, dict, name, 3) then
					TaskPlayAnim(ped, dict, name, 8.0, 8.0, time, flag, 1.0, false, false, false)	
				end
				Citizen.Wait(100)
			end
		end)
	end)
end

function CutOutMumble(time)
	local players = GetActivePlayers()
	local init = GetGameTimer()
	Citizen.CreateThread(function()
		while GetGameTimer() - init < time do
			for k,v in ipairs(players) do
				MumbleSetVolumeOverride(v, 0.0)
			end
			Citizen.Wait(300)
		end
		for k,v in ipairs(players) do
			MumbleSetVolumeOverride(v, -1.0)
		end
	end)
end

RegisterCommand("flashbang", function()
	GiveWeaponToPed(PlayerPedId(), `WEAPON_FLASHBANG`, 10, false, true)
end, false)