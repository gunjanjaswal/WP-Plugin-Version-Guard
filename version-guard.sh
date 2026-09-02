#!/usr/bin/env bash
#
# WP Plugin Version Guard
# Checks that a plugin's version is identical across the main file header,
# the readme.txt Stable tag, an optional version constant, and an optional
# Keep a Changelog heading. Exits non-zero on any mismatch.
#
set -euo pipefail

PLUGIN_FILE="${INPUT_PLUGIN_FILE:-}"
README="${INPUT_README:-readme.txt}"
CONSTANT="${INPUT_CONSTANT:-}"
CHANGELOG="${INPUT_CHANGELOG:-}"

err()  { echo "::error::$*"; }
note() { echo "$*"; }

if [ -z "$PLUGIN_FILE" ]; then err "The 'plugin-file' input is required."; exit 1; fi
if [ ! -f "$PLUGIN_FILE" ]; then err "Plugin file not found: $PLUGIN_FILE"; exit 1; fi

# Portable extractors (work with both BSD and GNU sed).
extract_header() {
	sed -nE 's/^[[:space:]]*\*?[[:space:]]*[Vv]ersion:[[:space:]]*([0-9A-Za-z._-]+).*/\1/p' "$1" | head -n1
}
extract_stable() {
	sed -nE 's/^[[:space:]]*[Ss]table tag:[[:space:]]*([0-9A-Za-z._-]+).*/\1/p' "$1" | head -n1
}
extract_constant() {
	sed -nE "s/.*define\\([[:space:]]*['\"]${2}['\"][[:space:]]*,[[:space:]]*['\"]([0-9A-Za-z._-]+)['\"].*/\\1/p" "$1" | head -n1
}
extract_changelog() {
	sed -nE 's/^##[[:space:]]*\[?([0-9]+\.[0-9]+(\.[0-9]+)?).*/\1/p' "$1" | head -n1
}

labels=()
values=()
add() { labels+=("$1"); values+=("$2"); }

header_ver="$(extract_header "$PLUGIN_FILE")"
if [ -z "$header_ver" ]; then err "No 'Version:' header found in $PLUGIN_FILE"; exit 1; fi
add "Plugin header ($PLUGIN_FILE)" "$header_ver"

if [ -n "$README" ] && [ -f "$README" ]; then
	stable="$(extract_stable "$README")"
	if [ -n "$stable" ]; then add "readme Stable tag ($README)" "$stable"; else note "Note: no 'Stable tag' in $README, skipping."; fi
elif [ -n "$README" ]; then
	note "Note: readme not found at $README, skipping."
fi

if [ -n "$CONSTANT" ]; then
	cver="$(extract_constant "$PLUGIN_FILE" "$CONSTANT")"
	if [ -z "$cver" ]; then
		# Fall back to scanning every PHP file in the tree.
		while IFS= read -r -d '' f; do
			cver="$(extract_constant "$f" "$CONSTANT")"
			[ -n "$cver" ] && break
		done < <(find . -name '*.php' -not -path '*/vendor/*' -not -path '*/.git/*' -print0)
	fi
	if [ -n "$cver" ]; then add "Constant $CONSTANT" "$cver"; else err "Version constant '$CONSTANT' not found."; exit 1; fi
fi

if [ -n "$CHANGELOG" ] && [ -f "$CHANGELOG" ]; then
	clver="$(extract_changelog "$CHANGELOG")"
	if [ -n "$clver" ]; then add "Changelog latest ($CHANGELOG)" "$clver"; else note "Note: no version heading in $CHANGELOG, skipping."; fi
elif [ -n "$CHANGELOG" ]; then
	note "Note: changelog not found at $CHANGELOG, skipping."
fi

ref="$header_ver"
mismatch=0

summary="${GITHUB_STEP_SUMMARY:-/dev/null}"
{
	echo "### WP Plugin Version Guard"
	echo ""
	echo "Reference version (plugin header): \`$ref\`"
	echo ""
	echo "| Source | Version | Match |"
	echo "| --- | --- | --- |"
} >> "$summary"

i=0
while [ "$i" -lt "${#labels[@]}" ]; do
	label="${labels[$i]}"
	val="${values[$i]}"
	if [ "$val" = "$ref" ]; then
		mark="yes"
	else
		mark="NO"
		mismatch=1
		err "$label is '$val' but expected '$ref' (from the plugin header)."
	fi
	echo "| $label | \`$val\` | $mark |" >> "$summary"
	note "$label: $val"
	i=$((i + 1))
done

if [ "$mismatch" -ne 0 ]; then
	err "Version mismatch. Every source must match the plugin header version ($ref)."
	exit 1
fi

note "All version references match: $ref"
