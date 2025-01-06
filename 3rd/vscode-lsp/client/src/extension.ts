/* --------------------------------------------------------------------------------------------
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for license information.
 * ------------------------------------------------------------------------------------------ */

import * as path from 'path';
import * as vscode from 'vscode';
import { workspace, ExtensionContext, Diagnostic } from 'vscode';
import * as os from 'os';
import {spawn} from 'child_process'

import {
	LanguageClient,
	LanguageClientOptions,
	ServerOptions,
	TransportKind
} from 'vscode-languageclient/node';


// fast client for complete
let langClient: LanguageClient;

export function activate(context: ExtensionContext) {
	let luaBin = "lua.exe"
	if(os.platform() == "win32") {
		luaBin = "lua.exe";
	} else if (os.platform() == "linux"){
		luaBin = "linux_lua";
	} else if (os.platform() == "darwin"){
		if(os.arch() == "x64"){
			luaBin = "osx_x64_lua";
		} else {
			luaBin = "osx_arm_lua";
		}
	}
	let luaCommand = context.asAbsolutePath(
		path.join('server', luaBin)
	);
	context.subscriptions.push(vscode.commands.registerCommand("TypeHintLua.runCode", ()=>{
		const term = vscode.window.createOutputChannel("TypeHintLua");
		const activeEditor = vscode.window.activeTextEditor;
		if(activeEditor){
			//For Getting File Path
			let filePath = activeEditor.document.uri.fsPath;
			term.show();
			const process = spawn(luaCommand, [filePath]);
			process.stdout.on('data', (data) => {
				term.append(data);
			});

			process.stderr.on('data', (data) => {
				term.append(data);
			});

			process.on('close', (code) => {
			});
		}
	}));

	const serverCommandArg1 = context.asAbsolutePath(
		path.join('server', 'thlua.lua')
	);
	const serverCommandArg2 = context.asAbsolutePath(
		path.join('server', 'global')
	);

	// If the extension is launched in debug mode then the debug server options are used

	// Options to control the language client
	const clientOptions: LanguageClientOptions = {
		// Register the server for plain text documents
		documentSelector: [{ scheme: 'file', language: 'thlua' }],
		synchronize: {
			// Notify the server about file changes to '.clientrc files contained in the workspace
			// fileEvents: workspace.createFileSystemWatcher('**/.clientrc')
		}
	};

	// Create the language client and start the client.
	langClient = new LanguageClient(
		'TypeHintLua',
		'TypeHintLua',
		{ // server option
			command : luaCommand,
			args: [serverCommandArg1, serverCommandArg2]
		},
		clientOptions
	);

	// Start the client. This will also launch the server
	langClient.start();
}

export function deactivate(): Thenable<void> | undefined {
	const promises:Thenable<void>[] = [];
	if (!langClient) {
		promises.push(langClient.stop());
	}
	return Promise.all(promises).then(() => undefined);
}
