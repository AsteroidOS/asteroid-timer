TEMPLATE = app
QT += widgets qml quick
CONFIG += link_pkgconfig
PKGCONFIG += qdeclarative5-boostable

SOURCES +=     main.cpp
RESOURCES +=   resources.qrc
OTHER_FILES += main.qml

TARGET = asteroid-timer
target.path = /usr/bin/

desktop.files = asteroid-timer.desktop
desktop.path = /usr/share/applications

INSTALLS += target desktop
