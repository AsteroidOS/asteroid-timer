/*
 * Copyright (C) 2017 - Florent Revest <revestflo@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "systemdtimer.h"

#include <QDBusInterface>
#include <QDateTime>
#include <QDBusMetaType>
#include <QProcessEnvironment>
#include <time.h>

#define SYSTEMD_SERVICE_NAME     "org.freedesktop.systemd1"
#define SYSTEMD_PATH_BASE        "/org/freedesktop/systemd1"
#define ASTEROID_TIMER_PATH_BASE "/org/freedesktop/systemd1/unit/asteroid_2dtimer_2etimer"
#define ASTEROID_SERV_PATH_BASE  "/org/freedesktop/systemd1/unit/asteroid_2dtimer_2eservice"
#define SYSTEMD_MANAGER_IFACE    "org.freedesktop.systemd1.Manager"
#define SYSTEMD_TIMER_IFACE      "org.freedesktop.systemd1.Timer"
#define SYSTEMD_UNIT_IFACE       "org.freedesktop.systemd1.Unit"
#define DBUS_PROPERTIES_IFACE    "org.freedesktop.DBus.Properties"

struct property {
    QString name;
    QVariant value;
};

struct additionalService {
    QString service;
    QList<struct property> properties;
};

struct startCommand {
    QString name;
    QStringList args;
    bool failure;
};

SystemdTimer::SystemdTimer(bool startElapsed, QObject *parent) : QObject(parent), m_running(false), m_nextElapse(0)
{
    qDBusRegisterMetaType<struct property>();
    qDBusRegisterMetaType<QList<struct property> >();
    qDBusRegisterMetaType<struct additionalService>();
    qDBusRegisterMetaType<QList<struct additionalService> >();
    qDBusRegisterMetaType<struct startCommand>();
    qDBusRegisterMetaType<QList<struct startCommand> >();

    m_timer.setInterval(1000);
    connect(&m_timer, &QTimer::timeout, this, &SystemdTimer::remainingSecChanged);

    QDBusInterface mngr(SYSTEMD_SERVICE_NAME, SYSTEMD_PATH_BASE, SYSTEMD_MANAGER_IFACE);
    mngr.call(QDBus::AutoDetect, "Subscribe");
    connect(this, SIGNAL(destroyed(QObject*)), this, SLOT(systemdUnsubscribe(QObject *)));

    QDBusInterface timer(SYSTEMD_SERVICE_NAME, ASTEROID_TIMER_PATH_BASE, SYSTEMD_TIMER_IFACE);
    if(timer.isValid())
        m_nextElapse = timer.property("NextElapseUSecMonotonic").toLongLong();

    QDBusInterface unit(SYSTEMD_SERVICE_NAME, ASTEROID_TIMER_PATH_BASE, SYSTEMD_UNIT_IFACE);
    if(unit.isValid()) {
        m_running = unit.property("ActiveState").toString().compare("active") == 0;
        if(m_running) m_timer.start();
    }

    QDBusConnection::sessionBus().connect(SYSTEMD_SERVICE_NAME, SYSTEMD_PATH_BASE, SYSTEMD_MANAGER_IFACE, "UnitRemoved", this, SLOT(onUnitRemoved(QString, QDBusObjectPath)));

    if(startElapsed)
        QTimer::singleShot(0, this, SIGNAL(elapsed()));
}

void SystemdTimer::systemdUnsubscribe(QObject *)
{
    QDBusInterface mngr(SYSTEMD_SERVICE_NAME, SYSTEMD_PATH_BASE, SYSTEMD_MANAGER_IFACE);
    mngr.call(QDBus::AutoDetect, "Unsubscribe");
}

/* QML Methods */
void SystemdTimer::start(int sec, int min, int hour)
{
    if(m_running) return;

    QList<struct property> timerProperties;
    timerProperties.append({"Description", "asteroid-timer countdown"});
    timerProperties.append({"AccuracyUSec", QVariant::fromValue((quint64)1000000)});
    timerProperties.append({"RemainAfterElapse", false});
    timerProperties.append({"WakeSystem", true});
    timerProperties.append({"OnActiveSec", QVariant::fromValue((quint64)(sec+60*min+60*60*hour)*1000000)});

    QList<struct additionalService> services;
    QDBusInterface service(SYSTEMD_SERVICE_NAME, ASTEROID_SERV_PATH_BASE, SYSTEMD_UNIT_IFACE);
    QList<struct property> serviceProperties;
    serviceProperties.append({"Description", "asteroid-timer show elapsed"});
    serviceProperties.append({"RemainAfterExit", false});
    serviceProperties.append({"Environment", QProcessEnvironment::systemEnvironment().toStringList()});
    QList<struct startCommand> execStart;
    QStringList args;
    args.append("/usr/bin/invoker");
    args.append("--no-wait");
    args.append("--single-instance");
    args.append("--type=qtcomponents-qt5");
    args.append("/usr/bin/asteroid-timer");
    args.append("--elapsed");

    execStart.append({"/usr/bin/invoker", args, false});
    serviceProperties.append({"ExecStart", QVariant::fromValue(execStart)});
    services.append({"asteroid-timer.service", serviceProperties});

    QDBusInterface mngr(SYSTEMD_SERVICE_NAME, SYSTEMD_PATH_BASE, SYSTEMD_MANAGER_IFACE);
    mngr.call(QDBus::AutoDetect, "StartTransientUnit", "asteroid-timer.timer", "replace", QVariant::fromValue(timerProperties), QVariant::fromValue(services));

    QDBusInterface *unit = new QDBusInterface(SYSTEMD_SERVICE_NAME, ASTEROID_TIMER_PATH_BASE, SYSTEMD_UNIT_IFACE);
    bool running = unit->property("ActiveState").toString().compare("active") == 0;
    if(running != m_running) {
        m_running = running;
        if(m_running) m_timer.start();
        else          m_timer.stop();
        emit runningChanged();
    }

    QDBusInterface *timer = new QDBusInterface(SYSTEMD_SERVICE_NAME, ASTEROID_TIMER_PATH_BASE, SYSTEMD_TIMER_IFACE);
    qint64 nextElapse = timer->property("NextElapseUSecMonotonic").toLongLong();
    if(nextElapse != m_nextElapse && nextElapse > 0) {
        m_nextElapse = nextElapse;
        emit remainingSecChanged();
    }

    QDBusConnection::sessionBus().connect(SYSTEMD_SERVICE_NAME, ASTEROID_TIMER_PATH_BASE, DBUS_PROPERTIES_IFACE, "PropertiesChanged", this, SLOT(unitPropertiesChanged(QString, QMap<QString, QVariant>, QStringList)));
}

