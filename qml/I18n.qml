pragma Singleton
import QtQuick

// English is the default; Russian is complete. Bindings that call t() re-evaluate when
// `language` changes because the lookup reads it.
QtObject {
    id: i18n
    property string language: "en"
    readonly property var locale: Qt.locale(language === "ru" ? "ru_RU" : "en_US")

    readonly property var en: ({
        "app": "Fake Clicker",
        "target": "Window", "target.any": "Any window", "target.title": "Choose a window", "target.refresh": "Refresh",
        "msg.targetGone": "The chosen window was closed", "msg.targetNotFront": "Bring the chosen window to the front",
        "nav.clicker": "Clicker", "nav.hotkeys": "Hotkeys", "nav.profiles": "Profiles", "nav.settings": "Settings",
        "mode": "Mode", "mode.legit": "Legit", "mode.blatant": "Blatant",
        "mode.legit.note": "Human-like rhythm", "mode.blatant.note": "Exact rate, no cap",
        "section.rate": "Rate", "section.options": "Options", "section.session": "Session",
        "cps": "CPS", "cps.title": "Clicks per second", "cps.custom": "Custom",
        "button": "Button", "button.0": "Left", "button.1": "Right", "button.2": "Middle",
        "variance": "Variance", "variance.0": "Tight", "variance.1": "Natural", "variance.2": "Loose",
        "hold": "Hold", "hold.instant": "Instant", "ms": "ms", "sec": "s",
        "limits": "Stop after", "limit.time": "Time limit", "limit.clicks": "Click limit", "limit.none": "No limit",
        "start": "Start", "stop": "Stop", "cancel": "Cancel",
        "state.idle": "Ready", "state.arming": "Starting", "state.running": "Running", "state.stopping": "Stopping",
        "live.clicks": "Clicks", "live.time": "Time", "live.average": "Average", 
        "keys.start": "Start", "keys.stop": "Stop", "keys.countdown": "Countdown", "keys.reset": "Reset",
        "keys.add": "Add shortcut", "keys.remove": "Remove shortcut",
        "sheet.single": "Single key", "sheet.combo": "Combination", "sheet.default": "Default",
        "sheet.apply": "Apply", "sheet.empty": "Press keys",
        "profiles.search": "Search", "profiles.save": "Save current", "profiles.import": "Import",
        "profiles.export": "Export", "profiles.folder": "Open folder", "profiles.apply": "Apply",
        "profiles.rename": "Rename", "profiles.duplicate": "Duplicate", "profiles.delete": "Delete",
        "profiles.active": "Active", "profiles.invalid": "Invalid", "profiles.empty": "No profiles yet",
        "profiles.noResults": "Nothing found", "profiles.name": "Name",
        "profiles.saveTitle": "Save profile", "profiles.renameTitle": "Rename profile",
        "profiles.deleteTitle": "Delete this profile?", "profiles.filter": "JSON profile (*.json)",
        "profiles.save.short": "Save",
        "look.island": "Island over other windows", "on": "On", "off": "Off",
        "settings.language": "Language", "settings.island": "Island", "settings.about": "About",
        "settings.sound": "Sound", "sound.effects": "Interface sounds", "sound.volume": "Volume",
        "settings.window": "Window", "look.frame": "Standard Windows title bar",
        "about.version": "Version", "about.build": "Windows 10/11 · x64",
        "win.minimize": "Minimize", "win.maximize": "Maximize", "win.restore": "Restore", "win.close": "Close",
        "boot.failed": "Couldn't start", "boot.retry": "Retry", "boot.loading": "Loading", "dismiss": "Dismiss",
        "lang.en": "English", "lang.ru": "Russian",

        "msg.savedRejected": "Saved settings were rejected", "msg.keyboardUnavailable": "Keyboard input is unavailable",
        "msg.stopFirst": "Stop clicking before changing settings",
        "msg.noTarget": "Switch to the target window before the countdown ends",
        "msg.noCounter": "High-resolution timer unavailable", "msg.noTimer": "Couldn't create a timer",
        "msg.timerFailed": "Timer error", "msg.focusLost": "Stopped: the window lost focus",
        "msg.noCursor": "Cursor position unavailable", "msg.cursorOutside": "Stopped: cursor left the window",
        "msg.buttonHeld": "Stopped: the mouse button is already held",
        "msg.inputRejected": "Windows rejected the input", "msg.pressRejected": "Windows rejected the press",
        "msg.releaseRejected": "Windows rejected the release", "msg.holdTimerFailed": "Hold timer error",
        "msg.windowsOnly": "Clicking works on Windows only",
        "msg.outOfRange": "Value out of range", "msg.holdTooLong": "Hold must be shorter than the click interval",
        "msg.tooManyBindings": "Up to eight shortcuts per action", "msg.legacyBinding": "Invalid legacy shortcut",
        "msg.chordSize": "Use one to three keys", "msg.badKey": "Unsupported or repeated key",
        "msg.reserved": "Reserved by Windows", "msg.overlap": "Already used or overlaps another shortcut",
        "msg.unsupportedKey": "Key not supported", "msg.sameStartStop": "Start and stop must differ",
        "msg.schema": "Unknown profile format", "msg.unknownField": "Unknown field: %1",
        "msg.notInteger": "Invalid value: %1", "msg.notNumber": "Invalid number: %1",
        "msg.badDelay": "Countdown must be 1–10 s", "msg.badBindingList": "Invalid shortcut list",
        "msg.badBinding": "Invalid shortcut", "msg.badKeySet": "Invalid key set",
        "msg.bindingsChanged": "Shortcuts changed, reopen the editor",
        "msg.legacyChordTooLong": "Old shortcut has more than three keys", "msg.maxThreeKeys": "Up to three keys",
        "msg.folderUnavailable": "Profiles folder unavailable", "msg.fileTooLarge": "File is missing or larger than 64 KB",
        "msg.badJson": "Invalid JSON", "msg.badName": "Name must be 1–64 characters",
        "msg.saveFailed": "Couldn't save", "msg.saved": "Profile saved", "msg.readFailed": "Couldn't read profile",
        "msg.duplicated": "Duplicated", "msg.notFound": "File not found", "msg.applied": "Applied · %1",
        "msg.deleteFailed": "Couldn't delete", "msg.deleted": "Profile deleted", "msg.renameFailed": "Couldn't rename",
        "msg.renamed": "Renamed", "msg.localJsonOnly": "Choose a local .json file", "msg.imported": "Imported",
        "msg.exported": "Exported", "msg.exportFailed": "Couldn't export",
        "msg.settingsFolder": "Settings folder unavailable"
    })

    readonly property var ru: ({
        "app": "Fake Clicker",
        "target": "Окно", "target.any": "Любое окно", "target.title": "Выберите окно", "target.refresh": "Обновить",
        "msg.targetGone": "Выбранное окно закрыто", "msg.targetNotFront": "Выведите выбранное окно на передний план",
        "nav.clicker": "Кликер", "nav.hotkeys": "Клавиши", "nav.profiles": "Профили", "nav.settings": "Настройки",
        "mode": "Режим", "mode.legit": "Легит", "mode.blatant": "Блатант",
        "mode.legit.note": "Ритм как у человека", "mode.blatant.note": "Точно и без лимита",
        "section.rate": "Скорость", "section.options": "Параметры", "section.session": "Сессия",
        "cps": "CPS", "cps.title": "Кликов в секунду", "cps.custom": "Своё",
        "button": "Кнопка", "button.0": "Левая", "button.1": "Правая", "button.2": "Средняя",
        "variance": "Разброс", "variance.0": "Узкий", "variance.1": "Живой", "variance.2": "Широкий",
        "hold": "Удержание", "hold.instant": "Мгновенно", "ms": "мс", "sec": "с",
        "limits": "Остановить после", "limit.time": "Лимит времени", "limit.clicks": "Лимит кликов", "limit.none": "Без лимита",
        "start": "Запустить", "stop": "Остановить", "cancel": "Отмена",
        "state.idle": "Готов", "state.arming": "Запуск", "state.running": "Работает", "state.stopping": "Остановка",
        "live.clicks": "Клики", "live.time": "Время", "live.average": "Среднее", 
        "keys.start": "Запуск", "keys.stop": "Остановка", "keys.countdown": "Отсчёт", "keys.reset": "Сбросить",
        "keys.add": "Добавить сочетание", "keys.remove": "Удалить сочетание",
        "sheet.single": "Одна клавиша", "sheet.combo": "Сочетание", "sheet.default": "По умолчанию",
        "sheet.apply": "Применить", "sheet.empty": "Нажмите клавиши",
        "profiles.search": "Поиск", "profiles.save": "Сохранить текущий", "profiles.import": "Импорт",
        "profiles.export": "Экспорт", "profiles.folder": "Открыть папку", "profiles.apply": "Применить",
        "profiles.rename": "Переименовать", "profiles.duplicate": "Дублировать", "profiles.delete": "Удалить",
        "profiles.active": "Активен", "profiles.invalid": "Ошибка", "profiles.empty": "Профилей пока нет",
        "profiles.noResults": "Ничего не найдено", "profiles.name": "Название",
        "profiles.saveTitle": "Сохранить профиль", "profiles.renameTitle": "Переименовать профиль",
        "profiles.deleteTitle": "Удалить профиль?", "profiles.filter": "Профиль JSON (*.json)",
        "profiles.save.short": "Сохранить",
        "look.island": "Остров поверх окон", "on": "Вкл", "off": "Выкл",
        "settings.language": "Язык", "settings.island": "Остров", "settings.about": "О приложении",
        "settings.sound": "Звук", "sound.effects": "Звуки интерфейса", "sound.volume": "Громкость",
        "settings.window": "Окно", "look.frame": "Обычный заголовок Windows",
        "about.version": "Версия", "about.build": "Windows 10/11 · x64",
        "win.minimize": "Свернуть", "win.maximize": "Развернуть", "win.restore": "Восстановить", "win.close": "Закрыть",
        "boot.failed": "Не удалось запустить", "boot.retry": "Повторить", "boot.loading": "Загрузка", "dismiss": "Скрыть",
        "lang.en": "Английский", "lang.ru": "Русский",

        "msg.savedRejected": "Сохранённые настройки отклонены", "msg.keyboardUnavailable": "Ввод с клавиатуры недоступен",
        "msg.stopFirst": "Остановите клики перед изменением настроек",
        "msg.noTarget": "Перейдите в нужное окно до конца отсчёта",
        "msg.noCounter": "Высокоточный таймер недоступен", "msg.noTimer": "Не удалось создать таймер",
        "msg.timerFailed": "Ошибка таймера", "msg.focusLost": "Остановлено: окно потеряло фокус",
        "msg.noCursor": "Позиция курсора недоступна", "msg.cursorOutside": "Остановлено: курсор вне окна",
        "msg.buttonHeld": "Остановлено: кнопка мыши уже зажата",
        "msg.inputRejected": "Windows отклонила ввод", "msg.pressRejected": "Windows отклонила нажатие",
        "msg.releaseRejected": "Windows отклонила отпускание", "msg.holdTimerFailed": "Ошибка таймера удержания",
        "msg.windowsOnly": "Клики работают только в Windows",
        "msg.outOfRange": "Значение вне диапазона", "msg.holdTooLong": "Удержание должно быть короче интервала",
        "msg.tooManyBindings": "Не больше восьми сочетаний", "msg.legacyBinding": "Некорректное старое сочетание",
        "msg.chordSize": "От одной до трёх клавиш", "msg.badKey": "Клавиша не поддерживается или повторяется",
        "msg.reserved": "Зарезервировано Windows", "msg.overlap": "Уже занято или пересекается с другим",
        "msg.unsupportedKey": "Клавиша не поддерживается", "msg.sameStartStop": "Запуск и остановка должны различаться",
        "msg.schema": "Неизвестный формат профиля", "msg.unknownField": "Неизвестное поле: %1",
        "msg.notInteger": "Некорректное значение: %1", "msg.notNumber": "Некорректное число: %1",
        "msg.badDelay": "Отсчёт — от 1 до 10 с", "msg.badBindingList": "Некорректный список сочетаний",
        "msg.badBinding": "Некорректное сочетание", "msg.badKeySet": "Некорректный набор клавиш",
        "msg.bindingsChanged": "Сочетания изменились, откройте редактор заново",
        "msg.legacyChordTooLong": "В старом сочетании больше трёх клавиш", "msg.maxThreeKeys": "Не больше трёх клавиш",
        "msg.folderUnavailable": "Папка профилей недоступна", "msg.fileTooLarge": "Файл недоступен или больше 64 КБ",
        "msg.badJson": "Некорректный JSON", "msg.badName": "Название — от 1 до 64 символов",
        "msg.saveFailed": "Не удалось сохранить", "msg.saved": "Профиль сохранён", "msg.readFailed": "Не удалось прочитать профиль",
        "msg.duplicated": "Копия создана", "msg.notFound": "Файл не найден", "msg.applied": "Применён · %1",
        "msg.deleteFailed": "Не удалось удалить", "msg.deleted": "Профиль удалён", "msg.renameFailed": "Не удалось переименовать",
        "msg.renamed": "Переименовано", "msg.localJsonOnly": "Выберите локальный файл .json", "msg.imported": "Импортировано",
        "msg.exported": "Экспортировано", "msg.exportFailed": "Не удалось экспортировать",
        "msg.settingsFolder": "Папка настроек недоступна"
    })

    function t(key) {
        const table = language === "ru" ? ru : en;
        const value = table[key];
        return value !== undefined ? value : (en[key] !== undefined ? en[key] : key);
    }
    // Backend messages are "code" or "code:argument"; nested codes in the argument are translated too.
    function msg(code) {
        if (!code)
            return "";
        const split = code.indexOf(":");
        const key = split < 0 ? code : code.slice(0, split);
        let arg = split < 0 ? "" : code.slice(split + 1);
        if (arg !== "" && (language === "ru" ? ru : en)["msg." + arg.split(":")[0]] !== undefined)
            arg = msg(arg);
        const text = t("msg." + key);
        if (text === "msg." + key)
            return code;
        return split < 0 ? text : (text.indexOf("%1") >= 0 ? text.replace("%1", arg) : text + " · " + arg);
    }
    function number(value, decimals) { return Number(value).toLocaleString(locale, 'f', decimals); }
    // Compact rate: whole numbers stay whole, fractions keep up to two decimals.
    function rate(value) {
        if (value < 0 || !isFinite(value))
            return "—";
        const rounded = Math.round(value * 100) / 100;
        const decimals = Math.abs(rounded - Math.round(rounded)) < 0.005 ? 0 : (Math.abs(rounded * 10 - Math.round(rounded * 10)) < 0.05 ? 1 : 2);
        return number(rounded, decimals);
    }
    function duration(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        const m = Math.floor(s / 60), h = Math.floor(m / 60);
        const pad = v => (v < 10 ? "0" : "") + v;
        return h > 0 ? h + ":" + pad(m % 60) + ":" + pad(s % 60) : m + ":" + pad(s % 60);
    }
}
