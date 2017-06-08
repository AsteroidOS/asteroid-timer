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

#ifndef SYSTEMDTIMER_H
#define SYSTEMDTIMER_H

#include <QObject>
#include <QTimer>
#include <QVariant>
#include <QDBusObjectPath>

class SystemdTimer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(unsigned int remainingSec READ remainingSec NOTIFY remainingSecChanged)

public:
    explicit SystemdTimer(bool startElapsed = false, QObject *parent = 0);

    Q_INVOKABLE void stop();
    Q_INVOKABLE void start(int sec, int min, int hour);

    unsigned int remainingSec();
    bool running();

private:
    bool m_running;
    QTimer m_timer;
    qint64 m_nextElapse;

signals:
    void runningChanged();
    void remainingSecChanged();
    void elapsed();

private slots:
    void unitPropertiesChanged(QString, QMap<QString, QVariant>, QStringList);
    void onUnitRemoved(QString unit, QDBusObjectPath);
    void systemdUnsubscribe(QObject *);
};

#endif // SYSTEMDTIMER_H
