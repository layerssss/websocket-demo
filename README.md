
# WebSocket introduction

Michael Yin

## Demo first

* Server: using a WebSocket library (em_websocket) for server
* Client: simple JavaScript

## Assumptions, before we go into the protocol…

### TCP Sockets

* Bidirectional stream of data
* Bytes order are ensured
* Bytes won’t be missing
* Bytes are what you get. (No other boundaries except “bytes”)

### HTTP 1.0

Client connects to server via TCP

Client sends request headers, and payload (if any)

```
GET /index.html HTTP/1.0
Host: www.example.com
User-Agent: NCSA_Mosaic/2.0 (Windows 3.1)
... other headers
```

Server sends response headers and playload (if any)

```
200 OK
Content-Type: text/html
... other headers

<html>
Welcome to the <img src="/logo.gif"> example.com homepage!
</html>
```

Server and client close connection when they are "done".

### HTTP 1.1

Client connects to server via TCP

Client sends request

```
GET /index.html HTTP/1.1
Host: www.example.com
User-Agent: NCSA_Mosaic/2.0 (Windows 3.1)
... other headers
```

Server sends response

```
200 OK
Connection: Keep-Alive
Keep-Alive: timeout=5, max=1000
Content-Type: text/html
... other headers

<html>
Welcome to the <img src="/logo.gif"> example.com homepage!
</html>
```

Client send another request, and server response within the same TCP connection

Either client or server can indicate `Connection: Close` in a request / response.

> https://www.quora.com/Is-the-Content-Length-header-mandatory-on-HTTP-responses
> 
> Is the **Content-Length** header mandatory on HTTP responses?
>
> The Content-Length header is not mandatory on HTTP responses. However, it is considered good practice to include it when the response body has a known length. This allows the recipient of the response to properly handle the response and ensure that the entire response has been received.
> 
> Not mandatory but the other options are:
> 
> * Responding with an HTTP status that doesn’t allow content in the response (e.g. 204 No Content)
> * close the connection when you’re finished transmitting the response’s bytes (instead of being able to re-use that connection for following request-response cycles)
> * transfer the response in chunked encoding, finished by “a chunk of length zero”
> * give the response as a multipart. In that case the response ends with the end of multipart boundary.


## WebSocket handshake

Client connects to server via TCP

Client sends handshake request

```
GET /chat HTTP/1.1
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
Sec-WebSocket-Version: 13
... other common HTTP headers like Host, Cookie, Referer etc.
```

`Sec-WebSocket-Key`: randomly generated for each connection.

Servers sends handshake response

```
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
... other common HTTP headers like Set-Cookie, Server etc.
```

`Sec-WebSocket-Accept` is calculated via `base64(request['Sec-WebSocket-Key] + MAGIC_STRING)`

`MAGIC_STRING` is `258EAFA5-E914-47DA-95CA-C5AB0DC85B11`

Handshake is designed this way so:

* It allows the client to verify that the server does indeed understand WebSockets
* If an intermediary caches the response and returns it as part of a new request, the client will be able to recognize that the response is no longer valid
* It is not intended to provide Authentication or enhance privacy

Then client and server start sending frames to each other

## WebSocket frames


```
Frame format:

      0                   1                   2                   3
      0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
     +-+-+-+-+-------+-+-------------+-------------------------------+
     |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
     |I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
     |N|V|V|V|       |S|             |   (if payload len==126/127)   |
     | |1|2|3|       |K|             |                               |
     +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
     |     Extended payload length continued, if payload len == 127  |
     + - - - - - - - - - - - - - - - +-------------------------------+
     |                               |Masking-key, if MASK set to 1  |
     +-------------------------------+-------------------------------+
     | Masking-key (continued)       |          Payload Data         |
     +-------------------------------- - - - - - - - - - - - - - - - +
     :                     Payload Data continued ...                :
     + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
     |                     Payload Data continued ...                |
     +---------------------------------------------------------------+

```

Parts of a frame:

* FIN (1 bit): 1 if this is the final frame (of a message)
* reserved bits (3 bits): not in use
* opscode (4 bits): 
    * **0x0** continuation frame, see Fragmentation
    * **0x1** text
    * **0x2** binary
    * **0x8** close
    * **0x9** ping
    * **0xA** pong
* MASK (1 bit): whether payload is masked. **Messages from the client must be masked**
* payload len (7 / 7 + 16 / 7 + 64 bits): single payload len max 2^63 ~=9.22 exabytes
* masking key (4 bits): if MASK is 1
* payload: raw payload or XOR-masked payload

Fragmentation: a single message can be sent via multiple frames, example:

```
Client: FIN=1, opcode=0x1, msg="hello"
Server: (process complete message immediately) Hi.
Client: FIN=0, opcode=0x1, msg="and a"
Server: (listening, new message containing text started)
Client: FIN=0, opcode=0x0, msg="happy new"
Server: (listening, payload concatenated to previous message)
Client: FIN=1, opcode=0x0, msg="year!"
Server: (process complete message) Happy new year to you too!


client text: hello
server text: Hi.
client text: and a happy new year!
server text: Happy new year to you too!
```

## Closing connection

either side send a **close**(0x8) frame, frame body can include these non-user visible info for debugging only purpose

* 2 bytes status code (not defined by WebSocket spec)
* UTF-8-encoded data for reason

> MDN: As the data is not guaranteed to be human readable, clients MUST NOT show it to end users.

The other side replies with another **close** frame, then the underlying TCP connection must be closed.

## Another demo...

... since we understand everything now.

## WebSocket Extensions & Protocol

* Extentions: think of an extension as compressing a file before emailing it to someone. 
* Subprotocols: `Sec-WebSocket-Protocol` header

An example of ActionCable client running on Google Chrome

```
GET wss://?????/cable?token=????
Host: ?????
Connection: Upgrade
Pragma: no-cache
Cache-Control: no-cache
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36
Upgrade: websocket
Origin: https://????
Sec-WebSocket-Version: 13
Accept-Encoding: gzip, deflate, br
Accept-Language: en-NZ,en;q=0.9,en-US;q=0.8,it-IT;q=0.7,it;q=0.6,de;q=0.5,zh-CN;q=0.4,zh;q=0.3
Sec-WebSocket-Key: /KxVjeOCGGAFxB7aAqfrDg==
Sec-WebSocket-Extensions: permessage-deflate; client_max_window_bits
Sec-WebSocket-Protocol: actioncable-v1-json, actioncable-unsupported
```

```
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: /O2k5y8t7gizyLi9L2u7quZlOGI=
Sec-WebSocket-Protocol: actioncable-v1-json
```

## Why Masking?

> Masking is a security feature that's meant to thwart malicious client-side code from having control over the exact sequence of bytes which appear on the wire. [Section 10.3](https://www.rfc-editor.org/rfc/rfc6455#section-10.3) has more details.

## HTTP2.0 and beyond

## References & more

* MDN: Writing WebSocket servers - https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_servers
* RFC 6455 - The WebSocket Protocol - https://www.rfc-editor.org/rfc/rfc6455
* websocket-ruby - https://github.com/imanel/websocket-ruby
* em-websocket - https://github.com/igrigorik/em-websocket
* Getting Started with Ruby and WebSockets - https://www.engineyard.com/blog/getting-started-with-ruby-and-websockets/
* Building a simple websockets server from scratch in Ruby - https://www.honeybadger.io/blog/building-a-simple-websockets-server-from-scratch-in-ruby/
