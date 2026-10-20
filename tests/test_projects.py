import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("projects", Path(__file__).resolve().parents[1] / "projects.py")
projects = importlib.util.module_from_spec(spec)
spec.loader.exec_module(projects)


class GitHead(unittest.TestCase):
    def test_branch_detached_worktree_and_non_repo(self):
        root = Path(tempfile.mkdtemp())
        repo = root / "repo"
        (repo / ".git" / "worktrees" / "wt").mkdir(parents=True)
        (repo / ".git" / "HEAD").write_text("ref: refs/heads/feat/x\n")
        (repo / ".git" / "worktrees" / "wt" / "HEAD").write_text("0123456789abcdef\n")
        worktree = root / "wt"
        worktree.mkdir()
        (worktree / ".git").write_text(f"gitdir: {repo}/.git/worktrees/wt\n")
        (root / "plain").mkdir()
        self.assertEqual(projects.git_head(repo), "feat/x")
        self.assertEqual(projects.git_head(worktree), "0123456")
        self.assertIsNone(projects.git_head(root / "plain"))

    def test_pretty_paths(self):
        self.assertEqual(projects.pretty(projects.HOME / "Programming" / "x"), "~/Programming/x")
        self.assertEqual(projects.pretty(Path("/opt/x")), "/opt/x")


if __name__ == "__main__":
    unittest.main()
