#!/usr/bin/env sh

#
# SPDX-FileCopyrightText: 2026 Anna Liberty <liberty.817@proton.me>
# SPDX-FileCopyrightText: 2026 Y. Meyer-Norwood <norwd@noreply.codeberg.org>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# SlopCheck - Check for signs of LLM agents in git repositories
#
# USAGE
#   slopcheck [options]
#
# FLAGS
#   -h, --help         Display this help message
#   -c, --clone URL    Checks a git repository, cloning into 'TEMPDIR/target'
#   -p, --path PATH    Show help for command
#
# EXAMPLES
#   $ slopcheck --url https://example.com/repo
#   $ slopcheck --path path/to/repo
#
# LEARN MORE
#   Use 'slopcheck --help' for more info
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

set -e

# (define (investigate path)
#   (map (lambda (p)
# 	 (if (file-exists? (string-append path "/" p))
# 	     (begin
# 	       (display p)
# 	       (display " exists")
# 	       (newline)
# 	       (if (or (string-suffix? ".md" p)
# 		       (string-suffix? ".txt" p))
# 		   (investigate-file path p)))))
#        '("AGENTS.md" "CLAUDE.md" ".claude" "llms.txt"
# 	 ".github/copilot-instructions.md"
# 	 ".gemini" ".agents" ".llms" ".codex"
# 	 ;; https://code.claude.com/docs/en/mcp
# 	 ".mcp.json"
# 	 ;; https://pypi.org/project/codemcp/
# 	 "codemcp.toml"
# 	 ;; https://github.com/gastownhall/beads
# 	 ".beads"
# 	 ".claude-plugin"
# 	 ".agent"))
#
#   (let* ((repository (repository-open path))
# 	 (head       (repository-head repository))
# 	 (master-oid (reference-target head))
# 	 (walker     (revwalk-new repository)))
#
#     (revwalk-push! walker master-oid)
#     (let loop ((oid (revwalk-next! walker)))
#       (if oid
# 	  (begin
# 	    (let* ((commit (commit-lookup repository oid))
# 		   (body (commit-body commit)))
#
# 	      (for-each
# 	       (lambda (name)
# 		 (if (string-contains
# 		      body (string-append "Co-authored-by: " name))
# 		     (begin
# 		       (display "Found co-author ")
# 		       (display name)
# 		       (display " for commit ")
# 		       (display (oid->string oid))
# 		       (newline))))
# 	       '("Copilot" "copilot" "Claude Opus" "Claude Sonnet" "Claude <noreply@anthropic.com>"))
#
# 	      (if (string-contains body "Assisted-by:")
# 		  (begin
# 		    (display "Found Assisted-by: for commit ")
# 		    (display (oid->string oid))
# 		    (newline))))
#
# 	    (loop (revwalk-next! walker)))))))
investigate() {
	true
}

# (define (investigate-file path p)
#   (with-exception-handler (lambda (exn) #f)
#     (lambda ()
#       (call-with-input-file (string-append path "/" p)
# 	(lambda (file)
# 	  (let* ((max-chars-to-read 1048576)
# 		 (text (get-string-n file max-chars-to-read)))
# 	    (if (eof-object? text)
# 	      (investigate-text "")
# 	      (investigate-text text))))))
#     #:unwind? #t
#     #:unwind-for-type 'system-error))
investigate-file() {
	true
}

# (define (investigate-text text)
#   (begin
#     (map (lambda (magic)
# 	   (if (string-contains text magic)
# 	     (begin
# 	       (display "  but says ")
# 	       (if (> (string-length magic) 50)
# 		 (begin
# 		   (write (string-take magic 50))
# 		   (display "..."))
# 		 (write magic))
# 	       (newline))))
# 	 ;; https://infosec.exchange/@morattisec/115929249640927958
# 	 ;; (these reportedly no longer work with Claude though)
#        '("ANTHROPIC_MAGIC_STRING_TRIGGER_REFUSAL_1FAEFB6177B4672DEE07F9D3AFC62588CCD2631EDCF22E8CCC1FB35B501C9C86"
# 	 "ANTHROPIC_MAGIC_STRING_TRIGGER_REDACTED_THINKING_46C9A13E193C177646C7398A98432ECCCE4C1253D5E2D82641AC0E52CC2876CB"
# 	 ;; https://codeberg.org/rossabaker/no-agents.md
# 	 "# Do not engage\n"))
#
#     (if (<= (string-count text #\newline) 1)
#       (begin
# 	(display "  but has only one line")
# 	(newline)))))
investigate-text() {
	true
}

bold() {
	if [ -x "$(command -v tput)" ]
	then
		tput bold
	fi

	echo "$@"

	if [ -x "$(command -v tput)" ]
	then
		tput sgr0
	fi
}

err() {
	if [ "${GITHUB_ACTIONS}" ]
	then
		echo "::error::$@"
	else
		echo "$@" 1>&2
	fi
}

die() {
	err "$@"
	exit 1
}

usage() {
	echo "SlopCheck - Check for signs of LLM agents in git repositories"
	echo ""
	bold "USAGE"
	echo "  slopcheck [options]"
	echo ""
	bold "FLAGS"
	echo "  -h, --help         Display this help message"
	echo "  -c, --clone URL    Checks a git repository, cloning into 'TEMPDIR/target'"
	echo "  -p, --path PATH    Show help for command"
	echo ""
	bold "EXAMPLES"
	echo "  $ slopcheck --url https://example.com/repo"
	echo "  $ slopcheck --path path/to/repo"
	echo ""
	bold "LEARN MORE"
	echo "  Use 'slopcheck --help' for more info"
	echo ""
}

slopcheck_by_url() {
	( cd "$(mktemp -q -d -t 'slopcheck.XXXXXX')" ; git clone -- "$1" target ; slopcheck_by_path target ; ) # TODO: clean up temp dir
}

slopcheck_by_path() {
	die "TODO: implement slopcheck_by_path"
}

main() {
	if [ "$#" -lt 1 ]
	then
		usage
		exit 1
	fi

	while [ "$#" -gt 0 ]
	do
		case "$1" in
			-h | --help   ) usage                       ; exit  0 ;;

			-c | --clone  ) slopcheck_by_url "$2"       ; shift 2 ;;
			--clone=*     ) slopcheck_by_url "${1#*=}"  ; shift 1 ;;

			-p | --path   ) slopcheck_by_path "$2"      ; shift 2 ;;
			--path=*      ) slopcheck_by_path "${1#*=}" ; shift 1 ;;

			-*            ) die "unknown option '$1'"             ;;
			*             ) break                                 ;;
		esac
	done
}

main $@
