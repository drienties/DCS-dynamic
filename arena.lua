package.path  = package.path..";"..lfs.currentdir().."/LuaSocket/?.lua"
package.cpath = package.cpath..";"..lfs.currentdir().."/LuaSocket/?.dll"

--type of Air defence units
AD_types = {
 'RED SAM',
 'RED EW'
 } 
 
critical_units = {
 'SR -',
 'TR -',
 'STR -'
}
critical_statics = {
 'Ammunition depot',
 'Comms tower'
}

markerlist = {}

markerPrefixes = {
 'Critical Target:',
 'Secondary Target:',
 'Recced Unit:'
}

EWRZones = {
 'Firefly',
  'Manis',
  'Pinpoint'
}

reconUnits = {}
reccelist = {}
reccedUnits = {}
cargoList = {}
GroupMenu = {}

--Sets
local SetClients = SET_CLIENT:New():FilterCoalitions( "blue" ):FilterActive():FilterStart()

local SetCriticalRedUnits = SET_UNIT:New():FilterCoalitions( "red" ):FilterCategories("ground"):FilterPrefixes(critical_units):FilterActive():FilterStart()
local SetCriticalRedStatics = SET_STATIC:New():FilterCoalitions( "red" ):FilterPrefixes(critical_statics):FilterStart()

local SetRedUnits = SET_UNIT:New():FilterCoalitions( "red" ):FilterCategories("ground"):FilterActive():FilterStart()
local SetRedStatics = SET_STATIC:New():FilterCoalitions( "red" ):FilterStart()

local SetBlueUnits = SET_UNIT:New():FilterCoalitions( "blue" ):FilterActive():FilterStart()

local SetPowerPlants = SET_STATIC:New():FilterCoalitions( "red" ):FilterPrefixes( "Powerplant" ):FilterStart()
local SetZones = SET_ZONE:New():FilterPrefixes( "capturezone-" ):FilterStart()

mission_id = "ArenaV5"
sortie_id = os.date("%x")

--handlers
EventHandler1 = EVENTHANDLER:New():HandleEvent( EVENTS.Kill )
EventHandler2 = EVENTHANDLER:New():HandleEvent( EVENTS.PlayerEnterAircraft )
EventHandler3 = EVENTHANDLER:New():HandleEvent( EVENTS.Land )
EventHandler4 = EVENTHANDLER:New():HandleEvent( EVENTS.Ejection )
EventHandler5 = EVENTHANDLER:New():HandleEvent( EVENTS.PilotDead )
EventHandler6 = EVENTHANDLER:New():HandleEvent( EVENTS.Hit )
EventHandler7 = EVENTHANDLER:New():HandleEvent( EVENTS.BDA )
EventHandler8 = EVENTHANDLER:New():HandleEvent( EVENTS.MarkAdded )
EventHandler9 = EVENTHANDLER:New():HandleEvent( EVENTS.Crash )
EventHandler10 = EVENTHANDLER:New():HandleEvent( EVENTS.Takeoff )

--check if list has value
function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

--check if table has key
function tableHasKey(table,key)
    return table[key] ~= nil
end

--check if value is numeric
function isNumeric(value)
	if value == tostring(tonumber(value)) then
		return true
	else
		return false
	end
end

