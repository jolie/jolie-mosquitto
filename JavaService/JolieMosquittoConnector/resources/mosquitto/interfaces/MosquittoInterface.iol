type SetMosquittoRequest: void {
    clientId?: string
    brokerURL: string
    options?: void {
        setAutomaticReconnect?: bool
        setCleanSession?: bool
        setConnectionTimeout?: int
        setKeepAliveInterval?: int
        setMaxInflight?: int
        setServerURIs?: string
        setUserName?: string
        setPassword?: string
        setWill?: void {
            topicWill: string
            payloadWill: string
            qos: int
            retained: bool 
        }
        setSocketFactory?: void {
            caCrtFile: string
            crtFile: string
            keyFile: string
            password: string
        }
        // setMqttVersion  
	    debug?: bool
    }
    subscribe?: void {
        topic[1,*]: string
    }
}

type MosquittoMessageRequest: void {
    topic: string
    message: string
}

interface MosquittoPublisherInterface {
    RequestResponse: 
        sendMessage (MosquittoMessageRequest)(void)
}

interface MosquittoInterface {
    RequestResponse:
        setMosquitto (SetMosquittoRequest)(void),
}

interface MosquittoReceiverInteface {
    OneWay: 
        receive (MosquittoMessageRequest)
}