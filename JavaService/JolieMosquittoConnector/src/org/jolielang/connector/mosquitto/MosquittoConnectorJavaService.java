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

package org.jolielang.connector.mosquitto;

import jolie.runtime.JavaService;
import jolie.runtime.Value;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.eclipse.paho.client.mqttv3.MqttTopic;
import org.eclipse.paho.client.mqttv3.persist.MqttDefaultFilePersistence;

public class MosquittoConnectorJavaService extends JavaService {
    
    private MqttClient client;
    
    public Value setMosquitto (Value request) {
        String brokerURL = request.getFirstChild("brokerURL").strValue();
        String clientId;
        if (request.hasChildren("clientId")) {
            clientId = request.getFirstChild("clientId").strValue();
        } else {
            clientId = MqttClient.generateClientId();
        }
        try {
            this.client = new MqttClient(brokerURL, clientId, new MqttDefaultFilePersistence("/tmp"));            
            
            MqttConnectOptions options = new MqttConnectOptions();
            
            // implementazione delle opzioni MqttConnectOptions
            if (request.getFirstChild("options").getFirstChild("debug").boolValue()) {
                System.out.println("================================================================================");
            }
            if (request.hasChildren("options")) {
                Value op = request.getFirstChild("options");
                if (op.hasChildren("setAutomaticReconnect")) {
                    options.setAutomaticReconnect(op.getFirstChild("setAutomaticReconnect").boolValue());
                    if (op.getFirstChild("debug").boolValue()) {
                        System.out.println("setAutomaticReconnect     correctly set   |   Value : "+op.getFirstChild("setAutomaticReconnect").boolValue());
                    }
                } else {
                    if (op.getFirstChild("debug").boolValue()) {
                        System.out.println("setAutomaticReconnect        default      |   Value : "+options.isAutomaticReconnect());
                    }
                }
                if (op.hasChildren("setCleanSession")) {
                    options.setCleanSession(op.getFirstChild("setCleanSession").boolValue());
                    if (op.getFirstChild("debug").boolValue()) {
                        System.out.println("setCleanSession           correctly set   |   Value : "+op.getFirstChild("setCleanSession").boolValue());
                    }
                } else {
                    if (op.getFirstChild("debug").boolValue()) {
                        System.out.println("setCleanSession              default      |   Value : "+options.isCleanSession());
                    }
                }
                if (op.hasChildren("setConnectionTimeout")) {
                    options.setConnectionTimeout(op.getFirstChild("setConnectionTimeout").intValue());
                    if (op.getFirstChild("debug").boolValue()) {
                        System.out.println("setConnectionTimeout      correctly set   |   Value : "+op.getFirstChild("setConnectionTimeout").intValue());
                    }
                } else {
                    if (op.getFirstChild("debug").boolValue()) {
                        System.out.println("setConnectionTimeout         default      |   Value : "+options.getConnectionTimeout());
                    }
                }
                if (op.hasChildren("setKeepAliveInterval")) {
                    options.setKeepAliveInterval(op.getFirstChild("setKeepAliveInterval").intValue());
                    if (op.getFirstChild("debug").boolValue()) {
                        System.out.println("setKeepAliveInterval      correctly set   |   Value : "+op.getFirstChild("setKeepAliveInterval").intValue());
                    }
                } else {
                    if (op.getFirstChild("debug").boolValue()) {
                        System.out.println("setKeepAliveInterval         default      |   Value : "+options.getKeepAliveInterval());
                    }
                }
                if (op.hasChildren("setMaxInflight")) {
                    options.setMaxInflight(op.getFirstChild("setMaxInflight").intValue());
                    if (op.getFirstChild("debug").boolValue()) {
                        System.out.println("setMaxInflight            correctly set   |   Value : "+op.getFirstChild("setMaxInflight").intValue());
                    }
                } else {
                    if (op.getFirstChild("debug").boolValue()) {
                        System.out.println("setMaxInflight               default      |   Value : "+options.getMaxInflight());
                    }
                }
                if (op.hasChildren("setServerURIs")) {
                    String[] serverURIs = new String[op.getChildren("setServerURIs").size()];
                    for (int i=0; i<op.getChildren("setServerURIs").size(); i++) {
                        serverURIs[i] = op.getChildren("setServerURIs").get(i).strValue();
                        if (op.getFirstChild("debug").boolValue()) {
                            System.out.println("URI["+i+"]            correctly set   |   Value : "+serverURIs[i]);
                        }
                    }
                    options.setServerURIs(serverURIs);
                }
                if (op.hasChildren("setUserName")) {
                    options.setUserName(op.getFirstChild("setUserName").strValue());
                    if (op.getFirstChild("debug").boolValue()) {
                        System.out.println("setUserName               correctly set   |   Value : "+op.getFirstChild("setUserName").strValue());
                    }
                } else {
                    if (op.getFirstChild("debug").boolValue()) {
                        System.out.println("setUserName                  default      |   Value : "+options.getUserName());
                    }
                }
                if (op.hasChildren("setPassword")) {
                    options.setPassword(op.getFirstChild("setPasswrd").strValue().toCharArray());
                    if (op.getFirstChild("debug").boolValue()) {
                        System.out.println("setPassword               correctly set   |   Value : "+op.getFirstChild("setPassword").strValue());
                    }
                } else {
                    if (op.getFirstChild("debug").boolValue()) {
                        System.out.println("setPassword                  default      |   Value : "+options.getPassword());
                    }
                }
                if (op.hasChildren("setWill")) {
                    Value setWill = op.getFirstChild("setWill");
                    String topic = setWill.getFirstChild("topicWill").strValue();
                    String payload = setWill.getFirstChild("payloadWill").strValue();
                    int qos = setWill.getFirstChild("qos").intValue();
                    boolean retained = setWill.getFirstChild("retained").boolValue();
                    options.setWill(client.getTopic(topic), payload.getBytes(), qos, retained);
                    if (op.getFirstChild("debug").boolValue()) {
                        System.out.println("setWill                   correctly set   |   Topic    : "+topic);
                        System.out.println("                                          |   Payload  : "+payload);
                        System.out.println("                                          |   Qos      : "+qos);
                        System.out.println("                                          |   Retained : "+retained);
                    }
                } else {
                    if (op.getFirstChild("debug").boolValue()) {
                        System.out.println("setWill                      default      |   Value : "+options.getWillMessage());
                    }
                }
            }
            if (request.getFirstChild("options").getFirstChild("debug").boolValue()) {
                System.out.println("================================================================================");
            }
            
            client.connect(options);
            if (request.hasChildren("subscribe")) {
                client.setCallback(new SubscribeCallback(this));
                for (int i=0; i<request.getFirstChild("subscribe").getChildren("topic").size(); i++) {
                    Value topic = request.getFirstChild("subscribe").getChildren("topic").get(i);
                    client.subscribe(topic.strValue());
                }
            }
            
	} catch (MqttException e) {
            e.printStackTrace();
	}
        return Value.create();
    }
    
    public Value sendMessage (Value request) {
        
        MqttTopic topic = client.getTopic(request.getFirstChild("topic").strValue());
		
        try {
            topic.publish(new MqttMessage(request.getFirstChild("message").strValue().getBytes()));
        } catch (MqttException ex) {
            ex.printStackTrace();
        }
        return Value.create();
    }
}
