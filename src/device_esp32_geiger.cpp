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
 * \date      2020
 * \author    Emeric Grange <emeric.grange@gmail.com>
 */

#include "device_esp32_geiger.h"
#include "utils_versionchecker.h"

#include <cmath>

#include <QBluetoothUuid>
#include <QBluetoothAddress>
#include <QBluetoothServiceInfo>
#include <QLowEnergyService>

#include <QSqlQuery>
#include <QSqlError>

#include <QDebug>

/* ************************************************************************** */

DeviceEsp32Geiger::DeviceEsp32Geiger(QString &deviceAddr, QString &deviceName, QObject *parent):
    DeviceEnvironmental(deviceAddr, deviceName, parent)
{
    m_deviceType = DEVICE_ENVIRONMENTAL;
    m_capabilities += DEVICE_GEIGER;
}

DeviceEsp32Geiger::DeviceEsp32Geiger(const QBluetoothDeviceInfo &d, QObject *parent):
    DeviceEnvironmental(d, parent)
{
    m_deviceType = DEVICE_ENVIRONMENTAL;
    m_capabilities += DEVICE_GEIGER;
}

DeviceEsp32Geiger::~DeviceEsp32Geiger()
{
    controller->disconnectFromDevice();
    delete serviceData;
}

/* ************************************************************************** */
/* ************************************************************************** */

void DeviceEsp32Geiger::serviceScanDone()
{
    //qDebug() << "DeviceEsp32Geiger::serviceScanDone(" << m_deviceAddress << ")";

    if (serviceData)
    {
        if (serviceData->state() == QLowEnergyService::DiscoveryRequired)
        {
            connect(serviceData, &QLowEnergyService::stateChanged, this, &DeviceEsp32Geiger::serviceDetailsDiscovered);
            connect(serviceData, &QLowEnergyService::characteristicChanged, this, &DeviceEsp32Geiger::bleReadNotify);
            serviceData->discoverDetails();
        }
    }
}

void DeviceEsp32Geiger::addLowEnergyService(const QBluetoothUuid &uuid)
{
    //qDebug() << "DeviceEsp32Geiger::addLowEnergyService(" << uuid.toString() << ")";

    if (uuid.toString() == "{5d061333-01fc-4c1a-919b-e68b8a2796e3}") // custom data service
    {
        delete serviceData;
        serviceData = nullptr;

        serviceData = controller->createServiceObject(uuid);
        if (!serviceData)
            qWarning() << "Cannot create service (data) for uuid:" << uuid.toString();
    }
}

void DeviceEsp32Geiger::serviceDetailsDiscovered(QLowEnergyService::ServiceState newState)
{
    if (newState == QLowEnergyService::ServiceDiscovered)
    {
        //qDebug() << "DeviceEsp32Geiger::serviceDetailsDiscovered(" << m_deviceAddress << ") > ServiceDiscovered";

        if (serviceData)
        {
            QBluetoothUuid f(QString("beb5483e-36e1-4688-b7f5-ea07361b26a1")); // firmware
            QLowEnergyCharacteristic chf = serviceData->characteristic(f);
            if (chf.value().size() > 0)
            {
                m_firmware = chf.value();
            }
            if (m_firmware.size() == 3)
            {
                if (Version(m_firmware) >= Version(LATEST_KNOWN_FIRMWARE_ESP32_GEIGER))
                {
                    m_firmware_uptodate = true;
                }
            }

            Q_EMIT sensorUpdated();

            QBluetoothUuid d(QString("beb5483e-36e1-4688-b7f5-ea07361b26a8")); // recap data
            QLowEnergyCharacteristic chd = serviceData->characteristic(d);

            m_rh = chd.value().toFloat();
            m_rm = chd.value().toFloat();
            m_rs = chd.value().toFloat();
            Q_EMIT dataUpdated();

            QBluetoothUuid rt(QString("beb5483e-36e1-4688-b7f5-ea07361b26a9")); // rt data
            QLowEnergyCharacteristic chrt = serviceData->characteristic(rt);
            //serviceData->readCharacteristic(chrt);
            m_notificationDesc = chrt.descriptor(QBluetoothUuid::ClientCharacteristicConfiguration);
            serviceData->writeDescriptor(m_notificationDesc, QByteArray::fromHex("0100"));
        }
    }
}

/* ************************************************************************** */

void DeviceEsp32Geiger::bleReadDone(const QLowEnergyCharacteristic &c, const QByteArray &value)
{
    const quint8 *data = reinterpret_cast<const quint8 *>(value.constData());
/*
    qDebug() << "DeviceEsp32Geiger::bleReadDone(" << m_deviceAddress << ") on" << c.name() << " / uuid" << c.uuid() << value.size();
    qDebug() << "WE HAVE DATA: 0x" \
             << hex << data[0]  << hex << data[1]  << hex << data[2] << hex << data[3] \
             << hex << data[4]  << hex << data[5]  << hex << data[6] << hex << data[7] \
             << hex << data[8]  << hex << data[9]  << hex << data[10] << hex << data[10] \
             << hex << data[12]  << hex << data[13]  << hex << data[14] << hex << data[15];
*/
    if (c.uuid().toString() == "{x}")
    {
        Q_UNUSED(data);
    }
}

void DeviceEsp32Geiger::bleReadNotify(const QLowEnergyCharacteristic &c, const QByteArray &value)
{
    const quint8 *data = reinterpret_cast<const quint8 *>(value.constData());
/*
    qDebug() << "DeviceEsp32Geiger::bleReadNotify(" << m_deviceAddress << ") on" << c.name() << " / uuid" << c.uuid() << value.size();
    qDebug() << "WE HAVE DATA: 0x" \
             << hex << data[0]  << hex << data[1]  << hex << data[2] << hex << data[3] \
             << hex << data[4]  << hex << data[5]  << hex << data[6] << hex << data[7] \
             << hex << data[8]  << hex << data[9]  << hex << data[10] << hex << data[10] \
             << hex << data[12]  << hex << data[13]  << hex << data[14] << hex << data[15];
*/
    if (c.uuid().toString() == "{beb5483e-36e1-4688-b7f5-ea07361b26a9}")
    {
        // Geiger Counter realtime data // handler 0x?

        if (value.size() > 0)
        {
            Q_UNUSED(data);
            m_rh = value.toFloat();
            m_rm = value.toFloat();
            m_rs = value.toFloat();

            m_lastUpdate = QDateTime::currentDateTime();

            Q_EMIT dataUpdated();
            //refreshDataFinished(true);
            //controller->disconnectFromDevice();

#ifndef QT_NO_DEBUG
            //qDebug() << "* DeviceEsp32Geiger update:" << getAddress();
            //qDebug() << "- m_firmware:" << m_firmware;
            //qDebug() << "- radioactivity min:" << m_rm;
            //qDebug() << "- radioactivity sec:" << m_rs;
#endif
        }
    }
}
