#!/usr/bin/env python3
"""Build and release TipCalculator.

    python scripts/deploy.py web              build the web app, deploy hosting
    python scripts/deploy.py web --host none  build the web app, deploy nothing
    python scripts/deploy.py android          build the release app bundle
    python scripts/deploy.py rules            deploy database rules only
    python scripts/deploy.py all

Configuration comes from flags or the environment, so the same script serves
local runs and CI:

    WEB_BASE_URL         overrides Config._defaultWebBaseUrl in the build
    RECAPTCHA_SITE_KEY   App Check on web; unset means App Check stays off
    FIREBASE_PROJECT     defaults to DEFAULT_PROJECT below
    WEB_HOST             firebase (default), cloudflare, or none

Standard library only, and no third-party dependency, so a CI image needs
nothing beyond python, flutter and the firebase CLI.
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

DEFAULT_PROJECT = "tipcalculator-a7607"
WEB_ENTRYPOINT = "lib/main_web.dart"
REPO_ROOT = Path(__file__).resolve().parent.parent
BUNDLE_PATH = "build/app/outputs/bundle/release/app-release.aab"
DEFAULT_WORKER = "tipcalculator-web"


class Aborted(Exception):
    """Raised when the operator declines, or a precondition is unmet."""


# --- output ----------------------------------------------------------------

# Colour only when attached to a terminal, so CI logs stay free of escapes.
_TTY = sys.stdout.isatty()


def step(message: str) -> None:
    print(f"\n\033[1m==> {message}\033[0m" if _TTY else f"\n==> {message}")


def warn(message: str) -> None:
    print(f"\033[33m!! {message}\033[0m" if _TTY else f"!! {message}", file=sys.stderr)


# --- command execution -----------------------------------------------------


class Runner:
    """Runs external commands, or prints them when dry.

    Every subprocess in this script goes through here, which is what makes
    --dry-run honest rather than approximate: nothing can bypass it.
    """

    def __init__(self, dry_run: bool, assume_yes: bool) -> None:
        self.dry_run = dry_run
        self.assume_yes = assume_yes

    def run(self, *command: str) -> None:
        if self.dry_run:
            print("   " + " ".join(command))
            return
        # shell=False: arguments are passed through as a list, so a value
        # containing spaces or quotes cannot turn into extra arguments.
        result = subprocess.run(command, cwd=REPO_ROOT)
        if result.returncode != 0:
            raise Aborted(f"{command[0]} exited with {result.returncode}")

    def confirm(self, message: str) -> None:
        """Gate for anything that leaves this machine.

        Hosting replaces what users load and rules take effect for the live
        Android app immediately, so neither is undone by re-running this.
        """
        if self.assume_yes or self.dry_run:
            return
        if input(f"{message} [y/N] ").strip().lower() != "y":
            raise Aborted("Aborted.")


# --- build configuration ---------------------------------------------------


def dart_defines(args: argparse.Namespace) -> list[str]:
    """Assembles --dart-define flags for the values that are actually set.

    Unset values are omitted rather than passed empty: an empty define would
    override the in-source default instead of deferring to it, which is how
    the share link silently lost its URL once already.
    """
    defines = []
    if args.web_base_url:
        defines.append(f"--dart-define=WEB_BASE_URL={args.web_base_url}")
    if args.recaptcha_site_key:
        defines.append(f"--dart-define=RECAPTCHA_SITE_KEY={args.recaptcha_site_key}")
    return defines


def require_tool(name: str) -> None:
    if shutil.which(name) is None:
        raise Aborted(f"Missing required tool: {name}")


# --- targets ---------------------------------------------------------------


def build_web(runner: Runner, args: argparse.Namespace) -> None:
    step(f"Building web ({WEB_ENTRYPOINT})")
    runner.run("flutter", "build", "web", "-t", WEB_ENTRYPOINT, "--release",
               *dart_defines(args))
    if not args.recaptcha_site_key:
        warn("RECAPTCHA_SITE_KEY unset: App Check is disabled in this web build")

    # Building and publishing are separated by --host so CI can take the
    # bundle and publish it in a step of its own, where a failure is
    # attributable to the deploy rather than to the build.
    if args.host == "none":
        step("Built build/web; no hosting deploy (--host none)")
        return

    if args.host == "cloudflare":
        runner.confirm(
            f"Deploy {args.worker} to Cloudflare Workers? This replaces the live site."
        )
        step("Deploying Cloudflare Worker")
        # Pinned major: wrangler ships breaking changes in majors, and an
        # unpinned npx would pick them up silently on some future run.
        runner.run("npx", "--yes", "wrangler@4", "deploy",
                   "--config", args.wrangler_config)
        return

    runner.confirm(f"Deploy hosting to {args.project}? This replaces the live site.")
    step("Deploying hosting")
    runner.run("firebase", "deploy", "--only", "hosting", "--project", args.project)


def build_android(runner: Runner, args: argparse.Namespace) -> None:
    # An unsigned release bundle is useless, and this reads better than the
    # Gradle failure it would otherwise become.
    if not (REPO_ROOT / "android" / "key.properties").exists():
        warn("android/key.properties not found: the bundle may not be signed for Play")

    step("Building Android app bundle")
    runner.run("flutter", "build", "appbundle", "--release", *dart_defines(args))
    step(f"Bundle: {BUNDLE_PATH}")
    print("   Upload it to the Play Console; this script does not publish.")


def deploy_rules(runner: Runner, args: argparse.Namespace) -> None:
    runner.confirm(
        f"Deploy database rules to {args.project}? "
        "Live for the Android app immediately."
    )
    step("Deploying database rules")
    runner.run("firebase", "deploy", "--only", "database", "--project", args.project)


# --- entrypoint ------------------------------------------------------------


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build and release TipCalculator.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("target", choices=["web", "android", "rules", "all"])
    parser.add_argument(
        "--project",
        default=os.environ.get("FIREBASE_PROJECT", DEFAULT_PROJECT),
        help=f"Firebase project id (default: {DEFAULT_PROJECT})",
    )
    parser.add_argument(
        "--web-base-url",
        default=os.environ.get("WEB_BASE_URL"),
        help="Overrides Config._defaultWebBaseUrl in the build.",
    )
    parser.add_argument(
        "--recaptcha-site-key",
        default=os.environ.get("RECAPTCHA_SITE_KEY"),
        help="reCAPTCHA v3 site key, enabling App Check on web.",
    )
    parser.add_argument(
        "--host",
        choices=["firebase", "cloudflare", "none"],
        default=os.environ.get("WEB_HOST", "firebase"),
        help="Where the web build is published (default: firebase).",
    )
    parser.add_argument(
        "--worker",
        default=os.environ.get("CLOUDFLARE_WORKER", DEFAULT_WORKER),
        help=f"Cloudflare Worker name, for the prompt (default: {DEFAULT_WORKER}).",
    )
    parser.add_argument(
        "--wrangler-config",
        default=os.environ.get("WRANGLER_CONFIG", "wrangler.jsonc"),
        help="Path to wrangler.jsonc, relative to the repo root.",
    )
    parser.add_argument("--dry-run", action="store_true",
                        help="Print every command instead of running it.")
    parser.add_argument("--yes", "-y", action="store_true",
                        help="Skip confirmation before anything is deployed.")
    parser.add_argument("--skip-checks", action="store_true",
                        help="Skip analyze and tests (not recommended).")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    runner = Runner(dry_run=args.dry_run, assume_yes=args.yes)

    try:
        require_tool("flutter")
        # `all` always deploys rules, so it needs firebase whatever --host says.
        if args.target in ("rules", "all") or (
            args.target == "web" and args.host == "firebase"
        ):
            require_tool("firebase")
        if args.target in ("web", "all") and args.host == "cloudflare":
            require_tool("npx")

        step(f"Project: {args.project}   Target: {args.target}")
        if args.dry_run:
            warn("dry run: nothing will be built or deployed")

        runner.run("flutter", "pub", "get")

        if args.skip_checks:
            warn("skipping analyze and tests")
        else:
            step("Static analysis")
            runner.run("flutter", "analyze")
            step("Tests")
            runner.run("flutter", "test")

        # Rules first in `all`: a deployed client should never run against
        # permissions older than itself.
        if args.target in ("rules", "all"):
            deploy_rules(runner, args)
        if args.target in ("web", "all"):
            build_web(runner, args)
        if args.target in ("android", "all"):
            build_android(runner, args)

        step("Done.")
        return 0
    except Aborted as error:
        print(f"\n{error}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("\nInterrupted.", file=sys.stderr)
        return 130


if __name__ == "__main__":
    sys.exit(main())
