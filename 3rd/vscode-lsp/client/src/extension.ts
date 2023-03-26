/* --------------------------------------------------------------------------------------------
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for license information.
 * ------------------------------------------------------------------------------------------ */

import * as path from 'path';
import { workspace, ExtensionContext, Diagnostic } from 'vscode';

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
	const serverCommand = context.asAbsolutePath(
		path.join('server', 'lua.exe')
	);
	const serverCommandArg = context.asAbsolutePath(
		path.join('server', 'thlua.lua')
	);

	// If the extension is launched in debug mode then the debug server options are used

	// Options to control the language client
	const clientOptions: LanguageClientOptions = {
		// Register the server for plain text documents
		documentSelector: [{ scheme: 'file', language: 'thlua' }],
		synchronize: {
			// Notify the server about file changes to '.clientrc files contained in the workspace
			fileEvents: workspace.createFileSystemWatcher('**/.clientrc')
		}
	};

	// Create the language client and start the client.
	slowClient = new LanguageClient(
		'TypeHintLua',
		'TypeHintLua',
		{ // server option
			command : serverCommand,
			args: [serverCommandArg, "slow"]
		},
		clientOptions
	);

	fastClient = new LanguageClient(
		'TypeHintLua',
		'TypeHintLua',
		{ // server option
			command : serverCommand,
			args: [serverCommandArg, "fast"]
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
