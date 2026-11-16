/* --------------------------------------------------------------------------------------------
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See License.txt in the project root for license information.
 * ------------------------------------------------------------------------------------------ */

import * as path from 'path';
import * as vscode from 'vscode';
import { workspace, ExtensionContext } from 'vscode';
import * as os from 'os';
import * as fs from 'fs';
import {spawn} from 'child_process'

import {
	LanguageClient,
	LanguageClientOptions,
	ServerOptions
} from 'vscode-languageclient/node';


// fast client for complete
let langClient: LanguageClient;

export function activate(context: ExtensionContext) {
	const bundledCommand = context.asAbsolutePath(
		path.join('server', os.platform() === 'win32' ? 'thlua.exe' : 'thlua')
	);
	const configuredCommand = workspace.getConfiguration('TypeHintLua').get<string>('executablePath', '').trim();
	const thluaCommand = configuredCommand || (fs.existsSync(bundledCommand) ? bundledCommand : 'thlua');
	const term = vscode.window.createOutputChannel('TypeHintLua');
	context.subscriptions.push(term);
	context.subscriptions.push(vscode.commands.registerCommand("TypeHintLua.runCode", ()=>{
		const activeEditor = vscode.window.activeTextEditor;
		if(activeEditor){
			//For Getting File Path
			let filePath = activeEditor.document.uri.fsPath;
			term.show();
			const cwd = workspace.getWorkspaceFolder(activeEditor.document.uri)?.uri.fsPath || path.dirname(filePath);
			const process = spawn(thluaCommand, ['run', filePath], {cwd});
			process.stdout.on('data', (data) => {
				term.append(data.toString());
			});

			process.stderr.on('data', (data) => {
				term.append(data.toString());
			});

			process.on('error', (error) => term.appendLine(error.message));
		}
	}));

	const globalDirectory = context.asAbsolutePath(
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

	const serverOptions: ServerOptions = {
		command: thluaCommand,
		args: ['lsp', '--stdio', '--global', globalDirectory]
	};
	// Create the language client and start the client.
	langClient = new LanguageClient(
		'TypeHintLua',
		'TypeHintLua',
		serverOptions,
		clientOptions
	);

	// Start the client. This will also launch the server
	langClient.start();
}

export function deactivate(): Thenable<void> | undefined {
	const promises:Thenable<void>[] = [];
	if (langClient) {
		promises.push(langClient.stop());
	}
	return Promise.all(promises).then(() => undefined);
}
