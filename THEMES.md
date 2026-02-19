#!/usr/bin/env false
# Not a script. A document. Stop trying to execute it.

# burnrate Themes

> A theme is just a bash variable file. If that disappoints you, I'm sorry. If that excites you, you have the right attitude for this project.

---

## What themes do

Themes control the entire visual personality of burnrate: colors, icons, status indicators, messages, labels, tips, and the occasional existential commentary on your token spend.

Every theme defines the same ~70 variables. You fill them in. burnrate does the rest.

---

## Quick start

**Use a built-in theme:**
```bash
burnrate --theme ocean        # one-off, any command
burnrate setup --theme matrix # set permanently during setup
burnrate preview hourglass    # try before you commit
```

**Create your own:**
```bash
# Option 1: Start from scratch with the template
cp /path/to/burnrate/config/themes/_template.theme ~/.config/burnrate/themes/mytheme.theme
# edit it, then:
burnrate preview mytheme

# Option 2: Clone a built-in and tweak the messages
burnrate theme clone glacial mytheme
# now edit ~/.config/burnrate/themes/mytheme.theme
```

**Install a custom theme:**

Custom themes go in `~/.config/burnrate/themes/` (or `$XDG_CONFIG_HOME/burnrate/themes/`). burnrate finds them automatically.

```bash
mkdir -p ~/.config/burnrate/themes/
cp mytheme.theme ~/.config/burnrate/themes/
burnrate themes                  # should appear in the list
burnrate preview mytheme         # verify it looks right
```

---

## Built-in themes

| Name | Emoji | Metaphor |
|------|-------|----------|
| `glacial` | ❄️ | Environmental impact — every token melts the ice |
| `ember` | 🔥 | Controlled burn — every prompt fans the flame |
| `battery` | 🔋 | Device charge draining — cache = power-saving mode |
| `hourglass` | ⏳ | Sand falling — tokens are time |
| `garden` | 🌱 | Growing carefully — cache is compost |
| `ocean` | 🌊 | Rising tide — every uncached token a drop |
| `space` | 🚀 | Spacecraft on a mission — finite fuel, infinite void |

---

## Variable reference

Every theme file must define all of the following. Missing variables fall back to the default (glacial) theme values — which is fine, but probably not what you intended.

### Metadata

```bash
THEME_NAME="mytheme"          # Internal ID — must match filename (no spaces, lowercase)
THEME_DISPLAY_NAME="My Theme" # Pretty display name shown in theme lists
THEME_EMOJI="🎯"              # Single emoji for the theme — appears in headers
THEME_DESCRIPTION="One line that explains the metaphor"
THEME_AUTHOR="yourname"       # Credit yourself
THEME_VERSION="1.0.0"         # Semver — doesn't matter but looks professional
```

### Colors

ANSI escape codes. Don't overthink it.

```bash
THEME_PRIMARY='\033[1;36m'   # Main accent color — headers, highlights
THEME_SUCCESS='\033[0;32m'   # Good news color — high cache rate, low cost
THEME_WARNING='\033[0;33m'   # Caution color — things trending bad
THEME_ERROR='\033[0;31m'     # Bad news color — critical levels, overbudget
THEME_INFO='\033[0;34m'      # Neutral info color — labels, secondary text
THEME_DIM='\033[2;36m'       # Subdued/muted — timestamps, footnotes
```

Common color codes:
- `\033[0;3Nm` — normal colors: 1=red 2=green 3=yellow 4=blue 5=magenta 6=cyan
- `\033[1;3Nm` — bold/bright variants
- `\033[2;3Nm` — dim variants
- `\033[0m` — reset (don't assign this to any variable — it's used internally)

### Status indicators

Five distinct levels. Use distinct characters — duplicates make the cascade useless.

