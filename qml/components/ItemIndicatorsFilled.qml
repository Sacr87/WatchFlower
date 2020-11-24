import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import "qrc:/js/UtilsNumber.js" as UtilsNumber

Item {
    id: indicatorsFilled
    width: parent.width
    height: columnData.height + 16
    z: 5

    function updateData() {
        if (typeof currentDevice === "undefined" || !currentDevice) return
        if (!currentDevice.hasSoilMoistureSensor()) return
        //console.log("DeviceScreenData // updateData() >> " + currentDevice)

        // Has data? always display them
        if (currentDevice.isAvailable()) {
            soil_moisture.visible = (currentDevice.deviceSoilConductivity > 0 || currentDevice.deviceSoilMoisture > 0)
            soil_conductivity.visible = (currentDevice.deviceSoilConductivity > 0 || currentDevice.deviceSoilMoisture > 0)
            soil_temperature.visible = currentDevice.hasSoilTemperatureSensor()
            temp.visible = currentDevice.hasTemperatureSensor()
            humi.visible = currentDevice.hasHumiditySensor()
            lumi.visible = currentDevice.hasLuminositySensor()
        } else {
            soil_moisture.visible = currentDevice.hasHumiditySensor() || currentDevice.hasSoilMoistureSensor()
            soil_conductivity.visible = currentDevice.hasSoilConductivitySensor()
            soil_temperature.visible = currentDevice.hasSoilTemperatureSensor()
            temp.visible = currentDevice.hasTemperatureSensor()
            humi.visible = currentDevice.hasHumiditySensor()
            lumi.visible = currentDevice.hasLuminositySensor()
        }

        resetDataBars()
    }

    function updateDataBars(tempD, lumiD, hygroD, conduD) {
        temp.value = (settingsManager.tempUnit === "F") ? UtilsNumber.tempCelsiusToFahrenheit(tempD) : tempD
        humi.value = -99
        lumi.value = lumiD
        soil_moisture.value = hygroD
        soil_conductivity.value = conduD
        soil_temperature.value = -99
    }

    function resetDataBars() {
        soil_moisture.value = currentDevice.deviceSoilMoisture
        soil_conductivity.value = currentDevice.deviceSoilConductivity
        soil_temperature.value = currentDevice.deviceSoilTemperature
        temp.value = (settingsManager.tempUnit === "F") ? currentDevice.deviceTempF : currentDevice.deviceTempC
        humi.value = currentDevice.deviceHumidity
        lumi.value = currentDevice.deviceLuminosity
    }

    ////////////////////////////////////////////////////////////////////////////

    Column {
        id: columnData
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        spacing: 14
        visible: (currentDevice.available || currentDevice.hasData())

        ////////

        ItemDataBarFilled {
            id: soil_moisture
            width: parent.width

            legend: currentDevice.hasSoilMoistureSensor() ? qsTr("Moisture") : qsTr("Humidity")
            suffix: "%"
            warning: true
            colorForeground: Theme.colorBlue
            //colorBackground: Theme.colorBackground

            value: currentDevice.deviceSoilMoisture
            valueMin: 0
            valueMax: settingsManager.dynaScale ? Math.ceil(currentDevice.hygroMax*1.10) : 50
            limitMin: currentDevice.limitHygroMin
            limitMax: currentDevice.limitHygroMax
        }

        ////////

        ItemDataBarFilled {
            id: temp
            width: parent.width

            legend: qsTr("Temperature")
            floatprecision: 1
            warning: true
            suffix: "°" + settingsManager.tempUnit
            colorForeground: Theme.colorGreen
            //colorBackground: Theme.colorBackground

            function tempHelper(tempDeg) {
                return (settingsManager.tempUnit === "F") ? UtilsNumber.tempCelsiusToFahrenheit(tempDeg) : tempDeg
            }

            value: tempHelper(currentDevice.deviceTemp)
            valueMin: tempHelper(settingsManager.dynaScale ? Math.floor(currentDevice.tempMin*0.80) : tempHelper(0))
            valueMax: tempHelper(settingsManager.dynaScale ? (currentDevice.tempMax*1.20) : tempHelper(40))
            limitMin: tempHelper(currentDevice.limitTempMin)
            limitMax: tempHelper(currentDevice.limitTempMax)
        }

        ////////

        ItemDataBarFilled {
            id: humi
            width: parent.width

            legend: qsTr("Humidity")
            suffix: "%"
            warning: true
            colorForeground: Theme.colorBlue
            //colorBackground: Theme.colorBackground

            value: currentDevice.deviceHumidity
            valueMin: 0
            valueMax: 100
            limitMin: 0
            limitMax: 100
        }

        ////////

        ItemDataBarFilled {
            id: lumi
            width: parent.width

            legend: qsTr("Luminosity")
            suffix: " " + qsTr("lux")
            colorForeground: Theme.colorYellow
            //colorBackground: Theme.colorBackground

            value: currentDevice.deviceLuminosity
            valueMin: 0
            valueMax: settingsManager.dynaScale ? Math.ceil(currentDevice.lumiMax*1.10) : 10000
            limitMin: currentDevice.limitLumiMin
            limitMax: currentDevice.limitLumiMax
        }

        ////////

        ItemDataBarFilled {
            id: soil_conductivity
            width: parent.width

            legend: qsTr("Fertility")
            suffix: " " + qsTr("µS/cm")
            colorForeground: Theme.colorRed
            //colorBackground: Theme.colorBackground

            value: currentDevice.deviceSoilConductivity
            valueMin: 0
            valueMax: settingsManager.dynaScale ? Math.ceil(currentDevice.conduMax*1.10) : 2000
            limitMin: currentDevice.limitConduMin
            limitMax: currentDevice.limitConduMax
        }

        ////////

        ItemDataBarFilled {
            id: soil_temperature
            width: parent.width

            legend: qsTr("Soil temp.")
            suffix: "°" + settingsManager.tempUnit
            colorForeground: Theme.colorGreen
            //colorBackground: Theme.colorBackground

            value: currentDevice.deviceSoilTemperature
            valueMin: 0
            valueMax: 0
            limitMin: tempHelper(currentDevice.limitTempMin)
            limitMax: tempHelper(currentDevice.limitTempMax)
        }
    }
}
