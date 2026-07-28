#!/usr/bin/env python3

"""
mail_cleanup.py - Himalaya-based mailbox cleanup
=================================================

Combines the old makeReport.py + performCleanup.py into one tool with
two subcommands:

    plan   - fetch/read email metadata, score it, write cleanup_plan.json
    run    - read cleanup_plan.json and actually delete / archive / review

Usage
-----
    python3 mail_cleanup.py plan [--update]
    python3 mail_cleanup.py run --dry-run
    python3 mail_cleanup.py run --archive
    python3 mail_cleanup.py run --delete
    python3 mail_cleanup.py run --review

Notes on what changed vs. the original two scripts
----------------------------------------------------
- Fixed: the "already fetched?" check tested for a file called
  `myAllEmails` (no extension) while the fetch writes `myAllEmails.json`.
  That mismatch meant --update-less runs re-fetched every single time.
- Fixed: performCleanup.py built a BASE_DIR but never used it, so the
  plan file was always read relative to the current working directory
  instead of the script's directory.
- Fixed: an email with an unparseable date got age_days = None, which
  *skipped* the safety downgrade instead of triggering it. Now unknown
  age is treated as the cautious case: DELETE/ARCHIVE decisions with
  unknown age always drop to REVIEW.
- Fixed: dict lookups like email["id"] would crash the whole run on one
  malformed record; switched to .get() with sane fallbacks.
- Removed dead code: `has_attachment` scoring, since Himalaya's
  `envelope list -o json` does not emit that field, so it always
  scored 0 and never actually protected anything with attachments.
- Added: a VIP/allowlist so senders you name never get auto-deleted or
  auto-archived, no matter what the score says.
- Added: an append-only audit log (cleanup_audit.log) recording every
  batch delete/archive actually executed, with timestamps, since
  deletes are irreversible.
- Added: everything is driven off one CONFIG block plus a script-local
  BASE_DIR so paths are stable regardless of cwd.

Advanced reject logic (junk/spam detection)
--------------------------------------------
- Keyword matching now uses word boundaries (regex) instead of plain
  substrings, so "job" no longer matches inside "jobless" and similar
  false positives.
- New: KNOWN_BULK_DOMAINS - recognizes mail sent through marketing
  infrastructure (Mailchimp, SendGrid, Klaviyo, Constant Contact,
  Mailgun, etc.) regardless of subject wording.
- New: TRUSTED_DOMAINS - domains that get an important-score boost and
  are hard-protected from auto DELETE/ARCHIVE, same as VIP_SENDERS.
- New: duplicate-subject detection - strips numbers/dates from the
  subject and counts repeats per sender, so "Order #123 shipped" and
  "Order #456 shipped" are recognized as the same automated template
  and scored as bulk mail even if no single copy trips a keyword.
- New: subject-shape detection - mostly-uppercase ("shouty") subjects
  and promo-style punctuation ("!!!", "$$", "50% off") add to the junk
  score independent of keyword matches.
- New: every classification now carries a `reasons` list explaining
  exactly which rules fired and by how much. Run `plan --explain` to
  print them for the sample output.
"""

import argparse
import json
import re
import subprocess
from collections import Counter
from datetime import datetime
from pathlib import Path
from time import sleep

# =========================
# CONFIG
# =========================
BASE_DIR = Path(__file__).resolve().parent

INPUT_FILE = BASE_DIR / "myAllEmails.json"
FULL_REPORT_FILE = BASE_DIR / "full_report.json"
CLEANUP_PLAN_FILE = BASE_DIR / "cleanup_plan.json"
AUDIT_LOG_FILE = BASE_DIR / "cleanup_audit.log"

DELETE_AFTER_DAYS = 30
ARCHIVE_AFTER_DAYS = 7

ARCHIVE_FOLDER = "[Gmail]/Bin"
BATCH_SIZE = 100
BATCH_DELAY = 0.5

# Senders that should NEVER be auto-deleted or auto-archived, no matter
# what the score says. Add substrings of email addresses here, e.g.
# "boss@company.com" or just "company.com" to cover a whole domain.
VIP_SENDERS = [
	# "boss@company.com",
]

