/*
   Copyright 2020 Riccardo Iattoni <riccardo.iattoni92@gmail.com>

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

from mosquitto.mqtt.mqtt import MQTT
from mosquitto.mqtt.mqtt import MosquittoReceiverInterface
from console import Console

service serverMQTT {

embed Console as Console
embed MQTT as Mosquitto

execution: concurrent

inputPort Server {
    Location: "local"
    Interfaces: MosquittoReceiverInterface
}

init {
    request << {
        brokerURL = "tcp://mqtt.eclipseprojects.io:1883",
        subscribe << {
            topic = "jolie/test"
        }
        // I can set all the options available from the Paho library
        options << {
            setAutomaticReconnect = true
            setCleanSession = false
            setConnectionTimeout = 25
            setKeepAliveInterval = 0
            setMaxInflight = 200
            setUserName = "username"
            setPassword = "password"
            setWill << {
                topicWill = "home/LWT"
                payloadWill = "server disconnected"
                qos = 0
                retained = true
            }
        }
    }
    setMosquitto@Mosquitto (request)()
}

main {
    receive (request)
    println@Console("topic :     "+request.topic)()
    println@Console("message :   "+request.message)()
}

}