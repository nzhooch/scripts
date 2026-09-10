#!/usr/bin/env python3
"""
Scan a host for Docker Compose files and generate Markdown documentation skeletons.

What it does:
- Searches common paths such as /home, /opt, /srv, and /mnt for compose files
- Ignores noisy folders like oldstuff, backups, cache, venvs, node_modules, .git
- Parses services, images, ports, volumes, networks, env_file, restart policy, container names
- Writes one Markdown file per stack plus an index.md summary

Requirements:
- Python 3.8+
- PyYAML (`python3 -m pip install pyyaml`)

Usage examples:
  python3 docker_docs_scanner.py
  python3 docker_docs_scanner.py --output /home/chris/docker-docs
  python3 docker_docs_scanner.py --roots /home/chris /mnt /opt
  python3 docker_docs_scanner.py --include-hidden
  python3 docker_docs_scanner.py --debug
"""

from __future__ import annotations

import argparse
import hashlib
import os
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML is required. Install it with: python3 -m pip install pyyaml", file=sys.stderr)
    sys.exit(1)

COMPOSE_FILENAMES = {
    "docker-compose.yml",
    "docker-compose.yaml",
    "compose.yml",
    "compose.yaml",
}

DEFAULT_ROOTS = [
    "/home",
    "/opt",
    "/srv",
    "/mnt",
]

DEFAULT_EXCLUDES = {
    ".git",
    ".cache",
    ".local",
    ".venv",
    "venv",
    "node_modules",
    "__pycache__",
    "oldstuff",
    "backup",
    "backups",
    ".backup",
    ".backups",
    ".old",
    ".olds",
    "lost+found",
    "tmp",
    "temp",
}

SENSITIVE_ENV_KEYS = {
    "PASSWORD",
    "PASS",
    "SECRET",
    "TOKEN",
    "KEY",
    "API_KEY",
    "AUTH",
    "JWT",
    "COOKIE",
    "SESSION",
    "DB_PASS",
    "DB_PASSWORD",
    "POSTGRES_PASSWORD",
    "MYSQL_PASSWORD",
}


@dataclass
class ServiceInfo:
    name: str
    image: str | None = None
    container_name: str | None = None
    restart: str | None = None
    ports: list[str] = field(default_factory=list)
    volumes: list[str] = field(default_factory=list)
    networks: list[str] = field(default_factory=list)
    env_files: list[str] = field(default_factory=list)
    environment_keys: list[str] = field(default_factory=list)
    depends_on: list[str] = field(default_factory=list)
    command: str | None = None


@dataclass
class StackInfo:
    stack_name: str
    compose_path: Path
    root_dir: Path
    services: list[ServiceInfo] = field(default_factory=list)
    top_level_networks: list[str] = field(default_factory=list)
    top_level_volumes: list[str] = field(default_factory=list)


@dataclass
class ScanResult:
    stacks: list[StackInfo] = field(default_factory=list)
    skipped: list[str] = field(default_factory=list)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate Markdown docs from Docker Compose files")
    parser.add_argument(
        "--roots",
        nargs="+",
        default=DEFAULT_ROOTS,
        help=f"Directories to scan (default: {' '.join(DEFAULT_ROOTS)})",
    )
    parser.add_argument(
        "--output",
        default="./docker-docs",
        help="Directory to write Markdown docs into (default: ./docker-docs)",
    )
    parser.add_argument(
        "--include-hidden",
        action="store_true",
        help="Include hidden directories while scanning",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Print extra debug information while scanning",
    )
    return parser.parse_args()


def should_skip_dir(dirname: str, include_hidden: bool) -> bool:
    if not include_hidden and dirname.startswith('.'):
        return True
    return dirname in DEFAULT_EXCLUDES


def find_compose_files(roots: Iterable[str], include_hidden: bool, debug: bool = False) -> list[Path]:
    found: list[Path] = []

    for root in roots:
        root_path = Path(root)
        if not root_path.exists():
            if debug:
                print(f"[skip] root does not exist: {root_path}")
            continue

        for current_root, dirnames, filenames in os.walk(root_path, topdown=True):
            dirnames[:] = [d for d in dirnames if not should_skip_dir(d, include_hidden)]

            for filename in filenames:
                if filename in COMPOSE_FILENAMES:
                    found.append(Path(current_root) / filename)

    # Stable sort keeps output predictable.
    return sorted(set(found))


def safe_load_yaml(path: Path) -> dict[str, Any] | None:
    try:
        with path.open("r", encoding="utf-8") as f:
            data = yaml.safe_load(f)
        if not isinstance(data, dict):
            return None
        return data
    except Exception:
        return None