IMPORTANT_KEYWORDS = [
	"invoice",
	"receipt",
	"payment",
	"security",
	"verification",
	"otp",
	"password",
	"github",
	"bank",
	"tax",
	"interview",
	"offer letter",
	"job application",
	"embedded",
	"developer",
]

PROMO_KEYWORDS = [
	"sale",
	"discount",
	"offer",
	"promotion",
	"unsubscribe",
	"deal",
	"coupon",
	"marketing",
	"buy now",
	"limited time",
]

JOB_ALERT_KEYWORDS = [
	"indeed",
	"linkedin",
	"job",
	"hiring",
	"freshers",
	"developer",
]

DELETE_SENDER_HINTS = [
	"noreply",
	"newsletter",
	"marketing",
	"promo",
]

# Infrastructure that mass-mailers and marketing platforms send through.
# A match here is a much stronger junk signal than a keyword in the
# subject, since a real person/company almost never sends through these.
KNOWN_BULK_DOMAINS = [
	"mailchimp.com",
	"mailchimpapp.net",
	"sendgrid.net",
	"sendgrid.com",
	"hubspotemail.net",
	"klaviyomail.com",
	"constantcontact.com",
	"mailgun.org",
	"sparkpostmail.com",
	"list-manage.com",
	"campaign-archive.com",
	"mandrillapp.com",
	"e.substack.com",
	"amazonses.com",
]

# Domains that should get an important-score boost and are protected
# from auto DELETE/ARCHIVE, e.g. your bank, employer, or landlord.
# Add full domains, e.g. "chase.com" or "mycompany.com".
TRUSTED_DOMAINS = [
	# "mycompany.com",
]

# If the same sender sends what's basically the same subject line (once
# numbers/dates are stripped out) this many times or more, treat it as
# a bulk/automated send rather than scoring each copy independently.
DUPLICATE_SUBJECT_THRESHOLD = 3

# Himalaya can emit a couple of different date formats depending on
# version/locale. Try each in turn instead of assuming one.
DATE_FORMATS = [
	"%a %b-%d-%Y %I:%M %p",
	"%a, %d %b %Y %H:%M:%S %z",
	"%Y-%m-%d %H:%M:%S",
]


# =========================
# HELPERS
# =========================
def normalize(text):
	return (text or "").lower()


def parse_date(date_str):
	if not date_str:
		return None
	for fmt in DATE_FORMATS:
		try:
			dt = datetime.strptime(date_str, fmt)
			if dt.tzinfo is not None:
				dt = dt.replace(tzinfo=None)
			return dt
		except ValueError:
			continue
	return None


def count_keyword_matches(text, keywords):
	"""Word-boundary matching instead of plain substring matching, so
	'job' doesn't false-positive on 'jobless' or 'developer' inside an
	unrelated word. Multi-word keywords like 'offer letter' still work
	since \\b anchors on the outer edges."""
	text = normalize(text)
	return sum(1 for kw in keywords if re.search(r"\b" + re.escape(kw) + r"\b", text))


def is_vip_sender(sender):
	sender = normalize(sender)
	return any(vip.lower() in sender for vip in VIP_SENDERS)


def sender_score(sender):
	sender = normalize(sender)
	return sum(3 for hint in DELETE_SENDER_HINTS if hint in sender)


def extract_domain(sender):
	sender = normalize(sender)
	return sender.split("@", 1)[1] if "@" in sender else ""


def _domain_matches(domain, domain_list):
	return any(domain == d or domain.endswith("." + d) for d in domain_list)


def is_bulk_domain(sender):
	return _domain_matches(extract_domain(sender), KNOWN_BULK_DOMAINS)


def is_trusted_domain(sender):
	return _domain_matches(extract_domain(sender), TRUSTED_DOMAINS)


def subject_is_shouty(raw_subject):
	"""True if the subject is mostly uppercase letters - a classic
	promo/spam pattern ('FINAL HOURS TO SAVE!!!')."""
	letters = [c for c in (raw_subject or "") if c.isalpha()]
	if len(letters) < 8:
		return False
	upper = sum(1 for c in letters if c.isupper())
	return (upper / len(letters)) > 0.6


def subject_has_promo_punctuation(raw_subject):
	"""Catches patterns like '!!!', '$$', or '50% off' that plain
	keyword lists miss."""
	return bool(re.search(r"(!{2,}|\${2,}|\d+%\s*off)", raw_subject or "", re.IGNORECASE))


