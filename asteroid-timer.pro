TARGET = asteroid-timer
CONFIG += asteroidapp

SOURCES +=     main.cpp
RESOURCES +=   resources.qrc
OTHER_FILES += main.qml

lupdate_only{ SOURCES += i18n/asteroid-timer.desktop.h }
TRANSLATIONS = $$files(i18n/$$TARGET.*.ts)