def normalize_to_list(value: Any) -> list[Any]:
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


def stringify_command(value: Any) -> str | None:
    if value is None:
        return None
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        return " ".join(str(x) for x in value)
    return str(value)


def extract_environment_keys(environment: Any) -> list[str]:
    keys: list[str] = []

    if isinstance(environment, dict):
        for key in environment.keys():
            keys.append(str(key))
    elif isinstance(environment, list):
        for item in environment:
            if isinstance(item, str):
                if "=" in item:
                    keys.append(item.split("=", 1)[0].strip())
                else:
                    keys.append(item.strip())

    cleaned = []
    for key in keys:
        if not key:
            continue
        cleaned.append(key)

    return sorted(set(cleaned), key=str.lower)


def redact_env_key(key: str) -> str:
    upper = key.upper()
    if any(token in upper for token in SENSITIVE_ENV_KEYS):
        return f"{key} (sensitive)"
    return key


def parse_service(name: str, raw: dict[str, Any]) -> ServiceInfo:
    ports = [str(x) for x in normalize_to_list(raw.get("ports"))]
    volumes = [str(x) for x in normalize_to_list(raw.get("volumes"))]
    env_files = [str(x) for x in normalize_to_list(raw.get("env_file"))]
    depends_on_raw = raw.get("depends_on")

    depends_on: list[str] = []
    if isinstance(depends_on_raw, dict):
        depends_on = [str(k) for k in depends_on_raw.keys()]
    else:
        depends_on = [str(x) for x in normalize_to_list(depends_on_raw)]

    networks_raw = raw.get("networks")
    networks: list[str] = []
    if isinstance(networks_raw, dict):
        networks = [str(k) for k in networks_raw.keys()]
    else:
        networks = [str(x) for x in normalize_to_list(networks_raw)]

    environment_keys = [redact_env_key(k) for k in extract_environment_keys(raw.get("environment"))]

    return ServiceInfo(
        name=name,
        image=str(raw.get("image")) if raw.get("image") is not None else None,
        container_name=str(raw.get("container_name")) if raw.get("container_name") is not None else None,
        restart=str(raw.get("restart")) if raw.get("restart") is not None else None,
        ports=ports,
        volumes=volumes,
        networks=networks,
        env_files=env_files,
        environment_keys=environment_keys,
        depends_on=depends_on,
        command=stringify_command(raw.get("command")),
    )


def make_stack_name(compose_path: Path, data: dict[str, Any]) -> str:
    # Compose v2 may have a top-level 'name'. If not, use the parent folder name.
    explicit_name = data.get("name")
    if isinstance(explicit_name, str) and explicit_name.strip():
        return explicit_name.strip()

    parent_name = compose_path.parent.name.strip()
    if parent_name:
        return parent_name

    return "unnamed-stack"


def parse_compose_file(compose_path: Path) -> StackInfo | None:
    data = safe_load_yaml(compose_path)
    if data is None:
        return None

    services_raw = data.get("services")
    if not isinstance(services_raw, dict) or not services_raw:
        return None

    services: list[ServiceInfo] = []
    for service_name, raw_service in services_raw.items():
        if not isinstance(raw_service, dict):
            continue
        services.append(parse_service(str(service_name), raw_service))

    networks_raw = data.get("networks", {})
    volumes_raw = data.get("volumes", {})

    top_level_networks = list(networks_raw.keys()) if isinstance(networks_raw, dict) else []
    top_level_volumes = list(volumes_raw.keys()) if isinstance(volumes_raw, dict) else []

    return StackInfo(
        stack_name=make_stack_name(compose_path, data),
        compose_path=compose_path,
        root_dir=compose_path.parent,
        services=services,
        top_level_networks=sorted(top_level_networks),
        top_level_volumes=sorted(top_level_volumes),
    )


def unique_filename(stack: StackInfo) -> str:
    slug = slugify(stack.stack_name)
    digest = hashlib.sha1(str(stack.compose_path).encode("utf-8")).hexdigest()[:8]
    return f"{slug}-{digest}.md"


