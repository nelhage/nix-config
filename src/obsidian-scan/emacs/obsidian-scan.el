;; Performance enhancement for obsidian.el using Rust-based scanner
;; Place this code in your Emacs configuration after loading obsidian.el

(defcustom obsidian-scan-binary "obsidian-scan"
  "Path to the obsidian-scan binary.
If just the binary name is given, it must be present in your PATH."
  :type 'string
  :group 'obsidian)

(defvar obsidian--scanner-process-output nil
  "Temporary storage for scanner process output.")

(defun obsidian--call-scanner ()
  "Call the Rust-based obsidian-scan binary and return its output as a parsed JSON object.
Falls back to the original implementation if the binary is not available."
  (condition-case err
      (with-temp-buffer
        (let ((exit-code (call-process obsidian-scan-binary nil t nil
                                     "--vault" (expand-file-name obsidian-directory))))
          (if (= exit-code 0)
              (let ((json-array-type 'vector)
                    (json-object-type 'hash-table))
                (goto-char (point-min))
                (json-read))
            (error "obsidian-scan failed with exit code %d" exit-code))))
    (error
     (message "Failed to run obsidian-scan: %s. Falling back to original implementation." 
              (error-message-string err))
     nil)))

(defun obsidian--process-scanner-output (data)
  "Process the output DATA from obsidian-scan into the internal data structures."
  (when data
    ;; Update tags list
    (setq obsidian--tags-list
          (gethash "tags" data))
    
    ;; Clear and repopulate aliases map
    (obsidian--clear-aliases-map)
    (maphash (lambda (alias path)
               (obsidian--add-alias alias path))
             (gethash "aliases" data))
    
    ;; Update files cache
    (setq obsidian-files-cache
          (append (gethash "files" data) nil))
    (setq obsidian-cache-timestamp (float-time))))

(defun obsidian--update-with-scanner ()
  "Update obsidian data using the Rust scanner if available."
  (when-let ((scanner-data (obsidian--call-scanner)))
    (obsidian--process-scanner-output scanner-data)
    t))

;; Main advice for obsidian-update
(define-advice obsidian-update (:around (orig-fn) use-rust-scanner)
  "Advice to use the Rust scanner for updating obsidian data.
Falls back to the original implementation if the scanner is not available."
  (unless (obsidian--update-with-scanner)
    (funcall orig-fn))
  (message "Obsidian tags and aliases updated"))

;; Additional advice to prevent redundant work when scanner succeeds
(define-advice obsidian-reset-cache (:before-while () check-scanner)
  "Skip cache reset if we're using the scanner."
  (not (obsidian--update-with-scanner)))

(define-advice obsidian-update-tags-list (:before-while () check-scanner)
  "Skip tags update if we're using the scanner."
  (not (obsidian--update-with-scanner)))

(define-advice obsidian--update-all-from-front-matter (:before-while () check-scanner)
  "Skip front matter update if we're using the scanner."
  (not (obsidian--update-with-scanner)))