```bash
# Efficiency / health levels (cache rate, budget remaining %)
THEME_STATUS_EXCELLENT="🎯"  # 90-100% — peak condition
THEME_STATUS_GOOD="✅"       # 75-89%  — solid, sustainable
THEME_STATUS_WARNING="⚠️"    # 50-74%  — attention needed
THEME_STATUS_CRITICAL="🔴"   # 25-49%  — intervention required
THEME_STATUS_DANGER="💀"     # 0-24%   — you had one job

# Budget status
THEME_BUDGET_SAFE="🟢"       # Within budget
THEME_BUDGET_WARNING="🟡"    # Approaching limit
THEME_BUDGET_CRITICAL="🔴"   # Near or at limit
THEME_BUDGET_EXCEEDED="⛔"   # Budget gone — keep this dramatic

# Cache efficiency
THEME_CACHE_EXCELLENT="⭐"   # 80%+ cache hit — theme's "best" symbol
THEME_CACHE_GOOD="👍"        # 50-80% cache hit
THEME_CACHE_POOR="❌"        # <50% cache hit — the expensive state
```

### Icons

Single-purpose symbols used inline throughout the interface.

```bash
THEME_ICON_LOADING="⏳"      # Shown while fetching/computing
THEME_ICON_SUCCESS="✅"       # Positive outcome
THEME_ICON_ERROR="❌"         # Negative outcome
THEME_ICON_WARNING="⚠️"       # Caution state
THEME_ICON_INFO="ℹ️"          # Informational
THEME_ICON_COST="💰"          # Monetary cost displayed
THEME_ICON_TOKENS="🔤"        # Token count displayed
THEME_ICON_CACHE="💾"         # Cache-related display
THEME_ICON_BUDGET="📊"        # Budget tracking display
```

**For a minimal/message-only theme:** set all icon variables to empty string `""`. The output will still be correct — just without decorative characters.

### Messages

The narrative voice of your theme. These appear as contextual commentary throughout the output.

```bash
# Status messages (cache rate / efficiency context)
THEME_MSG_EXCELLENT="Your one-line message for excellent state"
THEME_MSG_GOOD="Message for good state"
THEME_MSG_WARNING="Message for warning state"
THEME_MSG_CRITICAL="Message for critical state"
THEME_MSG_DANGER="Message for danger state — make it sting a little"

# Cache efficiency messages
THEME_CACHE_MSG_EXCELLENT="Cache is thriving"
THEME_CACHE_MSG_GOOD="Cache is healthy"
THEME_CACHE_MSG_POOR="Cache is suffering — and so is your wallet"

# Budget messages
THEME_BUDGET_MSG_OK="Budget holding"
THEME_BUDGET_MSG_WARNING="Budget trending hot"
THEME_BUDGET_MSG_CRITICAL="Budget nearly gone"
THEME_BUDGET_MSG_EXCEEDED="Budget gone — past tense"

# No-budget messages (shown when user hasn't set limits)
THEME_BUDGET_UNLIMITED_DAILY="One-liner for unlimited daily — gently judgmental"
THEME_BUDGET_UNLIMITED_MONTHLY="One-liner for unlimited monthly"
THEME_BUDGET_UNLIMITED_BOTH="One-liner for no limits at all — less gentle"

# Context window messages (shown by 'burnrate context')
THEME_CTX_OK="Context has plenty of room"
THEME_CTX_HALF="Context half full — plan accordingly"
THEME_CTX_WARNING="Context getting crowded — /compact soon"
THEME_CTX_CRITICAL="Context nearly full — /compact now"
```

### Labels

Short noun phrases used as column headers and field labels.

```bash
THEME_LABEL_COST="Cost Label"        # e.g. "Fuel Burned", "Water Used", "Charge"
THEME_LABEL_SAVINGS="Savings Label"  # e.g. "Solar Harvested", "Nutrients Saved"
THEME_LABEL_TOKENS="Token Label"     # e.g. "Propellant Used", "Drops Spent"
THEME_LABEL_CACHE_READ="Cache Label" # e.g. "SOLAR POWERED!", "ICE PRESERVED!"
THEME_LABEL_STATUS="Status Label"    # e.g. "Mission Status", "Sea Conditions"
```

