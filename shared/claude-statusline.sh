#!/usr/bin/env bash
# Claude Code status line — mirrors oh-my-posh theme segments
# Colors from palette: gray=#636e7b, blue=#316dca, green=#347d39, fgb=#cdd9e5, ink=#1c2128

input=$(cat)

# Pull every field out in one jq pass. This runs on each prompt render, so the
# seven separate jq invocations this replaces were the bulk of its cost.
#
# Fields are joined with U+001F (unit separator) rather than tabs: tab counts as
# IFS whitespace, so bash would collapse runs of empty fields and shift every
# later value into the wrong variable.
IFS=$'\x1f' read -r cwd model used_pct five_pct five_reset seven_pct seven_reset <<< "$(
  printf '%s' "$input" | jq -r '[
    (.workspace.current_dir // .cwd // ""),
    (.model.display_name // ""),
    (.context_window.used_percentage // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.five_hour.resets_at // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.rate_limits.seven_day.resets_at // "")
  ] | map(tostring) | join("\u001f")'
)"

# ANSI helpers (256-color approximations of hex palette)
reset="\033[0m"
bold="\033[1m"

# Foreground colors (approximate palette colors)
fg_gray="\033[38;2;99;110;123m"   # #636e7b
fg_green="\033[38;2;52;125;57m"   # #347d39
fg_blue="\033[38;2;49;109;202m"   # #316dca
fg_yellow="\033[38;2;150;102;0m"  # #966600
fg_red="\033[38;2;201;60;55m"     # #c93c37
fg_purple="\033[38;2;130;86;208m" # #8256d0
fg_cyan="\033[38;2;27;127;138m"   # #1b7f8a

# --- Glyphs: Nerd Font icons elsewhere, ASCII in JetBrains JediTerm (Rider) ---
# JediTerm font is usually not a Nerd Font; PUA glyphs render double-width and
# the width miscount shifts everything after them, jumbling the line.
if [ "$TERMINAL_EMULATOR" = "JetBrains-JediTerm" ]; then
  g_user=""; g_dir=""; g_model=""
  g_branch=""; g_ctx=""; g_5h=""; g_7d=""
  s_both="<>"; s_ahead="^"; s_behind="v"
else
  g_user="󰀄 "; g_dir="󰉋 "; g_model="󰚩 "
  g_branch="󰘬 "; g_ctx="󰧑 "; g_5h="󰥔 "; g_7d="󰃭 "
  s_both="⇕"; s_ahead="↑"; s_behind="↓"
fi

# --- Segment 1: user@host (gray) ---
user="${USER:-$(whoami)}"
host="${HOSTNAME%%.*}"
[ -n "$host" ] || host=$(hostname -s)
printf "${fg_gray}${g_user}${bold}%s${reset}${fg_gray}@%s${reset}" "$user" "$host"

# --- Segment 2: cwd (blue) ---
# Shorten home directory to ~. The tilde comes from a variable because a
# backslash-escaped ~ in the replacement is emitted literally, as "\~".
home="$HOME"
tilde="~"
display_dir="${cwd/#$home/$tilde}"
# Last two path components (folder style), via parameter expansion rather than
# an awk subprocess.
if [ "$display_dir" = "/" ]; then
  folder="/"
elif [[ "$display_dir" == */* ]]; then
  folder="${display_dir##*/}"
  parent="${display_dir%/*}"
  parent="${parent##*/}"
  if [ -n "$parent" ]; then
    folder="$parent/$folder"
  else
    # One level below root, e.g. /tmp — the parent component is root itself.
    folder="/$folder"
  fi
else
  folder="$display_dir"
fi
printf "  ${fg_blue}${g_dir}${bold}%s${reset}" "$folder"

# --- Segment 3: git branch (green/yellow) ---
# Single git invocation: branch name + ahead/behind + file status in one pass.
git_status=$(git -C "$cwd" status --porcelain=v2 --branch 2>/dev/null)
if [ -n "$git_status" ]; then
  # Parse header + entry lines in one awk pass.
  # Outputs: <branch>\t<ahead>\t<behind>\t<staged>\t<unstaged>
  parsed=$(printf '%s\n' "$git_status" | awk '
    /^# branch\.head / { branch=$3 }
    /^# branch\.ab / {
      a=$3; b=$4
      sub(/^\+/,"",a); sub(/^-/,"",b)
      ahead=a; behind=b
    }
    /^[12] / {
      xy=$2
      if (substr(xy,1,1) != ".") staged++
      if (substr(xy,2,1) != ".") unstaged++
    }
    /^\? / { unstaged++ }
    END { printf "%s\t%s\t%s\t%s\t%s", branch, ahead+0, behind+0, staged+0, unstaged+0 }
  ')
  IFS=$'\t' read -r branch ahead behind staged unstaged <<< "$parsed"

  # Detached HEAD: porcelain reports "(detached)" — fall back to short sha.
  if [ "$branch" = "(detached)" ] || [ -z "$branch" ]; then
    branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  fi
  # Truncate branch to 25 chars
  if [ "${#branch}" -gt 25 ]; then
    branch="${branch:0:25}..."
  fi

  dirty=$(( staged + unstaged ))
  if [ "$dirty" -gt 0 ]; then
    branch_color="$fg_yellow"
  elif [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
    branch_color="$fg_red"
  elif [ "$ahead" -gt 0 ]; then
    branch_color="\033[38;2;108;182;255m"  # #6cb6ff blueb
  elif [ "$behind" -gt 0 ]; then
    branch_color="$fg_purple"
  else
    branch_color="$fg_green"
  fi

  printf "  ${branch_color}${bold}${g_branch}%s${reset}" "$branch"

  # Ahead/behind indicators
  if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
    printf " ${fg_red}%s${reset}" "$s_both"
  elif [ "$ahead" -gt 0 ]; then
    printf " ${fg_blue}%s%s${reset}" "$s_ahead" "$ahead"
  elif [ "$behind" -gt 0 ]; then
    printf " ${fg_purple}%s%s${reset}" "$s_behind" "$behind"
  fi

  # Dirty indicator
  [ "$staged" -gt 0 ] && printf " ${fg_green}+%s${reset}" "$staged"
  [ "$unstaged" -gt 0 ] && printf " ${fg_yellow}~%s${reset}" "$unstaged"
fi

# --- Segment 4: Claude model (cyan) ---
if [ -n "$model" ]; then
  printf "  ${fg_cyan}${g_model}${bold}%s${reset}" "$model"
fi

# --- Line 2: usage bands (ctx / 5h / 7d) ---
printf "\n"

# --- Segment 5: context usage (gray / yellow / red) ---
if [ -n "$used_pct" ]; then
  pct_int=$(printf "%.0f" "$used_pct")
  if [ "$pct_int" -ge 50 ]; then
    ctx_color="$fg_red"
  elif [ "$pct_int" -ge 27 ]; then
    ctx_color="$fg_yellow"
  else
    ctx_color="$fg_gray"
  fi
  printf "  ${ctx_color}${g_ctx}ctx:%s%%${reset}" "$pct_int"
fi

# --- Segment 6: rate limits (gray) ---
# Format seconds-until-reset as compact remaining time (e.g. 3d4h, 2h13m, 45m)
fmt_remaining() {
  local secs="$1"
  [ -z "$secs" ] && return
  [ "$secs" -le 0 ] 2>/dev/null && { printf "0m"; return; }
  local d=$(( secs / 86400 ))
  local h=$(( (secs % 86400) / 3600 ))
  local m=$(( (secs % 3600) / 60 ))
  if [ "$d" -gt 0 ]; then
    printf "%dd%dh" "$d" "$h"
  elif [ "$h" -gt 0 ]; then
    printf "%dh%dm" "$h" "$m"
  else
    printf "%dm" "$m"
  fi
}

# Color by usage: yellow at warn%, red at crit%
rate_color() {
  local pct="$1" warn="$2" crit="$3"
  if [ "$pct" -ge "$crit" ]; then
    printf "%s" "$fg_red"
  elif [ "$pct" -ge "$warn" ]; then
    printf "%s" "$fg_yellow"
  else
    printf "%s" "$fg_gray"
  fi
}

now=$(date +%s)

if [ -n "$five_pct" ]; then
  five_int=$(printf '%.0f' "$five_pct")
  five_color=$(rate_color "$five_int" 75 90)
  printf "  ${five_color}${g_5h}5h:%s%%${reset}" "$five_int"
  if [ -n "$five_reset" ]; then
    printf " ${five_color}(%s)${reset}" "$(fmt_remaining $(( five_reset - now )))"
  fi
fi

if [ -n "$seven_pct" ]; then
  seven_int=$(printf '%.0f' "$seven_pct")
  seven_color=$(rate_color "$seven_int" 75 90)
  printf "  ${seven_color}${g_7d}7d:%s%%${reset}" "$seven_int"
  if [ -n "$seven_reset" ]; then
    printf " ${seven_color}(%s)${reset}" "$(fmt_remaining $(( seven_reset - now )))"
  fi
fi
