#!/usr/bin/env wolframscript
(* ::Package:: *)

<<KirillBelov`Internal`
<<KirillBelov`TCPServer`
<<KirillBelov`WebSocketHandler`

SetDirectory[FileNameJoin[{DirectoryName[$InputFileName], "DynamicWebsite"}]]
$PathDir := (Print["* IO Operations *"]; {"public", ""});

RandomWord[]

Get["https://raw.githubusercontent.com/JerryI/wl-wsp/main/Kernel/WSP.wl"]

Get[FileNameJoin[{ParentDirectory[ParentDirectory[]], "Kernel", "HTTPHandler.wl"}]]
Get[FileNameJoin[{ParentDirectory[ParentDirectory[]], "Kernel", "Extensions.wl"}]]
Get[FileNameJoin[{ParentDirectory[ParentDirectory[]], "Kernel", "WSPAdapter.wl"}]]

Get["https://raw.githubusercontent.com/JerryI/wl-misc/main/Kernel/Channels.wl"]
Get["https://raw.githubusercontent.com/JerryI/wl-misc/main/Kernel/Events.wl"]

Get["modules/Hydrator.wl"]
Get["modules/Polyfill.wl"]

Print["Staring HTTP server..."];

tcp = TCPServer[]
tcp["CompleteHandler", "HTTP"] = HTTPPacketQ -> HTTPPacketLength
tcp["MessageHandler", "HTTP"]  = HTTPPacketQ -> http

http = HTTPHandler[]
http["MessageHandler", "File"]  = GetFileRequestQ[{"html", "css", "js", "png", "jpg", "svg"}] -> (
  ImportFileAsText[#, "Base":>$PathDir] &
)
http["MessageHandler", "WSP"] = GetFileRequestQ[{"wsp"}] -> (HypertextProcess[#, "Base":>$PathDir]&)
http["MessageHandler", "Index"]  = AssocMatchQ[<|"Path" -> "/"|>] ->  (HypertextProcess[#, "index.wsp", "Base":>$PathDir]&)

http["MessageHandler", "Post"] = GetPOSTRequestQ[{"wsp"}] -> Composition[(HypertextProcess[#, "Base":>$PathDir]&), ProcessMultipart]


httplistener = SocketListen[8000, tcp@#&]

Print["Staring WS/HTTP server..."];

wcp = TCPServer[]
wcp["CompleteHandler", "WebSocket"] = WebSocketPacketQ -> WebSocketPacketLength
wcp["MessageHandler", "WebSocket"]  = WebSocketPacketQ -> ws

ws = WebSocketHandler[]

ws["MessageHandler", "Evaluate"]  = Function[True] -> evaluate



evaluate[cl_SocketObject, data_ByteArray] := Block[{Global`client = cl},
    Print["--------------------------------"];
    Print[data//ByteArrayToString];
    ToExpression[data//ByteArrayToString];
]

SocketListen[8005, wcp@#&]

SetOptions[WSPEngine, "Cache"->False];

WebSocketChannel[Automatic]["Serializer"] = ExportByteArray[#, "ExpressionJSON"]&
WebSocketChannel["jsio"]["Serializer"] = ExportByteArray[#, "ExpressionJSON"]&

StringTemplate["Open your browser on ``"][URLBuild[<|"Scheme" -> "http", 
  "Port" -> httplistener["Socket"]["DestinationPort"], 
  "Domain" -> First[httplistener["Socket"]["DestinationIPAddress"]]|>]] // Print;

Get /@ FileNames["server.wl", "public", Infinity];

While[True, Pause[1]];