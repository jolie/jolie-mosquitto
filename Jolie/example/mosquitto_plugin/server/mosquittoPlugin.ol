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
from json_utils import JsonUtils

include "CalculatorInterface.iol"

service MosquittoPluginInput {

embed MQTT as Mosquitto
embed Console as Console
embed JsonUtils as JsonUtils

execution: concurrent

inputPort Input {
    Location: "local"
    Interfaces: CalculatorInterface, MosquittoReceiverInterface
}
        
outputPort Output {
    Location: "socket://localhost:8000"
    Protocol: sodep
    Interfaces: CalculatorInterface
}

init {
    topicRootResponse = "mqttTransform4Jolie/response/socket://localhost:8000"
    topicRootRequest = "mqttTransform4Jolie/request/socket://localhost:8000"
    req << {
        brokerURL = "tcp://mqtt.eclipseprojects.io:1883"
        subscribe << {
            topic = topicRootRequest + "/#"
        }
    }
    setMosquitto@Mosquitto (req)()
}

main {
    [receive(requestReceive)]
    {
        getJsonValue@JsonUtils(requestReceive.message)(jsonMessage)
        if (requestReceive.topic == topicRootRequest+"/"+requestReceive.client_token+"/div/"+requestReceive.session_token) {
            scope (div) {
                install ( DivisionByZero => jsonString = "NaN" )
                div@Output(jsonMessage)(response)
                getJsonString@JsonUtils(response)(jsonString)
            }
            requestMosquitto << {
                topic = topicRootResponse+"/"+requestReceive.client_token+"/div/"+requestReceive.session_token+"/response"
                message = jsonString
            }
            sendMessage@Mosquitto (requestMosquitto)()
        }
        if (requestReceive.topic == topicRootRequest+"/"+requestReceive.client_token+"/mul/"+requestReceive.session_token) {
            mul@Output(jsonMessage)(response)
            getJsonString@JsonUtils(response)(jsonString)
            requestMosquitto << {
                topic = topicRootResponse+"/"+requestReceive.client_token+"/mul/"+requestReceive.session_token+"/response"
                message = jsonString
            }
            sendMessage@Mosquitto (requestMosquitto)()
        }
        if (requestReceive.topic == topicRootRequest+"/"+requestReceive.client_token+"/sub/"+requestReceive.session_token) {
            sub@Output(jsonMessage)(response)
            getJsonString@JsonUtils(response)(jsonString)
            requestMosquitto << {
                topic = topicRootResponse+"/"+requestReceive.client_token+"/sub/"+requestReceive.session_token+"/response"
                message = jsonString
            }
            sendMessage@Mosquitto (requestMosquitto)()
        }
        if (requestReceive.topic == topicRootRequest+"/"+requestReceive.client_token+"/sum/"+requestReceive.session_token) {
            sum@Output(jsonMessage)(response)
            getJsonString@JsonUtils(response)(jsonString)
            requestMosquitto << {
                topic = topicRootResponse+"/"+requestReceive.client_token+"/sum/"+requestReceive.session_token+"/response"
                message = jsonString
            }
            sendMessage@Mosquitto (requestMosquitto)()
        }
    }
}

}