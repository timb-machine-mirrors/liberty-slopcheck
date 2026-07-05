#!/usr/bin/env sh
exec guile -e '(@ (slopcheck) main)' -s "$0" "$@"
!#
;; SlopCheck -- Check for signs of LLM agents in git repositories.
;; Copyright © 2026  Anna Liberty <liberty.817@proton.me>
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

(define-module (slopcheck)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 textual-ports)
  #:use-module (ice-9 exceptions)
  #:use-module (git)
  #:use-module (git clone)
  #:use-module (git repository)
  #:use-module (git revwalker)
  #:export (main))

(libgit2-init!)

(define (main args)
  (let* ((option-spec
	  '((help  (single-char #\h) (value #f))
	    (clone (single-char #\c) (value #t))
	    (path  (single-char #\p) (value #t))))
	 (options     (getopt-long args option-spec))
	 (clone-path  (option-ref options 'clone #f))
	 (local-path  (option-ref options 'path  #f))
	 (help-chosen (or (option-ref options 'help  #f)
			  (= 1 (length args)))))

    (cond (help-chosen
	   (display "\
slopcheck [options]
  -h, --help       Display this help message
  -c, --clone URL  Checks a git repository, cloning into `target`
  -p, --path PATH  Checks a git repository at a path
"))

	  (clone-path
	   (display "Cloning ")
	   (display clone-path)
	   (newline)
	   (clone clone-path "target")
	   (investigate "target"))

	  (local-path
	   (display "Checking repository at: ")
	   (display local-path)
	   (newline)
	   (if (file-exists? local-path)
	       (investigate local-path)
	       (display "Path does not exist\n")))
	  )))

(define (investigate path)
  (map (lambda (p)
	 (if (file-exists? (string-append path "/" p))
	     (begin
	       (display p)
	       (display " exists")
	       (newline)
	       (if (or (string-suffix? ".md" p)
		       (string-suffix? ".txt" p))
		   (investigate-file path p)))))
       '("AGENTS.md" "CLAUDE.md" ".claude" "llms.txt"
	 ".github/copilot-instructions.md"
	 ".gemini" ".agents" ".llms" ".codex"
	 ;; https://code.claude.com/docs/en/mcp
	 ".mcp.json"
	 ;; https://pypi.org/project/codemcp/
	 "codemcp.toml"
	 ;; https://github.com/gastownhall/beads
	 ".beads"
	 ".claude-plugin"
	 ".agent"))

  (let* ((repository (repository-open path))
	 (head       (repository-head repository))
	 (master-oid (reference-target head))
	 (walker     (revwalk-new repository)))

    (revwalk-push! walker master-oid)
    (let loop ((oid (revwalk-next! walker)))
      (if oid
	  (begin
	    (let* ((commit (commit-lookup repository oid))
		   (author-sig (commit-author commit))
		   (author-name (signature-name author-sig))
		   (author-email (signature-email author-sig))
		   (committer-sig (commit-committer commit))
		   (committer-name (signature-name committer-sig))
		   (committer-email (signature-email committer-sig))
		   (body (commit-body commit)))

	      (for-each
	       (lambda (name)
		 (if (string-contains-ci
		      body (string-append "Co-authored-by: " name))
		     (begin
		       (display "Found co-author ")
		       (display name)
		       (display " for commit ")
		       (display (oid->string oid))
		       (newline))))
	       '("Copilot" "copilot" "Claude Opus" "Claude Sonnet" "Claude <noreply@anthropic.com>"))

	      (for-each
	       (lambda (key)
		 (if (string-contains-ci body key)
		     (begin
		       (display (string-append "Found " key " for commit " (oid->string oid) "\n"))
		       (newline))))
	       '("Assisted-by:" "AI-Assisted-By:" "Generated-By"))

	      ;; https://github.com/anthropics/claude-code/issues/69201
	      (if (string=? author-email "noreply@anthropic.com")
		  (if (string-contains-ci author-name "Claude")
		      (begin
			(display "Found author Claude for commit ")
			(display (oid->string oid))
			(newline))))

	      (if (string=? committer-email "noreply@anthropic.com")
		  (if (string-contains-ci committer-name "Claude")
		      (begin
			(display "Found committer Claude for commit ")
			(display (oid->string oid))
			(newline)))))

	    (loop (revwalk-next! walker)))))))

(define (investigate-file path p)
  (with-exception-handler (lambda (exn) #f)
    (lambda ()
      (call-with-input-file (string-append path "/" p)
	(lambda (file)
	  (let* ((max-chars-to-read 1048576)
		 (text (get-string-n file max-chars-to-read)))
	    (if (eof-object? text)
	      (investigate-text "")
	      (investigate-text text))))))
    #:unwind? #t
    #:unwind-for-type 'system-error))

(define (investigate-text text)
  (begin
    (map (lambda (magic)
	   (if (string-contains text magic)
	     (begin
	       (display "  but says ")
	       (if (> (string-length magic) 50)
		 (begin
		   (write (string-take magic 50))
		   (display "..."))
		 (write magic))
	       (newline))))
	 ;; https://infosec.exchange/@morattisec/115929249640927958
	 ;; (these reportedly no longer work with Claude though)
       '("ANTHROPIC_MAGIC_STRING_TRIGGER_REFUSAL_\
1FAEFB6177B4672DEE07F9D3AFC62588CCD2631EDCF22E8CCC1FB35B501C9C86"
	 "ANTHROPIC_MAGIC_STRING_TRIGGER_REDACTED_THINKING_\
46C9A13E193C177646C7398A98432ECCCE4C1253D5E2D82641AC0E52CC2876CB"
	 ;; https://codeberg.org/rossabaker/no-agents.md
	 "# Do not engage\n"))

    (if (<= (string-count text #\newline) 1)
      (begin
	(display "  but has only one line")
	(newline)))))

(libgit2-shutdown!)
