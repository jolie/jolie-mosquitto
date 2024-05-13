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
from mosquitto.mqtt.mqtt import MosquittoReceiverInterface, MosquittoRequest
from console import Console
from json_utils import JsonUtils

include "../server/CalculatorInterface.iol"

service MosquittoPluginOutput {

embed MQTT as Mosquitto
embed Console as Console
embed JsonUtils as JsonUtils

execution: concurrent

inputPort Input {
    Location: "local"
    Interfaces: CalculatorInterface, MosquittoReceiverInterface
}

init {
    clientToken = new
    topicRootResponse = "mqttTransform4Jolie/response/socket://localhost:8000/"+clientToken
    topicRootRequest = "mqttTransform4Jolie/request/socket://localhost:8000/"+clientToken
    req << {
        brokerURL = "tcp://mqtt.eclipseprojects.io:1883"
        subscribe << {
            topic = topicRootResponse+"/#"
        }
    }
    setMosquitto@Mosquitto (req)()
}

cset {
    session_token: MosquittoRequest.session_token
}

main {
    [div(requestMessage)(response)
    {
        csets.session_token = new
        getJsonString@JsonUtils(requestMessage)(jsonString)
        requestMosquitto << {
            topic = topicRootRequest+"/div/"+csets.session_token,
            message = jsonString
        }
        sendMessage@Mosquitto (requestMosquitto)()

        receive(reqReceive)
        if ( reqReceive.message == "NaN" )
            throw ( DivisionByZero )

        getJsonValue@JsonUtils(reqReceive.message)(jsonMessage)
        response << jsonMessage
    }]

    [mul(requestMessage)(response)
    {
        csets.session_token = new
        getJsonString@JsonUtils(requestMessage)(jsonString)
        requestMosquitto << {
            topic = topicRootRequest+"/mul/"+csets.session_token,
            message = jsonString
        }
        sendMessage@Mosquitto (requestMosquitto)()

        receive(reqReceive)
        
        getJsonValue@JsonUtils(reqReceive.message)(jsonMessage)
        response << jsonMessage
    }]

    [sub(requestMessage)(response)
    {
        csets.session_token = new
        getJsonString@JsonUtils(requestMessage)(jsonString)
        requestMosquitto << {
            topic = topicRootRequest+"/sub/"+csets.session_token,
            message = jsonString
        }
        sendMessage@Mosquitto (requestMosquitto)()

        receive(reqReceive)
        
        getJsonValue@JsonUtils(reqReceive.message)(jsonMessage)
        response << jsonMessage
    }]

    [sum(requestMessage)(response)
    {
        csets.session_token = new
        getJsonString@JsonUtils(requestMessage)(jsonString)
        requestMosquitto << {
            topic = topicRootRequest+"/sum/"+csets.session_token,
            message = jsonString
        }
        sendMessage@Mosquitto (requestMosquitto)()

        receive(reqReceive)
        
        getJsonValue@JsonUtils(reqReceive.message)(jsonMessage)
        response << jsonMessage
    }]
}

}