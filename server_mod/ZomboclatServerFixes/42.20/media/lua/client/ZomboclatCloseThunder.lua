-- Project Zomboid's built-in `lightning` command transmits
-- strike=false, lightning=true, rumble=true. The flash and distant rumble are
-- rendered by the game, but the close `Thunder` sound is gated by strike=true.
-- Add only that missing sound and leave real strike events untouched.

ZomboclatCloseThunder = ZomboclatCloseThunder or {}

if not ZomboclatCloseThunder.registered then
    ZomboclatCloseThunder.registered = true
    ZomboclatCloseThunder.pending = ZomboclatCloseThunder.pending or {}

    local function nearestPlayerDistance(x, y)
        local nearest = 10000

        for playerIndex = 0, getNumActivePlayers() - 1 do
            local player = getSpecificPlayer(playerIndex)
            if player then
                local dx = player:getX() - x
                local dy = player:getY() - y
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance < nearest then
                    nearest = distance
                end
            end
        end

        return nearest
    end

    local function onThunderEvent(x, y, strike, lightning, _rumble)
        if strike or not lightning then
            return
        end

        local distance = nearestPlayerDistance(x, y)
        if distance >= 10000 then
            return
        end

        -- Vanilla delays thunder by roughly one real second per 300 tiles.
        local delayMs = math.floor((distance / 300) * 1000)
        table.insert(ZomboclatCloseThunder.pending, {
            playAt = getTimestampMs() + delayMs,
            x = math.floor(x),
            y = math.floor(y),
        })
    end

    local function onTick()
        local now = getTimestampMs()

        for index = #ZomboclatCloseThunder.pending, 1, -1 do
            local event = ZomboclatCloseThunder.pending[index]
            if now >= event.playAt then
                getSoundManager():PlayWorldSoundImpl(
                    "Thunder",
                    false,
                    event.x,
                    event.y,
                    100,
                    0,
                    0,
                    1,
                    false
                )
                table.remove(ZomboclatCloseThunder.pending, index)
            end
        end
    end

    Events.OnThunderEvent.Add(onThunderEvent)
    Events.OnTick.Add(onTick)
    print("[ZomboclatServerFixes] Close thunder enhancer loaded")
end
