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

type SendChatMessageRequest: void {
    message: string
}

type GetChatMessagesResponse: void {
    messageQueue*: void {
        message: string
        username: string
        session_user: string
    }
}

type SetUsernameRequest: void {
    username: string
}

interface FrontendInterface {
    RequestResponse:
		sendChatMessage( SendChatMessageRequest )( void ),
        getChatMessages( void )( GetChatMessagesResponse ),
        setUsername( SetUsernameRequest )( void )
}

service Frontend {

embed MQTT as Mosquitto
embed Console as Console
embed JsonUtils as JsonUtils

execution: concurrent

inputPort Frontend {
    Location: "local"
    Interfaces: MosquittoReceiverInterface, FrontendInterface
}

init {
    request << {
        brokerURL = "tcp://mqtt.eclipseprojects.io:1883",
        subscribe << {
            topic = "jolie/test/chat"
        }
        // I can set all the options available from the Paho library
        options << {
            setUserName = "joliechat"
            setPassword = "joliechat"
        }
    }

    setMosquitto@Mosquitto (request)()
    println@Console("SUBSCRIBER connection done! Waiting for message on topic : "+request.subscribe.topic)()
}

main {
    [ receive (request) ] {
        getJsonValue@JsonUtils(request.message)(jsonMessage)
        global.messageQueue[#global.messageQueue] << {
            message = jsonMessage.message
            username = jsonMessage.username
            session_user = global.username
        }
    }

    [ getChatMessages( GetChatMessagesRequest )( GetChatMessagesResponse ) {
        for (i=0, i<#global.messageQueue, i++) {
            GetChatMessagesResponse.messageQueue[i] << global.messageQueue[i]
        }
        undef(global.messageQueue)
    }]

    [ sendChatMessage( messageRequest )( response ) {
        json << {
            username = global.username
            message = messageRequest.message
        }
        getJsonString@JsonUtils(json)(jsonString)
        req << {
            topic = "jolie/test/chat",
            message = jsonString
        }
        println@Console("PUBLISHER ["+global.username+"] connection done! Message correctly send: "+messageRequest.message)()
        sendMessage@Mosquitto (req)()
	}]

    [ setUsername( usernameRequest )( usernameResponse ) {
        global.username = usernameRequest.username
        println@Console("Username set for the current session: "+global.username)()
    }]
}

}