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

type SendChatMessageRequest: void {
    message: string
} 

type GetChatMessagesResponse: void {
    messageQueue*: void {
        message: string
        username: string
        session_user: string
    }
}

type SetUsernameRequest: void {
    username: string
}

interface FrontendInterface {
    RequestResponse:
		sendChatMessage( SendChatMessageRequest )( void ),
        getChatMessages( void )( GetChatMessagesResponse ),
        setUsername( SetUsernameRequest )( void )
}