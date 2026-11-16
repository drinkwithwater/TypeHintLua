"""Standalone executable contract tests. Run after `cargo build`.

python test/rust_cli.py [path/to/thlua.exe]
Only the executable is copied into the temporary workspace; no Lua installation,
shared libraries, bundled scripts, or source tree are available to the process.
"""
import json
import os
from pathlib import Path
import queue
import shutil
import subprocess
import sys
import tempfile
import threading
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
BINARY = Path(os.environ.get('THLUA_TEST_BINARY', ROOT / (
    'target/debug/thlua.exe' if os.name == 'nt' else 'target/debug/thlua'))).resolve()


class Standalone(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix='thlua-中文-')
        self.addCleanup(self.directory.cleanup)
        self.cwd = Path(self.directory.name)
        self.exe = self.cwd / BINARY.name
        shutil.copy2(BINARY, self.exe)
        self.env = os.environ.copy()
        self.env['LUA_PATH'] = ''
        self.env['LUA_CPATH'] = ''

    def write(self, name, content):
        path = self.cwd / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding='utf-8')
        return path

    def cli(self, *args):
        return subprocess.run([str(self.exe), *args], cwd=self.cwd, env=self.env,
                              capture_output=True, encoding='utf-8', timeout=30)

    def test_compile_and_run_with_args(self):
        self.write('hello.thlua', 'const value:Integer = 42\nprint(value, arg[0], arg[1])\n')
        result = self.cli('thc', 'hello.thlua', '-o', 'hello.lua')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn(':Integer', (self.cwd / 'hello.lua').read_text())
        result = self.cli('run', 'hello.thlua', '世界')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('42\thello.thlua\t世界', result.stdout)

    def test_compile_stdout_and_syntax_error_preserves_output(self):
        self.write('ok.thlua', 'const value:Integer = 42\n')
        result = self.cli('compile', 'ok.thlua')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('local value', result.stdout)
        self.write('broken.thlua', 'local =\n')
        self.write('keep.lua', 'keep')
        result = self.cli('compile', 'broken.thlua', '-o', 'keep.lua')
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertEqual((self.cwd / 'keep.lua').read_text(), 'keep')

    def test_bad_arguments_and_io_status(self):
        for args in [('unknown',), ('compile',), ('lsp', '--socket'), ('check', '--project')]:
            with self.subTest(args=args):
                self.assertEqual(self.cli(*args).returncode, 2, args)
        self.assertEqual(self.cli('compile', 'missing.thlua').returncode, 2)
        self.write('same.thlua', 'const value = 1')
        self.assertEqual(self.cli('compile', 'same.thlua', '-o', 'same.thlua').returncode, 2)

    def test_check_and_project_use_embedded_globals(self):
        self.write('app/good.thlua', 'const value:Integer = 42\nprint(value)\n')
        self.write('app/throot.thlua', 'require "good"\n')
        result = self.cli('check', '--project', 'app', '--json')
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        self.assertEqual(json.loads(result.stdout), [])
        self.write('bad.thlua', 'local value:Integer = "wrong"\n')
        result = self.cli('the', 'bad.thlua', '--json')
        self.assertEqual(result.returncode, 1, result.stderr + result.stdout)
        diagnostics = json.loads(result.stdout)
        self.assertEqual(len(diagnostics), 1, diagnostics)
        self.assertEqual((diagnostics[0]['severity'], diagnostics[0]['line']), (1, 1))
        self.assertIn('type not match', diagnostics[0]['message'])

    def test_json_and_async_host_contract(self):
        self.write('host.thlua', r'''
local json = require 'thlua.server.json'
local data = assert(json.decode('{"a":[],"b":{},"c":[null,1],"s":"中文"}'))
assert(json.encode(data.a) == '[]')
assert(json.encode(data.b) == '{}')
assert(json.encode(data.c) == '[null,1]')
assert(json.decode('broken') == nil)
local cycle = {}; cycle.self = cycle
assert(not pcall(json.encode, cycle))
local uv = require 'luv'
local count = 0
local handle
handle = uv.new_async(function()
    count = count + 1
    if count == 2 then handle:close() else handle:send() end
end)
handle:send(); handle:send()
uv.run()
assert(count == 2 and handle:is_closing())
local chrono = require 'chrono'
local before = chrono.now()
local after = chrono.now()
assert(after >= before and chrono.sub(after, before) == after - before)
print('ok')
''')
        result = self.cli('run', 'host.thlua')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), 'ok')


    def test_legacy_testcase_reports_failures(self):
        self.write('driver.thlua', """
local file = assert(io.open('case.txt', 'r'))
local source = file:read('*a')
file:close()
require('thlua.TestCase').go(source, 'compatibility test')
print('ok')
""")
        cases = [
            ('valid', 'local value:Integer=3\n', 0),
            ('expected', 'local value:Integer="wrong" --E\n', 0),
            ('unmarked', 'local value:Integer="wrong"\n', 1),
            ('missing', 'local value:Integer=3 --E\n', 1),
            ('comment', 'local value:Integer=3 --Example of an ordinary comment\n', 0),
            ('explained', 'local value:Integer="wrong" --E: incompatible assignment\n', 0),
            ('wrong severity', 'local value:Integer="wrong" --W\n', 1),
        ]
        for name, source, status in cases:
            with self.subTest(name=name):
                self.write('case.txt', source)
                result = self.cli('run', 'driver.thlua')
                self.assertEqual(result.returncode, status, result.stderr)
                if status == 0:
                    self.assertEqual(result.stdout, 'ok\n')

    def lsp(self, global_directory=None):
        command = [str(self.exe), 'lsp', '--stdio']
        if global_directory is not None:
            command.extend(['--global', str(global_directory)])
        process = subprocess.Popen(command, cwd=self.cwd,
                                   env=self.env, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE)
        def cleanup():
            if process.poll() is None:
                process.kill()
            process.wait(timeout=5)
            reader.join(timeout=5)
            error_reader.join(timeout=5)
            process.stdin.close()
            process.stdout.close()
            process.stderr.close()
        self.addCleanup(cleanup)
        messages = queue.Queue()
        errors = bytearray()
        def read_errors():
            while True:
                data = process.stderr.read(4096)
                if not data:
                    break
                errors.extend(data)
        error_reader = threading.Thread(target=read_errors, daemon=True)
        error_reader.start()
        def read():
            try:
                while True:
                    length = None
                    while True:
                        line = process.stdout.readline()
                        if not line:
                            process.wait(timeout=5)
                            error_reader.join(timeout=2)
                            raise EOFError('server closed stdout: ' + errors.decode('utf-8', errors='replace'))
                        if line == b'\r\n':
                            break
                        key, value = line.split(b':', 1)
                        if key.lower() == b'content-length':
                            length = int(value)
                    if length is None:
                        raise ValueError('missing length')
                    messages.put(json.loads(process.stdout.read(length)))
            except Exception as error:
                messages.put(error)
        reader = threading.Thread(target=read, daemon=True)
        reader.start()
        def send(method, params=None, id=None):
            packet = {'jsonrpc': '2.0', 'method': method}
            if params is not None:
                packet['params'] = params
            if id is not None:
                packet['id'] = id
            raw = json.dumps(packet, ensure_ascii=False).encode()
            process.stdin.write(f'Content-Length: {len(raw)}\r\n\r\n'.encode() + raw)
            process.stdin.flush()
        def wait(predicate):
            deadline = time.monotonic() + 20
            while time.monotonic() < deadline:
                try:
                    packet = messages.get(timeout=max(0.001, deadline - time.monotonic()))
                except queue.Empty:
                    break
                if isinstance(packet, Exception):
                    raise packet
                if predicate(packet):
                    return packet
            self.fail('expected LSP message not found')
        return process, send, wait

    def test_lsp_diagnostics_changes_shutdown_and_exit(self):
        self.exercise_lsp()

    def test_lsp_with_extension_globals(self):
        self.exercise_lsp(ROOT / '3rd/vscode-lsp/server/global')

    def exercise_lsp(self, global_directory=None):
        process, send, wait = self.lsp(global_directory)
        send('initialize', {'rootUri': self.cwd.as_uri(), 'rootPath': None,
                            'capabilities': {}}, id=0)
        response = wait(lambda p: p.get('id') == 0)
        self.assertTrue(response['result']['capabilities']['hoverProvider'])
        send('initialized', {})
        uri = self.write('编辑.thlua', '').as_uri()
        send('textDocument/didOpen', {'textDocument': {'uri': uri, 'languageId': 'thlua',
             'version': 1, 'text': 'local value:Integer = "中文"\n'}})
        diagnostic = wait(lambda p: p.get('method') == 'textDocument/publishDiagnostics'
                          and p['params']['uri'] == uri and p['params'].get('diagnostics'))
        self.assertTrue(diagnostic['params']['diagnostics'])
        send('textDocument/didChange', {'textDocument': {'uri': uri, 'version': 2},
             'contentChanges': [{'text': 'local value:Integer = 42\nprint(value)\n'}]})
        wait(lambda p: p.get('method') == 'textDocument/publishDiagnostics'
             and p['params']['uri'] == uri and p['params'].get('version') == 2
             and p['params']['diagnostics'] == [])
        # didChange publishes empty syntax diagnostics before type checking.
        wait(lambda p: p.get('method') == 'window/logMessage'
             and 'rerun finish' in p['params'].get('message', ''))
        send('textDocument/hover', {'textDocument': {'uri': uri},
             'position': {'line': 1, 'character': 8}}, id='hover')
        hover = wait(lambda p: p.get('id') == 'hover')['result']
        self.assertIsInstance(hover, dict)
        self.assertIn('Integer', hover['contents']['value'])
        send('textDocument/hover', {'textDocument': {'uri': uri},
             'position': {'line': 10, 'character': 0}}, id='empty-hover')
        self.assertIsNone(wait(lambda p: p.get('id') == 'empty-hover')['result'])
        send('textDocument/completion', {'textDocument': {'uri': uri},
             'position': {'line': 10, 'character': 0}}, id='empty-completion')
        self.assertIsNone(wait(lambda p: p.get('id') == 'empty-completion')['result'])
        send('unknown/method', {}, id='missing')
        self.assertEqual(wait(lambda p: p.get('id') == 'missing')['error']['code'], -32601)
        send('shutdown', id='shutdown')
        self.assertIsNone(wait(lambda p: p.get('id') == 'shutdown')['result'])
        self.assertIsNone(process.poll())
        send('exit')
        self.assertEqual(process.wait(timeout=5), 0)

    def test_lsp_exit_without_shutdown_fails(self):
        process, send, _ = self.lsp()
        send('exit')
        self.assertEqual(process.wait(timeout=5), 1)

    def test_lsp_parse_error_recovers_and_uninitialized_request(self):
        process, send, wait = self.lsp()
        process.stdin.write(b'Content-Length: 1\r\n\r\n{')
        process.stdin.flush()
        self.assertEqual(wait(lambda p: 'error' in p)['error']['code'], -32700)
        # Valid JSON null is Invalid Request, distinct from malformed JSON.
        process.stdin.write(b'Content-Length: 4\r\n\r\nnull')
        process.stdin.flush()
        self.assertEqual(wait(lambda p: 'error' in p)['error']['code'], -32600)
        send('textDocument/hover', {}, id=1)
        self.assertEqual(wait(lambda p: p.get('id') == 1)['error']['code'], -32002)
        send('initialize', {'rootUri': self.cwd.as_uri(), 'capabilities': {}}, id=2)
        self.assertIn('result', wait(lambda p: p.get('id') == 2))
        send('initialize', {'capabilities': {}}, id=3)
        self.assertEqual(wait(lambda p: p.get('id') == 3)['error']['code'], -32600)
        send('shutdown', id=4)
        self.assertIsNone(wait(lambda p: p.get('id') == 4)['result'])
        send('exit')
        self.assertEqual(process.wait(timeout=5), 0)


if __name__ == '__main__':
    if len(sys.argv) > 1 and not sys.argv[1].startswith('-'):
        BINARY = Path(sys.argv.pop(1)).resolve()
    unittest.main()