def slugify(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    value = re.sub(r"-+", "-", value).strip("-")
    return value or "stack"


def format_bullets(items: list[str], indent: int = 0) -> str:
    if not items:
        return " " * indent + "- none\n"
    return "".join(" " * indent + f"- {item}\n" for item in items)


def render_stack_markdown(stack: StackInfo) -> str:
    lines: list[str] = []
    lines.append(f"# {stack.stack_name}\n")
    lines.append("## Auto-Discovered Details\n")
    lines.append(f"- **Compose file:** `{stack.compose_path}`\n")
    lines.append(f"- **Stack root:** `{stack.root_dir}`\n")
    lines.append(f"- **Service count:** {len(stack.services)}\n")

    lines.append("\n## Services\n")
    for service in stack.services:
        lines.append(f"### {service.name}\n")
        lines.append(f"- **Image:** `{service.image or 'not set'}`\n")
        lines.append(f"- **Container name:** `{service.container_name or 'not set'}`\n")
        lines.append(f"- **Restart policy:** `{service.restart or 'not set'}`\n")
        lines.append(f"- **Command:** `{service.command or 'not set'}`\n")

        lines.append("- **Ports:**\n")
        lines.append(format_bullets([f"`{x}`" for x in service.ports], indent=2))

        lines.append("- **Volumes:**\n")
        lines.append(format_bullets([f"`{x}`" for x in service.volumes], indent=2))

        lines.append("- **Networks:**\n")
        lines.append(format_bullets([f"`{x}`" for x in service.networks], indent=2))

        lines.append("- **env_file references:**\n")
        lines.append(format_bullets([f"`{x}`" for x in service.env_files], indent=2))

        lines.append("- **Environment keys:**\n")
        lines.append(format_bullets([f"`{x}`" for x in service.environment_keys], indent=2))

        lines.append("- **Depends on:**\n")
        lines.append(format_bullets([f"`{x}`" for x in service.depends_on], indent=2))
        lines.append("\n")

    lines.append("## Top-Level Compose Objects\n")
    lines.append("### Networks\n")
    lines.append(format_bullets([f"`{x}`" for x in stack.top_level_networks]))
    lines.append("\n### Volumes\n")
    lines.append(format_bullets([f"`{x}`" for x in stack.top_level_volumes]))

    lines.append(
        """
## Notes To Fill In
- **Purpose:**
- **External URL:**
- **Internal URL:**
- **Host machine:**
- **Backups:**
- **Restore steps:**
- **Authentication:**
- **Known issues / gotchas:**
- **Depends on what elsewhere in the lab:**
- **Things to check after restore or reboot:**

## Change Log
- Initial skeleton generated automatically.
"""
    )

    return "".join(lines).strip() + "\n"


def render_index_markdown(stacks: list[StackInfo], generated_dir: Path) -> str:
    lines: list[str] = []
    lines.append("# Docker Documentation Index\n\n")
    lines.append(f"Generated stack docs: **{len(stacks)}**\n\n")
    lines.append("## Stacks\n")

    for stack in stacks:
        filename = unique_filename(stack)
        lines.append(
            f"- [{stack.stack_name}]({filename}) — `{stack.compose_path}` ({len(stack.services)} services)\n"
        )

    lines.append("\n## Scan Notes\n")
    lines.append("- Hidden directories are skipped unless `--include-hidden` is used.\n")
    lines.append("- Common junk folders are skipped automatically.\n")
    lines.append("- Environment values are not written out; only environment key names are listed.\n")
    lines.append("- Compose files are documented individually, so multiple stacks with the same folder name are handled safely.\n")

    return "".join(lines)


def write_docs(result: ScanResult, output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)

    for stack in result.stacks:
        target = output_dir / unique_filename(stack)
        target.write_text(render_stack_markdown(stack), encoding="utf-8")

    index_path = output_dir / "index.md"
    index_path.write_text(render_index_markdown(result.stacks, output_dir), encoding="utf-8")


def main() -> int:
    args = parse_args()

    compose_files = find_compose_files(args.roots, args.include_hidden, args.debug)
    if args.debug:
        print(f"[info] found {len(compose_files)} compose files")

    result = ScanResult()

    for compose_file in compose_files:
        stack = parse_compose_file(compose_file)
        if stack is None:
            result.skipped.append(str(compose_file))
            if args.debug:
                print(f"[skip] could not parse or no services: {compose_file}")
            continue
        result.stacks.append(stack)
        if args.debug:
            print(f"[ok] {compose_file} -> {stack.stack_name} ({len(stack.services)} services)")

    result.stacks.sort(key=lambda s: (s.stack_name.lower(), str(s.compose_path).lower()))

    output_dir = Path(args.output)
    write_docs(result, output_dir)

    print(f"Done. Wrote {len(result.stacks)} stack docs to: {output_dir.resolve()}")
    print(f"Index: {output_dir.resolve() / 'index.md'}")
    if result.skipped:
        print(f"Skipped {len(result.skipped)} compose files that were empty, invalid, or unsupported.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
