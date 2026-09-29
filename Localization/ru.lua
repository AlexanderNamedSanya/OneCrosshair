local strings = {
    PRESET_DOT = "Точка", NORMAL = "Обычный", TARGET = "Цель", BLOCK = "Блок",
    CROSSHAIR = "Прицел", PRESET = "Пресет", APPEARANCE = "Внешний вид",
    CROSSHAIR_OPACITY = "Непрозрачность прицела", HUD_OPACITY = "Непрозрачность HUD", HUD = "HUD",
    RESOURCES = "Ресурсы", GCD = "Глобальная перезарядка", VISIBILITY = "Видимость",
    ALWAYS = "Всегда", COMBAT_ONLY = "Только в бою", DYNAMIC = "Динамически", OFF = "Выключено",
    EFFECTS = "Эффекты", LOW_RESOURCE = "Предупреждение о низком ресурсе", CRITICAL_STATE = "Критическое состояние",
    SHIELD = "Щит", HEAVY_CHANNEL = "Прогресс тяжёлой / поддерживаемой атаки", COMBAT_FEEDBACK = "Отклик на атаку",
    TIMING_LIMITATION = "Пока недоступно: для этой версии API не подтверждён надёжный источник времени и отмены тяжёлой атаки / поддерживаемой способности.",
}
for key, value in pairs(strings) do SafeAddString(_G["SI_ONECROSSHAIR_" .. key], value, 1) end
