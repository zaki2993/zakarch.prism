# Prism

Window border studio for Omarchy and Hyprland: gradients, motion and focus effects
that run in the compositor, set from one panel in your bar.

## Features

- **Live strip**: the panel's top strip is drawn with your current border, including
  its gradient, spin, breathing and glow. It lists the effects that are on, and it turns
  into a Resume button while Prism is paused.
- **Effects that run in Hyprland**:
  - **Spin**: the gradient rotates around the focused window (`borderangle` loop)
  - **Glow**: a palette-tinted shadow halo that follows palette changes
  - **Breathe**: the border and its halo slowly pulse
  - **Color morph**: palette changes blend instead of snapping
  - **Focus**: dim unfocused windows and lower their opacity
- **Corner shapes**: **Facet** cuts a straight triangle off each corner, **Round** is classic
  (Hyprland `rounding_power` 1 / 2). With Facet, **every bar plugin's popup** gets the same cut
  corners, including built-in panels and plugins you install later. Prism finds them at runtime
  (`FacetInjector.qml`) and masks their corners without changing their code. Switching back to
  Round or pausing restores them exactly.
- **Gradient angle dial**: drag the ring or pick a preset.
- **28 palettes**, including Rosé Pine, Catppuccin, Tokyo Night, Nord, Dracula, Gruvbox,
  Everforest, Kanagawa, Vaporwave and Champagne, plus **Theme**, which follows your Omarchy theme live.
- **Mix your own**: start from any palette, then tune each of the three stops with hue,
  saturation and lightness sliders.
- **Favorites** (the ☆ on a palette card) and **auto-cycle**, in order or shuffled,
  through all palettes or only your favorites.
- **Looks**: 10 curated looks (Prism, Rosé Dawn, Crystal Facet, Neon Circuit, Midnight Tokyo,
  Nordic Calm, Ember Hearth, Champagne, Deep Focus, Dracula Noir), each tagged with its effects; save your own and recall them in one click.
- **Undo**, **shuffle** and **pause** buttons in the header. Pausing hands the borders back to your theme.
- **Shell surfaces follow**: plugin popups and notifications always use the border palette and width.
- Every change goes to Hyprland as one atomic `hyprctl eval`, so a slider drag never leaves
  the compositor half-configured.

## Install

```bash
omarchy plugin add https://github.com/zaki2993/zakarch.prism --enable
```

## Remove

```bash
omarchy plugin remove zakarch.prism
hyprctl reload
```

## Files

- `Engine.js`: palettes, looks, color math and Lua generation (pure, tested by `node check.js`)
- `Service.qml`: state, persistence, timers and Hyprland IPC
- `Panel.qml`: bar icon and studio popup
- `FacetInjector.qml`: applies Facet corners to every bar popup
- `PrismFrame.qml`, `PrismSlider.qml`, `PrismIcon.qml`, `AngleDial.qml`, `GradientSlider.qml`, `Segmented.qml`: UI pieces
- State: `~/.local/state/omarchy/zakarch.prism/settings.json`

Note: Spin keeps the compositor redrawing the focused border, so it uses a little more GPU.
