do -- Public Function
    function PrintArr(arr, pre)
        if arr ~= nil then
            if type(arr) ~= "table" then
                env.info("this is not table")
                return nil
            end
            local indent = ""
            if pre ~= nil then
                indent = pre .. "    "
            end
            for key, value in pairs(arr) do
                local type = type(value)
                if type == "table" then
                    env.info(
                        indent .. "[" .. key .. "] is table"
                    )
                    PrintArr(value, indent)
                    env.info(
                        indent .. "end of [" .. key .. "] table"
                    )
                else
                    env.info(
                        indent .. "[" .. key .. "] is " .. type
                    )
                    env.info(
                        indent .. "[" .. key .. "] = " .. tostring(value)
                    )
                end
            end
        end
    end

    function Translate(point, dist, radian, alt)
        if alt ~= nil then
            return {
                x = (dist * math.cos(radian)) + point.x,
                z = (dist * math.sin(radian)) + point.z,
                y = alt
            }
        else
            return {
                x = (dist * math.cos(radian)) + point.x,
                z = (dist * math.sin(radian)) + point.z,
                y = point.y
            }
        end
    end

    function HeadingTo(from, to)
        local dz = to.z - from.z
        local dx = to.x - from.x
        local heading = math.deg(
            math.atan2(dz, dx)
        )
        if heading < 0 then
            heading = heading + 360
        end
        return heading
    end

    function GetCoordStr(point, dms)
        local lat, lon, alt = coord.LOtoLL(point)
        local latHemi, lonHemi do
            if lat > 0 then
                latHemi = "N"
            else
                latHemi = "S"
            end
            if lon > 0 then
                lonHemi = "E"
            else
                lonHemi = "W"
            end
        end

        lat = math.abs(lat)
        lon = math.abs(lon)

        local latDeg = math.floor(lat)
        local latMin = (lat - latDeg) * 60
        local lonDeg = math.floor(lon)
        local lonMin = (lon - lonDeg) * 60

        local result = nil
        if dms == true then -- Degree, Minutes, Seconds
            local oldLatMin = latMin
            latMin = math.floor(latMin)
            local latSec = mist.utils.round(
                (oldLatMin - latMin) * 60, 6
            )

            local oldLonMin = lonMin
            lonMin = math.floor(lonMin)
            local lonSec = mist.utils.round(
                (oldLonMin - lonMin) * 60, 6
            )

            if latSec == 60 then
                latSec = 0
                latMin = latMin + 1
            end
          
            if lonSec == 60 then
                lonSec = 0
                lonMin = lonMin + 1
            end

            result = latHemi .. string.format("%03d°", latDeg) .. string.format("%02d'", latMin) .. string.format("%02.2f'", latSec) .. " " ..
                     lonHemi .. string.format("%03d°", lonDeg) .. string.format("%02d'", lonMin) .. string.format("%02.2f'", lonSec)
        else -- Degree, Decimal Minutes.
            latMin = mist.utils.round(latMin, 4)
            lonMin = mist.utils.round(lonMin, 4)

            if latMin == 60 then
                latMin = 0
                latDeg = latDeg + 1
            end

            if lonMin == 60 then
                lonMin = 0
                lonDeg = lonDeg + 1
            end

            result = latHemi .. string.format("%03d°", latDeg) .. string.format("%07.4f", latMin) .. " " ..
                     lonHemi .. string.format("%03d°", lonDeg) .. string.format("%07.4f", lonMin)
        end

        -- Return
        return result
    end

    function GetAngelStr(point, prs)
        local altitude = land.getHeight(
            {
                x = point.x,
                y = point.z
            }
        )
        local ft = math.floor(altitude * 3.281)
        local m = math.floor(altitude)
        if prs == true then -- Pressure
            local k, p = atmosphere.getTemperatureAndPressure(
                {
                    x = point.x,
                    z = point.z,
                    y = altitude
                }
            )
            p = p / 100
            p = string.format(
                "%03.1f", p
            )
            return string.format(
                "%sft / %sm / %shPa",
                ft, m, p
            )
        else
            return string.format(
                "%sft / %sm",
                ft, m
            )
        end
    end

    function GetUnitAngel(unit)
        local p = unit:getPoint()
        return p.y
    end
end

do -- Mission Structure
    MIZ        = {}
    MIZ.Menu   = {}
    MIZ.Event  = {}
    MIZ.Blast  = {}
    MIZ.Inform = {}
    MIZ.Sensor = {}
    MIZ.Detect = {}
    MIZ.Circle = {}
    MIZ.Convoy = {}
    MIZ.Combat = {}
    MIZ.Refuel = {}
    MIZ.Strike = {}
    MIZ.Detect.Progress = {}
    MIZ.Strike.Progress = {}
    MIZ.Sensor.Progress = {}
    MIZ.Combat.Progress = {}
    MIZ.Refuel.Progress = {
        [1] = "ready",
        [2] = "ready",
        [3] = "ready",
        [4] = "ready"
    }
    MIZ.Strike.Template = {
        [1] = {
            name = "SA-2 Dvina",
            list = {
                [1] = "RED_TGT_SR_P19",
                [2] = "RED_TGT_TR_SNR75",
                [3] = "RED_TGT_LN_SM90",
                [4] = "RED_TGT_IR_9P31",
                [5] = "RED_TGT_AA_ZSU572",
                [6] = "RED_TGT_AA_ZSU232",
                [7] = "RED_TGT_TS_GAZ66"
            }
        },
        [2] = {
            name = "SA-11 Buk",
            list = {
                [1] = "RED_TGT_SR_9S18M1",
                [2] = "RED_TGT_CC_9S470M1",
                [3] = "RED_TGT_LN_9A310M1",
                [4] = "RED_TGT_RM_OSA",
                [5] = "RED_TGT_IR_9A35",
                [6] = "RED_TGT_AA_ZSU234",
                [7] = "RED_TGT_TS_KAMAZ"
            }
        },
        [3] = {
            name = "SA-10 Grumble",
            list = {
                [1] = "RED_TGT_SR_64H6E",
                [2] = "RED_TGT_TR_30N6",
                [3] = "RED_TGT_LN_5P85D",
                [4] = "RED_TGT_CC_54K6",
                [5] = "RED_TGT_RM_TOR",
                [6] = "RED_TGT_AA_2S6",
                [7] = "RED_TGT_TS_KAMAZ"
            }
        }
    }
    MIZ.Blast.Switch = true
    MIZ.Zones = {
        [1] = {
            name = "Circle",
            zone = {"CC001", "CC002"}
        },
        [2] = {
            name = "Convoy",
            zone = {"CV001", "CV002"}
        },
        [3] = {
            name = "Strike",
            zone = {"ST001", "ST002", "ST003"}
        }
    }
