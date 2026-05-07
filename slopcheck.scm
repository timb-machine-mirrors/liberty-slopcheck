#!/usr/bin/env sh
exec guile -e '(@ (slopcheck) main)' -s "$0" "$@"
!#
;; SlopCheck -- Check for signs of LLM agents in git repositories.
;; Copyright © 2026  Anna Liberty
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
	       (newline))))
       '("AGENTS.md" "CLAUDE.md" ".claude" "llms.txt"
	 ".gemini" ".agents" ".llms" ".codex"))

  (let* ((repository (repository-open path))
	 (head       (repository-head repository))
	 (master-oid (reference-target head))
	 (walker     (revwalk-new repository)))

    (revwalk-push! walker master-oid)
    (let loop ((oid (revwalk-next! walker)))
      (if oid
	  (begin
	    (let* ((commit (commit-lookup repository oid))
		   (body (commit-body commit)))

	      (for-each
	       (lambda (name)
		 (if (string-contains
		      body (string-append "Co-authored-by: " name))
		     (begin
		       (display "Found co-author ")
		       (display name)
		       (display " for commit ")
		       (display (oid->string oid))
		       (newline))))
	       '("Copilot" "Claude Opus" "Claude Sonnet")))
	    (loop (revwalk-next! walker)))))))

(libgit2-shutdown!)