def normalize_subject_for_dedup(raw_subject):
	"""Strips numbers/dates out of a subject so 'Order #1234 shipped'
	and 'Order #5678 shipped' are recognized as the same bulk template."""
	s = normalize(raw_subject)
	s = re.sub(r"\d+", "", s)
	s = re.sub(r"\s+", " ", s).strip()
	return s


def log_audit(action, ids, dry_run):
	"""Append-only record of what was actually done, since deletes
	can't be undone. Always written, even for dry runs (marked as such)."""
	with open(AUDIT_LOG_FILE, "a", encoding="utf-8") as f:
		ts = datetime.now().isoformat(timespec="seconds")
		tag = "DRY-RUN" if dry_run else "EXECUTED"
		f.write(f"[{ts}] {tag} {action.upper()} count={len(ids)} ids={ids}\n")


# =========================
# SCORING / CLASSIFICATION
# =========================
def classify_email(email, sender_frequency, dup_count):
	raw_subject = email.get("subject", "") or ""
	subject = normalize(raw_subject)
	sender = normalize(email.get("from", {}).get("addr", ""))

	important_score = 0
	junk_score = 0
	reasons = []

	def bump(target, amount, reason):
		nonlocal important_score, junk_score
		if target == "important":
			important_score += amount
		else:
			junk_score += amount
		reasons.append(f"{'+' if amount >= 0 else ''}{amount} {reason}")

	# --- keyword rules (word-boundary, not substring) ---
	important_hits = count_keyword_matches(subject, IMPORTANT_KEYWORDS)
	if important_hits:
		bump("important", important_hits * 3, f"important keyword match x{important_hits}")

	promo_hits = count_keyword_matches(subject, PROMO_KEYWORDS)
	if promo_hits:
		bump("junk", promo_hits * 3, f"promo keyword match x{promo_hits}")

	if count_keyword_matches(subject, JOB_ALERT_KEYWORDS):
		bump("important", 2, "job-alert keyword")
		if sender_frequency > 20:
			bump("junk", 2, "frequent job-alert sender")

	# --- sender-identity rules ---
	hint_score = sender_score(sender)
	if hint_score:
		bump("junk", hint_score, "sender name hints (noreply/marketing/etc.)")

	if is_bulk_domain(sender):
		bump("junk", 4, "known bulk-mail sending domain")

	if is_trusted_domain(sender):
		bump("important", 5, "trusted domain")

	# --- volume / repetition rules ---
	if sender_frequency > 50:
		bump("junk", 3, "very high-frequency sender (>50 emails)")
	elif sender_frequency > 20:
		bump("junk", 2, "high-frequency sender (>20 emails)")

	if dup_count >= DUPLICATE_SUBJECT_THRESHOLD:
		bump("junk", 3, f"near-duplicate subject seen {dup_count}x from this sender")

	# --- subject-shape rules (catch promo patterns keywords miss) ---
	if subject_is_shouty(raw_subject):
		bump("junk", 2, "mostly-uppercase 'shouty' subject")

	if subject_has_promo_punctuation(raw_subject):
		bump("junk", 2, "promo-style punctuation ('!!!', '$$', 'X% off')")

	email_date = parse_date(email.get("date", ""))
	age_days = (datetime.now() - email_date).days if email_date else None

	if important_score >= 8:
		action = "KEEP"
	elif junk_score >= 9:
		action = "DELETE"
	elif junk_score >= 5:
		action = "ARCHIVE"
	else:
		action = "REVIEW"

	# Age safety rules. Unknown age (date failed to parse) is the
	# cautious case: it always forces a downgrade to REVIEW for any
	# destructive/semi-destructive action, instead of skipping the
	# check the way the original script did.
	if action == "DELETE":
		if age_days is None or age_days < DELETE_AFTER_DAYS:
			action = "REVIEW"
			reasons.append("downgraded to REVIEW: age unknown or under delete threshold")
	elif action == "ARCHIVE":
		if age_days is None or age_days < ARCHIVE_AFTER_DAYS:
			action = "REVIEW"
			reasons.append("downgraded to REVIEW: age unknown or under archive threshold")

	# VIP / trusted-domain override: never auto-delete or auto-archive,
	# regardless of score.
	if (is_vip_sender(sender) or is_trusted_domain(sender)) and action in ("DELETE", "ARCHIVE"):
		action = "REVIEW"
		reasons.append("downgraded to REVIEW: VIP/trusted sender override")

	return {
		"id": email.get("id"),
		"subject": email.get("subject", ""),
		"sender": sender,
		"date": email.get("date", ""),
		"age_days": age_days,
		"important_score": important_score,
		"junk_score": junk_score,
		"action": action,
		"reasons": reasons,
	}


