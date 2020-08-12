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

include "FrontendInterface.iol"
include "mosquitto/interfaces/MosquittoInterface.iol"
include "console.iol"
include "json_utils.iol"

execution {concurrent}

outputPort Mosquitto {
    Interfaces: MosquittoPublisherInterface , MosquittoInterface
}

embedded {
    Java: 
        "org.jolielang.connector.mosquitto.MosquittoConnectorJavaService" in Mosquitto
}

inputPort Frontend {
    Location: "local"
    Protocol: sodep
    Interfaces: MosquittoReceiverInteface, FrontendInterface
}

init {
    
    request << {
        brokerURL = "ssl://localhost:8883",
        subscribe << {
            topic = "jolie/test/chat"
        }
        // I can set all the options available from the Paho library
        options << {
            setCleanSession = false
            debug = true
            setUserName = "joliechat"
            setPassword = "riccardoiattoni"
            setSocketFactory << {
                caCrtFile = "C:\\Program Files\\mosquitto\\certs\\ca.crt"
                crtFile = "C:\\Program Files\\mosquitto\\certs\\server.crt"
                keyFile = "C:\\Program Files\\mosquitto\\certs\\server.key"
                password = "riccardoiattoni"
            }
        }
    }

    setMosquitto@Mosquitto (request)()
    println@Console("SUBSCRIBER connection done! Waiting for message on topic : "+request.subscribe.topic)()
    
}

main {

    [ receive (request) ]
    {
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