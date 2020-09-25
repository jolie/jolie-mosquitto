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

import jolie.net.CommMessage;
import jolie.runtime.JavaService;
import jolie.runtime.Value;
import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.MqttMessage;

public class SubscribeCallback implements MqttCallback {

        private JavaService javaService;
    
        public SubscribeCallback (JavaService javaService) {
            this.javaService = javaService;
        }
    
	@Override
	public void connectionLost(Throwable cause) {
            // I have to implement a behavior in case of lost connection		
	}

	@Override
	public void deliveryComplete(IMqttDeliveryToken token) {
            // method called when a message is delivered
	}

	@Override
	public void messageArrived(String topic, MqttMessage message) throws Exception {
            Value request = Value.create();
            request.getNewChild("topic").setValue(topic);
            request.getNewChild("message").setValue(message.toString());
            
            String[] tokens = topic.split("/");
            
            if (tokens[0].equals("mqttTransform4Jolie")) {
                if (tokens[tokens.length - 1].equals("response")) {
                    request.getNewChild("session_token").setValue(tokens[tokens.length - 2]);
                    request.getNewChild("client_token").setValue(tokens[tokens.length - 4]);
                } else {
                    request.getNewChild("session_token").setValue(tokens[tokens.length - 1]);
                    request.getNewChild("client_token").setValue(tokens[tokens.length - 3]);
                }
            }
            javaService.sendMessage(CommMessage.createRequest("receive", "/", request));
	}

}
