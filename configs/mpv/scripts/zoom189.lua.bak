-- zoom189.lua
-- Applica automaticamente uno zoom 1.125x ai video 16:9 per un formato 18:9

mp.observe_property("video-params/aspect", "number", function(name, aspect)
    if aspect == nil then return end

    -- Se l'aspect ratio corrisponde al 16:9 (tra 1.77 e 1.78)
    if aspect >= 1.77 and aspect <= 1.78 then
        -- MpV usa il logaritmo in base 2 per lo zoom. Log2(1.125) = 0.169925
        mp.set_property("video-zoom", "0.169925")
        mp.msg.info("Rilevato video 16:9. Applico lo zoom per il 18:9.")
    else
        -- Rimette lo zoom a zero per i film nativi in 21:9 o altri formati
        mp.set_property("video-zoom", "0")
    end
end)
