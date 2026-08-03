# Signs

Positive signs are those indicating for LLM involvement. Negative signs are those indicating *against* LLM involvement.

## Files

Positive signs:
- Names of files and folders used to instruct LLMs (e.g. `AGENTS.md`, `.agents`)
  (`files`)

Negative signs:
- Opposing instructions (such as "Do not engage")
  (`deny-strings`)
  The challenge with these is ensuring they are strict enough to ensure the author is intending to oppose LLMs.

## Commits

Positive signs:
- Putting an LLM "agent" in `Co-authored-by:`, `Co-developed-by:`, or `Assisted-by:` trailers
  (`agent-names`)
  - The first two should check loosely for name and for an associated email to avoid false positives.
  - The last one should check only for harness name and also model names (ideally with another check to avoid false positives).
- Using `AI-Assisted-by:` or other trailers only used to indicate LLM usage
  (`trailers`)
- Authored by an LLM "agent" with their name and email
  (`agent-names`)

Negative signs:
- Putting non-LLM tools as commit contributors (e.g. GoToSocial's `Assisted-by: GNU sed 4.10 <sed@gnu.org>`)
