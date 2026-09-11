# SlopCheck [![Delightful Humane Tech](https://codeberg.org/delightful-commons/delightful-humane-design/raw/branch/main/humane-tech-badge.svg)](https://codeberg.org/delightful-commons/delightful-humane-design)

Check for signs of LLM agents in git repositories.

This does not use any AI models or statistical inference. It simply checks common signs of LLM-generated code in a repository and reports them. Such signs include: contributions directly from LLM agents, common mistakes only commonly made by LLMs, and the existence of files like AGENTS.md.

SlopCheck aims to minimize false positives. Most of the criteria checked assume developers are not trying to hide their usage of LLMs. False negatives are inevitable with this approach. Those who need more are encouraged to use a tool that leverages statistical inference.

## Requirements

- [GNU Guile](https://www.gnu.org/software/guile/) >= 3.0.x (earliest version tested)
- [Guile-Git](https://codeberg.org/guile-git/guile-git) >= 0.12.0
  Note: most distributions provide an old version of Guile-Git.
  Installing manually or using Guix may be required.

Both of these (and their dependencies) can be pulled into a local environment with `guix shell -m manifest.scm`.

## Usage

Check the main branch of a repository for signs of LLM agents:

```sh
./slopcheck.scm --path path/to/repo
```

Example output:
```
Checking repository at: llm-generated-code
AGENTS.md exists
CLAUDE.md exists
Found co-author Claude Opus for commit xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Found co-author Claude Opus for commit xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxy
Found co-author Copilot for commit xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxz
```

[Open Slopware](https://codeberg.org/small-hack/open-slopware) is a good place to look for testing this tool.

## Future Ideas

- Check individual files for clear signs of LLM-generated code

## Contributing

Please contribute!

Some contributions I'm looking for in particular include:
- Updates to lists of signs of LLMs
- A proper Guix module specification

If you aren't comfortable with Guile, [opening an issue](https://codeberg.org/liberty/slopcheck/issues) is a welcome contribution too!

## License

Copyright © 2026  Anna Liberty <liberty.817@proton.me>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
