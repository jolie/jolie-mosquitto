type RequestType:void {
  .x[1,1]:double
  .y[1,1]:double
}

interface CalculatorInterface {
RequestResponse:
  div( RequestType )( double ),
  mul( RequestType )( double ),
  sub( RequestType )( double ),
  sum( RequestType )( double )
}


include "console.iol"
include "mosquitto/interfaces/MosquittoInterface.iol"
include "json_utils.iol"

execution {concurrent}

inputPort Input {
    Location: "local"
    Protocol: sodep
    Interfaces: CalculatorInterface, MosquittoReceiverInteface
}
        
outputPort Output {
    Location: "socket://localhost:8000"
    Protocol: sodep
    Interfaces: CalculatorInterface
}

outputPort Mosquitto {
    Interfaces: MosquittoPublisherInterface , MosquittoInterface
}

embedded {
    Java: 
        "org.jolielang.connector.mosquitto.MosquittoConnectorJavaService" in Mosquitto
}

init {
    topicRootResponse = "mqttTransform4Jolie/response/socket://localhost:8000"
    topicRootRequest = "mqttTransform4Jolie/request/socket://localhost:8000"
    req << {
        brokerURL = "tcp://mqtt.eclipse.org:1883"
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
            div@Output(jsonMessage)(response)
            getJsonString@JsonUtils(response)(jsonString)
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