end

do -- Marking
    local function GetText(point, str)
        return string.format(
            "MISSION MARK OF " .. str .. "\n" ..
            "DDM: " .. GetCoordStr(point, false) .. "\n" ..
            "DMS: " .. GetCoordStr(point, true) .. "\n" ..
            "ALT: " .. GetAngelStr(point, true)
        )
    end

    for index, data in ipairs(MIZ.Zones) do
        for idx, str in ipairs(data.zone) do
            for zid, zone in pairs(mist.DBs.zonesByNum) do
                if zone.name == str then
                    local point = zone.point
                    trigger.action.markToAll(
                        zid, GetText(point, str),
                        point, true, nil
                    )
                    break
                end
            end
        end
    end
end

do -- Blast
    local function GetBlastPos(pos, dist, deg, pitch)
        local rad = math.rad(deg + math.random(0, 360, 60))
        local alt = (pitch * 3) + math.random(-1, 5)
        return {
            x = (dist * math.cos(rad)) + pos.x + math.random(-10, 10),
            z = (dist * math.sin(rad)) + pos.z + math.random(-10, 10),
            y = pos.y + alt
        }
    end

    local function Explosing(pos)
        local count  = 0
        local radius = 2
        timer.scheduleFunction(
            function(...)
                if count == arg[1] then
                    return nil
                end
                local circum = (radius * 2) * math.pi
                local disperse = (360 / (circum / 8))
                for angle = 0, 359, disperse do
                    trigger.action.explosion(
                        GetBlastPos(pos, radius, angle, count),
                        0 -- Power
                    )
                end
                count = count + 1
                radius = radius + 2
                return arg[2] + 0.025
            end, 2, timer.getTime() + 0.01
        )
    end

    function MIZ.Blast:Tracking(weapon)
        local pos = nil
        timer.scheduleFunction(
            function(...)
                local ran, err = pcall(
                    function()
                        pos = weapon:getPoint()
                    end
                )
                if ran == true then
                    return arg[2] + 0.001
                else
                    if pos ~= nil then
                        Explosing(
                            {
                                x = pos.x,
                                z = pos.z,
                                y = pos.y - 5
                            }
                        )
                    end
                    return nil
                end
            end, nil, timer.getTime() + 1
        )
    end
end

do -- Detect
    local function IsRadar(unit)
        local desc = unit:getDesc()
        local data = desc.attributes
        if data["SAM SR"] == true then
            return true
        end
        if data["SAM TR"] == true then
            return true
        end
        return false
    end

    local function IsSilentable(unit)
        for k, v in pairs(MIZ.Detect.Progress) do
            if v == unit then
                return false
            end
        end
        return true
    end

    local function IsAdversary(unit, weapon)
        if weapon:getCoalition() ~= unit:getCoalition() then
            return true
        end
        return false
    end

    local function DoSilent(unit, weapon)
        -- Registration
        local uid = unit:getID()
        MIZ.Detect.Progress[uid] = unit

        -- Turning Off
        local control = unit:getController()
        control:setOnOff(false)

        -- Check Missile Exist
        timer.scheduleFunction(
            function(...)
                if weapon:isExist() ~= true then
                    control:setOnOff(true)
                    MIZ.Detect.Progress[uid] = nil
                    return nil
                end
                return arg[2] + 1
            end, nil, timer.getTime() + 1
        )
    end

    function MIZ.Detect:Tracking(weapon)
        timer.scheduleFunction(
            function(...)
                -- Is Missile Exist?
                if weapon:isExist() ~= true then
                    return nil
                end
                -- Searching Nearest Radar
                world.searchObjects(
                    Object.Category.UNIT,
                    {
                        id = world.VolumeType.SPHERE,
                        params = {
                            point  = weapon:getPoint(),
                            radius = math.random(5000, 7500)
                        }
                    },
                    function(unit)
                        if IsRadar(unit) == true then
                            if IsSilentable(unit) == true then
                                if IsAdversary(unit, weapon) == true then
                                    DoSilent(unit, weapon)
                                end
                            end
                        end
                    end
                )
                return arg[2] + 1
            end, nil, timer.getTime() + 1
        )
    end
end

do -- Sensor
    local function Notice(unit, shooter)
        if shooter:isExist() == true and shooter:getPlayerName() ~= nil then
            local gid = shooter:getGroup():getID()
            trigger.action.outTextForGroup(
                gid, "You Kill " .. unit:getPlayerName(), 15, false
            )
            trigger.action.outSoundForGroup(
                gid, "bell.ogg"
            )
        end
    end

    local function Declare(gid, unit)
        timer.scheduleFunction(
            function(...)
                if arg[1] < arg[2] then
                    return nil
                end
                trigger.action.signalFlare(
                    unit:getPoint(), 1,
                    math.deg(
                        mist.getHeading(unit)
                    )
                )
                return arg[2] + 0.1
            end, timer.getTime() + 1.6, timer.getTime() + 0.1
        )
        trigger.action.outTextForGroup(
            gid, "You're Dead", 15, true
        )
        trigger.action.outSoundForGroup(
            gid, "dead.ogg"
        )
    end

    function MIZ.Sensor:MissileTracking(weapon)
        local shooter = weapon:getLauncher()
        local missile = nil
        timer.scheduleFunction(
            function(...)
                local ran, err = pcall(
                    function()
                        missile = weapon:getPoint()
                    end
                )
                if ran == true then
                    return arg[2] + 0.001
                else
                    for gid, table in pairs(mist.DBs.humansById) do
                        local unit = Unit.getByName(table.unitName)
                        if unit ~= nil and unit:inAir() == true then
                            if mist.utils.get3DDist(missile, unit:getPoint()) < 100 then
                                Notice(unit, shooter)
                                Declare(gid, unit)
                                break
                            end
                        end
                    end
                    return nil
                end
            end, nil, timer.getTime() + 1
        )
    end

    function MIZ.Sensor:CannonFire(unit, key)
        local detected = false
        timer.scheduleFunction(
            function(...)
                if arg[1] < arg[2] then
                    MIZ.Sensor.Progress[key] = nil
                    return nil
                end
                if detected ~= true then
                    world.searchObjects(
                        Object.Category.WEAPON,
                        {
                            id = world.VolumeType.SPHERE,
                            params = {
                                point = unit:getPoint(),
                                radius = 5
                            }
                        },
                        function(weapon)
                            local gid = unit:getGroup():getID()
                            Declare(gid, unit)
                            detected = true
                        end
                    )
                end
                return arg[2] + 0.001
            end, timer.getTime() + 3, timer.getTime() + 0.001
        )
    end
