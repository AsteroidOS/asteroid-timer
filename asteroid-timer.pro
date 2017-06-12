TARGET = asteroid-timer
CONFIG += asteroidapp

SOURCES +=     main.cpp systemdtimer.cpp
HEADERS +=     systemdtimer.h
RESOURCES +=   resources.qrc
OTHER_FILES += main.qml

lupdate_only{ SOURCES = i18n/$$TARGET.desktop.h }
TRANSLATIONS = $$files(i18n/$$TARGET.*.ts)
