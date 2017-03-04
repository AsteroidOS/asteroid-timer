TEMPLATE = app
QT += qml quick
CONFIG += link_pkgconfig
PKGCONFIG += qdeclarative5-boostable

SOURCES +=     main.cpp
RESOURCES +=   resources.qrc
OTHER_FILES += main.qml

lupdate_only{
    SOURCES = i18n/asteroid-timer.desktop.h
}

# Needed for lupdate
TRANSLATIONS = i18n/asteroid-timer.de.ts \
               i18n/asteroid-timer.es.ts \
               i18n/asteroid-timer.fa.ts \
               i18n/asteroid-timer.fr.ts \
               i18n/asteroid-timer.ko.ts \
               i18n/asteroid-timer.nl.ts \
               i18n/asteroid-timer.pl.ts \
               i18n/asteroid-timer.pt_BR.ts \
               i18n/asteroid-timer.ru.ts \
               i18n/asteroid-timer.sv.ts \
               i18n/asteroid-timer.uk.ts

TARGET = asteroid-timer
target.path = /usr/bin/

desktop.commands = bash $$PWD/i18n/generate-desktop.sh $$PWD asteroid-timer.desktop
desktop.files = $$OUT_PWD/asteroid-timer.desktop
desktop.path = /usr/share/applications
desktop.CONFIG = no_check_exist

INSTALLS += target desktop
