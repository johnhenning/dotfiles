import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class PathTests(unittest.TestCase):
    def run_shell(self, shell, body, root):
        executable = shutil.which(shell)
        if not executable:
            self.skipTest(f'{shell} is unavailable')
        env = os.environ.copy()
        env.update(DOTFILES_PATH_MODULE=str(ROOT/'home/dot_config/shell/path.sh'),
                   XDG_CONFIG_HOME=str(root/'config'), ZDOTDIR=str(root/'zsh'),
                   SDK_DIR=str(root/'SDK with spaces [local]'), TEST_ROOT=str(root))
        flags = ['--noprofile', '--norc'] if shell == 'bash' else ['-df']
        return subprocess.run([executable, *flags, '-c', '. "$DOTFILES_PATH_MODULE"; '+body],
                              env=env, text=True, capture_output=True)

    def test_deduplication_and_order_in_both_shells(self):
        for shell in ['bash','zsh']:
            with self.subTest(shell=shell), tempfile.TemporaryDirectory() as td:
                root=Path(td);(root/'SDK with spaces [local]').mkdir()
                r=self.run_shell(shell, 'PATH="/usr/bin:/bin:/usr/bin::/bin"; path_prepend "$SDK_DIR"; path_prepend "$SDK_DIR"; printf "%s" "$PATH"',root)
                self.assertEqual(r.returncode,0,r.stderr)
                self.assertEqual(r.stdout,str(root/'SDK with spaces [local]')+':/usr/bin:/bin')

    def test_scoped_tool_does_not_change_parent_path(self):
        for shell in ['bash','zsh']:
            with self.subTest(shell=shell), tempfile.TemporaryDirectory() as td:
                root=Path(td);sdk=root/'SDK with spaces [local]';sdk.mkdir()
                tool=sdk/'example-tool';tool.write_text('#!/bin/sh\nprintf scoped\n');tool.chmod(0o755)
                r=self.run_shell(shell,'before=$PATH; with_path "$SDK_DIR" example-tool; [ "$PATH" = "$before" ] || exit 9',root)
                self.assertEqual(r.returncode,0,r.stderr);self.assertEqual(r.stdout,'scoped')

    def test_machine_additions_do_not_require_rc_edits(self):
        for shell in ['bash','zsh']:
            with self.subTest(shell=shell), tempfile.TemporaryDirectory() as td:
                root=Path(td);sdk=root/'SDK with spaces [local]';sdk.mkdir()
                config=root/'config/shell';config.mkdir(parents=True)
                (config/'path.local.sh').write_text('path_prepend "$SDK_DIR"\n')
                r=self.run_shell(shell,'printf "%s" "$PATH"',root)
                self.assertEqual(r.returncode,0,r.stderr)
                self.assertTrue(r.stdout.startswith(str(sdk)+':'))

    def test_missing_paths_and_colon_paths(self):
        for shell in ['bash','zsh']:
            with self.subTest(shell=shell), tempfile.TemporaryDirectory() as td:
                r=self.run_shell(shell,'before=$PATH; path_prepend "$TEST_ROOT/absent"; [ "$PATH" = "$before" ] || exit 9; path_prepend "bad:path"; [ "$?" = 2 ]',Path(td))
                self.assertEqual(r.returncode,0,r.stderr)


if __name__ == '__main__':
    unittest.main()
