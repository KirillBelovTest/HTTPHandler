#!/usr/bin/env wolframscript
(* ::Package:: *)

<<KirillBelov`Internal`
<<KirillBelov`TCPServer`

SetDirectory[FileNameJoin[{DirectoryName[$InputFileName], "StaticWebsite"}]]

Get[FileNameJoin[{ParentDirectory[ParentDirectory[]], "Kernel", "HTTPHandler.wl"}]]
Get[FileNameJoin[{ParentDirectory[ParentDirectory[]], "Kernel", "Extensions.wl"}]]

tcp = TCPServer[]
tcp["CompleteHandler", "HTTP"] = HTTPPacketQ -> HTTPPacketLength
tcp["MessageHandler", "HTTP"]  = HTTPPacketQ -> http

Print["Starting HTTP handler"];

http = HTTPHandler[]
http["MessageHandler", "Index"]  = AssocMatchQ[<|"Path" -> "/"|>] -> Function[StringToByteArray["hello"]]
http["MessageHandler", "TXT"]  = AssocMatchQ[<|"Path" -> __ ~~ ".txt"|>] -> Function[Import["C:\\Users\\Kirill\\Projects\\HTTPHandler\\Examples\\StaticWebsite\\file.txt"]]

listener = CSocketListen[8000, tcp#&]

While[True, Pause[0.01]]
