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

from console import Console
from file import File

include "metajolie.iol"
include "metarender.iol"

service MosquittoTransformPort {

embed Console as Console
embed File as File

init {
    if ( #args != 3 ) {
      println@Console("Usage: jolie mqttTransformPort.ol <service_filename> <port_name> <input_output>")()
    }
    service_filename = args[0]
    port_name = args[1]
    input_output = args[2]
}

main {
    if (args[2] == "output") {

        GetMetaDataRequest.filename = service_filename

        getOutputPortMetaData@MetaJolie( GetMetaDataRequest )( outputPortResponse )

        for (i=0, i<#outputPortResponse.output, i++) {
            if (outputPortResponse.output[i].name == port_name) {
                getInterface@MetaRender( outputPortResponse.output[i].interfaces )( resInterface )
                out = i
            }
        }

        fileContent = ""

        fileContent += "from mosquitto.mqtt.mqtt import MQTT
from mosquitto.mqtt.mqtt import MosquittoReceiverInterface, MosquittoRequest
from console import Console
from json_utils import JsonUtils\n\n"

        fileContent += resInterface

        fileContent += "service MosquittoPluginOutput {

embed MQTT as Mosquitto
embed Console as Console
embed JsonUtils as JsonUtils

execution: concurrent

inputPort Input {
    Location: \"local\"
    Interfaces: "+outputPortResponse.output[out].interfaces.name+", MosquittoReceiverInterface
}

init {
    clientToken = new
    topicRootResponse = \"mqttTransform4Jolie/response/"+outputPortResponse.output[out].location+"/\"+clientToken
    topicRootRequest = \"mqttTransform4Jolie/request/"+outputPortResponse.output[out].location+"/\"+clientToken
    req << {
        brokerURL = \"tcp://mqtt.eclipseprojects.io:1883\"
        subscribe << {
            topic = topicRootResponse+\"/#\"
        }
    }
    setMosquitto@Mosquitto (req)()
}

cset {
    session_token: MosquittoRequest.session_token
}

main {\n"
    for (i=0, i<#outputPortResponse.output[out].interfaces.operations, i++) {
        if( !is_defined(outputPortResponse.output[out].interfaces.operations[i].output) ) {
            opName = outputPortResponse.output[out].interfaces.operations[i].operation_name
            fileContent += "    ["+opName+"(requestMessage)]
    {
        csets.session_token = new
        getJsonString@JsonUtils(requestMessage)(jsonString)
        requestMosquitto << {
            topic = topicRootRequest+\"/"+opName+"/\"+csets.session_token,
            message = jsonString
        }
        sendMessage@Mosquitto (requestMosquitto)()
    }\n\n"
        } else {
            opName = outputPortResponse.output[out].interfaces.operations[i].operation_name
            fileContent += "    ["+opName+"(requestMessage)(response)
    {
        csets.session_token = new
        getJsonString@JsonUtils(requestMessage)(jsonString)
        requestMosquitto << {
            topic = topicRootRequest+\"/"+opName+"/\"+csets.session_token,
            message = jsonString
        }
        sendMessage@Mosquitto (requestMosquitto)()

        receive(reqReceive)

        getJsonValue@JsonUtils(reqReceive.message)(jsonMessage)
        response << jsonMessage
    }]\n\n"
        }
    }

        fileContent += "}\n\n}"

        req << {
            filename = "mosquittoPlugin.ol"
            content = fileContent
        }

        writeFile@File( req )(  )
    } else if (args[2] == "input") {
        GetMetaDataRequest.filename = service_filename

        getInputPortMetaData@MetaJolie( GetMetaDataRequest )( inputPortResponse )

        for (i=0, i<#inputPortResponse.input, i++) {
            if (inputPortResponse.input[i].name == port_name) {
                getInterface@MetaRender( inputPortResponse.input[i].interfaces )( resInterface )
                inp = i
            }
        }

        fileContent = ""

        fileContent += "from mosquitto.mqtt.mqtt import MQTT
from mosquitto.mqtt.mqtt import MosquittoReceiverInterface
from console import Console
from json_utils import JsonUtils\n\n"

        fileContent += resInterface

        fileContent += "service MosquittoPluginInput {

embed MQTT as Mosquitto
embed Console as Console
embed JsonUtils as JsonUtils

execution: concurrent

inputPort Input {
    Location: \"local\"
    Interfaces: "+inputPortResponse.input[inp].interfaces.name+", MosquittoReceiverInterface
}
        
outputPort Output {
    Location: \""+inputPortResponse.input[inp].location+"\"
    Protocol: sodep
    Interfaces: "+inputPortResponse.input[inp].interfaces.name+"
}

init {
    topicRootResponse = \"mqttTransform4Jolie/response/"+inputPortResponse.input[inp].location+"\"
    topicRootRequest = \"mqttTransform4Jolie/request/"+inputPortResponse.input[inp].location+"\"
    req << {
        brokerURL = \"tcp://mqtt.eclipseprojects.io:1883\"
        subscribe << {
            topic = topicRootRequest + \"/#\"
        }
    }
    setMosquitto@Mosquitto (req)()
}

main {\n"

    fileContent += "    [receive(requestReceive)]
    {
        getJsonValue@JsonUtils(requestReceive.message)(jsonMessage)\n"
        for (i=0, i<#inputPortResponse.input[inp].interfaces.operations, i++) {
            if( !is_defined(inputPortResponse.input[inp].interfaces.operations[i].output) ) {
                op = inputPortResponse.input[inp].interfaces.operations[i].operation_name
                fileContent += "        if (requestReceive.topic == topicRootRequest+\"/\"+requestReceive.client_token+\"/"+op+"/\"+requestReceive.session_token) {\n"
                fileContent += "            "+op+"@Output(jsonMessage)
        }\n"
            } else {
                op = inputPortResponse.input[inp].interfaces.operations[i].operation_name
                fileContent += "        if (requestReceive.topic == topicRootRequest+\"/\"+requestReceive.client_token+\"/"+op+"/\"+requestReceive.session_token) {\n"
                fileContent += "            "+op+"@Output(jsonMessage)(response)
            getJsonString@JsonUtils(response)(jsonString)
            requestMosquitto << {
                topic = topicRootResponse+\"/\"+requestReceive.client_token+\"/"+op+"/\"+requestReceive.session_token+\"/response\"
                message = jsonString
            }
            sendMessage@Mosquitto (requestMosquitto)()
        }\n"
            }      
        }
        fileContent += "    }
}\n\n}"

        req << {
            filename = "mosquittoPlugin.ol"
            content = fileContent
        }

        writeFile@File( req )(  )
            
    } else {
        println@Console("WARNING: args[2] must be <input> or <output> ")()
    }
}

}