Keep labels short. They appear next to numbers.

### Tips

Seven rotating tips shown in the daily report. Each starts with `💡` by convention — or don't, it's your theme.

```bash
THEME_TIP_1="💡 Tip about cache hit rate"
THEME_TIP_2="💡 Tip about cache strategy"
THEME_TIP_3="💡 Tip about prompt length"
THEME_TIP_4="💡 Tip about output tokens (they cost 5x input)"
THEME_TIP_5="💡 Tip about /compact"
THEME_TIP_6="💡 Tip about budgets"
THEME_TIP_7="💡 A slightly more opinionated tip"
```

### Fun messages

Random variety shown in specific contexts. These are the places where your theme can have the most personality.

```bash
# Token burn intensity (shown after large spends)
THEME_BURN_LOW="Reaction to tiny spend"
THEME_BURN_MEDIUM="Reaction to moderate spend"
THEME_BURN_HIGH="Reaction to large spend"
THEME_BURN_MASSIVE="Reaction to catastrophic spend — make it dramatic"

# Cache hit celebrations (shown randomly on cache-efficient sessions)
THEME_CACHE_HIT_1="Celebration variant 1"
THEME_CACHE_HIT_2="Celebration variant 2"
THEME_CACHE_HIT_3="Celebration variant 3"
THEME_CACHE_HIT_4="Celebration variant 4"

# Cache miss lamentations
THEME_CACHE_MISS_1="Lament variant 1"
THEME_CACHE_MISS_2="Lament variant 2"
THEME_CACHE_MISS_3="Lament variant 3 — this one can be judgmental"

# Daily summary reactions
THEME_SUMMARY_EFFICIENT="Reaction to efficient day — praise, but measured"
THEME_SUMMARY_AVERAGE="Reaction to normal day — not bad, not good"
THEME_SUMMARY_WASTEFUL="Reaction to wasteful day — gentle disappointment"
THEME_SUMMARY_DISASTER="Reaction to disaster day — let them have it"

# Startup messages (shown when burnrate loads)
THEME_STARTUP_1="Startup message 1"
THEME_STARTUP_2="Startup message 2"
THEME_STARTUP_3="Startup message 3"

# Footer
THEME_FOOTER="One-line footer that appears at the bottom — make it the theme's thesis"
```

---

## Design philosophy

### Pick one metaphor and commit

The best themes have a single clear metaphor — ice, fire, water, time — and map *every concept* through that lens. Costs become "fuel burned" or "water used" or "sand spent." Cache reads become "frozen" or "solar powered" or "anchored." The five status levels escalate coherently within the metaphor.

Don't mix metaphors. A theme that's mostly about the ocean and then uses 💰 for cost icons is jarring and weak. If your metaphor doesn't have a natural icon for budgets, invent one that fits. The ocean theme uses 🚢 for budget — because ships have a budget of ocean to cross.

### Five-level cascade, no duplicates

The five status levels (`EXCELLENT → GOOD → WARNING → CRITICAL → DANGER`) must use five *distinct* icons. The reader should be able to glance at any indicator and immediately know the severity without reading the label. Duplicating icons across levels defeats this.

### The messages carry the personality

Colors and icons orient the reader. The messages are where the theme *speaks*. Every message is an opportunity to say something about the token economy in the voice of the metaphor. "Solar panels offline — burning chemical fuel for every token" communicates the same information as "cache miss" but actually makes someone think about what they're doing.

The best theme messages feel like they were written by a single consistent author who takes the metaphor seriously. They don't break the fourth wall (except maybe once, in the footer or danger message). They escalate in intensity as the situation deteriorates.

### The danger message earns the right to be honest

The lowest level — `THEME_STATUS_DANGER`, `THEME_SUMMARY_DISASTER`, `THEME_BUDGET_MSG_EXCEEDED` — is the place to drop the metaphor for a beat and just say what happened. "Running on fumes in the infinite void. This was preventable." or "The ship is at the bottom. A lighthouse would have helped." The user hit the worst case. The theme is allowed to notice.

