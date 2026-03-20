import os
import re
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

    def create_sourceable_system_script(self, directory: Path) -> Path:
        original = (REPO_ROOT / "system" / "system.sh").read_text(encoding="utf-8")
        lines = original.splitlines()
        filtered_lines = []
        for line in lines:
            if line.strip() == 'source "$SCRIPT_DIR/../utils/utils.sh"':
                continue
            if line.strip() == "main":
                continue
            filtered_lines.append(line)

        script_path = directory / "system-sourceable.sh"
        script_path.write_text("\n".join(filtered_lines) + "\n", encoding="utf-8")
        return script_path

    def test_shell_syntax_is_valid(self):
        scripts = [
            ".githooks/pre-commit",
            ".githooks/pre-push",
            "run.sh",
            "scripts/install-hooks.sh",
            "scripts/smoke-system.sh",
            "system/system.sh",
            "sdk/sdk.sh",
            "git/git.sh",
            "dotfiles/dotfiles.sh",
            "utils/utils.sh",
            "utils/settings.sh",
            "scripts/test.sh",
            "scripts/verify-system-smoke.sh",
            "scripts/vm-smoke-test.sh",
            "web2app/web2app.sh",
        ]
        result = self.run_cmd(["bash", "-n", *scripts])
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_shellcheck_passes(self):
        files = [
            ".githooks/pre-commit",
            ".githooks/pre-push",
            "run.sh",
            "scripts/install-hooks.sh",
            "scripts/smoke-system.sh",
            "system/system.sh",
            "sdk/sdk.sh",
            "git/git.sh",
            "dotfiles/dotfiles.sh",
            "utils/utils.sh",
            "utils/settings.sh",
            "scripts/test.sh",
            "scripts/verify-system-smoke.sh",
            "scripts/vm-smoke-test.sh",
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

    def test_manifests_are_well_formed(self):
        simple_manifests = [
            REPO_ROOT / "system" / "apt-packages.txt",
            REPO_ROOT / "system" / "npm-packages.txt",
            REPO_ROOT / "system" / "uv-tools.txt",
        ]
        for manifest in simple_manifests:
            seen = set()
            for raw_line in manifest.read_text(encoding="utf-8").splitlines():
                line = raw_line.split("#", 1)[0].strip()
                if not line:
                    continue
                self.assertNotIn(line, seen, f"Duplicate entry {line!r} in {manifest}")
                seen.add(line)

        snap_seen = set()
        for raw_line in (REPO_ROOT / "system" / "snap-packages.txt").read_text(encoding="utf-8").splitlines():
            line = raw_line.split("#", 1)[0].strip()
            if not line:
                continue
            parts = line.split()
            self.assertGreaterEqual(len(parts), 1)
            self.assertLessEqual(len(parts), 3)
            self.assertNotIn(line, snap_seen)
            snap_seen.add(line)
            if len(parts) >= 2:
                self.assertTrue(parts[1] == "-" or re.fullmatch(r"[A-Za-z0-9./_-]+", parts[1]))
            if len(parts) == 3:
                self.assertEqual(parts[2], "classic")

        github_seen = set()
        valid_modes = {"raw", "tar.gz"}
        for raw_line in (REPO_ROOT / "system" / "github-tools.txt").read_text(encoding="utf-8").splitlines():
            line = raw_line.split("#", 1)[0].strip()
            if not line:
                continue
            parts = line.split("|")
            self.assertEqual(len(parts), 5, f"Expected 5 columns in github-tools.txt, got {line!r}")
            command_name, repo, asset_pattern, mode, binary_name = parts
            self.assertTrue(command_name)
            self.assertRegex(repo, r"^[^/]+/[^/]+$")
            self.assertTrue(asset_pattern)
            self.assertIn(mode, valid_modes)
            self.assertTrue(binary_name)
            self.assertNotIn(command_name, github_seen)
            github_seen.add(command_name)

    def test_system_installer_uses_expected_apt_command(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir)
            log_file = Path(tmp_dir) / "log.txt"
            manifest = Path(tmp_dir) / "apt.txt"
            sourceable_script = self.create_sourceable_system_script(tmp_path)
            manifest.write_text("rg\nfd-find\njq\n", encoding="utf-8")

            command = textwrap.dedent(
                f"""\
                source "{REPO_ROOT / 'utils' / 'utils.sh'}"
                sudo_run() {{ printf 'sudo:%s\\n' "$*" >> "{log_file}"; }}
                log_info() {{ :; }}
                log_warn() {{ :; }}
                log_success() {{ :; }}
                echo_header() {{ :; }}
                source "{sourceable_script}"
                APT_PACKAGES_FILE="{manifest}"
                install_apt_packages
                """
            )

            result = self.run_cmd(["bash", "-lc", command])
            self.assertEqual(result.returncode, 0, result.stderr)
            log_output = log_file.read_text(encoding="utf-8")
            self.assertIn("sudo:apt-get install -y --no-install-recommends rg fd-find jq", log_output)

    def test_system_installer_parses_snap_manifest(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir)
            log_file = Path(tmp_dir) / "log.txt"
            manifest = Path(tmp_dir) / "snaps.txt"
            sourceable_script = self.create_sourceable_system_script(tmp_path)
            manifest.write_text(
                "discord - classic\npostman latest/stable\nlocalsend\n",
                encoding="utf-8",
            )

            command = textwrap.dedent(
                f"""\
                source "{REPO_ROOT / 'utils' / 'utils.sh'}"
                sudo_run() {{ printf 'sudo:%s\\n' "$*" >> "{log_file}"; }}
                log_info() {{ :; }}
                log_warn() {{ :; }}
                log_success() {{ :; }}
                echo_header() {{ :; }}
                snap() {{ return 1; }}
                source "{sourceable_script}"
                SNAP_PACKAGES_FILE="{manifest}"
                install_snap_packages
                """
            )

            result = self.run_cmd(["bash", "-lc", command])
            self.assertEqual(result.returncode, 0, result.stderr)
            lines = log_file.read_text(encoding="utf-8").splitlines()
            self.assertIn("sudo:snap install discord --classic", lines)
            self.assertIn("sudo:snap install postman --channel=latest/stable", lines)
            self.assertIn("sudo:snap install localsend", lines)

    def test_ensure_line_in_file_is_idempotent(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir)
            target = tmp_path / ".bashrc"
            line = 'eval "$("$HOME/.local/bin/mise" activate bash)"'

            command = textwrap.dedent(
                f"""\
                source "{REPO_ROOT / 'utils' / 'utils.sh'}"
                ensure_line_in_file '{line}' "{target}"
                ensure_line_in_file '{line}' "{target}"
                """
            )

            result = self.run_cmd(["bash", "-lc", command])
            self.assertEqual(result.returncode, 0, result.stderr)
            bashrc = target.read_text(encoding="utf-8").splitlines()
            self.assertEqual(bashrc.count(line), 1)

    def test_system_main_respects_skip_flags(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir)
            log_file = Path(tmp_dir) / "log.txt"
            sourceable_script = self.create_sourceable_system_script(tmp_path)
            command = textwrap.dedent(
                f"""\
                source "{REPO_ROOT / 'utils' / 'utils.sh'}"
                source "{sourceable_script}"
                check_root() {{ :; }}
                ensure_sudo() {{ :; }}
                ensure_core_packages() {{ printf 'core\\n' >> "{log_file}"; }}
                upgrade_base_system() {{ printf 'upgrade\\n' >> "{log_file}"; }}
                install_apt_packages() {{ printf 'apt\\n' >> "{log_file}"; }}
                ensure_agent_command_names() {{ printf 'compat\\n' >> "{log_file}"; }}
                setup_docker_repo() {{ printf 'docker\\n' >> "{log_file}"; }}
                install_snap_packages() {{ printf 'snaps\\n' >> "{log_file}"; }}
                setup_vscode_repo() {{ printf 'vscode\\n' >> "{log_file}"; }}
                install_vscode_extensions() {{ printf 'vscode-ext\\n' >> "{log_file}"; }}
                setup_google_chrome_repo() {{ printf 'chrome\\n' >> "{log_file}"; }}
                install_github_release_tools() {{ printf 'gh-tools\\n' >> "{log_file}"; }}
                install_uv() {{ printf 'uv\\n' >> "{log_file}"; }}
                install_uv_tools() {{ printf 'uv-tools\\n' >> "{log_file}"; }}
                install_claude_code() {{ printf 'claude\\n' >> "{log_file}"; }}
                install_npm_clis() {{ printf 'npm\\n' >> "{log_file}"; }}
                echo_header() {{ :; }}
                log_success() {{ :; }}
                export LINUX_SETUP_SKIP_SNAPS=1
                export LINUX_SETUP_SKIP_VSCODE=1
                export LINUX_SETUP_SKIP_CHROME=1
                main
                """
            )

            result = self.run_cmd(["bash", "-lc", command])
            self.assertEqual(result.returncode, 0, result.stderr)
            output = log_file.read_text(encoding="utf-8").splitlines()
            self.assertIn("core", output)
            self.assertIn("apt", output)
            self.assertIn("docker", output)
            self.assertNotIn("snaps", output)
            self.assertNotIn("vscode", output)
            self.assertNotIn("chrome", output)

    def test_dotfiles_script_is_idempotent(self):
        with tempfile.TemporaryDirectory() as temp_home:
            env = os.environ.copy()
            env["HOME"] = temp_home

            first = self.run_cmd(["bash", "dotfiles/dotfiles.sh"], env=env)
            second = self.run_cmd(["bash", "dotfiles/dotfiles.sh"], env=env)

            self.assertEqual(first.returncode, 0, first.stderr)
            self.assertEqual(second.returncode, 0, second.stderr)
            self.assertTrue((Path(temp_home) / ".bash_aliases").exists())


if __name__ == "__main__":
    unittest.main()
