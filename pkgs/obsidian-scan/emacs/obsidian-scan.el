;;; obsidian-scan.el --- Use Rust scanner for Obsidian vault -*- lexical-binding: t; -*-

;; Copyright (C) 2024

;; Author: Assistant
;; Keywords: obsidian, performance
;; Package-Requires: ((emacs "27.1") (obsidian "1.0") (json "1.5"))

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; This package provides advice to make obsidian.el use a Rust-based scanner
;; for improved performance when scanning large Obsidian vaults.
;;
;; Installation:
;; 1. Build the Rust scanner and ensure it's in your PATH
;; 2. Load this file after obsidian.el
;; 3. Set `obsidian-scan-executable' to the path of the scanner
;;
;; The scanner will be used automatically when calling `obsidian-rescan-cache'
;; or `obsidian-update'.

;;; Code:

(require 'obsidian)
(require 'json)

(defgroup obsidian-scan nil
  "Rust scanner integration for obsidian.el."
  :group 'obsidian)

(defcustom obsidian-scan-executable "obsidian-scan"
  "Path to the Rust obsidian vault scanner executable."
  :type 'string
  :group 'obsidian-scan)

(defcustom obsidian-scan-enabled t
  "Whether to use the Rust scanner instead of Elisp scanning."
  :type 'boolean
  :group 'obsidian-scan)

(defvar obsidian-scan--debug nil
  "Enable debug output for the Rust scanner integration.")

(defun obsidian-scan--available-p ()
  "Check if the Rust scanner is available."
  (and obsidian-scan-enabled
       (executable-find obsidian-scan-executable)))

(defun obsidian-scan--run ()
  "Run the Rust scanner and return the parsed JSON output."
  (let* ((default-directory obsidian-directory)
         (output-buffer (generate-new-buffer " *obsidian-scanner-output*")))
    (unwind-protect
        (let ((exit-code (call-process obsidian-scan-executable
                                       nil
                                       output-buffer
                                       nil
                                       obsidian-directory)))
          (if (zerop exit-code)
              (with-current-buffer output-buffer
                (goto-char (point-min))
                (condition-case err
                    (json-parse-buffer :object-type 'hash-table
                                       :array-type 'list
                                       :null-object nil
                                       :false-object nil)
                  (json-error
                   (error "Failed to parse scanner output: %s" err))))
            (error "Scanner failed with exit code %d" exit-code)))
      (kill-buffer output-buffer))))

(defun obsidian-scan--convert-link-info (link-data)
  "Convert LINK-DATA from JSON format to the expected Elisp format."
  (list (gethash "begin" link-data)
        (gethash "end" link-data)
        (gethash "link_text" link-data)
        (gethash "url" link-data)
        (gethash "reference_label" link-data)
        (gethash "title_text" link-data)
        (gethash "bang" link-data)))

(defun obsidian-scan--convert-links (links-hash)
  "Convert LINKS-HASH from JSON format to obsidian.el format."
  (let ((converted-links (make-hash-table :test 'equal)))
    (maphash (lambda (target link-list)
               (puthash target
                        (mapcar #'obsidian-scan--convert-link-info link-list)
                        converted-links))
             links-hash)
    converted-links))

(defun obsidian-scan--populate-cache (json-data)
  "Populate the obsidian cache from JSON-DATA."
  ;; Clear existing cache
  (setq obsidian--aliases-map (make-hash-table :test 'equal))
  (setq obsidian--backlinks-alist (make-hash-table :test 'equal))
  (setq obsidian--jump-list nil)
  (setq obsidian-vault-cache (make-hash-table :test 'equal
                                              :size (hash-table-count json-data)))

  ;; Populate cache from JSON data
  (maphash (lambda (file-path file-data)
             ;; Create metadata hash table for this file
             (let ((meta (make-hash-table :test 'equal :size 3)))
               ;; Set tags
               (puthash 'tags (gethash "tags" file-data) meta)

               ;; Set aliases and update aliases map
               (let ((aliases (gethash "aliases" file-data)))
                 (puthash 'aliases aliases meta)
                 (dolist (alias aliases)
                   (puthash alias file-path obsidian--aliases-map)))

               ;; Convert and set links
               (puthash 'links
                        (obsidian-scan--convert-links (gethash "links" file-data))
                        meta)

               ;; Add to main cache
               (puthash file-path meta obsidian-vault-cache)))
           json-data)

  (setq obsidian--updated-time (float-time))
  (hash-table-count obsidian-vault-cache))

(defun obsidian-scan--rescan-cache-advice (orig-fun &rest args)
  "Advice for `obsidian-rescan-cache' to use Rust scanner.
ORIG-FUN is the original function, ARGS are its arguments."
  (if (obsidian-scan--available-p)
      (progn
        ;; Ensure directory is properly initialized
        (customize-set-variable 'obsidian-directory obsidian-directory)

        (let* ((start-time (current-time))
               (json-data (obsidian-scan--run))
               (file-count (obsidian-scan--populate-cache json-data))
               (elapsed (float-time (time-subtract (current-time) start-time))))
          file-count))
    ;; Fall back to original implementation
    (apply orig-fun args)))

(defun obsidian-scan--update-advice (orig-fun &rest args)
  "Advice for `obsidian-update' to use Rust scanner when appropriate.
ORIG-FUN is the original function, ARGS are its arguments."
  (if (obsidian-scan--available-p)
      ;; Always use Rust scanner when available
      (obsidian-rescan-cache)
    ;; Fall back to original implementation if scanner not available
    (apply orig-fun args)))

(defun obsidian-scan-benchmark ()
  "Benchmark the Rust scanner vs Elisp scanner."
  (interactive)
  (let ((rust-time nil)
        (elisp-time nil))
    ;; Benchmark Rust scanner
    (when (obsidian-scan--available-p)
      (let ((start (current-time)))
        (let ((obsidian-scan-enabled t))
          (obsidian-rescan-cache))
        (setq rust-time (float-time (time-subtract (current-time) start)))))

    ;; Benchmark Elisp scanner
    (let ((start (current-time)))
      (let ((obsidian-scan-enabled nil))
        (obsidian-rescan-cache))
      (setq elisp-time (float-time (time-subtract (current-time) start))))

    (message "Scanner benchmark results:\nRust: %.2f seconds\nElisp: %.2f seconds\nSpeedup: %.1fx"
             (or rust-time -1)
             elisp-time
             (if rust-time (/ elisp-time rust-time) 0))))

;;;###autoload
(defun obsidian-scan-enable ()
  "Enable the Rust scanner for obsidian.el."
  (interactive)
  (advice-add 'obsidian-rescan-cache :around #'obsidian-scan--rescan-cache-advice)
  (advice-add 'obsidian-update :around #'obsidian-scan--update-advice)
  (setq obsidian-scan-enabled t)
  (message "Obsidian Rust scanner enabled"))

;;;###autoload
(defun obsidian-scan-disable ()
  "Disable the Rust scanner for obsidian.el."
  (interactive)
  (advice-remove 'obsidian-rescan-cache #'obsidian-scan--rescan-cache-advice)
  (advice-remove 'obsidian-update #'obsidian-scan--update-advice)
  (setq obsidian-scan-enabled nil)
  (message "Obsidian Rust scanner disabled"))

;;;###autoload
(defun obsidian-scan-toggle ()
  "Toggle the Rust scanner for obsidian.el."
  (interactive)
  (if obsidian-scan-enabled
      (obsidian-scan-disable)
    (obsidian-scan-enable)))

;; Enable by default when loaded
(obsidian-scan-enable)

(provide 'obsidian-scan)
;;; obsidian-scan.el ends here