---

## Complete template

Copy this to `~/.config/burnrate/themes/YOURNAME.theme` and fill it in:

```bash
#!/usr/bin/env bash
# YOURNAME Theme - [One-line metaphor description]
# "[Your theme tagline — the philosophy in one sentence]"

# ============================================================================
# THEME METADATA
# ============================================================================

THEME_NAME="yourname"           # lowercase, no spaces, matches filename
THEME_DISPLAY_NAME="Your Name"
THEME_EMOJI="🎯"
THEME_DESCRIPTION="One sentence describing the metaphor and what it represents"
THEME_AUTHOR="yourhandle"
THEME_VERSION="1.0.0"

# ============================================================================
# COLORS
# ============================================================================

THEME_PRIMARY='\033[1;36m'      # Main accent
THEME_SUCCESS='\033[0;32m'      # Positive
THEME_WARNING='\033[0;33m'      # Caution
THEME_ERROR='\033[0;31m'        # Danger
THEME_INFO='\033[0;34m'         # Neutral
THEME_DIM='\033[2;36m'          # Subdued

# ============================================================================
# STATUS INDICATORS
# ============================================================================

THEME_STATUS_EXCELLENT=""       # 90-100%
THEME_STATUS_GOOD=""            # 75-89%
THEME_STATUS_WARNING=""         # 50-74%
THEME_STATUS_CRITICAL=""        # 25-49%
THEME_STATUS_DANGER=""          # 0-24%

THEME_BUDGET_SAFE=""
THEME_BUDGET_WARNING=""
THEME_BUDGET_CRITICAL=""
THEME_BUDGET_EXCEEDED=""

THEME_CACHE_EXCELLENT=""
THEME_CACHE_GOOD=""
THEME_CACHE_POOR=""

# ============================================================================
# ICONS
# ============================================================================

THEME_ICON_LOADING=""
THEME_ICON_SUCCESS=""
THEME_ICON_ERROR=""
THEME_ICON_WARNING=""
THEME_ICON_INFO=""
THEME_ICON_COST=""
THEME_ICON_TOKENS=""
THEME_ICON_CACHE=""
THEME_ICON_BUDGET=""

# ============================================================================
# MESSAGES
# ============================================================================

THEME_MSG_EXCELLENT=""
THEME_MSG_GOOD=""
THEME_MSG_WARNING=""
THEME_MSG_CRITICAL=""
THEME_MSG_DANGER=""

THEME_CACHE_MSG_EXCELLENT=""
THEME_CACHE_MSG_GOOD=""
THEME_CACHE_MSG_POOR=""

THEME_BUDGET_MSG_OK=""
THEME_BUDGET_MSG_WARNING=""
THEME_BUDGET_MSG_CRITICAL=""
THEME_BUDGET_MSG_EXCEEDED=""

THEME_BUDGET_UNLIMITED_DAILY=""
THEME_BUDGET_UNLIMITED_MONTHLY=""
THEME_BUDGET_UNLIMITED_BOTH=""

THEME_FOOTER=""

THEME_CTX_OK=""
THEME_CTX_HALF=""
THEME_CTX_WARNING=""
THEME_CTX_CRITICAL=""

# ============================================================================
# LABELS
# ============================================================================

THEME_LABEL_COST=""
THEME_LABEL_SAVINGS=""
THEME_LABEL_TOKENS=""
THEME_LABEL_CACHE_READ=""
THEME_LABEL_STATUS=""

# ============================================================================
# TIPS
# ============================================================================

THEME_TIP_1="💡 "
THEME_TIP_2="💡 "
THEME_TIP_3="💡 "
THEME_TIP_4="💡 "
THEME_TIP_5="💡 "
THEME_TIP_6="💡 "
THEME_TIP_7="💡 "

# ============================================================================
# FUN MESSAGES
# ============================================================================

THEME_BURN_LOW=""
THEME_BURN_MEDIUM=""
THEME_BURN_HIGH=""
THEME_BURN_MASSIVE=""

THEME_CACHE_HIT_1=""
THEME_CACHE_HIT_2=""
THEME_CACHE_HIT_3=""
THEME_CACHE_HIT_4=""

THEME_CACHE_MISS_1=""
THEME_CACHE_MISS_2=""
THEME_CACHE_MISS_3=""

THEME_SUMMARY_EFFICIENT=""
THEME_SUMMARY_AVERAGE=""
THEME_SUMMARY_WASTEFUL=""
THEME_SUMMARY_DISASTER=""

THEME_STARTUP_1=""
THEME_STARTUP_2=""
THEME_STARTUP_3=""
```

