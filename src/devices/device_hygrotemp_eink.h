/*!
 * This file is part of WatchFlower.
 * COPYRIGHT (C) 2020 Emeric Grange - All Rights Reserved
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * \date      2019
 * \author    Emeric Grange <emeric.grange@gmail.com>
 */

#ifndef DEVICE_HYGROTEMP_EINK_H
#define DEVICE_HYGROTEMP_EINK_H
/* ************************************************************************** */

#include "device_sensor.h"

#include <QObject>
#include <QList>

#include <QBluetoothDeviceInfo>
#include <QLowEnergyController>

/* ************************************************************************** */

/*!
 * ClearGrass "Digital bluetooth Thermometer and Hygrometer"
 * CGG1 device / Round body, E-Ink
 *
 * Protocol infos:
 * - TODO
 */
class DeviceHygrotempEInk: public DeviceSensor
{
    Q_OBJECT

public:
    DeviceHygrotempEInk(QString &deviceAddr, QString &deviceName, QObject *parent = nullptr);
    DeviceHygrotempEInk(const QBluetoothDeviceInfo &d, QObject *parent = nullptr);
    ~DeviceHygrotempEInk();

private:
    // QLowEnergyController related
    void serviceScanDone();
    void addLowEnergyService(const QBluetoothUuid &uuid);
    void serviceDetailsDiscovered_data(QLowEnergyService::ServiceState newState);
    void serviceDetailsDiscovered_infos(QLowEnergyService::ServiceState newState);

    QLowEnergyService *serviceData = nullptr;
    QLowEnergyService *serviceInfos = nullptr;
    QLowEnergyDescriptor m_notificationDesc;
    void confirmedDescriptorWrite(const QLowEnergyDescriptor &d, const QByteArray &value);

    void bleWriteDone(const QLowEnergyCharacteristic &c, const QByteArray &value);
    void bleReadDone(const QLowEnergyCharacteristic &c, const QByteArray &value);
    void bleReadNotify(const QLowEnergyCharacteristic &c, const QByteArray &value);
};

/* ************************************************************************** */
#endif // DEVICE_HYGROTEMP_EINK_H
