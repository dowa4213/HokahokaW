(* Wolfram Language Package *)

(* Created by the Wolfram Workbench Jan 31, 2015 *)

BeginPackage["HokahokaW`Package`"];

General::invalidArgs="Function called with invalid arguments `1`.";
General::invalidOptionValue="Option argument `2` -> `1` is invalid.";
General::deprecated="Function is deprecated, use `1` instead.";

(* ::Section::Closed:: *)
(* Package Git functions *)
HHPackageNewestFileDate::usage="Prints the newest file change date for all files within the given package or within the current NotebookDirectory[].";
HHPackageGitRemotes::usage="Prints a list of git remotes for either the given package or the current NotebookDirectory[].";
HHPackageGitHEAD::usage="Prints the git HEAD hash for either the given directory or the current NotebookDirectory[].";
HHPackageMessage::usage="Prints standard package message.";
(* TODO: test that notebook message is working with HHPackageMessage[] *)
(*HHNotebookMessage::usage="Prints standard notebook message.";*)

Begin["`Private`"];
(* Implementation of the package *)

(* ::Section::Closed:: *)
(* Package Git functions *)

(* ::Subsection::Closed:: *)
(* HHPackageNewestFileDate *)


HHPackageNewestFileDate[package_String]:=
Module[{packageFile,tempdir},
	
	packageFile = FindFile[package];
	
	tempdir = If[packageFile =!= $Failed,
		FileNames[ "*",
			ParentDirectory[DirectoryName[ packageFile ]],
			Infinity
		],
		{}
	];
	
	If[ Length[tempdir]==0,
		Message[HHPackageNewestFileDate::noFilesFound, package]; "",
		DateString[Max @@ AbsoluteTime /@ FileDate /@ tempdir ]
	]
	
];
HHPackageNewestFileDate[args___]:=Message[HHPackageNewestFileDate::invalidArgs,{args}];
HHPackageNewestFileDate::noFilesFound = "No files were found for package:  `1`.";

(* ::Subsection::Closed:: *)
(* HHPackageGitImpl (private) *)

HHPackageGitImpl[directory_String, command_String]:=
Module[{errorcode,tempret},
	SetDirectory[ directory ];
	errorcode = Run[command <> " > HHPackageGitImplTemp.txt"];
	If[ errorcode == 0,
		tempret = Import["HHPackageGitImplTemp.txt"];
		DeleteFile["HHPackageGitImplTemp.txt"],
		Message[HHPackageGitImpl::gitError, command, directory];
		tempret = $Failed; 		
	];
	ResetDirectory[];
	tempret
];
HHPackageGitImpl::gitError="Call to Git returned error. It could be that Git is " <>
 "not installed correctly, the command `1` is not valid, or the directory `2` is not valid."; 

(* ::Subsection::Closed:: *)
(* HHPackageGitRemotes *)

HHPackageGitRemotes[package_String]:= Module[{tempFile},
	tempFile=FindFile[package];
	If[ tempFile === $Failed,
		Message[HHPackageGitRemotes::noFilesFound, package];
		$Failed,
		HHPackageGitImpl[ ParentDirectory[DirectoryName[ tempFile ]], "git remote -v" ]
	]
];
HHPackageGitRemotes[]:= HHPackageGitImpl[ NotebookDirectory[], "git remote -v" ];
HHPackageGitRemotes[args___]:=Message[HHPackageGitRemotes::invalidArgs,{args}];
HHPackageGitRemotes::noFilesFound = HHPackageNewestFileDate::noFilesFound;

(* ::Subsection::Closed:: *)
(* HHPackageGitHEAD *)

HHPackageGitHEAD[package_String]:= Module[{tempFile},
	tempFile=FindFile[package];
	If[ tempFile === $Failed,
		Message[HHPackageGitHEAD::noFilesFound, package];
		" ",
		HHPackageGitImpl[ ParentDirectory[DirectoryName[ tempFile ]], "git rev-parse HEAD" ]
	]
];
HHPackageGitHEAD[]:= HHPackageGitImpl[ NotebookDirectory[], "git rev-parse HEAD" ];


HHPackageGitHEAD[args___]:=Message[HHPackageGitHEAD::invalidArgs,{args}];
HHPackageGitHEAD::noFilesFound = HHPackageNewestFileDate::noFilesFound;

(* ::Subsection::Closed:: *)
(* HHPackageMessage *)
HHPackageMessage[package_String]:=
Module[{remotes, head, newest},
	remotes=Quiet[HHPackageGitRemotes[package]];
	head=   Quiet[HHPackageGitHEAD[package]];
	newest= Quiet[HHPackageNewestFileDate[package]];
	
	If[ remotes === $Failed || head === $Failed || newest === $Failed,
		Message[HHPackageMessage::gitError, " ", package],
		CellPrint[TextCell[Row[{
			Style[package, 
				FontFamily -> "Helvetica", FontWeight -> "Bold", 
				FontVariations -> {"Underline" -> True}
				], 
			"\n" ,
			Style[StringJoin@@Riffle[
					"("<> #[[1]]<>")[" <> #[[2]] <>"]"& /@
					Union[ImportString[remotes][[All, 1;;2]]]
				,"\n"],
				Small, FontFamily->"Courier"
				], 
			"\n",
			Style[
				"current Git HEAD:  "<> head <>"\n" <>
				"newest file:  "<> newest <>" ", 
				Small, FontFamily->"Courier"]
			}],"Text", Background -> LightGray]]
	];
];
HHPackageMessage[]:=HHPackageMessage[ NotebookDirectory[] ];

HHPackageMessage::gitError=HHPackageGitImpl::gitError;

(* ::Section::Closed:: *)
(* End *)

End[];

HHPackageMessage["HokahokaW`"];

EndPackage[];