---

## Clone from a built-in

The fastest way to create a theme is to clone one you like and replace the messages. The structure, variable order, and comments are already there.

**Using the CLI (if implemented):**
```bash
burnrate theme clone glacial mytheme
# creates ~/.config/burnrate/themes/mytheme.theme
# as a copy of glacial.theme with THEME_NAME/AUTHOR updated
# then open in your $EDITOR
```

**Manually:**
```bash
THEME_DIR="$(brew --prefix 2>/dev/null)/share/burnrate/themes"
# or: /usr/local/share/burnrate/themes
# or: wherever burnrate is installed

cp "$THEME_DIR/glacial.theme" ~/.config/burnrate/themes/mytheme.theme
```

Then edit:
1. Change `THEME_NAME` to match your filename
2. Change `THEME_DISPLAY_NAME`, `THEME_EMOJI`, `THEME_DESCRIPTION`, `THEME_AUTHOR`
3. Update colors if your metaphor calls for different ones
4. Replace icons with ones that fit your metaphor
5. Rewrite messages — this is the actual work
6. Run `burnrate preview mytheme` to see how it looks

You don't have to rewrite everything. If you love glacial's tips but hate its icons, change the icons and leave the tips alone. burnrate doesn't care. It's just variable substitution.

---

## Testing your theme

```bash
burnrate preview mytheme          # full preview with all states
burnrate --theme mytheme today    # test against real data
burnrate --theme mytheme context  # test context window display
burnrate --theme mytheme query cost  # quick sanity check
```

If something looks wrong, `burnrate preview` shows all states in one screen — excellent, warning, critical, budget states, cache states. It's easier than using real data to hit every level.

---

## Sharing your theme

Drop a PR at the burnrate repo with your `.theme` file added to `config/themes/`. Include in the PR description:
- One sentence describing the metaphor
- Your `THEME_FOOTER` as a preview of the voice
- Why you made it

We'll review for:
- Complete variable coverage (all ~70 vars defined)
- Distinct 5-level cascade (no duplicate status icons)
- Consistent metaphor (no mixed signals)
- Messages that say something (not just "ok" / "bad" / "warning")

We will not review for taste. Themes are personal. If your theme is intensely niche — aviation checklists, stock market tickers, golf handicaps — that's fine. More themes is more better.

---

## Notes for agents

If you're building tooling that creates or validates burnrate themes programmatically:

- Variable names are stable and listed above — the spec won't change without a major version bump
- All variables are simple strings — no arrays, no associative maps, no functions
- A theme file is sourced with `source theme.theme` in bash 3.2+ — no bashisms beyond 3.2
- Unknown variables in a theme file are ignored harmlessly
- Missing variables fall back to glacial theme defaults — this is intentional
- The 5-level cascade (`EXCELLENT/GOOD/WARNING/CRITICAL/DANGER`) maps to numeric thresholds: 90/75/50/25%
- ANSI color codes work as-is on any terminal that supports color (which is most of them)
- Theme files should be idempotent — sourcing them multiple times should produce the same result (no side effects, no command substitution, no output)

---

*burnrate — because someone has to count the tokens.*