# =========================
# PLAN SUBCOMMAND
# =========================
def fetch_emails():
	print("Fetching email list...")
	subprocess.run(
		["himalaya", "envelope", "list", "--page-size", "10000", "-o", "json"],
		stdout=open(INPUT_FILE, "w", encoding="utf-8"),
		check=True,
	)
	print("Email list fetched successfully.")


def load_emails():
	with open(INPUT_FILE, "r", encoding="utf-8") as f:
		data = json.load(f)

	# Flatten nested lists (some himalaya versions paginate into
	# a list of lists).
	if isinstance(data, list) and len(data) > 0 and isinstance(data[0], list):
		emails = []
		for group in data:
			emails.extend(group)
		return emails
	return data


def cmd_plan(args):
	if args.update or not INPUT_FILE.exists():
		fetch_emails()
	else:
		print("Using existing email list.")

	print("Loading emails...")
	emails = load_emails()
	print(f"Loaded {len(emails)} emails.")

	sender_counts = Counter(normalize(e.get("from", {}).get("addr", "")) for e in emails)

	# (sender, template-subject) counts, used to catch bulk/automated
	# sends where only a number or date changes between copies.
	dedup_counts = Counter(
		(
			normalize(e.get("from", {}).get("addr", "")),
			normalize_subject_for_dedup(e.get("subject", "")),
		)
		for e in emails
	)

	results = []
	categorized_ids = {"KEEP": [], "ARCHIVE": [], "DELETE": [], "REVIEW": []}

	for email in emails:
		sender = normalize(email.get("from", {}).get("addr", ""))
		dedup_key = (sender, normalize_subject_for_dedup(email.get("subject", "")))
		result = classify_email(email, sender_counts[sender], dedup_counts[dedup_key])
		results.append(result)
		categorized_ids[result["action"]].append(result["id"])

	with open(FULL_REPORT_FILE, "w", encoding="utf-8") as f:
		json.dump(results, f, indent=4)

	cleanup_plan = {
		"summary": {
			"total_emails": len(emails),
			"keep": len(categorized_ids["KEEP"]),
			"archive": len(categorized_ids["ARCHIVE"]),
			"delete": len(categorized_ids["DELETE"]),
			"review": len(categorized_ids["REVIEW"]),
			"generated_at": datetime.now().isoformat(),
		},
		"actions": categorized_ids,
		"detailed_results": results,
	}

	with open(CLEANUP_PLAN_FILE, "w", encoding="utf-8") as f:
		json.dump(cleanup_plan, f, indent=4)

	print("\n=== CLEANUP SUMMARY ===")
	for category, ids in categorized_ids.items():
		print(f"{category}: {len(ids)}")

	print("\nFiles generated:")
	print(CLEANUP_PLAN_FILE.name)
	print(FULL_REPORT_FILE.name)

	print("\n=== SAMPLE ACTIONS ===")
	for item in results[:20]:
		print(f"{item['id']} | {item['action']:7} | {item['sender'][:30]:30} | {item['subject'][:60]}")
		if args.explain:
			for reason in item["reasons"]:
				print(f"        - {reason}")


# =========================
# RUN SUBCOMMAND
# =========================
def chunk_list(data, size):
	for i in range(0, len(data), size):
		yield data[i : i + size]


def run_command(cmd, dry_run=False):
	preview = " ".join(cmd[:10])
	suffix = " ..." if len(cmd) > 10 else ""
	print(f"> {preview}{suffix}")

	if dry_run:
		return True

	try:
		result = subprocess.run(cmd, check=True, text=True, capture_output=True)
		if result.stdout.strip():
			print(result.stdout.strip())
		return True
	except subprocess.CalledProcessError as e:
		print(f"FAILED: {' '.join(cmd[:10])} ...")
		if e.stderr:
			print(e.stderr.strip())
		return False