end

do -- Circle
    local function MakeCircle(point, radius, degree)
        for angle = 0, 359, degree do
            local pos = Translate(
                point, radius, math.rad(angle)
            )
            coalition.addStaticObject(
                country.id.CJTF_RED,
                {
                    ["category"] = "Fortifications",
                    ["shape_name"] = "H-tyre_B",
                    ["type"] = "Black_Tyre",
                    ["dead"] = true,
                    ["x"] = pos.x,
                    ["y"] = pos.z,
                    ["heading"] = 0,
                    ["name"] = "BLACK_TYRE"
                }
            )
        end
    end

    local function MakeTarget(point)
        local data = mist.getGroupData("RED_TGT_101")
        data.units[1].heading = math.rad(
            math.random(000, 359)
        )
        data.units[1].x = point.x
        data.units[1].y = point.z
        data.units[1]["AddPropVehicle"] = {
            Variant = 4
        }
        data.clone = true
        local add = mist.dynAdd(data)
        local group = Group.getByName(add.name)
        local control = group:getController()
        control:setOnOff(false)
        control:setCommand(
            {
                id = "SetImmortal",
                params = {
                    value = true
                }
            }
        )
        MIZ.Circle[#MIZ.Circle + 1] = group
    end

    for index, data in ipairs(mist.DBs.zonesByNum) do
        if string.sub(data.name, 1, 2) == "CC" then
            MakeCircle(data.point, 75, 2)
            MakeCircle(data.point, 45, 4)
            MakeCircle(data.point, 15, 8)
            MakeTarget(data.point)
        end
    end
end

do -- Convoy
    local function MakeTarget(point, heading, quantity)
        for count = 1, quantity do
            local trans = Translate(
                point, 50*(count-1), math.rad(heading)
            )
            local data = mist.getGroupData("RED_TGT_101")
            data.units[1].heading = math.rad(
                heading + 180
            )
            data.units[1].x = trans.x
            data.units[1].y = trans.z
            data.units[1]["AddPropVehicle"] = {
                Variant = 4
            }
            data.clone = true
            local add = mist.dynAdd(data)
            local group = Group.getByName(add.name)
            local control = group:getController()
            control:setOnOff(false)
            control:setCommand(
                {
                    id = "SetImmortal",
                    params = {
                        value = true
                    }
                }
            )
            MIZ.Convoy[#MIZ.Convoy + 1] = group
        end
    end

    MakeTarget(
        mist.DBs.zonesByName["CV001"]["point"],
        100, 5
    )
    MakeTarget(
        mist.DBs.zonesByName["CV002"]["point"],
        358, 5
    )
end

do -- Combat
    local function Inspect(gid, unit)
        if unit:inAir() ~= true then
            trigger.action.outTextForGroup(
                gid, "You're Not in the Air", 15, false
            )
            trigger.action.outSoundForGroup(
                gid, "warn.wav"
            )
            return false
        end
        if MIZ.Combat.Progress[gid] ~= nil then
            trigger.action.outTextForGroup(
                gid, "You Have Your Target Already", 15, false
            )
            trigger.action.outSoundForGroup(
                gid, "warn.wav"
            )
            return false
        end
        return true
    end

    local function SetUp(template, trans, point, quantity)
        local data = mist.getGroupData(template)
        for count = 1, quantity do
            local dictionary = {}
            for key, value in pairs(data.units[1]) do
                dictionary[key] = value
            end
            dictionary.x = trans.x
            dictionary.y = trans.z
            dictionary.alt = trans.y
            dictionary.skill = "Excellent"
            dictionary.payload.flare = 999
            dictionary.payload.chaff = 0
            dictionary.onboard_num = string.format(
                "%03d", count
            )
            data.units[count] = dictionary
        end
        data.clone = true
        data.route = {
            points = {
                [1] = mist.fixedWing.buildWP(trans, nil, 999, trans.y, "BARO"),
                [2] = mist.fixedWing.buildWP(point, nil, 999, point.y, "BARO")
            }
        }
        local spawn = mist.dynAdd(data)
        return Group.getByName(spawn.name)
    end

    local function GetTargets(point, radius)
        local arr = {}
        world.searchObjects(
            Object.Category.UNIT,
            {
                id = world.VolumeType.SPHERE,
                params = {
                    point = point,
                    radius = radius
                }
            },
            function(found)
                local desc = found:getDesc()
                desc = desc.attributes
                if found:inAir() == true and found:getCoalition() == 2 and desc.Planes == true then
                    arr[#arr+1] = found
                end
            end
        )
        return arr
    end

    local function Option(control)
        control:setOption(0, 2) -- ROE: Open Fire
        control:setOption(1, 3) -- ROT: Bypass and Escape
        control:setOption(4, 3) -- Flare: Using Near Enemy
        control:setOption(5, 1) -- Formation: Line Abreast
        control:setOption(6, false) -- Do Not RTB in Bingo
        control:setOption(13, 0) -- Do Not Using ECM
        control:setOption(18, 3) -- Weapon Fire in Estimate
    end

    local function Tasking(bogey, target)
        timer.scheduleFunction(
            function(...)
                if bogey:isExist() == true then
                    local control = bogey:getController()
                    control:pushTask(
                        {
                            id = "AttackUnit",
                            params = {
                                unitId = target:getID()
                            }
                        }
                    )
                    Option(control)
                end
                return nil
            end, nil, timer.getTime() + 3
        )
    end

    local function Assessment(gid, unit, bogey, targets)
        timer.scheduleFunction(
            function(...)
                if bogey:isExist() == true then
                    return arg[2] + 1
                else
                    for index, target in ipairs(targets) do
                        if target:isExist() == true then
                            local tid = target:getGroup():getID()
                            trigger.action.outTextForGroup(
                                tid, "Terminated", 15, false
                            )
                            trigger.action.outSoundForGroup(
                                tid, "bell.ogg"
                            )
                        end
                    end
                    MIZ.Combat.Progress[gid] = nil
                    return nil
                end
            end, nil, timer.getTime() + 1
        )
    end

    -- Initiate Combat
    MIZ.Combat["Init"] = function(gid, unit, radian, dist, template, quantity)
        if Inspect(gid, unit) ~= true then
            return nil
        end

        -- Find Spawning Position
        local point = unit:getPoint()
        local trans = Translate(
            point, dist, mist.getHeading(unit)+radian, nil
        )

        -- Make Bogey
        local bogey = SetUp(template, trans, point, quantity)
        local targets = GetTargets(point, 18520)
        for index, target in ipairs(targets) do
            local tid = target:getGroup():getID()
            trigger.action.outTextForGroup(
                tid, "Bogey Incoming", 15, false
            )
            trigger.action.outSoundForGroup(
                tid, "beep.ogg"
            )
            Tasking(bogey, target)
        end

        -- Post of Spawn
        MIZ.Combat.Progress[gid] = bogey
        Assessment(gid, unit, bogey, targets)
    end

    -- Aborting
    MIZ.Combat["Abort"] = function(gid)
        if MIZ.Combat.Progress[gid] ~= nil then
            MIZ.Combat.Progress[gid]:destroy()
        else
            trigger.action.outTextForGroup(
                gid, "You're Not Have Your Target", 15, false
            )
            trigger.action.outSoundForGroup(
                gid, "warn.wav"
            )
        end
    end
end

do -- Refuel
    local function GetIndex()
        for index, slot in ipairs(MIZ.Refuel.Progress) do
            if slot == "ready" then
                return index
            end
        end
        return nil
    end

    local function Inspect(gid, unit, desc, slot)
        if desc.attributes["Refuelable"] ~= true then
            trigger.action.outTextForGroup(
                gid, "Aircraft Can't Do", 15, false
            )
            trigger.action.outSoundForGroup(
                gid, "warn.wav"
            )
            return false
        end
        if unit:inAir() ~= true then
            trigger.action.outTextForGroup(
                gid, "You're Not in the Air", 15, false
            )
            trigger.action.outSoundForGroup(
                gid, "warn.wav"
            )
            return false
        end
        return true
    end

    local function GetTemplate(desc)
        if desc.tankerType == 0 then
            return "BLUE_REFUEL_K135"
        else
            return "BLUE_REFUEL_MPRS"
        end
    end

    local function GetTanker(template, trans, steer, speed)
        local data = mist.getGroupData(template)
        data.units[1].x = trans.x
        data.units[1].y = trans.z
        data.units[1].alt = trans.y
        data.units[1].speed = 210
        data.clone = true
        data.route = {
            points = {
                [1] = mist.fixedWing.buildWP(trans, nil, speed, trans.y, "BARO"),
                [2] = mist.fixedWing.buildWP(steer, nil, speed, steer.y, "BARO")
            }
        }
        local spawn = mist.dynAdd(data)
        return Group.getByName(spawn.name)
    end

    local function GetTacanFreq(channel, mode)
        if type(channel) ~= "number" then
            return nil
        end
        if mode ~= "X" and mode ~= "Y" then
            return nil
        end
        local alpha = 1151
        local omega = 64
        if channel < 64 then
            omega = 1
        end
        if mode == "Y" then
            alpha = 1025
            if channel < 64 then
                alpha = 1088
            end
        else
            if channel < 64 then
                alpha = 962
            end
        end
        return (alpha + channel - omega) * 1000000
    end

    local function SetCommand(control, index)
        control:setCommand(
            {
                id = "SetInvisible",
                params = {
                    value = true
                }
            }
        )
        control:setCommand(
            {
                id = "SetImmortal",
                params = {
                    value = true
                }
            }
        )
        control:setCommand(
            {
                id = "SetFrequency",
                params = {
                    frequency = tonumber("315." .. index) * 1000000,
                    modulation = 0
                }
            }
        )
        control:setCommand(
            {
                id = "SetCallsign",
                params = {
                    callname = 1,
                    number = index
                }
            }
        )
        local name = tostring("TX" .. index)
        local freq = tonumber("09" .. index)
        control:setCommand(
            {
                id = "ActivateBeacon",
                params = {
                    type = 4,
                    system = 4,
                    name = name,
                    callsign = name,
                    frequency = GetTacanFreq(freq, "Y")
                }
            }
        )
    end

    local function Tasking(control, steer, speed)
        local anchor = {
            x = steer.x,
            y = steer.z
        }
        control:setTask(
            {
                id = "Orbit",
                params = {
                    pattern = "Circle",
                    point = anchor,
                    speed = speed,
                    altitude = 4572
                }
            }
        )
        control:pushTask(
            {
                id = "Tanker",
                params = {}
            }
        )
    end

    local function Option(control)
        control:setOption(1, 0) -- ROT: Ignore
        control:setOption(6, false) -- Do Not RTB in Bingo
        control:setOption(7, true) -- Silence
    end

    MIZ.Refuel["Call"] = function(gid, unit)
        local desc = unit:getDesc()
        if Inspect(gid, unit, desc) ~= true then
            return nil
        end

        -- Is Can Make More?
        local index = GetIndex()
        if index == nil then
            trigger.action.outTextForGroup(
                gid, "Can't Do More", 15, false
            )
            trigger.action.outSoundForGroup(
                gid, "warn.wav"
            )
            return nil
        end

        -- Is A-10?
        local speed = 258
        if string.find(string.upper(desc.displayName), "A-10") ~= nil then
            speed = 129
        end

        -- Servicing
        local template = GetTemplate(desc)
        local heading = mist.getHeading(unit)
        local point = unit:getPoint()
        local trans = Translate(point, 1852, heading + math.rad(15), 4572)
        local steer = Translate(point, 9260, heading, 4572)
        local tanker = GetTanker(template, trans, steer, speed)
        MIZ.Refuel.Progress[index] = tanker
        local control = tanker:getController()
        timer.scheduleFunction(
            function(...)
                SetCommand(control, index)
                Tasking(control, steer, speed)
                Option(control)
                return nil
            end, nil, timer.getTime() + 3
        )
        local text = string.format(
            "Tanker Texaco " .. index .. "-1 Airborned at Angel 15\n" ..
            "Freq: 315." .. index .. "00 AM, A/A TCN: 9" .. index .. "X"
        )
        trigger.action.outTextForGroup(
            gid, text, 60, false
        )
        trigger.action.outSoundForGroup(
            gid, "beep.ogg"
        )
    end

    -- Monitoring
    local function GetUnits(tanker)
        local result = {}
        world.searchObjects(
            Object.Category.UNIT,
            {
                id = world.VolumeType.SPHERE,
                params = {
                    point  = tanker:getPoint(),
                    radius = 5556
                }
            },
            function(unit)
                local data = unit:getDesc()
                data = data.attributes["Refuelable"]
                if unit:getPlayerName() ~= nil and data == true then
                    result[#result + 1] = unit
                end
            end
        )
        return result
    end

    local function PrintRemain(units, fuel)
        for key, unit in ipairs(units) do
            local remain = math.floor(
                (fuel - 0.25) * 100
            )
            local text = string.format(
                "Tanker Fuel: " .. remain .. " Percent"
            )
            trigger.action.outTextForGroup(
                unit:getGroup():getID(), text, 9, false
            )
        end
    end

    timer.scheduleFunction(
        function(...)
            for index, group in ipairs(MIZ.Refuel.Progress) do
                if group ~= "ready" then
                    local tanker = group:getUnit(1)
                    local fuel = tanker:getFuel()
                    local units = GetUnits(tanker)
                    if #units == 0 or fuel < 0.25 then
                        MIZ.Refuel.Progress[index] = "ready"
                        group:destroy()
                    else
                        PrintRemain(units, fuel)
                    end
                end
            end
            return arg[2] + 10
        end, nil, timer.getTime() + 1
    )
end

do -- Information
    local function GetText(point, str)
        return string.format(
            "COORDINATE INFORMATION OF " .. str .. "\n" ..
            "DDM: " .. GetCoordStr(point, false) .. "\n" ..
            "DMS: " .. GetCoordStr(point, true) .. "\n" ..
            "ALT: " .. GetAngelStr(point, true)
        )
    end

    MIZ.Inform["Show"] = function(gid, str)
        for index, data in pairs(mist.DBs.zonesByNum) do
            if data.name == str then
                trigger.action.outTextForGroup(
                    gid, GetText(data.point, str), 180, true
                )
                trigger.action.outSoundForGroup(
                    gid, "beep.ogg"
                )
                break
            end
        end
    end
end

do -- Strike
    local function Inspect(gid, unit)
        if unit:inAir() ~= true then
            trigger.action.outTextForGroup(
                gid, "You're Not in the Air", 15, false
            )
            trigger.action.outSoundForGroup(
                gid, "warn.wav"
            )
            return false
        end
        if MIZ.Strike.Progress[gid] ~= nil then
            trigger.action.outTextForGroup(
                gid, "You Have Your Target Already", 15, false
            )
            trigger.action.outSoundForGroup(
                gid, "warn.wav"
            )
            return false
        end
        return true
    end

    local function GetDvina(point, list, heading)
        local master = mist.getGroupData(list[1])
        master.x = point.x
        master.y = point.z
        master.clone = true

        do -- Surveillance Radar
            local data = mist.utils.deepCopy(master.units[1])
            local trans = Translate(
                point, 200, math.rad(heading - 90)
            )
            data.x = trans.x
            data.y = trans.z
            data.heading = math.rad(heading + 90)
            master.units[1] = data
        end

        do -- Tracking Radar
            local data = mist.getGroupData(list[2])
            data = mist.utils.deepCopy(data.units[1])
            data.x = point.x
            data.y = point.z
            data.heading = math.rad(heading)
            master.units[2] = data
        end

        do -- Launcher
            local data = mist.getGroupData(list[3])
            data = data.units[1]
            local inst = {
                [1] = 040,
                [2] = 050,
                [3] = 130,
                [4] = 140,
                [5] = 220,
                [6] = 230,
                [7] = 310,
                [8] = 320
            }
            for index, angle in ipairs(inst) do
                local face = math.rad(heading + angle)
                local copy = mist.utils.deepCopy(data)
                local trans = Translate(
                    point, 100, face
                )
                copy.x = trans.x
                copy.y = trans.z
                copy.heading = face
                master.units[#master.units + 1] = copy
            end
        end

        do -- Strela
            local data = mist.getGroupData(list[4])
            data = data.units[1]
            for i = 1, 3 do
                local face = math.rad((120 * i) + heading)
                local copy = mist.utils.deepCopy(data)
                local trans = Translate(
                    point, 150, face
                )
                copy.x = trans.x
                copy.y = trans.z
                copy.heading = face
                master.units[#master.units + 1] = copy
            end
        end

        do -- ZSU-57-2
            local data = mist.getGroupData(list[5])
            data = data.units[1]
            for i = 1, 8 do
                local face = math.rad((40 * i) + heading)
                local copy = mist.utils.deepCopy(data)
                local trans = Translate(
                    point, 250, face
                )
                copy.x = trans.x
                copy.y = trans.z
                copy.heading = face
                master.units[#master.units + 1] = copy
            end
        end

        do -- ZSU-23-2
            local data = mist.getGroupData(list[6])
            data = data.units[1]
            for i = 1, 4 do
                local face = math.rad((90 * i) + heading)
                local copy = mist.utils.deepCopy(data)
                local trans = Translate(
                    point, 225, face
                )
                copy.x = trans.x
                copy.y = trans.z
                copy.heading = face
                master.units[#master.units + 1] = copy
            end
        end

        do -- GAZ-66
            local data = mist.getGroupData(list[7])
            data = data.units[1]
            local base = Translate(
                point, 50, math.rad(
                    heading + 135
                )
            )
            for i = 0, 3 do
                local copy = mist.utils.deepCopy(data)
                local trans = Translate(
                    base, (10 * i), math.rad(
                        heading - 135
                    )
                )
                copy.x = trans.x
                copy.y = trans.z
                copy.heading = math.rad(heading)
                master.units[#master.units + 1] = copy
            end
        end

        -- Spawn
        local add = mist.dynAdd(master)
        return Group.getByName(add.name)
    end

    local function GetBuk(point, list, heading)
        local master = mist.getGroupData(list[1])
        master.x = point.x
        master.y = point.z
        master.clone = true

        do -- Surveillance Radar
            local data = mist.utils.deepCopy(master.units[1])
            data.x = point.x
            data.y = point.z
            data.heading = math.rad(heading)
            master.units[1] = data
        end

        do -- Command
            local data = mist.getGroupData(list[2])
            data = mist.utils.deepCopy(data.units[1])
            local trans = Translate(
                point, 250, math.rad(
                    heading - 135
                )
            )
            data.x = trans.x
            data.y = trans.z
            data.heading = math.rad(heading + 45)
            master.units[2] = data
        end

        do -- Launcher
            local data = mist.getGroupData(list[3])
            data = data.units[1]
            for i = 0, 7 do
                local face = math.rad((40 * i) + heading)
                local copy = mist.utils.deepCopy(data)
                local trans = Translate(
                    point, 125, face
                )
                copy.x = trans.x
                copy.y = trans.z
                copy.heading = face + math.rad(180)
                master.units[#master.units + 1] = copy
            end
        end

        do -- Radar Missile
            local data = mist.getGroupData(list[4])
            data = data.units[1]
            for i = 0, 1 do
                local face = math.rad((180 * i) + (heading + 45))
                local copy = mist.utils.deepCopy(data)
                local trans = Translate(
                    point, 200, face
                )
                copy.x = trans.x
                copy.y = trans.z
                copy.heading = face + math.rad(90)
                master.units[#master.units + 1] = copy
            end
        end

        do -- IR Missile
            local data = mist.getGroupData(list[5])
            data = data.units[1]
            for i = 0, 2 do
                local face = math.rad((120 * i) + (heading + 20))
                local copy = mist.utils.deepCopy(data)
                local trans = Translate(
                    point, 175, face
                )
                copy.x = trans.x
                copy.y = trans.z
                copy.heading = face
                master.units[#master.units + 1] = copy
            end
        end

        do -- Shilka
            local data = mist.getGroupData(list[6])
            data = data.units[1]
            for i = 0, 5 do
                local face = math.rad((60 * i) + heading)
                local copy = mist.utils.deepCopy(data)
                local trans = Translate(
                    point, 200, face
                )
                copy.x = trans.x
                copy.y = trans.z
                copy.heading = face + math.rad(30)
                master.units[#master.units + 1] = copy
            end
        end

        do -- Truck
            local data = mist.getGroupData(list[7])
            data = data.units[1]
            local base = Translate(
                point, 50, math.rad(
                    heading - 90
                )
            )
            for i = 0, 3 do
                local copy = mist.utils.deepCopy(data)
                local trans = Translate(
                    base, (15 * i), math.rad(
                        heading - 180
                    )
                )
                copy.x = trans.x
                copy.y = trans.z
                copy.heading = math.rad(heading + 90)
                master.units[#master.units + 1] = copy
            end
        end

        -- Spawn
        local add = mist.dynAdd(master)
        return Group.getByName(add.name)
    end

    local function GetGrumble(point, list, heading)
        local master = mist.getGroupData(list[1])
        master.x = point.x
        master.y = point.z
        master.clone = true

        do -- Surveillance Radar
            local data = mist.utils.deepCopy(master.units[1])
            local trans = Translate(
                point, 250, math.rad(heading + 180)
            )
            data.x = trans.x
            data.y = trans.z
            data.heading = math.rad(heading + 90)
            master.units[1] = data
        end

        do -- Tracking Radar
            local data = mist.getGroupData(list[2])
            data = mist.utils.deepCopy(data.units[1])
            data.x = point.x
            data.y = point.z
            data.heading = math.rad(heading)
            master.units[2] = data
        end

        do -- Launcher
            local data = mist.getGroupData(list[3])
            data = data.units[1]
            local base = Translate(
                point, 150, math.rad(heading)
            )
            for i = 0, 3 do
                local copy = mist.utils.deepCopy(data)
                local trans = Translate(
                    base, ((50 * i) + 50), math.rad(
                        heading - 90
                    )
                )
                copy.x = trans.x
                copy.y = trans.z
                copy.heading = math.rad(heading)
                master.units[#master.units + 1] = copy
            end
            for i = 0, 3 do
                local copy = mist.utils.deepCopy(data)
                local trans = Translate(
                    base, ((50 * i) + 50), math.rad(
                        heading + 90
                    )
                )
                copy.x = trans.x
                copy.y = trans.z
                copy.heading = math.rad(heading)
                master.units[#master.units + 1] = copy
            end
        end

        do -- Contoller
            local data = mist.getGroupData(list[4])
            data = data.units[1]
            local copy = mist.utils.deepCopy(data)
            local trans = Translate(
                point, 275, math.rad(
                    heading - 135
                )
            )
            copy.x = trans.x
            copy.y = trans.z
            copy.heading = math.rad(heading + 45)
            master.units[#master.units + 1] = copy
        end

        do -- Tor
            local data = mist.getGroupData(list[5])
            data = data.units[1]
            for i = 0, 2 do
                local face = math.rad((120 * i) + heading)
                local copy = mist.utils.deepCopy(data)
                local trans = Translate(
                    point, 300, face
                )
                copy.x = trans.x
                copy.y = trans.z
                copy.heading = face
                master.units[#master.units + 1] = copy
            end
        end

        do -- Tunguska
            local data = mist.getGroupData(list[6])
            data = data.units[1]
            for i = 0, 3 do
                local face = math.rad((90 * i) + (heading + 45))
                local copy = mist.utils.deepCopy(data)
                local trans = Translate(
                    point, 300, face
                )
                copy.x = trans.x
                copy.y = trans.z
                copy.heading = face
                master.units[#master.units + 1] = copy
            end
        end

        do -- Truck
            local data = mist.getGroupData(list[7])
            data = data.units[1]
            local base = Translate(
                point, 100, math.rad(
                    heading + 135
                )
            )
            for i = 0, 5 do
                local copy = mist.utils.deepCopy(data)
                local trans = Translate(
                    base, (10 * i), math.rad(
                        heading + 90
                    )
                )
                copy.x = trans.x
                copy.y = trans.z
                copy.heading = math.rad(heading + 180)
                master.units[#master.units + 1] = copy
            end
        end

        -- Spawn
        local add = mist.dynAdd(master)
        return Group.getByName(add.name)
    end

    local function SetTarget(control)
        control:setOption(0, 2)
        control:setOption(8, false)
        control:setOption(9, 2)
        control:setOption(20, true)
        control:setOption(24, 100)
    end

    local function IsAlive(target)
        if target:isExist() == true then
            for index, unit in ipairs(target:getUnits()) do
                if unit:isExist() == true then
                    return true
                end
            end
        end
        return false
    end

    local function Assessment(gid, unit, target)
        timer.scheduleFunction(
            function(...)
                if IsAlive(target) == true then
                    return arg[2] + 1
                else
                    trigger.action.outTextForGroup(
                        gid, "Eliminated", 15, false
                    )
                    trigger.action.outSoundForGroup(
                        gid, "bell.ogg"
                    )
                    MIZ.Strike.Progress[gid] = nil
                    return nil
                end
            end, nil, timer.getTime() + 1
        )
    end

    MIZ.Strike["Initiate"] = function(gid, unit, zone, name, list)
        if Inspect(gid, unit) ~= true then
            return nil
        end

        -- Declare
        local point = mist.getRandomPointInZone(zone, nil)
        point = {
            x = point.x,
            z = point.y,
            y = land.getHeight(
                {
                    x = point.x,
                    y = point.y
                }
            )
        }
        local heading = HeadingTo(point, unit:getPoint())
        
        -- Spawn
        local target = nil
        if name == "SA-2 Dvina" then
            target = GetDvina(point, list, heading)
        elseif name == "SA-11 Buk" then
            target = GetBuk(point, list, heading)
        elseif name == "SA-10 Grumble" then
            target = GetGrumble(point, list, heading)
        end

        -- Setting
        SetTarget(target:getController())
        MIZ.Strike.Progress[gid] = target

        -- Assessment
        Assessment(gid, unit, target)

        do-- Messaging
            local text = string.format(
                name .. " Spawned at " .. zone
            )
            trigger.action.outTextForGroup(
                gid, text, 15, false
            )
            trigger.action.outSoundForGroup(
                gid, "beep.ogg"
            )
        end
    end

    MIZ.Strike["Reset"] = function(gid)
        if MIZ.Strike.Progress[gid] ~= nil then
            MIZ.Strike.Progress[gid]:destroy()
        else
            trigger.action.outTextForGroup(
                gid, "You Not Have Your Target", 15, false
            )
            trigger.action.outSoundForGroup(
                gid, "warn.wav"
            )
        end
    end

    MIZ.Strike["Erase"] = function(gid)
        for key, val in pairs(MIZ.Strike.Progress) do
            if MIZ.Strike.Progress[key] ~= nil then
                MIZ.Strike.Progress[key]:destroy()
            end
        end
        trigger.action.outTextForGroup(
            gid, "Erased", 15, false
        )
        trigger.action.outSoundForGroup(
            gid, "bell.ogg"
        )
    end
end

do -- Menu
    -- Combat
    MIZ.Menu[1] = function(gid, unit)
        local visual = {
            [1] = {"MSL: MiG-21", "RED_AIR_WVR_M21"},
            [2] = {"MSL: F-5E-3", "RED_AIR_WVR_F5E"},
            [3] = {"GUN: MiG-29", "RED_AIR_WVR_M29"},
            [4] = {"GUN: FA-18C", "RED_AIR_WVR_F18"}
        }
        
        local beyond = {
            [1] = {"AA10", "RED_AIR_BVR_A10"},
            [2] = {"AA12", "RED_AIR_BVR_A12"},
            [3] = {"120C", "RED_AIR_BVR_120"},
            [4] = {"SD10", "RED_AIR_BVR_S10"}
        }

        do -- Build Procedure
            local cmbt = missionCommands.addSubMenuForGroup(
                gid, "Combat", nil
            )

            local function GetDirection(gid, menu)
                return {
                    [1] = missionCommands.addSubMenuForGroup(
                        gid, "Front", menu
                    ),
                    [2] = missionCommands.addSubMenuForGroup(
                        gid, "Right", menu
                    ),
                    [3] = missionCommands.addSubMenuForGroup(
                        gid, "Behind", menu
                    ),
                    [4] = missionCommands.addSubMenuForGroup(
                        gid, "Left", menu
                    )
                }
            end

            do -- WVR
                local main = missionCommands.addSubMenuForGroup(
                    gid, "WVR", cmbt
                )
                local direction = GetDirection(
                    gid, main
                )
                local distance = nil
                for number, menu in ipairs(direction) do
                    if number == 3 then -- Behind
                        distance = 2778
                    else
                        distance = 27780
                    end
                    local radian = math.rad(90 * (number - 1))
                    for index, data in ipairs(visual) do
                        local type = missionCommands.addSubMenuForGroup(
                            gid, data[1], menu
                        )
                        for quantity = 1, 4 do
                            missionCommands.addCommandForGroup(
                                gid, quantity .. " Ship", type,
                                MIZ.Combat["Init"],
                                gid, unit, radian, distance, data[2], quantity
                            )
                        end
                    end
                end
            end

            do -- BVR
                local main = missionCommands.addSubMenuForGroup(
                    gid, "BVR", cmbt
                )
                local direction = GetDirection(
                    gid, main
                )
                for number, menu in ipairs(direction) do
                    local radian = math.rad(90 * (number - 1))
                    for index, data in ipairs(beyond) do
                        local type = missionCommands.addSubMenuForGroup(
                            gid, data[1], menu
                        )
                        for quantity = 1, 4 do
                            missionCommands.addCommandForGroup(
                                gid, quantity .. " Ship", type,
                                MIZ.Combat["Init"],
                                gid, unit, radian, 111120, data[2], quantity
                            )
                        end
                    end
                end
            end

            -- Abort Option
            missionCommands.addCommandForGroup(
                gid, "Abort", cmbt,
                MIZ.Combat["Abort"], gid
            )
        end
    end

    MIZ.Menu[2] = function(gid, unit)
        local main = missionCommands.addSubMenuForGroup(
            gid, "Strike", nil
        )
        for index, str in ipairs(MIZ.Zones[3]["zone"]) do
            local menu = missionCommands.addSubMenuForGroup(
                gid, str, main
            )
            for idx, data in ipairs(MIZ.Strike.Template) do
                missionCommands.addCommandForGroup(
                    gid, data.name, menu,
                    MIZ.Strike["Initiate"],
                    gid, unit, str, data.name, data.list
                )
            end
        end
        missionCommands.addCommandForGroup(
            gid, "Reset", main,
            MIZ.Strike["Reset"],
            gid
        )
        missionCommands.addCommandForGroup(
            gid, "Erase", main,
            MIZ.Strike["Erase"],
            gid
        )
    end

    MIZ.Menu[3] = function(gid, unit)
        local main = missionCommands.addSubMenuForGroup(
            gid, "Refuel", nil
        )
        missionCommands.addCommandForGroup(
            gid, "Call", main,
            MIZ.Refuel["Call"],
            gid, unit
        )
    end

    MIZ.Menu[4] = function(gid, unit)
        local main = missionCommands.addSubMenuForGroup(
            gid, "Inform", nil
        )
        for index, data in ipairs(MIZ.Zones) do
            local menu = missionCommands.addSubMenuForGroup(
                gid, data.name, main
            )
            for idx, str in ipairs(data.zone) do
                missionCommands.addCommandForGroup(
                    gid, str, menu,
                    MIZ.Inform["Show"],
                    gid, str
                )
            end
        end
    end

    --[[
    MIZ.Menu[#MIZ.Menu + 1] = function(gid, unit)
        missionCommands.addCommandForGroup(
            gid, "Debug", nil,
            function()
                env.info("Debug")
            end
        )
    end]]
end

do -- Event
    function MIZ.Event:onEvent(data)
        if data.id == 1 then -- Shot
            local desc = data.weapon:getDesc()
            local mcat = desc.missileCategory
            if mcat == 1 or mcat == 2 then -- AAM or SAM
                MIZ.Sensor:MissileTracking(data.weapon)
            end
            if MIZ.Blast.Switch == true and desc.category == 3 then -- Bomb for MIZ.Blast
                if desc.warhead.explosiveMass > 150 then
                    MIZ.Blast:Tracking(data.weapon)
                end
            end
            if desc.guidance == 5 then
                MIZ.Detect:Tracking(data.weapon)
            end
        end
        if data.id == 2 then -- Hit
            if data.target ~= nil and data.target:getCategory() == 1 then
                local target = data.target:getGroup()
                for index, group in ipairs(MIZ.Circle) do
                    if group == target then
                        local gid = data.initiator:getGroup():getID()
                        trigger.action.outTextForGroup(
                            gid, "Hit", 5, true
                        )
                        trigger.action.outSoundForGroup(
                            gid, "bell.ogg"
                        )
                        break
                    end
                end
                for index, group in ipairs(MIZ.Convoy) do
                    if group == target then
                        local gid = data.initiator:getGroup():getID()
                        trigger.action.outTextForGroup(
                            gid, "Hit", 5, true
                        )
                        trigger.action.outSoundForGroup(
                            gid, "bell.ogg"
                        )
                        break
                    end
                end
            end
        end
        if data.id == 6 then -- Eject
            local unit = data.initiator
            if unit:getCoalition() == 1 then
                timer.scheduleFunction(
                    function(...)
                        if unit:isExist() == true then
                            trigger.action.explosion(
                                unit:getPoint(),
                                100 -- Power
                            )
                        end
                        return nil
                    end, nil, timer.getTime() + 3
                )
            else
                unit:destroy()
            end
        end
        if data.id == 15 then -- Birth
            local unit = data.initiator
            local desc = unit:getDesc()
            env.info(desc.displayName)
            desc = desc.attributes
            if unit:getPlayerName() ~= nil and desc.Planes == true then
                local gid = unit:getGroup():getID()
                missionCommands.removeItemForGroup(gid, nil) -- Refresh
                for index, func in ipairs(MIZ.Menu) do
                    func(gid, unit)
                end
            end
        end
        if data.id == 23 then -- Cannon
            local unit = data.initiator
            local uid = unit:getID()
            if MIZ.Sensor.Progress[uid] == nil then
                world.searchObjects(
                    Object.Category.UNIT,
                    {
                        id = world.VolumeType.SPHERE,
                        params = {
                            point = unit:getPoint(),
                            radius = 1852
                        }
                    },
                    function(found)
                        if found:getPlayerName() ~= nil and found ~= unit then
                            MIZ.Sensor:CannonFire(found, uid)
                            MIZ.Sensor.Progress[uid] = true
                        end
                    end
                )
            end
        end
        if data.id == 31 then -- Ejected Pilot
            data.initiator:destroy()
        end
    end

    -- Handling
    world.addEventHandler(MIZ.Event)
end

do -- Export User Defined Common Waypoint
    local address = env.mission.coalition.blue
    local waypoints = {
        ["F-16C_50"] = {
            [1] = "WP001",
            [2] = "WP002",
            [3] = "WP003",
            [4] = "WP004",
            [5] = "WP005",
            [6] = "WP006",
            [7] = "WP007",
            [8] = "WP008",
            [9] = "WP009",
            [10] = "WP010",
            [11] = "WP009",
            [12] = "WP008",
            [13] = "WP007",
            [14] = "WP006",
            [15] = "WP005",
            [16] = "WP004",
            [17] = "CC001",
            [18] = "WP004",
            [19] = "CC002",
            [20] = "WP004",
            [21] = "CV001",
            [22] = "WP004",
            [23] = "CV002",
            [24] = "WP004",
            [25] = "WP003",
            [26] = "WP002",
            [27] = "WP001",
            [28] = "ST001",
            [29] = "ST002",
            [30] = "ST003"
        }
    }

    local function Inserting(table)
        for cid, cdata in ipairs(table.country) do
            for gid, gdata in ipairs(cdata.plane.group) do
                if gdata.units[1].skill == "Client" then
                    local array = waypoints[gdata.units[1].type]
                    if array ~= nil then
                        for zid, zone in ipairs(mist.DBs.zonesByNum) do
                            for wid, wdata in ipairs(array) do
                                if zone.name == wdata then
                                    local pdata = gdata.route.points
                                    pdata[wid + 1] = mist.fixedWing.buildWP(
                                        zone.point, "Turning Point", 0, 0, "BARO"
                                    )
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local function Exporting()
        Inserting(address)
        local serial = mist.utils.serialize("blue", address)
        if lfs and io then
            local path = lfs.writedir() .. "/Missions/miho_mission.lua"
            local file = io.open(path, "w")
            file:write(serial)
            file:close()
        end
    end

    -- Run
    -- Exporting()
end