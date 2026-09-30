# OneCrosshair 1.0 — publication package

Author: **oneDOK**. Required library: **LibAddonMenu-2.0** (install separately). Manifest API: **101051**. Archive: `dist/OneCrosshair-1.0.zip`; checksum: `dist/OneCrosshair-1.0.zip.sha256`. Prepared locally; not uploaded.

## English description

OneCrosshair brings your crosshair and essential combat information together near the center of the screen.

Choose from five presets: Dot, Large Dots, Rays, Diamonds, or the original ESO crosshair. Custom presets animate between normal, target and block states. Rays open into triangular corners when targeting and rearrange when blocking. Crosshairs turn red in combat, including the original ESO preset.

The surrounding bars show Health, Magicka and Stamina, with an optional shield overlay and outward low-resource warnings. The bottom bar displays GCD, Heavy Attack and finite cast/channel progress. Its green cue helps time your next Light Attack using a capped latency estimate.

Includes English and Russian translations, account-wide preferences and a live settings preview of the enabled bars. Preset, visibility and feature switches are available in-game. Appearance sliders are absent in 1.0; advanced users can edit the commented Core/Config.lua values and reload the interface.

Install LibAddonMenu-2.0, extract the OneCrosshair folder into live/AddOns and run /reloadui. No other combat addon is required.

The green timing cue is a heuristic, not a guaranteed action queue window. Unknown and indefinite channels cannot provide a finite completion cue.

## Русское описание

OneCrosshair объединяет прицел и основные боевые индикаторы в центре экрана.

Пять пресетов: Точка, Крупные точки, Лучи, Ромбы и Стандартный ESO. Пользовательские прицелы плавно меняются при наведении и блокировании. Лучи раскрываются в уголки и перестраиваются в перевёрнутый треугольник при блоке. В бою прицел становится красным, включая штатный вариант ESO.

Полоски показывают здоровье, магию, запас сил и щит. При низком ресурсе вся соответствующая дуга подсвечивается наружу. Нижняя полоска показывает GCD, тяжёлые атаки и конечные касты/каналы; зелёный цвет подсказывает момент следующей лёгкой атаки с учётом задержки.

Есть русский и английский интерфейс, настройки на аккаунт и превью с включёнными полосками. Выбор пресета, режима видимости и функций доступен в игре. Геометрия и прозрачность зафиксированы для версии 1.0; ручные изменения доступны в Core/Config.lua с комментариями.

Требуется LibAddonMenu-2.0. Распакуйте папку OneCrosshair в live/AddOns и выполните /reloadui. Подсказка тайминга основана на оценке задержки и не гарантирует принятие действия сервером.

## Changelog 1.0

- First publication release, author oneDOK.
- Dot and Large Dots reduced to half their previous diameter; small-dot spacing increased 25%.
- Captured appearance: arc length 90%, radius 45.25, thickness 5, custom crosshair opacity 65%, HUD opacity 50%.
- Five appearance controls removed from the in-game settings; manual values documented in Core/Config.lua.
- Combat color added to the native ESO crosshair with cleanup on UI/preset changes.
- Existing five presets, animations, resource warnings and weaving timing retained.

## Validation before upload

Automated checks pass (87 behavior scenarios, seven locales, API symbols); ZIP entries are compared byte-for-byte with runtime source. In-game final smoke test: reload, all five presets, target/block animations, both dot sizes, native combat entry/exit and hit, menus/stealth, absence of sliders, bars and GCD/channel cue. The ZIP excludes development tools, reference addons, dependencies and SavedVariables. Capture gameplay screenshots for the publication page after the client check; offline mock images are not gameplay evidence.
