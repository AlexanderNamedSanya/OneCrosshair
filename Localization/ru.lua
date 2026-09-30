local strings = {
    PRESET_DOT = "Точка", NORMAL = "Обычный", TARGET = "Цель", BLOCK = "Блок",
    CROSSHAIR = "Прицел", PRESET = "Пресет", APPEARANCE = "Внешний вид",
    CROSSHAIR_OPACITY = "Непрозрачность прицела", HUD_OPACITY = "Непрозрачность HUD", HUD = "HUD",
    RESOURCES = "Ресурсы", GCD = "Глобальная перезарядка", VISIBILITY = "Видимость",
    ALWAYS = "Всегда", COMBAT_ONLY = "Только в бою", DYNAMIC = "Динамически", OFF = "Выключено",
    EFFECTS = "Эффекты", LOW_RESOURCE = "Предупреждение о низком ресурсе", CRITICAL_STATE = "Критическое состояние",
    SHIELD = "Щит", HEAVY_CHANNEL = "Прогресс тяжёлой / поддерживаемой атаки", COMBAT_FEEDBACK = "Отклик на атаку",
    TIMING_DESCRIPTION = "Показывает расчётный прогресс тяжёлой атаки, произнесения и поддержания способности. При отмене возвращается текущий GCD. Для некоторых особых способностей события времени могут быть ненадёжны.",
}
for key, value in pairs(strings) do SafeAddString(_G["SI_ONECROSSHAIR_" .. key], value, 1) end
