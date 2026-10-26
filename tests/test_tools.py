import hashlib
import io
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ToolsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.home = self.root / 'home'
        self.bin = self.home / '.local/bin'
        self.bin.mkdir(parents=True)
        self.source = self.root / 'source'
        (self.source / 'scripts').mkdir(parents=True)
        self.fake_bin = self.root / 'fake-bin'
        self.fake_bin.mkdir()
        for name in ('git', 'bash', 'zsh', 'tmux', 'direnv', 'uv'):
            self.write_executable(self.fake_bin / name, '#!/bin/sh\nexit 0\n')
        self.write_executable(self.fake_bin / 'curl', '#!/bin/sh\nwhile [ "$1" != -o ]; do shift; done\ncp "$ARCHIVE_FIXTURE" "$2"\n')
        self.archive = self.root / 'nvim.tar.gz'
        with tarfile.open(self.archive, 'w:gz') as stream:
            body = b'#!/bin/sh\necho "NVIM v0.12.6"\n'
            info = tarfile.TarInfo('nvim-fixture/bin/nvim')
            info.mode = 0o755
            info.size = len(body)
            stream.addfile(info, io.BytesIO(body))
        checksum = hashlib.sha256(self.archive.read_bytes()).hexdigest()
        (self.source / 'scripts/vendors.sh').write_text(
            f'uv_version=fixture\nnvim_version=0.12.6\nnvim_asset=nvim-fixture\nnvim_sha={checksum}\n')
        shutil.copy(ROOT / 'scripts/tools.sh', self.source / 'scripts/tools.sh')
        self.env = os.environ.copy()
        self.env.update(HOME=str(self.home), XDG_DATA_HOME=str(self.home / '.local/share'),
                        DOTFILES_SOURCE=str(self.source), ARCHIVE_FIXTURE=str(self.archive),
                        PATH=f'{self.bin}:{self.fake_bin}:/usr/bin:/bin')

    def write_executable(self, path, content):
        path.write_text(content)
        path.chmod(0o755)

    def run_tools(self):
        return subprocess.run(['sh', str(self.source / 'scripts/tools.sh'), '--apply'],
                              env=self.env, text=True, capture_output=True)

    def test_incompatible_local_neovim_is_backed_up_and_replacement_is_repeatable(self):
        old = '#!/bin/sh\necho "NVIM v0.10.0"\n'
        self.write_executable(self.bin / 'nvim', old)
        result = self.run_tools()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.bin / 'nvim').is_symlink())
        backups = list((self.home / '.local/share/john-dotfiles-tools').glob('replaced-tool-*/nvim'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), old)
        result = self.run_tools()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('Tools are ready', result.stdout)

    def test_checksum_failure_preserves_existing_tool(self):
        old = '#!/bin/sh\necho "NVIM v0.10.0"\n'
        self.write_executable(self.bin / 'nvim', old)
        self.archive.write_bytes(b'corrupt fixture')
        result = self.run_tools()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Checksum mismatch', result.stderr)
        self.assertEqual((self.bin / 'nvim').read_text(), old)


if __name__ == '__main__':
    unittest.main()
