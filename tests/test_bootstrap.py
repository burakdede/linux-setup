import os
import shutil
import stat
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


class BootstrapRepoTests(unittest.TestCase):
    def run_cmd(self, args, cwd=None, env=None):
        return subprocess.run(
            args,
            cwd=cwd or REPO_ROOT,
            env=env,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_shell_syntax_is_valid(self):
        scripts = [
            "run.sh",
            "system/system.sh",
            "sdk/sdk.sh",
            "git/git.sh",
            "dotfiles/dotfiles.sh",
            "utils/utils.sh",
            "utils/settings.sh",
            "web2app/web2app.sh",
        ]
        result = self.run_cmd(["bash", "-n", *scripts])
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_shellcheck_passes(self):
        files = [
            "run.sh",
            "system/system.sh",
            "sdk/sdk.sh",
            "git/git.sh",
            "dotfiles/dotfiles.sh",
            "utils/utils.sh",
            "utils/settings.sh",
            "web2app/web2app.sh",
            "dotfiles/.bash_aliases",
        ]
        result = self.run_cmd(["shellcheck", *files])
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_run_help_succeeds(self):
        result = self.run_cmd(["bash", "run.sh", "--help"])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Usage: ./run.sh [options]", result.stdout)
        self.assertIn("--only STEP", result.stdout)

    def test_settings_script_skips_without_desktop_session(self):
        env = os.environ.copy()
        env.pop("DISPLAY", None)
        env.pop("WAYLAND_DISPLAY", None)

        result = self.run_cmd(["bash", "utils/settings.sh"], env=env)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Skipping GNOME settings because no desktop session is active.", result.stderr)

    def test_dotfiles_script_installs_and_backs_up(self):
        with tempfile.TemporaryDirectory() as temp_home:
            home = Path(temp_home)
            existing_gitconfig = home / ".gitconfig"
            existing_gitconfig.write_text("[user]\n\tname = Old User\n", encoding="utf-8")

            env = os.environ.copy()
            env["HOME"] = temp_home

            result = self.run_cmd(["bash", "dotfiles/dotfiles.sh"], env=env)
            self.assertEqual(result.returncode, 0, result.stderr)

            installed_aliases = home / ".bash_aliases"
            installed_gitconfig = home / ".gitconfig"
            installed_config_dir = home / ".config"

            self.assertTrue(installed_aliases.exists())
            self.assertTrue(installed_gitconfig.exists())
            self.assertTrue(installed_config_dir.exists())

            backup_root = home / ".local" / "state" / "linux-setup" / "dotfiles-backups"
            backups = list(backup_root.rglob(".gitconfig"))
            self.assertTrue(backups, "Expected .gitconfig backup to be created")

    def test_run_only_executes_requested_step(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            repo = Path(tmp_dir) / "repo"
            (repo / "utils").mkdir(parents=True)
            (repo / "system").mkdir()
            (repo / "dotfiles").mkdir()
            (repo / "sdk").mkdir()
            (repo / "web2app").mkdir()
            (repo / "git").mkdir()

            shutil.copy2(REPO_ROOT / "run.sh", repo / "run.sh")
            shutil.copy2(REPO_ROOT / "utils" / "utils.sh", repo / "utils" / "utils.sh")

            marker_dir = repo / "markers"
            marker_dir.mkdir()

            for step_dir, script_name, marker_name in [
                ("system", "system.sh", "system"),
                ("dotfiles", "dotfiles.sh", "dotfiles"),
                ("sdk", "sdk.sh", "sdk"),
                ("web2app", "web2app.sh", "web2app"),
                ("git", "git.sh", "git"),
            ]:
                script_path = repo / step_dir / script_name
                script_path.write_text(
                    textwrap.dedent(
                        f"""\
                        #!/usr/bin/env bash
                        set -euo pipefail
                        touch "{marker_dir / marker_name}"
                        """
                    ),
                    encoding="utf-8",
                )
                script_path.chmod(script_path.stat().st_mode | stat.S_IXUSR)

            settings_path = repo / "utils" / "settings.sh"
            settings_path.write_text(
                textwrap.dedent(
                    f"""\
                    #!/usr/bin/env bash
                    set -euo pipefail
                    touch "{marker_dir / 'settings'}"
                    """
                ),
                encoding="utf-8",
            )
            settings_path.chmod(settings_path.stat().st_mode | stat.S_IXUSR)

            env = os.environ.copy()
            env["HOME"] = str(Path(tmp_dir) / "home")
            Path(env["HOME"]).mkdir()

            result = self.run_cmd(["bash", "run.sh", "--only", "sdk"], cwd=repo, env=env)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((marker_dir / "sdk").exists())
            self.assertFalse((marker_dir / "system").exists())
            self.assertFalse((marker_dir / "dotfiles").exists())
            self.assertFalse((marker_dir / "web2app").exists())
            self.assertFalse((marker_dir / "git").exists())
            self.assertFalse((marker_dir / "settings").exists())

    def test_read_list_file_skips_comments_and_blank_lines(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            manifest = Path(tmp_dir) / "manifest.txt"
            manifest.write_text(
                textwrap.dedent(
                    """\
                    # comment

                    rg
                    fd-find   # inline comment

                    jq
                    """
                ),
                encoding="utf-8",
            )

            command = (
                f'source "{REPO_ROOT / "utils" / "utils.sh"}"; '
                f'read_list_file "{manifest}"'
            )
            result = self.run_cmd(["bash", "-lc", command])
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.splitlines(), ["rg", "fd-find", "jq"])


if __name__ == "__main__":
    unittest.main()
