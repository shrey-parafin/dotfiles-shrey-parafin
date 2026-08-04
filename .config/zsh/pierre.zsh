# Pierre developer-tool launchers.

# Open the Pierre Diffs site or one of its main sections.
diffs() {
  local page="${1:-}"

  case "$page" in
    "")
      open "https://diffs.com"
      ;;
    docs|edit|playground|theme)
      open "https://diffs.com/${page}"
      ;;
    *)
      print -u2 "usage: diffs [docs|edit|playground|theme]"
      return 2
      ;;
  esac
}

# Open the Pierre Trees site or documentation.
trees() {
  local page="${1:-}"

  case "$page" in
    "")
      open "https://trees.software"
      ;;
    docs)
      open "https://trees.software/docs"
      ;;
    *)
      print -u2 "usage: trees [docs]"
      return 2
      ;;
  esac
}

# Open a GitHub change in DiffsHub. With no argument, use the current pull request.
diffshub() {
  local url="${1:-}"

  if [[ -z "$url" ]]; then
    if (( ! $+commands[gh] )); then
      print -u2 "diffshub: gh is required when no GitHub URL is provided"
      return 1
    fi

    url="$(gh pr view --json url --jq '.url')" || return
  fi

  case "$url" in
    https://github.com/*|http://github.com/*)
      ;;
    github.com/*)
      url="https://${url}"
      ;;
    *)
      print -u2 "usage: diffshub [https://github.com/OWNER/REPO/pull/NUMBER]"
      return 2
      ;;
  esac

  open "${url/github.com/diffshub.com}"
}
