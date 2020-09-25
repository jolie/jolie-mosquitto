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

outputPort Mosquitto {
    Interfaces: MosquittoPublisherInterface , MosquittoInterface
}

embedded {
    Java: 
        "org.jolielang.connector.mosquitto.MosquittoConnectorJavaService" in Mosquitto
}

init {
    clientToken = new
    topicRootResponse = "mqttTransform4Jolie/response/socket://localhost:8000/"+clientToken
    topicRootRequest = "mqttTransform4Jolie/request/socket://localhost:8000/"+clientToken
    req << {
        brokerURL = "tcp://mqtt.eclipse.org:1883"
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