import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
MANAGER = os.environ.get('DOTFILES_CHEZMOI') or shutil.which('chezmoi')


@unittest.skipUnless(MANAGER, 'Set DOTFILES_CHEZMOI to the verified chezmoi binary')
class InstallTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name).resolve() / 'home'
        self.home.mkdir()
        self.env = os.environ.copy()
        self.env.update(HOME=str(self.home), DOTFILES_SOURCE=str(ROOT),
                        DOTFILES_CHEZMOI=str(Path(MANAGER).resolve()),
                        XDG_CONFIG_HOME=str(self.home / '.config'),
                        XDG_DATA_HOME=str(self.home / '.local/share'),
                        XDG_STATE_HOME=str(self.home / '.local/state'),
                        XDG_CACHE_HOME=str(self.home / '.cache'),
                        ZDOTDIR=str(self.home), PATH='/usr/bin:/bin:/usr/sbin:/sbin')

    def run_script(self, script, *args):
        return subprocess.run(['sh', str(ROOT / script), *args], env=self.env,
                              text=True, capture_output=True)

    def apply(self):
        result = self.run_script('scripts/manage.sh', 'apply', '--yes')
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_bootstrap_defaults_to_preview(self):
        result = self.run_script('install.sh', '--source', str(ROOT))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('Preview only', result.stdout)
        self.assertFalse((self.home / '.zshrc').exists())

    def test_apply_backs_up_conflicts_preserves_local_files_and_is_idempotent(self):
        (self.home / '.zshrc').write_text('# previous settings\n')
        local = self.home / '.config/shell/path.local.sh'
        local.parent.mkdir(parents=True)
        local.write_text('# machine settings\n')
        self.apply()
        backups = list((self.home / '.local/state/john-dotfiles/backups').glob('*/files.tar.gz'))
        self.assertEqual(len(backups), 1)
        with tarfile.open(backups[0]) as archive:
            self.assertEqual(archive.extractfile('.zshrc').read(), b'# previous settings\n')
        self.assertEqual(local.read_text(), '# machine settings\n')
        result = self.run_script('scripts/manage.sh', 'diff')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, '')
        self.apply()
        self.assertEqual(self.run_script('scripts/manage.sh', 'diff').stdout, '')

    def test_symlink_ancestor_is_rejected_without_touching_target(self):
        outside = Path(self.temp.name) / 'outside'
        outside.mkdir()
        (self.home / '.config').symlink_to(outside, target_is_directory=True)
        result = self.run_script('scripts/manage.sh', 'apply', '--yes')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('symlink', result.stderr)
        self.assertEqual(list(outside.iterdir()), [])
        self.assertFalse((self.home / '.zshrc').exists())

    def test_applied_startup_loads_helpers_in_each_shell(self):
        self.apply()
        for shell in ('bash', 'zsh'):
            executable = shutil.which(shell)
            if not executable:
                continue
            flags = ['--noprofile', '--rcfile', str(self.home / '.bashrc')] if shell == 'bash' else ['-d']
            result = subprocess.run([executable, *flags, '-ic',
                                     'type path_prepend >/dev/null && type with_path >/dev/null'],
                                    env=self.env, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_backup_directory_symlink_is_rejected_before_writes(self):
        outside = Path(self.temp.name).resolve() / 'outside'
        outside.mkdir()
        state = self.home / '.local/state/john-dotfiles'
        state.mkdir(parents=True)
        (state / 'backups').symlink_to(outside, target_is_directory=True)
        result = self.run_script('scripts/manage.sh', 'apply', '--yes')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('symlink', result.stderr)
        self.assertEqual(list(outside.iterdir()), [])
        self.assertFalse((self.home / '.zshrc').exists())

    def test_tools_plan_does_not_install(self):
        result = self.run_script('scripts/manage.sh', 'tools')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('Tool plan', result.stdout)
        self.assertFalse((self.home / '.local/bin').exists())


if __name__ == '__main__':
    unittest.main()
