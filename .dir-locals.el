;; From guile-git.
;; The 'nil' configuration applies to all modes.
((scheme-mode
  . ((indent-tabs-mode . nil)
     (tab-width . 8)
     (eval . (progn
               (put 'with-directory 'scheme-indent-function 1)
               (put 'with-repository 'scheme-indent-function 2))))))
