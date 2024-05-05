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

type MosquittoRequest: void {
    topic: string
    message: string
    session_token?: string
    client_token?: string
}

interface MosquittoPublisherInterface {
    RequestResponse:
        sendMessage (MosquittoRequest)(void)
}

interface MosquittoInterface {
    RequestResponse:
        setMosquitto (SetMosquittoRequest)(void)
}

interface MosquittoReceiverInterface {
    OneWay:
        receive (MosquittoRequest)
}