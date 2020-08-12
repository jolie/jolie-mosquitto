# Jolie_Mosquitto

Jolie connector for Mosquitto framework

- Jolie: https://www.jolie-lang.org/
- Mosquitto: https://mosquitto.org/

## Architecture

The MQTT protocol is based on the principle of publishing messages and subscribing to topics, or "pub/sub". Multiple clients connect to a broker and subscribe to topics that they are interested in. Clients also connect to the broker and publish messages to topics. Many clients may subscribe to the same topics and do with the information as they please. The broker and MQTT act as a simple, common interface for everything to connect to.

![Architecture](https://github.com/rickyiatto/Jolie_Mosquitto/blob/develop/architecture.png)

JavaService uses the Paho library to create both the publisher and the subscriber.
Jolie's client service communicates with the JavaService, which takes care of creating a publisher client, creating the connection with the Mosquitto broker and finally transmitting the message.
Jolie's server service communicates with JavaService, which is responsible for creating a subscriber client, creating the connection with the Mosquitto broker and finally subscribing to the desired topics.

To install the Mosquitto broker on your computer follow the instructions provided by the official Eclipse Mosquitto website at the link: https://mosquitto.org/download/

## Example

To be able to use the connector correctly, be sure to add both the file JolieMosquittoConnector.jar and org.eclipse.paho.client.mqttv3-1.1.2-20170804.042534-34.jar to your project folder.
- ```JolieMosquittoConnector.jar``` contains both the connector and the interfaces necessary for the Jolie service to communicate with the Mosquitto broker.
- ```org.eclipse.paho.client.mqttv3-1.1.2-20170804.042534-34.jar``` is the dependency on the Paho library that JavaService uses to create the publisher and subscriber.

### CLIENT - SERVER :

#### server.ol

```java
include "mosquitto/interfaces/MosquittoInterface.iol"
include "console.iol"

execution {concurrent}

inputPort Server {
    Location: "local"
    Protocol: sodep
    Interfaces: MosquittoReceiverInteface
}

outputPort Mosquitto {
    Interfaces: MosquittoInterface
}

embedded {
    Java: 
        "org.jolielang.connector.mosquitto.MosquittoConnectorJavaService" in Mosquitto
}

init {
    request << {
        brokerURL = "tcp://localhost:1883",
        subscribe << {
            topic = "home/#"
        }
        // I can set all the options available from the Paho library
        options << {
            setAutomaticReconnect = true
            setCleanSession = false
            setConnectionTimeout = 25
            setKeepAliveInterval = 0
            setMaxInflight = 200
            setUserName = "SERVERadmin"
            setPassword = "passwordAdmin"
            setWill << {
                topicWill = "home/LWT"
                payloadWill = "server disconnected"
                qos = 0
                retained = false
            }
        }
    }
    setMosquitto@Mosquitto (request)()
}

main {
    receive (request)
    println@Console("topic :     "+request.topic)()
    println@Console("message :   "+request.message)()
}
```

You can modify all options values and the topic you want to subscribe in. The string "home/#" is used to subscribe on every subtopic of "home".
An example of launch of this client is:  
    ```jolie server.ol```.

The interface to be included must follow exactly the path reported ```"mosquitto/interfaces/MosquittoInterface.iol"```, as the requested file is located in the jar at this address.

#### client.ol

```java
include "mosquitto/interfaces/MosquittoInterface.iol"

outputPort Mosquitto {
    Interfaces: MosquittoPublisherInterface , MosquittoInterface
}

embedded {
    Java: 
        "org.jolielang.connector.mosquitto.MosquittoConnectorJavaService" in Mosquitto
}

init {
    req << {
        brokerURL = "tcp://localhost:1883"
        // I can set all the options available from the Paho library
        options << {
            setAutomaticReconnect = true
            setCleanSession = false
            setConnectionTimeout = 20
            setKeepAliveInterval = 20
            setMaxInflight = 150
            setUserName = "CLIENTadmin"
            setPassword = "password"
            setWill << {
                topicWill = "home/LWT"
                payloadWill = "client disconnected"
                qos = 0
                retained = false
            }
        }
    }
    setMosquitto@Mosquitto (req)()
}

main {
    request << {
        topic = "home/test",
        message = args[0]
    }
    sendMessage@Mosquitto (request)()
}
```

You can modify all options values and the topic you want to publish in.
An example of launch of this client is:  
    ```jolie client.ol "hello"```.

The interface to be included must follow exactly the path reported ```"mosquitto/interfaces/MosquittoInterface.iol"```, as the requested file is located in the jar at this address.

#### MosquittoInterface.iol

```java
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
```

The ```MosquittoPublisherInterface``` exposes a method called ```sendMessage``` which receives an input request of the ```MosquittoMessageRequest``` type. This type requires two fields: a ```topic``` (to publish the message) and a ```message``` (to publish).

The ```MosquittoInterface``` exposes a method called ```setMosquitto``` which receives in input a request of the type ```SetMosquittoRequest```. This type requires two mandatory fields: a ```brokerURL``` (which is used to connect to the broker Mosquitto) and a ```clientId``` (if not specified a random one is generated).
You can also specify some values of the ```options``` to customize the connection (if not specified, the default values are used).

The ```MosquittoReceiverInteface``` exposes a method called ```receive``` which receives a ```MosquittoMessageRequest``` request, described above.

This interface is already inside the ```JolieMosquittoConnector.jar``` file.
To be included correctly you need to call it through the string ```include "mosquitto/interfaces/MosquittoInterface.iol"```.

### CHAT :

In this example I wanted to apply the MQTT communication protocol to a simple chat.
Always exploiting the JavaService explained in the previous example, and exploiting Leonardo (a Web Server written in Jolie: https://github.com/jolie/leonardo) is sufficient to launch the command ```jolie leonardo.ol``` and subsequently open a browser to the page ```localhost:16000``` to observe its operation.

To test the chat with your friends without necessarily having a server with Mosquitto installed, just use the sandbox provided at the link https://iot.eclipse.org/projects/sandboxes/

#### frontend.ol

```java
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
        brokerURL = "tcp://mqtt.eclipse.org:1883",
        subscribe << {
            topic = "jolie/test/chat"
        }
        // I can set all the options available from the Paho library
        options.debug = true
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
```

The ```frontend.ol``` service presents an ```outputPort``` in which the JavaService described in the previous example is embedded, while the ```inputPort``` communicates both with the JavaService and with the ```FrontendInterface``` interface.
In the ```init``` method, it prepares the request (setting all the desired parameters) to send to the JavaService to open a connection with the broker Mosquitto.
In the ```main``` method, instead, it develops four operations:
- **setUsername:** sets the username of the user who wants to connect to the chat.
- **sendChatMessage:** publish the messages sent in the chat at the broker Mosquitto to the topic set in the connection. The message is converted into a json to allow the sending of additional information along with the message text.
- **receive:** receives the messages from broker Mosquitto and saves them in a global variable ```messageQueue```.
- **getChatMessages:** this operation reads all the messages in the queue, sends them to the WebService which prints them in the chat and empties the ```messageQueueue```. This operation is called cyclically every 0.5 seconds by the web page.

## Options

In order to let you customize your communications, you can modify some options (these descriptions are taken from the official Paho library documentation):
https://www.eclipse.org/paho/files/javadoc/org/eclipse/paho/client/mqttv3/MqttConnectOptions.html

- **setAutomaticReconnect : bool**
Sets whether the client will automatically attempt to reconnect to the server if the connection is lost.
    - If set to **false**, the client will not attempt to automatically reconnect to the server in the event that the connection is lost.
    - If set to **true**, in the event that the connection is lost, the client will attempt to reconnect to the server. 
    It will initially wait 1 second before it attempts to reconnect, for every failed reconnect attempt, the delay will double until it is at 2 minutes at which point the delay will stay at 2 minutes.

- **setCleanSession : bool**
Sets whether the client and server should remember state across restarts and reconnects.
    - If set to **false** both the client and server will maintain state across restarts of the client, the server and the connection. As state is maintained:
        - Message delivery will be reliable meeting the specified QOS even if the client, server or connection are restarted.
        - The server will treat a subscription as durable.
    - If set to **true** the client and server will not maintain state across restarts of the client, the server or the connection. This means:
        - Message delivery to the specified QOS cannot be maintained if the client, server or connection are restarted
        - The server will treat a subscription as non-durable.

- **setConnectionTimeout : int**
Sets the connection timeout value. This value, measured in seconds, defines the maximum time interval the client will wait for the network connection to the MQTT server to be established. The default timeout is 30 seconds. 
A value of 0 disables timeout processing meaning the client will wait until the network connection is made successfully or fails.

- **setKeepAliveInterval : int**
Sets the "keep alive" interval. This value, measured in seconds, defines the maximum time interval between messages sent or received. It enables the client to detect if the server is no longer available, without having to wait for the TCP/IP timeout. The client will ensure that at least one message travels across the network within each keep alive period. In the absence of a data-related message during the time period, the client sends a very small "ping" message, which the server will acknowledge. A value of 0 disables keepalive processing in the client.
The default value is 60 seconds.

- **setMaxInflight : int**
Sets the "max inflight". please increase this value in a high traffic environment.
The default value is 10.

- **setUserName : string**
Sets the user name to use for the connection.

- **setPassword : char[]**
Sets the password to use for the connection.

- **setServerURIs : string[]**
Set a list of one or more serverURIs the client may connect to.
Each serverURI specifies the address of a server that the client may connect to. Two types of connection are supported tcp:// for a TCP connection and ssl:// for a TCP connection secured by SSL/TLS. For example:
    tcp://localhost:1883
    ssl://localhost:8883
If the port is not specified, it will default to 1883 for tcp://" URIs, and 8883 for ssl:// URIs.
If serverURIs is set then it overrides the serverURI parameter passed in on the constructor of the MQTT client.
When an attempt to connect is initiated the client will start with the first serverURI in the list and work through the list until a connection is established with a server. If a connection cannot be made to any of the servers then the connect attempt fails.
Specifying a list of servers that a client may connect to has several uses:
    - **High Availability and reliable message delivery**
    Some MQTT servers support a high availability feature where two or more "equal" MQTT servers share state. An MQTT client can connect to any of the "equal" servers and be assured that messages are reliably delivered and durable subscriptions are maintained no matter which server the client connects to.
    The cleansession flag must be set to false if durable subscriptions and/or reliable message delivery is required.
    - **Hunt List**
    A set of servers may be specified that are not "equal" (as in the high availability option). As no state is shared across the servers reliable message delivery and durable subscriptions are not valid. The cleansession flag must be set to true if the hunt list mode is used.

- **setWill : void**
Sets the "Last Will and Testament" (LWT) for the connection. In the event that this client unexpectedly loses its connection to the server, the server will publish a message to itself using the supplied details.
**Parameters**:
    - **topic** - the topic to publish to : ```string```
    - **payload** - the byte payload for the message : ```string```
    - **qos** - the quality of service to publish the message at (0, 1 or 2) : ```int```
    - **retained** - whether or not the message should be retained : ```bool```

- **setSocketFactory : void**
Sets the SocketFactory to use. This allows an application to apply its own policies around the creation of network sockets. If using an SSL connection, an SSLSocketFactory can be used to supply application-specific security settings.
**Parameters**:
    - **caCrtFile** - the path to the CA Certificate file : ```string```
    - **crtFile** - the path to the Server Certificate file : ```string```
    - **keyFile** - the path to the Server Key Pair file : ```string```
    - **password** - the password you used to encrypt the certificates : ```string```

## SSL configuration

So far we have seen how to implement the MQTT protocol for data transmission without worrying about communication security.

In order to properly run the connector with an SSL encrypted connection, you need to add dependencies to your project to the **Bouncy Castle** library https://www.bouncycastle.org/java.html.
In particular, just add the following two jar files:
- ```bcpkix-jdk15to18-166.jar```;
- ```bcprov-ext-jdk15to18-166.jar```;
to download the jars go to https://www.bouncycastle.org/latest_releases.html.

##### Username and Password:

The MQTT protocol provides different degrees of security.
The simplest is authentication with **username** and **password**. In this case the communication is not secure (the transmitted data are not encrypted) but it is a good way to limit the access to the broker only to clients who know the username and password authentication.
To implement this behavior you need to perform two steps:
- create a password file;
- modify the ```mosquitto.conf``` file to force the use of the password;
To create a pasword file, open a text editor and enter your username and password, one for each line, separated by two dots as shown below:
```java
admin:adminPassword
test:testPassword
```

Now you need to convert the password file that encrypts passwords, go to a command line and type:
```mosquitto_passwd -U passwordfile```

At this point you must copy the newly encrypted password file to the mosquitto installation folder.
Now you only have to edit the ```mosquitto.conf``` file in which you will have to set the following commands:
```java
allow_anonymous false
password_file C:\mosquitto\passwords.txt
```
In order to take advantage of the changes made it will be necessary to restart the execution of the Mosquito broker.

After performing all the above steps, in the examples (```client_server``` and ```chat```) you can take advantage of the ```setUserName``` and ```setPassword``` connection options displayed in the ```MosquittoInterface.iol``` interface to create a connection to your Mosquitto broker as shown below:
```java
    request << {
        brokerURL = "ssl://localhost:8883",
        subscribe << {
            topic = "jolie/test/chat"
        }
        // I can set all the options available from the Paho library
        options << {
            setUserName = "test"
            setPassword = "testPassword"
        }
    }
    setMosquitto@Mosquitto (request)()
```

##### Certified based encryption:

Below is a text extracted from Mosquitto's official documentation (https://mosquitto.org/man/mosquitto-conf-5.html#):

```When using certificate based encryption there are three options that affect authentication. The first is require_certificate, which may be set to true or false. If false, the SSL/TLS component of the client will verify the server but there is no requirement for the client to provide anything for the server: authentication is limited to the MQTT built in username/password. If require_certificate is true, the client must provide a valid certificate in order to connect successfully. In this case, the second and third options, use_identity_as_username and use_subject_as_username, become relevant. If set to true, use_identity_as_username causes the Common Name (CN) from the client certificate to be used instead of the MQTT username for access control purposes. The password is not used because it is assumed that only authenticated clients have valid certificates. This means that any CA certificates you include in cafile or capath will be able to issue client certificates that are valid for connecting to your broker. If use_identity_as_username is false, the client must authenticate as normal (if required by password_file) through the MQTT options. The same principle applies for the use_subject_as_username option, but the entire certificate subject is used as the username instead of just the CN.```

In order to implement this type of encryption it is necessary to create a series of certificates. This is a fairly delicate step so I suggest you to follow the tutorial at the following link: https://mcuoneclipse.com/2017/04/14/enable-secure-communication-with-tls-and-the-mosquitto-broker/

Once you have created the certificates, properly modified the ```mosquitto.conf``` file and restarted the Mosquitto broker as shown in the tutorial above, you are ready to implement an encrypted communication in the ```client_server``` and ```chat``` examples.

To do this you need to set the certificate paths in the ```setSocketFactory``` option exposed by the ```MosquittoInterface.iol``` interface as shown below:

```java
    request << {
        brokerURL = "ssl://localhost:8883",
        subscribe << {
            topic = "jolie/test/chat"
        }
        // I can set all the options available from the Paho library
        options << {
            setSocketFactory << {
                caCrtFile = "C:\\Program Files\\mosquitto\\certs\\m2mqtt_ca.crt"
                crtFile = "C:\\Program Files\\mosquitto\\certs\\m2mqtt_srv.crt"
                keyFile = "C:\\Program Files\\mosquitto\\certs\\m2mqtt_srv.key"
                password = "password" //the password you used to encrypt the certificates
            }
        }
    }
    setMosquitto@Mosquitto (request)()
```