/* --------------------------------------------------------------------------------------------
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for license information.
 * ------------------------------------------------------------------------------------------ */

import * as path from 'path';
import { workspace, ExtensionContext, Diagnostic } from 'vscode';
import * as os from 'os';

import {
	LanguageClient,
	LanguageClientOptions,
	ServerOptions,
	TransportKind
} from 'vscode-languageclient/node';


// fast client for complete
let fastClient: LanguageClient;
// slow client for diagnostic
let slowClient: LanguageClient;

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
	let serverCommand = context.asAbsolutePath(
		path.join('server', luaBin)
	);
	const serverCommandArg1 = context.asAbsolutePath(
		path.join('server', 'thlua.lua')
	);
	const serverCommandArg3 = context.asAbsolutePath(
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
	slowClient = new LanguageClient(
		'TypeHintLua_slow',
		'TypeHintLua_slow',
		{ // server option
			command : serverCommand,
			args: [serverCommandArg1, "slow", serverCommandArg3]
		},
		clientOptions
	);

	fastClient = new LanguageClient(
		'TypeHintLua_fast',
		'TypeHintLua_fast',
		{ // server option
			command : serverCommand,
			args: [serverCommandArg1, "fast", serverCommandArg3]
		},
		clientOptions
	);

	// Start the client. This will also launch the server
	fastClient.start();
	slowClient.start();
}

export function deactivate(): Thenable<void> | undefined {
	const promises:Thenable<void>[] = [];
	if (!slowClient) {
		promises.push(slowClient.stop());
	}
	if (!fastClient) {
		promises.push(fastClient.stop());
	}
	return Promise.all(promises).then(() => undefined);
}
