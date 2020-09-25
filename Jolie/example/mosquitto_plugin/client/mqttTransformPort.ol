include "metajolie.iol"
include "metarender.iol"
include "console.iol"
include "file.iol"
include "runtime.iol"
include "string_utils.iol"

init {
    if ( #args != 3 ) {
      println@Console("Usage: jolie mosquitto.ol <service_filename> <port_name> <input_output>")()
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

        fileContent += resInterface+"\n"
        fileContent += "include \"console.iol\"
include \"mosquitto/interfaces/MosquittoInterface.iol\"
include \"json_utils.iol\"

execution {concurrent}

inputPort Input {
    Location: \"local\"
    Protocol: sodep
    Interfaces: "+outputPortResponse.output[out].interfaces.name+", MosquittoReceiverInteface
}

outputPort Mosquitto {
    Interfaces: MosquittoPublisherInterface , MosquittoInterface
}

embedded {
    Java: 
        \"org.jolielang.connector.mosquitto.MosquittoConnectorJavaService\" in Mosquitto
}

init {
    clientToken = new
    topicRootResponse = \"mqttTransform4Jolie/response/"+outputPortResponse.output[out].location+"/\"+clientToken
    topicRootRequest = \"mqttTransform4Jolie/request/"+outputPortResponse.output[out].location+"/\"+clientToken
    req << {
        brokerURL = \"tcp://mqtt.eclipse.org:1883\"
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

    fileContent += "}"

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

        fileContent += resInterface+"\n"
        fileContent += "include \"console.iol\"
include \"mosquitto/interfaces/MosquittoInterface.iol\"
include \"json_utils.iol\"

execution {concurrent}

inputPort Input {
    Location: \"local\"
    Protocol: sodep
    Interfaces: "+inputPortResponse.input[inp].interfaces.name+", MosquittoReceiverInteface
}
        
outputPort Output {
    Location: \""+inputPortResponse.input[inp].location+"\"
    Protocol: sodep
    Interfaces: "+inputPortResponse.input[inp].interfaces.name+"
}

outputPort Mosquitto {
    Interfaces: MosquittoPublisherInterface , MosquittoInterface
}

embedded {
    Java: 
        \"org.jolielang.connector.mosquitto.MosquittoConnectorJavaService\" in Mosquitto
}

init {
    topicRootResponse = \"mqttTransform4Jolie/response/"+inputPortResponse.input[inp].location+"\"
    topicRootRequest = \"mqttTransform4Jolie/request/"+inputPortResponse.input[inp].location+"\"
    req << {
        brokerURL = \"tcp://mqtt.eclipse.org:1883\"
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
}"

        req << {
            filename = "mosquittoPlugin.ol"
            content = fileContent
        }

        writeFile@File( req )(  )
            
    } else {
        println@Console("WARNING: args[2] must be <input> or <output> ")()
    }
}

