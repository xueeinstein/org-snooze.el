;;; org-snooze.el --- Snooze your code, doc and feed

;; Copyright (C) 2018 Bill Xue <github.com/xueeinstein>
;; Author: Bill Xue
;; URL: https://github.com/xueeinstein/org-snooze.el
;; Created: 2018
;; Version: 0.0.1
;; Keywords: extensions

;;; Commentary:

;; Inspired by Google Inbox, org-snooze.el let you snooze code, doc and feed
;; then alert at desired time.
;; This file is NOT part of GNU Emacs.

;;; Code:
(require 'org-agenda)

(defvar org-snooze-records-file
  (expand-file-name "~/.snooze.org")
  "The org file where to store the snoozed items.")

(defvar org-snooze-records-file-title "Snoozed"
  "The title of org file which stores the snoozed items.")

(defvar org-snooze-default-late-today "18:00"
  "The default time of late today.")

(defvar org-snooze-default-early-tomorrow "08:00"
  "The default time of early tomorrow.")

(defun org-snooze-strip-text-properties (txt)
  "Strip text TXT propertiese."
  (set-text-properties 0 (length txt) nil txt)
  txt)

(defun org-snooze-left-trim-special-chars (s)
  "Left trim special characters in string S."
  (declare (pure t) (side-effect-free t))
  (save-match-data
    (if (string-match "\\`[^a-zA-Z]+" s)
        (replace-match "" t t s)
      s)))

(defun org-snooze-right-trim-special-chars (s)
  "Right trim special characters in string S."
  (declare (pure t) (side-effect-free t))
  (save-match-data
    (if (string-match "[^a-zA-Z]+\\'" s)
        (replace-match "" t t s)
      s)))

(defun org-snooze-trim-special-chars (s)
  "Trim special characters in string S."
  (org-snooze-left-trim-special-chars (org-snooze-right-trim-special-chars s)))

(defun org-snooze-parse-line-to-search (line)
  "Parse line content LINE to searchable text."
  (format "file:%s::%s" (buffer-file-name)
          (org-link-escape (org-snooze-trim-special-chars line))))

(defun org-snooze-refresh-agenda-appt ()
  "Refresh agenda list and appt."
  (org-agenda-list)
  (run-with-timer 2 nil 'org-agenda-redo)
  (org-agenda-to-appt)
  (org-agenda-quit))

(defun org-snooze ()
  "Main function to snooze current line and pick time."
  (interactive)
  (let* ((this-file (buffer-file-name))
         (line (org-snooze-strip-text-properties (thing-at-point 'line)))
         (search (org-snooze-parse-line-to-search line))
         (time (org-read-date)) ;; TODO: support to select quick time, like "early tomorrow"
         (dir (file-name-directory org-snooze-records-file)))

    (unless (file-exists-p dir)
      (make-directory t))

    ;; BEGIN -- modify snooze records file
    (with-temp-buffer
      (when (file-exists-p org-snooze-records-file)
        (insert-file-contents org-snooze-records-file))
      (org-mode)

      ;; insert title if not find
      (goto-char (point-min))
      (unless (re-search-forward (concat "^\\* " org-snooze-records-file-title) nil t)
        (beginning-of-line)
        (org-insert-heading)
        (insert org-snooze-records-file-title)
        (goto-char (point-min))
        (end-of-line))

      ;; insert new item as a subheading
      (org-insert-todo-subheading t)
      (insert (format "check snoozed %s" this-file))
      (org-deadline "" time)
      (insert (format " [[[%s][link]]]" search))
      (end-of-line)

      (write-region nil nil org-snooze-records-file))
    ;; END -- modify snooze records file

    ;; add to agenda files
    (unless (member org-snooze-records-file org-agenda-files)
      (add-to-list 'org-agenda-files org-snooze-records-file))

    ;; update appt-time-msg-list
    (appt-activate 1)
    (run-with-idle-timer 2 nil 'org-snooze-refresh-agenda-appt) ;; "idle" means record file is writen

    ;; notify success
    (message "Snoozed %s to %s" search time)))

(provide 'org-snooze)
;;; org-snooze.el ends here
