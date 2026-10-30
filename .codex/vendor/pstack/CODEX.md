# pstack in Codex

Upstream: https://github.com/cursor/plugins/tree/main/pstack
Revision: `4dd1d05818d19792e7cd6e818f1667f95f7e1dbe` (version 0.15.36).
The skills, agents, guide, and license are unmodified upstream files.

This is a skills installation. Cursor plugin registration and Cursor services
are not installed. Follow the current session's instructions and tool schemas
when upstream assumes a different harness.

- Invoke skills with `$poteto-mode`, `$how`, or another installed skill name.
  Read sibling skills from this directory's `skills/` folder when needed.
- Map `Task` to the session's subagent tool, if available and authorized.
  Use only models and arguments accepted by that tool. Inherit the parent
  model by default; do not pass Cursor model slugs or subagent type names.
  Read `agents/poteto-agent.md` or `agents/comment-sicko.md` as a worker brief
  when requested, rather than assuming registered agent types exist.
- Map shell, read, and search operations to the available execution tools.
  Map questions and progress tracking to available tools or concise chat text.
- For `setup-pstack`, read and write `~/.codex/pstack-models.md` instead of
  Cursor rules. Load that file explicitly when a pstack workflow needs role
  choices. If absent, inherit the session model. Never modify Cursor settings.
- Resolve upstream links to local files when those files are present here.
  Never assume Cursor transcript paths contain Codex conversation history.
- Cursor Automations, cloud agents, Bugbot setup, and other plugins are
  separate dependencies. If unavailable, report the unsupported step and
  continue independent work; do not claim it ran.

To update, reinstall all upstream `pstack/skills/*` at a chosen revision,
refresh the bundled agents and guide, update this revision, and rerun
`scripts/bootstrap_ai_configs.sh`. Keep this note separate from upstream files.