--check if there are enemies in zones
function splitValue(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function enemies_in_zone(zone)
	local TestZone = ZONE:FindByName(zone)
	local zoneCriticalUnits = false
	local zoneCriticalStatics = false
	local zoneNonCriticalUnits = false
	local zoneNonCriticalStatics = false
	
	SetCriticalRedUnits:ForEachUnit( function( unit )  -- Tests set for dead unit.
                        if unit:IsInZone(TestZone) then
							--
							zoneCriticalUnits = true
						else
							--
						end
                      end )	
	SetCriticalRedStatics:ForEachStatic( function( static )  -- Tests set for dead static.
                        if static:IsInZone(TestZone) then
							--
							zoneCriticalStatics = true
						else
							--
						end
                      end )	
	SetRedUnits:ForEachUnit( function( unit )  -- Tests set for dead unit.
                        if unit:IsInZone(TestZone) then
							--
							zoneNonCriticalUnits = true
						else
							--
						end
                      end )	
	SetRedStatics:ForEachStatic( function( static )  -- Tests set for dead unit.
                        if static:IsInZone(TestZone) then
							--
							zoneNonCriticalStatics = true
						else
							--
						end
                      end )	
	TestZone:UndrawZone()	
	
	if zoneCriticalUnits == true or zoneCriticalStatics == true then
		zoneCritical = true
	else
		zoneCritical = false
	end
	
	if zoneNonCriticalUnits == true or zoneNonCriticalStatics == true then
		zoneNonCritical = true
	else
		zoneNonCritical = false
	end
	
	
	if zoneCritical == true then
		TestZone:DrawZone(-1, {1,0,0}, 1, {1,0,0}, 0, 1, true)
	elseif zoneNonCritical == true then
		TestZone:DrawZone(-1, {1,1,0}, 1, {1,1,0}, 0, 1, true)
	else
		TestZone:DrawZone(-1, {0,1,0}, 1, {0,1,0}, 0, 1, true)
		
	end
end

function check_zones()
	SetZones:ForEachZone( function( zone )
					enemies_in_zone(zone:GetName())
				end )
end

--send data to DB
function sendData(_querytype, _var1, _var2, _var3, _var4, _var5, _var6, _var7, _var8)
  MySocket = socket.try(socket.connect(IPAddress, Port))
  MySocket:setoption("tcp-nodelay",true)   
 
 if _querytype == "unitDead" then
	socket.try(MySocket:send(string.format(_querytype .. "," .. _var1 .. "," ..  _var2 .. "," .. _var3 .. "," .. _var4 .. ",")))
  elseif _querytype == "unitKill" then
	socket.try(MySocket:send(string.format(_querytype .. "," .. _var1 .. "," ..  _var2 .. "," .. _var3 .. "," .. _var4 .. "," .. _var5 .. "," .. _var6 .. ",")))
  elseif _querytype == "unitBirthDeath" then
	socket.try(MySocket:send(string.format(_querytype .. "," .. _var1 .. "," ..  _var2 .. "," .. _var3 .. "," .. _var4 .. "," .. _var5 .. ",")))
  elseif _querytype == "unitRecced" then
	socket.try(MySocket:send(string.format(_querytype .. "," .. _var1 .. "," ..  _var2 .. "," .. _var3 .. "," .. _var4 .. ",")))
  elseif _querytype == "unitReccedExtended" then
    socket.try(MySocket:send(string.format(_querytype .. "," .. _var1 .. "," ..  _var2 .. "," .. _var3 .. "," .. _var4 .. "," .. _var5 .. "," .. _var6 .. "," .. _var7 .. "," .. _var8 .. ",")))
  end
  MySocket:close()
end

function markReccedUnit(unit, client)
	local UnitToMark
	if UNIT:FindByName(unit) ~= nil then
		if UNIT:FindByName(unit):IsAlive() == true then
			UnitToMark = UNIT:FindByName(unit)
			env.info("unit alive?" )
			local mymarker=MARKER:New(UnitToMark:GetCoordinate(), "Recced Unit: "..UnitToMark:GetTypeName()  .. "\nDetected by: "..client .. "\n".. UnitToMark:GetCoordinate():ToStringLLDDM() .."\n".. UnitToMark:GetCoordinate():ToStringMGRS().."\nAltitude\(ft\): "..math.floor(UTILS.MetersToFeet(UnitToMark:GetAltitude())).." QFE\(mb\): "..math.floor(UnitToMark:GetCoordinate():GetPressure(UnitToMark:GetAltitude(FromGround)))):ReadOnly():ToAll()
		end
	else
		if STATIC:FindByName(unit):IsAlive() == true then
			UnitToMark = STATIC:FindByName(unit)
			env.info("unit alive?" )
			local mymarker=MARKER:New(UnitToMark:GetCoordinate(), "Recced Unit: "..UnitToMark:GetTypeName()  .. "\nDetected by: "..client .. "\n".. UnitToMark:GetCoordinate():ToStringLLDDM() .."\n".. UnitToMark:GetCoordinate():ToStringMGRS().."\nAltitude\(ft\): "..math.floor(UTILS.MetersToFeet(UnitToMark:GetAltitude())).." QFE\(mb\): "..math.floor(UnitToMark:GetCoordinate():GetPressure(UnitToMark:GetAltitude(FromGround)))):ReadOnly():ToAll()
		end
	end	
	
	table.insert(reccedUnits, unit)
end

function EventHandler1:OnEventKill( EventData )
	if EventData.IniGroupName == nill then
		env.info("responsible Player dead, unable to log event")
	else
		if EventData.IniPlayerName == nil then
			--AI killed something, no logging required
		else
			if EventData.weapon_name == nil then 
				weapon = "Unknown"
			else		
				weapon = EventData.weapon_name
			end
			
			initiator = EventData.IniPlayerName
			
			if EventData.TgtPlayerName == nil then 
				
				target = EventData.target:getName()
				env.info("test1: "..target)
			else
				
				target = EventData.TgtPlayerName
				env.info("test2: "..target)
			end
			
			target_unit_type = EventData.TgtObjectCategory
			unittype = EventData.TgtTypeName
			
			targetVehicleType = "Unknown"	
			
			env.info("storing dead unit/static( "..targetVehicleType.."): ".. target .. "killed with: ".. weapon .. " by player: ".. initiator)
			
			sendData("unitDead", mission_id, sortie_id, target, target_unit_type)
			sendData("unitKill", mission_id, sortie_id, target, target_unit_type, initiator, weapon)
		end
	end
end

function EventHandler2:OnEventPlayerEnterAircraft( EventData )
	if EventData.IniPlayerName == nil then 
			--AI birth, not interresting
	else	
			local EventInitiator = EventData.IniPlayerName
			local EventType = "Birth"
			local EventVehicle = EventData.IniTypeName
			local UnitName = EventData.IniDCSUnitName
			local EventVehicleObject = UNIT:FindByName(UnitName)
			
			env.info("storing Player birth: ".. EventInitiator .. " Spawned in: ".. EventVehicle)
			sendData("unitBirthDeath", mission_id, sortie_id, EventType, EventInitiator, EventVehicle)
			
			--check if helicopter
			if EventVehicleObject:IsHelicopter() == true then
				env.info(EventInitiator .. " Spawned in a Helo!")
				local MessageAll = MESSAGE:New(EventInitiator .. " Spawned in a Helo!",  60):ToAll()
				
				
				local Client_Unit = CLIENT:FindByName(UnitName)
				local ClientGroup = GROUP:FindByName(Client_Unit:GetClientGroupName())
				GroupMenu[ClientGroup:GetName()] = MENU_GROUP:New( ClientGroup, "Cargo Menu" )
				MENU_GROUP_COMMAND:New( ClientGroup, "Load EWR", GroupMenu[ClientGroup:GetName()], LoadEWR, Client_Unit )				
				MENU_GROUP_COMMAND:New( ClientGroup, "Unload EWR", GroupMenu[ClientGroup:GetName()], UnloadEWR, Client_Unit )				
			end
			
			
			--clear previous recon
			local UnitName = EventData.IniDCSUnitName
			env.info("clearing previuous Recon stats for ".. UnitName)
			
			for k, v in ipairs(reconUnits) do
				env.info("current unit to check for cleanup: ".. v)
				if v == UnitName then
					env.info(UnitName.. " matches, removing")
					table.remove(reconUnits, k)
				end
			end
			
			for k, v in pairs(reccelist) do
				env.info("current unit to check for cleanup: ".. k)
				if k == UnitName then
					env.info(UnitName.. " matches, removing")
					reccelist[k] = nil
				end
			end
			
	end
end

function EventHandler3:OnEventLand( EventData )
	if EventData.IniPlayerName ~= nil then
		
		local UnitName = EventData.IniDCSUnitName
		local location = AIRBASE:FindByName(EventData.PlaceName)
		local locationCoalition = location:GetCoalitionName()
		
		if locationCoalition == "Blue" then
		--clear previous recon
			env.info("clearing previuous Recon stats for ".. UnitName)
			
			--remove from recon schedule
			for k, v in pairs(reconUnits) do
				if v == UnitName then
					reconUnits[k] = nil
				end
			end
			
			
			for k, v in pairs(reccelist) do
				------------------------------------
				--check to only turn in own units---
				------------------------------------
				if k == UnitName then
					local newReconCount = 0
					for k2, v2 in pairs(v) do
						if has_value(reccedUnits, v2) == false then
							newReconCount = newReconCount + 1
							local ClientName = CLIENT:FindByName(UnitName):GetPlayerName()
							---------------------------
							--mark units
							---------------------------
							markReccedUnit(v2, ClientName)
							
							
							---------------------------
							--add to DB for persistence
							---------------------------
							if UNIT:FindByName(v2) ~= nil then
								if UNIT:FindByName(v2):IsAlive() == true then
									UnitToMark = UNIT:FindByName(v2)
									env.info("Alive unit, Set UnitToMark to UNIT")
								else
									env.info("unit not alive, no point in marking")
								end
							else
								if STATIC:FindByName(v2):IsAlive() == true then
									UnitToMark = STATIC:FindByName(v2)
									env.info("Alive unit, Set UnitToMark to STATIC")
								else
									env.info("static not alive, no point in marking")
								end
							end
							
							local unitType = UnitToMark:GetTypeName()
							local llDMS = UnitToMark:GetCoordinate():ToStringLLDMS()
							local latlonRAW = llDMS:gsub("%LL DMS ", "")
							local latlontable = {}		
							local lattable = {}
							local lontable = {}
							--spit Lat from Lon
							for w in latlonRAW:gmatch("([^ ]+)") do
								table.insert(latlontable, w)
							end
							
							--split lat digits
							for w in latlontable[1]:gmatch("(%d+)") do
								table.insert(lattable, w)
							end
							local lat_1 = lattable[1]
							local lat_2 = ((lattable[2] + (tonumber(lattable[3].."."..lattable[4])/60))/60)
							local lat = lat_1 + lat_2

							--split lon digits
							for w in latlontable[2]:gmatch("(%d+)") do
								table.insert(lontable, w)
							end
							local lon_1 = lontable[1]
							local lon_2 = ((lontable[2] + (tonumber(lontable[3].."."..lontable[4])/60))/60)
							local lon = lon_1 + lon_2
							
							local alt = UnitToMark:GetAltitude()
							env.info("lat: "..lat)
							env.info("lon: "..lon)
							env.info("alt: "..alt)
							
							
							sendData("unitReccedExtended", mission_id, sortie_id, v2, ClientName, lat, lon, alt, unitType)
							table.insert(reccedUnits, v2)
						else
							env.info(v2.." already recced earlier")
						end
					end
					if newReconCount > 0 then
						local MessageAll = MESSAGE:New(CLIENT:FindByName(UnitName):GetPlayerName() .." is turning in intel about new targets",  60):ToAll()
					else
						local MessageAll = MESSAGE:New(CLIENT:FindByName(UnitName):GetPlayerName() .." found no new targets",  60):ToAll()
					end
				end
			end
		
		
			--cleanup radio menu
			local Client_Unit = CLIENT:FindByName(UnitName)
			local ClientGroup = GROUP:FindByName(Client_Unit.ClientGroupName)
			GroupMenu[ClientGroup:GetName()]:Remove()
		
		
			--cleanup reccelist
			for k, v in pairs(reccelist) do
				env.info("current unit to check for cleanup: ".. k)
				if k == UnitName then
					env.info(UnitName.. " matches, removing")
					reccelist[k] = nil
				end
			end
		end
	end
end

function EventHandler4:OnEventEjection( EventData )
	if EventData.IniPlayerName == nil then 
			--AI Death, not interresting
	else	
			local EventInitiator = EventData.IniPlayerName
			local EventType = "Ejection"
			local EventVehicle = EventData.IniTypeName
			env.info("storing Player Ejection: ".. EventInitiator .. " ejected from: ".. EventVehicle)
			sendData("unitBirthDeath", mission_id, sortie_id, EventType, EventInitiator, EventVehicle)
	end
end

function EventHandler5:OnEventPilotDead( EventData )
	if EventData.IniPlayerName == nil then 
			--AI Death, not interresting
	else	
			local EventInitiator = EventData.IniPlayerName
			local EventType = "Death"
			local EventVehicle = EventData.IniTypeName
			env.info("storing Player Death: ".. EventInitiator .. " Died in: ".. EventVehicle)
			sendData("unitBirthDeath", mission_id, sortie_id, EventType, EventInitiator, EventVehicle)
	end
end

function EventHandler8:OnEventMarkAdded(EventData)
	for index, value in pairs(markerPrefixes) do
		if string.find(EventData.MarkText, value) then
			env.info("adding marker: "..EventData.MarkID.." to list")
			table.insert(markerlist, EventData.MarkID)
		end
	end

end

function EventHandler9:OnEventCrash( EventData )
	if EventData.IniPlayerName == nil then 
			--AI Death, not interresting
	else	
			local EventInitiator = EventData.IniPlayerName
			local EventType = "Crash"
			local EventVehicle = EventData.IniTypeName
			env.info("storing Player Crash: ".. EventInitiator .. " Crashed: ".. EventVehicle)
			sendData("unitBirthDeath", mission_id, sortie_id, EventType, EventInitiator, EventVehicle)
	end
end

function EventHandler10:OnEventTakeoff( EventData )
	if EventData.IniPlayerName == nil then 
			--AI Takeoff, not interresting
	else	
			local UnitName = EventData.IniDCSUnitName
			ValidateReconLoadout(UnitName)
	end
end



--function to destroy units
function destroyUnit(unit)
	env.info("request received to destroy: ".. unit)
	if UNIT:FindByName(unit) == nil then
		--assume static
		if isNumeric(unit) == true then
			env.info("static not found, probably a map asset: " .. unit)
		else
			env.info("Assuming STATIC")
			unitToBeKilled = STATIC:FindByName(unit)
			unitToBeKilled:Destroy( false )
		end
	else
		env.info("Assuming UNIT")
		unitToBeKilled = UNIT:FindByName(unit)
        unitToBeKilled:Destroy( false )
	end
end

--Retrieve Dead units from DB
function getDestroyedUnits(_mission)
  MySocket = socket.try(socket.connect(IPAddress, Port))
  MySocket:setoption("tcp-nodelay",true)  
  MySocket:settimeout(1)
  socket.try(MySocket:send(string.format("getDestroyedUnits," .. _mission .. ",")))
  local s, status, result = MySocket:receive()
  MySocket:close()
  
  result = result:sub(1, -2)
  for token in string.gmatch(result, "[^;]+") do  
    env.info("sending request to destroy: ".. token)
	
	if pcall(destroyUnit, token) then
		env.info("Successfully destroyed: ".. token)
	else
		env.info("Failed to destroy: ".. token)
	end
  end
end

function getReccedUnits(_mission)
  MySocket = socket.try(socket.connect(IPAddress, Port))
  MySocket:setoption("tcp-nodelay",true)  
  MySocket:settimeout(1)
  socket.try(MySocket:send(string.format("getReccedUnits," .. _mission .. ",")))
  local s, status, result = MySocket:receive()
  MySocket:close()
  
  result = result:sub(1, -2)
  for token in string.gmatch(result, "[^;]+") do  
	env.info("string to split: ".. token)
    local splitString = splitValue(token, ":")
		env.info("sending request to mark as recced: ".. splitString[1] .. " by: ".. splitString[2] )
		if pcall(markReccedUnit, splitString[1], splitString[2]) then
			env.info("Successfully marked as recced unit: ".. splitString[1])
		else
			env.info("Failed to mark unit as recced: ".. splitString[1])
		end
	
  end
end


getDestroyedUnits(mission_id)


--MANTIS/SHORAD
--SHORAD instance for RADAR protection
local EWSet = SET_GROUP:New():FilterPrefixes(AD_types):FilterCoalitions("red"):FilterStart()
RED_SHORAD = SHORAD:New("RedShorad", "RED SHORAD", EWSet, 22000, 600, "red", true)
--RED_SHORAD:SwitchDebug(true)

RED_MANTIS = MANTIS:New("Red_MANTIS","RED SAM","RED EW","MANTIS Command Center","red",true,nil,true)
RED_MANTIS:SetMaxActiveSAMs(2, 2, 4, 6)
RED_MANTIS:SetAdvancedMode(true)
--RED_MANTIS:Debug(true)
RED_MANTIS:Start()



--CAP/QRA
DetectionSetGroup = SET_GROUP:New()
DetectionSetGroup:FilterPrefixes( { "RED SAM", "RED EW", "RED SHORAD" } )
DetectionSetGroup:FilterStart() 

Detection = DETECTION_AREAS:New( DetectionSetGroup, 20000 )
A2ADispatcher = AI_A2A_DISPATCHER:New( Detection )

A2ADispatcher:SetEngageRadius(150000) -- 100000 is the default value.
A2ADispatcher:SetGciRadius(50000) -- 200000 is the default value.


function enableRedCap()
	--MOOSE/IADS integration CAP/QRA
	--plane sets
	local SET_Damascus_MIG21_Planes = SET_STATIC:New():FilterPrefixes( "RED_Damascus_MiG21" ):FilterStart()
	local SET_Damascus_SU27_Planes = SET_STATIC:New():FilterPrefixes( "RED_Damascus_SU27" ):FilterStart()
	
	local SET_Aleppo_MIG21_Planes = SET_STATIC:New():FilterPrefixes( "RED_Aleppo_MiG21" ):FilterStart()
	local SET_Aleppo_SU27_Planes = SET_STATIC:New():FilterPrefixes( "RED_Aleppo_SU27" ):FilterStart()
	
	local SET_Bassel_MIG21_Planes = SET_STATIC:New():FilterPrefixes( "RED_Bassel_MiG21" ):FilterStart()
	local SET_Bassel_SU27_Planes = SET_STATIC:New():FilterPrefixes( "RED_Bassel_SU27" ):FilterStart()
	
	local SET_Incirlik_MIG21_Planes = SET_STATIC:New():FilterPrefixes( "RED_Incirlik_MiG21" ):FilterStart()
	local SET_Incirlik_MIG23_Planes = SET_STATIC:New():FilterPrefixes( "RED_Incirlik_MiG23" ):FilterStart()
	
	local SET_Akrotiri_MIG21_Planes = SET_STATIC:New():FilterPrefixes( "RED_Akrotiri_MiG21" ):FilterStart()
	local SET_Akrotiri_SU27_Planes = SET_STATIC:New():FilterPrefixes( "RED_Akrotiri_SU27" ):FilterStart()
	
	local SET_Abu_al_Duhur_SU27_Planes = SET_STATIC:New():FilterPrefixes( "RED_Abu_al_Duhur_SU27" ):FilterStart()
	
	local SET_Ramat_SU27_Planes = SET_STATIC:New():FilterPrefixes( "RED_Ramat_SU27" ):FilterStart()
	
	local SET_Beirut_SU27_Planes = SET_STATIC:New():FilterPrefixes( "RED_Beirut_SU27" ):FilterStart()
	

	--initial plane sets
	Damascus_MIG21_Planes = SET_Damascus_MIG21_Planes:CountAlive()
	Damascus_SU27_Planes = SET_Damascus_SU27_Planes:CountAlive()
	
	Aleppo_MIG21_Planes = SET_Aleppo_MIG21_Planes:CountAlive()
	Aleppo_SU27_Planes = SET_Aleppo_SU27_Planes:CountAlive()
	
	Bassel_MIG21_Planes = SET_Bassel_MIG21_Planes:CountAlive()
	Bassel_SU27_Planes = SET_Bassel_SU27_Planes:CountAlive()
	
	Incirlik_MIG21_Planes = SET_Incirlik_MIG21_Planes:CountAlive()
	Incirlik_MIG23_Planes = SET_Incirlik_MIG23_Planes:CountAlive()
	
	Akrotiri_MIG21_Planes = SET_Akrotiri_MIG21_Planes:CountAlive()
	Akrotiri_SU27_Planes = SET_Akrotiri_SU27_Planes:CountAlive()
	
	Abu_al_Duhur_SU27_Planes = SET_Abu_al_Duhur_SU27_Planes:CountAlive()
	
	Ramat_SU27_Planes = SET_Ramat_SU27_Planes:CountAlive()
	
	Beirut_SU27_Planes = SET_Beirut_SU27_Planes:CountAlive()
	
	env.info("RED Plane Stockpile for today:")
	env.info("Damascus MiG21: "..Damascus_MIG21_Planes)
	env.info("Damascus SU27: "..Damascus_SU27_Planes)
	env.info("Aleppo MiG21: "..Aleppo_MIG21_Planes)
	env.info("Aleppo SU27: "..Aleppo_SU27_Planes)
	env.info("Bassel MiG21: "..Bassel_MIG21_Planes)
	env.info("Bassel SU27: "..Bassel_SU27_Planes)
	env.info("Incirlik MiG21: "..Incirlik_MIG21_Planes)
	env.info("Incirlik SU27: "..Incirlik_MIG23_Planes)
	env.info("Abu_al_Duhur SU27: "..Abu_al_Duhur_SU27_Planes)
	env.info("Ramat SU27: "..Ramat_SU27_Planes)
	env.info("Beirut SU27: "..Beirut_SU27_Planes)
	
	--Damascus
	A2ADispatcher:SetSquadron( "Damascus Defenders MIG21", AIRBASE.Syria.Damascus, { "RED - CAP - MIG21" }, Damascus_MIG21_Planes )
	A2ADispatcher:SetSquadronOverhead( "Damascus Defenders MIG21", 0.5)
	A2ADispatcher:SetSquadron( "Damascus Defenders SU27", AIRBASE.Syria.Damascus, { "RED - CAP - SU27A" }, Damascus_SU27_Planes )
	A2ADispatcher:SetSquadronOverhead( "Damascus Defenders SU27", 0.5)

	A2ADispatcher:SetSquadronGci( "Damascus Defenders MIG21", 900, 1200 )
	A2ADispatcher:SetSquadronGci( "Damascus Defenders SU27", 900, 1200 )

	--Aleppo
	A2ADispatcher:SetSquadron( "Aleppo Defenders MIG21", AIRBASE.Syria.Aleppo, { "RED - CAP - MIG21" }, Aleppo_MIG21_Planes )
	A2ADispatcher:SetSquadronOverhead( "Aleppo Defenders MIG21", 0.5)
	A2ADispatcher:SetSquadron( "Aleppo Defenders SU27", AIRBASE.Syria.Aleppo, { "RED - CAP - SU27A" }, Aleppo_SU27_Planes )
	A2ADispatcher:SetSquadronOverhead( "Aleppo Defenders SU27", 0.5)

	A2ADispatcher:SetSquadronGci( "Aleppo Defenders MIG21", 900, 1200 )
	A2ADispatcher:SetSquadronGci( "Aleppo Defenders SU27", 900, 1200 )

	--Bassel al assad
	A2ADispatcher:SetSquadron( "Bassel Al Assad Defenders MIG21", AIRBASE.Syria.Bassel_Al_Assad, { "RED - CAP - MIG21" }, Bassel_MIG21_Planes )
	A2ADispatcher:SetSquadronOverhead( "Bassel Al Assad Defenders MIG21", 1)
	A2ADispatcher:SetSquadron( "Bassel Al Assad Defenders SU27", AIRBASE.Syria.Bassel_Al_Assad, { "RED - CAP - SU27A" }, Bassel_SU27_Planes )
	A2ADispatcher:SetSquadronOverhead( "Bassel Al Assad Defenders SU27", 1)

	A2ADispatcher:SetSquadronGci( "Bassel Al Assad Defenders MIG21", 900, 1200 )
	A2ADispatcher:SetSquadronGci( "Bassel Al Assad Defenders SU27", 900, 1200 )
	
	--Incirlik
	A2ADispatcher:SetSquadron( "Incirlik Defenders MIG21", AIRBASE.Syria.Incirlik, { "RED - CAP - MIG21" }, Bassel_MIG21_Planes )
	A2ADispatcher:SetSquadronOverhead( "Incirlik Defenders MIG21", 1)
	A2ADispatcher:SetSquadron( "Incirlik Defenders MIG23", AIRBASE.Syria.Incirlik, { "RED - CAP - MIG23" }, Bassel_MIG23_Planes )
	A2ADispatcher:SetSquadronOverhead( "Incirlik Defenders MIG23", 1)

	A2ADispatcher:SetSquadronGci( "Incirlik Defenders MIG21", 900, 1200 )
	A2ADispatcher:SetSquadronGci( "Incirlik Defenders MIG23", 900, 1200 )
	
	--Akrotiri
	A2ADispatcher:SetSquadron( "Akrotiri Defenders SU27", AIRBASE.Syria.Akrotiri, { "RED - CAP - SU27A" }, Akrotiri_SU27_Planes )
	A2ADispatcher:SetSquadronOverhead( "Akrotiri Defenders SU27", 1)
	A2ADispatcher:SetSquadron( "Akrotiri Defenders MIG21", AIRBASE.Syria.Akrotiri, { "RED - CAP - MIG21" }, Akrotiri_MIG21_Planes )
	A2ADispatcher:SetSquadronOverhead( "Akrotiri Defenders MIG21", 1)

	A2ADispatcher:SetSquadronGci( "Akrotiri Defenders SU27", 900, 1200 )
	A2ADispatcher:SetSquadronGci( "Akrotiri Defenders MIG21", 900, 1200 )
	
	--Abu Al-Duhur
	A2ADispatcher:SetSquadron( "Abu Al-Duhur Defenders SU27", AIRBASE.Syria.Abu_al_Duhur, { "RED - CAP - SU27A" }, Abu_al_Duhur_SU27_Planes )
	A2ADispatcher:SetSquadronOverhead( "Abu Al-Duhur Defenders SU27", 1)

	A2ADispatcher:SetSquadronGci( "Abu Al-Duhur Defenders SU27", 900, 1200 )
	
	--Ramat
	A2ADispatcher:SetSquadron( "Ramat Defenders SU27", AIRBASE.Syria.Ramat_David, { "RED - CAP - SU27A" }, Ramat_SU27_Planes )
	A2ADispatcher:SetSquadronOverhead( "Ramat Defenders SU27", 1)

	A2ADispatcher:SetSquadronGci( "Ramat Defenders SU27", 900, 1200 )
	
	--Beirut
	A2ADispatcher:SetSquadron( "Beirut Defenders SU27", AIRBASE.Syria.Beirut_Rafic_Hariri, { "RED - CAP - SU27A" }, Beirut_SU27_Planes )
	A2ADispatcher:SetSquadronOverhead( "Beirut Defenders SU27", 1)

	A2ADispatcher:SetSquadronGci( "Beirut Defenders SU27", 900, 1200 )
	
	


	

	--CAP Setup
	CAPZoneNorth = ZONE:New( "CAP_NORTH")
	A2ADispatcher:SetSquadronCap( "Aleppo Defenders SU27", CAPZoneNorth, 4000, 8000, 300, 800, 800, 1200, "BARO" )
	A2ADispatcher:SetSquadronCapInterval( "Aleppo Defenders SU27", 2, 180, 600, 1 )
	
	CAPZoneCenter = ZONE:New( "CAP_CENTER")
	A2ADispatcher:SetSquadronCap( "Abu Al-Duhur Defenders SU27", CAPZoneCenter, 4000, 8000, 300, 800, 800, 1200, "BARO" )
	A2ADispatcher:SetSquadronCapInterval( "Abu Al-Duhur Defenders SU27", 2, 180, 600, 1 )

	CAPZoneSouth = ZONE:New( "CAP_SOUTH")
	A2ADispatcher:SetSquadronCap( "Damascus Defenders SU27", CAPZoneSouth, 4000, 8000, 300, 800, 800, 1200, "BARO" )
	A2ADispatcher:SetSquadronCapInterval( "Damascus Defenders SU27", 2, 180, 600, 1 )
	
	CAPZoneWest = ZONE:New( "CAP_WEST")
	A2ADispatcher:SetSquadronCap( "Akrotiri Defenders SU27", CAPZoneWest, 4000, 8000, 300, 800, 800, 1200, "BARO" )
	A2ADispatcher:SetSquadronCapInterval( "Akrotiri Defenders SU27", 2, 180, 600, 1 )

	--default CAPGCI Settings

	A2ADispatcher:SetDefaultTakeoffFromParkingHot()
	A2ADispatcher:SetDefaultGrouping( 1 )

	A2ADispatcher:Start()
	
end


--mark Targets
function ResetMarkers()
	RemoveMissionMarkers()
	SetPowerPlants:ForEachStatic( function( static ) 
		if static:IsAlive() == true then
			local mymarker=MARKER:New(static:GetCoordinate(), "Secondary Target: Coordinates are precise\nTarget: Powerplant\n".. static:GetCoordinate():ToStringLLDDM() .."\n".. static:GetCoordinate():ToStringMGRS().."\nAltitude\(ft\): "..math.floor(UTILS.MetersToFeet(static:GetAltitude())).." QFE\(mb\): "..math.floor(static:GetCoordinate():GetPressure(static:GetAltitude(FromGround)))):ReadOnly():ToAll()
		end
	end )
	SetCriticalRedUnits:ForEachUnit( function( unit ) 
		if unit:IsAlive() == true then
			local mymarker=MARKER:New(unit:GetCoordinate():GetRandomCoordinateInRadius(1000, 200), "Critical Target: Coordinates are inaccurate\nTarget: "..unit:GetName() .."\n".. unit:GetCoordinate():ToStringLLDDM() .."\n".. unit:GetCoordinate():ToStringMGRS().."\nAltitude\(ft\): "..math.floor(UTILS.MetersToFeet(unit:GetAltitude())).." QFE\(mb\): "..math.floor(unit:GetCoordinate():GetPressure(unit:GetAltitude(FromGround)))):ReadOnly():ToAll()
		end
	end )
	SetCriticalRedStatics:ForEachStatic( function( static ) 
		if static:IsAlive() == true then
			local mymarker=MARKER:New(static:GetCoordinate():GetRandomCoordinateInRadius(1000, 200), "Critical Target:Coordinates are inaccurate\nTarget: "..static:GetName() .."\n".. static:GetCoordinate():ToStringLLDDM() .."\n".. static:GetCoordinate():ToStringMGRS().."\nAltitude\(ft\): "..math.floor(UTILS.MetersToFeet(static:GetAltitude())).." QFE\(mb\): "..math.floor(static:GetCoordinate():GetPressure(static:GetAltitude(FromGround)))):ReadOnly():ToAll()
		end
	end )
end

function RemoveMissionMarkers()
	for index, value in pairs(markerlist) do
			trigger.action.removeMark(value)
	end
end

--Recon
function unitsRecced(who, what)
	local Client_Unit =  CLIENT:FindByName(who)
	
	local MessageAll = MESSAGE:New( "Recce unit: ".. who .." found: ".. what,  1):ToClient(Client_Unit)
	if tableHasKey(reccelist, who) == true then
		if has_value(reccelist[who], what) == false then
			table.insert(reccelist[who], what)
		else
			env.info(what.." alreadt recced")
		end
	else
		reccelist[who] = {what}
	end
end
	
	
function addToRecon(client)	
	--add to running schedule
	table.insert(reconUnits, client:GetName())
end

function Recon(Client_Unit)
		local Client_Unit =  CLIENT:FindByName(Client_Unit)
		local UnitName = Client_Unit:GetName()
		local rollAngle = Client_Unit:GetRoll()
		local pitchAngle = Client_Unit:GetPitch()
		
		if rollAngle == nil or pitchAngle == nil then
			--clear recon, you most likely died
			--remove from recon schedule
			
			for k, v in pairs(reconUnits) do
				if v == UnitName then
					env.info("removing: ".. UnitName .." from reconUnits array")
					reconUnits[k] = nil
				end
			end
				
			--cleanup radio menu
			--local Client_Unit = CLIENT:FindByName(UnitName)
			local ClientGroup = GROUP:FindByName(Client_Unit.ClientGroupName)
			GroupMenu[ClientGroup:GetName()]:Remove()
		
			--cleanup reccelist
			for k, v in pairs(reccelist) do
				env.info("current unit to check for cleanup: ".. k)
				if k == UnitName then
					env.info(UnitName.. " matches, removing")
					reccelist[k] = nil
				end
			end
		elseif 15 >= rollAngle and rollAngle >= -15 and 15 >= pitchAngle and pitchAngle >= -15 then
			--do recon, unit is alive and returning valid data
			local MessageAll = MESSAGE:New( "Doing Recon, roll angle: ".. rollAngle .. " Pitch angle: ".. pitchAngle,  1):ToClient(Client_Unit)
			local currentPosition = Client_Unit:GetCoordinate()
			local groundLevel = currentPosition:GetLandHeight()
			local currentASL = Client_Unit:GetHeight()
			local currentAGL = currentASL - groundLevel
			local reconradius = 4/3 * currentAGL
			--local MessageAll = MESSAGE:New( "Recon radius: ".. reconradius.. "ASL: ".. currentASL.. "GL: "..groundLevel.. "AGL: "..currentAGL,  2):ToClient(Client_Unit)
			
			
			if reconZone == nil then
				reconZone = ZONE_RADIUS:New(Client_Unit:GetName(), currentPosition:GetVec2(), reconradius)
				--local MessageAll = MESSAGE:New( "initial zone",  1):ToClient(Client_Unit)
				SetRedUnits:ForEachUnit( function( unit )  -- Tests set for dead unit.
						if unit:IsInZone(reconZone) then
							unitsRecced(Client_Unit:GetName(), unit:GetName())
						else
							--
						end
				end )
				SetRedStatics:ForEachStatic( function( static )  -- Tests set for dead unit.
						if static:IsInZone(reconZone) then
							unitsRecced(Client_Unit:GetName(), static:GetName())
						else
							--
						end
				end )
			else
				reconZone:SetRadius(reconradius)
				reconZone:SetVec2(currentPosition:GetVec2())
				--local MessageAll = MESSAGE:New( "moved zone",  1):ToClient(Client_Unit)
				
				--debug visualize zone
				--reconZone:DrawZone(-1, {1,0,0}, 1, {1,0,0}, 0.5, 1, true)
				
				--list units
				SetRedUnits:ForEachUnit( function( unit )  -- Tests set for dead unit.
					if unit:IsInZone(reconZone) then
						unitsRecced(Client_Unit:GetName(), unit:GetName())
					else
						--
					end
				  end )	
				  SetRedStatics:ForEachStatic( function( static )  -- Tests set for dead unit.
						if static:IsInZone(reconZone) then
							unitsRecced(Client_Unit:GetName(), static:GetName())
						else
							--
						end
				end )
			end
		else
			local MessageAll = MESSAGE:New( "Aborting recon, roll angle excessive: ".. rollAngle,  60):ToClient(Client_Unit)
			for k, v in pairs(reconUnits) do
				if v == Client_Unit:GetName() then
					table.remove(reconUnits, k)
				end
			end
		end

end

function loadrecon()
	local MessageAll = MESSAGE:New( "Recon report",  60):ToAll()
	for k, v in pairs(reccelist) do
		local MessageAll = MESSAGE:New( "k: ".. k,  60):ToAll()
		for k2, v2 in pairs(v) do
			local MessageAll = MESSAGE:New( "k2: ".. k2 .."v2: ".. v2,  60):ToAll()
		end
		
	end
end


function ValidateReconLoadout(unitName)
	--move to takeoff
			if UNIT:FindByName(unitName):GetAmmunition() == 0 then
				local Client_Unit = CLIENT:FindByName(unitName)
				MessageAll = MESSAGE:New( "Valid Recon Layout",  60):ToClient(Client_Unit)
				local ClientGroup = GROUP:FindByName(Client_Unit.ClientGroupName)
				GroupMenu[ClientGroup:GetName()] = MENU_GROUP:New( ClientGroup, "Recon Menu" )
				MENU_GROUP_COMMAND:New( ClientGroup, "Start Recon", GroupMenu[ClientGroup:GetName()], addToRecon, Client_Unit )				
				MENU_GROUP_COMMAND:New( ClientGroup, "View Recon", GroupMenu[ClientGroup:GetName()], loadrecon, Client_Unit )				
				
			else
				MessageAll = MESSAGE:New( "Loadout not valid for recon, remove all weapons and ammo",  60):ToClient(Client_Unit)				
			end
end

--Mobile EWR deployment
function LoadEWR(Client)
	local Zone = ZONE:FindByName("Pickup")
	if Client:InAir() == false and Client:IsInZone(Zone) == true then
		local MessageAll = MESSAGE:New(Client:GetName() .. " Valid EWR Pickup Location",  10):ToAll()
		local who = Client:GetName()
		local what = "EWR" 
		if tableHasKey(cargoList, who) == true then
			if has_value(cargoList[who], what) == false then
				table.insert(cargoList[who], what)
			else
				env.info(what.." already on board")
			end
		else
			cargoList[who] = {what}
		end
	else
		local MessageAll = MESSAGE:New("Please land at a valid EWR Pickup Location",  10):ToAll()
	end
end


function SpawnEWR(Client)
	--check if in EWRZones

	local SpawnUnit = SPAWN:NewWithAlias( "BLUE EWR", math.random(99999999999))
	local coord = Client:GetCoordinate()
	local heading = Client:GetHeading()
	local newCoord = coord:Translate(25, heading, false, false)
	local EWR = SpawnUnit:SpawnFromVec2( newCoord:GetVec2() )
end

function UnloadEWR(Client)
	local who = Client:GetName()
	local what = "EWR" 
	
	if tableHasKey(cargoList, who) == true then
		--has cargo on board, not checking what assuming EWR (lazy hack)
		local MessageAll = MESSAGE:New("Deploying EWR",  10):ToAll()
		SpawnEWR(Client)
		
		--cleanup cargolist
		for k, v in pairs(cargoList) do
			env.info("current unit to check for cleanup: ".. k)
			if k == who then
				env.info(who.. " matches, removing")
				cargoList[k] = nil
			end
		end
	else
		local MessageAll = MESSAGE:New("No EWR on board",  10):ToAll()
	end
end


--Blue HQ
local HQ = GROUP:FindByName( "Carier group" )
local CommandCenter = COMMANDCENTER:New( HQ, "Lima" )

--Blue F10 Menu
local MenuBlue = MENU_COALITION:New( coalition.side.BLUE, "Options" )
local MenuAdd = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Reset Active Markers",MenuBlue,ResetMarkers,1 )

--Firing Range

local bombCirclesFDM = {"CircleA", "CircleB"}
RangeFDM = RANGE:New("Training Range")
	RangeFDM:SetRangeZone(ZONE:New("Range"))
	RangeFDM:SetScoreBombDistance(200)
	RangeFDM:AddBombingTargets( bombCirclesFDM, 30)
	RangeFDM:SetDefaultPlayerSmokeBomb(false)
	RangeFDM:SetRangeControl(260)
	RangeFDM:SetInstructorRadio(270)
RangeFDM:Start()

--timers
local ScheduleEvery10Sec = SCHEDULER:New( nil, 
  function()
		check_zones()
	  end, {}, 1,10
)

local ScheduleAfter10Sec = SCHEDULER:New( nil, 
  function()
		ResetMarkers()
		getReccedUnits(mission_id)
		enableRedCap()
	  end, {}, 10
)

local ReconSched = SCHEDULER:New( nil, 
	function()
		--check reccelist for active reconunits
		for k, v in pairs(reconUnits) do
			Recon(v)
		end
		
	end, {}, 1, 3
)