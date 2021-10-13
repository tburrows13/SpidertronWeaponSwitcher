Spidertron Weapon Switcher
==================

If you've been wanting your spidertrons to fire more than just rockets, this is the mod for you! They now contain machine guns, shotguns, flamethrowers, cannons and rocket launchers.

![Demonstration gif](https://i.imgur.com/hdvItFc.gif)

-----
Features
-----

- Press *Control + Tab* (or *\\* ) whilst in a spidertron or whilst hovering over one with the mouse to rotate through 5 different weapon options
- Machine gun, shotgun, cannon and flamethrower have all been given their own 'spidertron version' with increased range and damage compared to normal
- Supports MK2 & MK3 spidertrons from [Spidertron Extended](https://mods.factorio.com/mod/spidertron-extended) and spiderling from [Spidertron Patrols](https://mods.factorio.com/mod/SpidertronPatrols)

-----
Limitations
-----

- When you switch a spidertron's weapons, any remotes connected to it that are stored in an inventory more than 30 tiles from a player will become disconnected
- Compatibility with [Spidertron Enhancements](https://mods.factorio.com/mod/SpidertronEnhancements) is limited. Specifically, any ammo in inactive weapon slots is lost when using that mod's enter/exit vehicles feature 

-----
Translation
-----

You can help by translating this mod into your language using [CrowdIn](https://crowdin.com/project/factorio-mods-localization). Any translations made will be included in the next release.

-----
Mod Compatibility
-----
When a spidertron is switched, the entity is destroyed and replaced with a new one that has different weapons. If your mod stores references to spidertrons, then these references will become invalid after a switch. This mod adds the event `on_spidertron_switched` containing `old_spidertron` :: LuaEntity and `new_spidertron` :: LuaEntity that will allow you to transfer information associated with the old spidertron's unit number to the new spidertron.
```
if game.active_mods["SpidertronWeaponSwitcher"] then
    local event_ids = remote.call("SpidertronWeaponSwitcher", "get_events")
    local on_spidertron_switched = event_ids.on_spidertron_switched
    script.on_event(on_spidertron_switched, function(event)
        -- Do stuff here
    end)
end
```

Let me know if you plan on using this and I can help you with debugging or adding new features if you need them.

-----

If you have specific weapons from other mods that you'd like added into the weapon rotation, let me know!
Check out my other mods: [Spidertron Patrols](https://mods.factorio.com/mod/SpidertronPatrols) and [Spidertron Enhancements](https://mods.factorio.com/mod/SpidertronEnhancements)