void SystemdTimer::stop()
{
    if(!m_running) return;

    QDBusInterface mngr(SYSTEMD_SERVICE_NAME, SYSTEMD_PATH_BASE, SYSTEMD_MANAGER_IFACE);
    mngr.call(QDBus::AutoDetect, "StopUnit", "asteroid-timer.timer", "replace");
}

/* QML Properties */
unsigned int SystemdTimer::remainingSec()
{
    struct timespec time;
    clock_gettime(CLOCK_BOOTTIME, &time);
    qint64 remainingTime = (m_nextElapse)/1000000-time.tv_sec;

    if(remainingTime > 0)
        return remainingTime;
    else {
        stop();
        emit elapsed();
        return 0;
    }
}

bool SystemdTimer::running()
{
    return m_running;
}

/* ASTEROID_TIMER_PATH_BASE removed */
void SystemdTimer::onUnitRemoved(QString unit, QDBusObjectPath)
{
    if(unit.compare("asteroid-timer.timer") == 0) {
        if(m_running) {
            m_running = false;
            m_timer.stop();
            emit runningChanged();
        }

        QDBusConnection::sessionBus().disconnect(SYSTEMD_SERVICE_NAME, ASTEROID_TIMER_PATH_BASE, DBUS_PROPERTIES_IFACE, "PropertiesChanged", this, SLOT(unitPropertiesChanged(QString, QMap<QString, QVariant>, QStringList)));
    }
}

/* ASTEROID_TIMER_PATH_BASE modified */
void SystemdTimer::unitPropertiesChanged(QString, QMap<QString, QVariant> changedProperties, QStringList)
{
    if(changedProperties.contains("NextElapseUSecMonotonic")) {
        qint64 nextElapse = changedProperties.value("NextElapseUSecMonotonic").toLongLong();
        if(nextElapse != m_nextElapse && nextElapse > 0) {
            m_nextElapse = nextElapse;
            emit remainingSecChanged();
        }
    }

    if(changedProperties.contains("ActiveState")) {
        bool running = changedProperties.value("ActiveState").toString().compare("active") == 0;
        if(running != m_running) {
            m_running = running;
            if(m_running) m_timer.start();
            else          m_timer.stop();
            emit runningChanged();
        }
    }
}

/* Various D-Bus marshalling wizardry */
Q_DECLARE_METATYPE(struct property)
Q_DECLARE_METATYPE(struct additionalService)
Q_DECLARE_METATYPE(struct startCommand)

QDBusArgument &operator<<(QDBusArgument &argument, const struct property &pc)
{
    argument.beginStructure();
    argument << pc.name << QDBusVariant(pc.value);
    argument.endStructure();
    return argument;
}

const QDBusArgument &operator>>(const QDBusArgument &argument, struct property &pc)
{
    argument.beginStructure();
    argument >> pc.name >> pc.value;
    argument.endStructure();
    return argument;
}

QDBusArgument &operator<<(QDBusArgument &argument, const struct additionalService &as)
{
    argument.beginStructure();
    argument << as.service << as.properties;
    argument.endStructure();
    return argument;
}

const QDBusArgument &operator>>(const QDBusArgument &argument, struct additionalService &as)
{
    argument.beginStructure();
    argument >> as.service >> as.properties;
    argument.endStructure();
    return argument;
}

QDBusArgument &operator<<(QDBusArgument &argument, const struct startCommand &sc)
{
    argument.beginStructure();
    argument << sc.name << sc.args << sc.failure;
    argument.endStructure();
    return argument;
}

const QDBusArgument &operator>>(const QDBusArgument &argument, struct startCommand &sc)
{
    argument.beginStructure();
    argument >> sc.name >> sc.args >> sc.failure;
    argument.endStructure();
    return argument;
}
