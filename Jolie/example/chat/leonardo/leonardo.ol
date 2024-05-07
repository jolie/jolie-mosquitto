/*
   Copyright 2008-2012 Fabrizio Montesi <famontesi@gmail.com>

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
from string-utils import StringUtils
from protocols.http import DefaultOperationHttpRequest
from .frontend import Frontend, SetUsernameRequest, GetChatMessagesResponse,
    SendChatMessageRequest

include "config.iol"

interface HTTPInterface {
RequestResponse:
	default(DefaultOperationHttpRequest)(undefined)
}

service Leonardo {

embed Console as Console
embed File as File
embed StringUtils as StringUtils
embed Frontend as Frontend

execution: concurrent

inputPort HTTPInput {
	Protocol: http {
		.keepAlive = false; // Keep connections open
		.debug = DebugHttp;
		.debug.showContent = DebugHttpContent;
		.format -> format;
		.contentType -> mime;
		.default = "default"
	}
	Location: "auto:ini:/Locations/Leonardo:file:locations.ini"
	Interfaces: HTTPInterface
	Aggregates: Frontend
}

init {
	if ( is_defined( args[0] ) ) {
		documentRootDirectory = args[0]
	} else {
		documentRootDirectory = RootContentDirectory
	}
}

main {
	[ default( request )( response ) {
		scope( scp ) {
			install( FileNotFound => println@Console( "File not found: " + file.filename )() );

			s = request.operation;
			s.regex = "\\?";
			split@StringUtils( s )( s );

			// Default page
			if ( s.result[0] == "" ) {
				s.result[0] = DefaultPage
			};
			file.filename = documentRootDirectory + s.result[0];

			getMimeType@File( file.filename )( mime );
			mime.regex = "/";
			split@StringUtils( mime )( s );
			if ( s.result[0] == "text" ) {
				file.format = "text";
				format = "html"
			} else {
				file.format = format = "binary"
			};

			readFile@File( file )( response )
		}
	} ] { nullProcess }
}

}