def process_ids(ids, action, dry_run=False):
	success = 0
	failed = 0

	for batch in chunk_list(ids, BATCH_SIZE):
		batch_ids = [str(i) for i in batch]

		if action == "delete":
			cmd = ["himalaya", "message", "delete"] + batch_ids
		elif action == "archive":
			cmd = ["himalaya", "message", "move", ARCHIVE_FOLDER] + batch_ids
		else:
			continue

		ok = run_command(cmd, dry_run=dry_run)
		if ok:
			success += len(batch)
		else:
			failed += len(batch)

		sleep(BATCH_DELAY)

	log_audit(action, ids, dry_run)
	return success, failed


def preview_review(ids, max_preview=50):
	print("\n=== REVIEW IDS ===")
	for eid in ids[:max_preview]:
		print(eid)
	if len(ids) > max_preview:
		print(f"... and {len(ids) - max_preview} more")


def cmd_run(args):
	if not CLEANUP_PLAN_FILE.exists():
		print(f"Missing cleanup plan: {CLEANUP_PLAN_FILE}")
		print("Run `python3 mail_cleanup.py plan` first.")
		return

	with open(CLEANUP_PLAN_FILE, "r", encoding="utf-8") as f:
		cleanup_plan = json.load(f)

	delete_ids = cleanup_plan["actions"]["DELETE"]
	archive_ids = cleanup_plan["actions"]["ARCHIVE"]
	review_ids = cleanup_plan["actions"]["REVIEW"]

	print("\n=== CLEANUP PLAN ===")
	print(f"DELETE : {len(delete_ids)}")
	print(f"ARCHIVE: {len(archive_ids)}")
	print(f"REVIEW : {len(review_ids)}")

	if args.dry_run:
		print("\n--- DELETE SAMPLE ---")
		for eid in delete_ids[:20]:
			print(f"DELETE {eid}")

		print("\n--- ARCHIVE SAMPLE ---")
		for eid in archive_ids[:20]:
			print(f"ARCHIVE {eid}")

		preview_review(review_ids)
		log_audit("delete", delete_ids, dry_run=True)
		log_audit("archive", archive_ids, dry_run=True)
		return

	if args.review:
		preview_review(review_ids)

	if args.archive:
		print("\nStarting ARCHIVE...")
		confirm = input(f"Archive {len(archive_ids)} emails? Type YES: ")
		if confirm == "YES":
			success, failed = process_ids(archive_ids, action="archive", dry_run=False)
			print(f"ARCHIVE complete: {success} success / {failed} failed")
		else:
			print("Archive cancelled.")

	if args.delete:
		print("\nWARNING: DELETE is destructive.")
		confirm = input(f"Delete {len(delete_ids)} emails? Type DELETE: ")
		if confirm == "DELETE":
			success, failed = process_ids(delete_ids, action="delete", dry_run=False)
			print(f"DELETE complete: {success} success / {failed} failed")
		else:
			print("Delete cancelled.")


# =========================
# CLI
# =========================
def main():
	parser = argparse.ArgumentParser(description="Himalaya mailbox cleanup")
	sub = parser.add_subparsers(dest="command", required=True)

	plan_parser = sub.add_parser("plan", help="Fetch/score emails and write cleanup_plan.json")
	plan_parser.add_argument("--update", action="store_true", help="Force re-fetch from Himalaya")
	plan_parser.add_argument("--explain", action="store_true", help="Show why each sample email was scored the way it was")
	plan_parser.set_defaults(func=cmd_plan)

	run_parser = sub.add_parser("run", help="Execute actions from cleanup_plan.json")
	run_parser.add_argument("--dry-run", action="store_true", help="Preview actions only, no changes")
	run_parser.add_argument("--delete", action="store_true", help="Delete all DELETE-flagged emails")
	run_parser.add_argument("--archive", action="store_true", help="Archive all ARCHIVE-flagged emails")
	run_parser.add_argument("--review", action="store_true", help="Preview REVIEW-flagged emails")
	run_parser.set_defaults(func=cmd_run)

	args = parser.parse_args()
	args.func(args)


if __name__ == "__main__":
	main()
