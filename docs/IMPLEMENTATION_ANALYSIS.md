# CodexBar Implementation Analysis

## Overview
Analyzed [CodexBar](https://github.com/steipete/CodexBar) - a macOS menu bar app for tracking AI provider usage.

## Their Approach: Multi-Source Data Fetching

### Data Sources (4 methods)
```swift
public enum ClaudeUsageDataSource {
    case auto          // Auto-detect best method
    case oauth         // OAuth API (primary)
    case web           // Web scraping with cookies
    case cli           // Claude CLI with PTY
}
```

### 1. **OAuth API** (Primary Method)
- Uses Anthropic OAuth for authentication
- Fetches usage data via API endpoints
- Stores credentials in macOS Keychain
- Handles token refresh automatically
- **Pros**: Official API, reliable, secure
- **Cons**: Requires OAuth flow, network access

### 2. **Web API** (Cookie-based)
- Scrapes Claude web interface using browser cookies
- Extracts usage from web responses
- **Pros**: No OAuth needed
- **Cons**: Fragile (breaks if UI changes), requires cookies

### 3. **CLI (PTY)** (Interactive Terminal)
- Runs `claude` CLI in pseudo-terminal
- Sends commands: "Show plan usage limits"
- Parses JSON output
- Maintains persistent session
- **Pros**: Official CLI, structured output
- **Cons**: Complex (PTY management), slower

### 4. **Auto** (Smart Selection)
- Tries methods in priority order
- Falls back gracefully
- **Priority**: OAuth > CLI > Web

## Data Structure

### ClaudeUsageSnapshot
```swift
{
  primary: RateWindow        // 5-hour session limit
  secondary: RateWindow?     // Weekly all-models limit
  opus: RateWindow?          // Weekly opus/sonnet limit
  providerCost: {
    used: Double            // Amount spent
    limit: Double           // Budget limit
    currencyCode: String    // USD, EUR, etc
    period: String?         // "Monthly"
    resetsAt: Date?         // Reset timestamp
  }
  accountEmail: String?
  accountOrganization: String?
}
```

### RateWindow
```swift
{
  usedPercent: Double       // 0-100%
  windowMinutes: Int?       // Window duration
  resetsAt: Date?           // Reset time
  resetDescription: String? // "3h 45m"
}
```

## Our Current Approach

### Burnrate (Simple File-based)
```bash
# Read local cache file
~/.claude/stats-cache.json

# Parse JSON (pure bash)
{
  "version": 2,
  "modelUsage": {
    "inputTokens": 218326,
    "outputTokens": 910583,
    "cacheReadInputTokens": 546467923,
    "cacheCreationInputTokens": 44943815
  }
}

# Calculate costs
- Uses hardcoded pricing table
- Supports all Claude models (Opus, Sonnet, Haiku 3/3.5/4/4.5)
- Bash 3 compatible (no associative arrays)
```

**Pros:**
- ✅ Zero tokens used (reads local files)
- ✅ No authentication needed
- ✅ Works offline
- ✅ Pure bash (no dependencies)
- ✅ Fast (no network/subprocess)

**Cons:**
- ❌ Only cumulative totals (no daily/weekly breakdown)
- ❌ No rate limit info (5h/weekly limits)
- ❌ No account info (email, org)
- ❌ No reset times
- ❌ Pricing hardcoded (needs manual updates)

## Recommended Hybrid Approach

### Strategy: Best of Both Worlds

```
┌─────────────────────────────────────────────┐
│  BURNRATE HYBRID ARCHITECTURE              │
├─────────────────────────────────────────────┤
│                                             │
│  PRIMARY: Local File (stats-cache.json)    │
│  - Fast, offline, zero tokens              │
│  - Token counts & cumulative costs         │
│  - Model detection                          │
│                                             │
│  OPTIONAL: Claude CLI Integration          │
│  - Rate limits (5h session, weekly)        │
│  - Account info (email, org)               │
│  - Reset times                              │
│  - "Show plan usage limits"                 │
│                                             │
│  PRICING: Hybrid Model                      │
│  - Local pricing table (fast)              │
│  - Optional: Fetch live pricing from API   │
│  - Cache pricing data (update weekly)      │
│                                             │
└─────────────────────────────────────────────┘
```

## Implementation Plan

### Phase 1: Enhanced Local Parsing ✅
- [x] Parse stats-cache.json (DONE)
- [x] Multi-model support (DONE)
- [x] Cost calculation (DONE)
- [x] Cache efficiency (DONE)

### Phase 2: CLI Integration (OPTIONAL)
```bash
# Add optional CLI data source
burnrate --data-source=cli      # Use CLI for rate limits
burnrate --data-source=auto     # Auto-detect
burnrate --data-source=file     # File only (default)
```

**Implementation:**
```bash
# lib/claude-cli.sh
query_claude_cli() {
    # Run: claude --usage-json
    # Parse rate limits
    # Return: session_5h, week_all, week_opus
}

# Fallback chain
get_usage_data() {
    if [[ "$DATA_SOURCE" == "auto" ]]; then
        try_local_file || try_cli
    elif [[ "$DATA_SOURCE" == "cli" ]]; then
        try_cli
    else
        try_local_file
    fi
}
```

### Phase 3: Historical Data
```bash
# Parse dailyModelTokens from stats-cache.json
{
  "dailyModelTokens": [
    {
      "date": "2026-01-06",
      "tokensByModel": {
        "claude-sonnet-4-5": {
          "inputTokens": 12345,
          "outputTokens": 67890,
          ...
        }
      }
    }
  ]
}
```

**Benefits:**
- Daily breakdown
- Weekly/monthly aggregates
- Cost trends
- Model usage patterns

### Phase 4: Smart Pricing
```bash
# Pricing sources (priority order)
1. User config override
2. Cached pricing (updated weekly)
3. Hardcoded fallback
4. Optional: Fetch from API
```

## Key Improvements

### 1. **Hybrid Data Sources**
```bash
CONFIG_DATA_SOURCE="auto"  # auto, file, cli

if [[ "$CONFIG_DATA_SOURCE" == "auto" ]]; then
    # Try file first (fast)
    # Fall back to CLI if needed
fi
```

### 2. **Historical Tracking**
```bash
# Parse dailyModelTokens from stats-cache.json
- Get daily breakdown
- Calculate weekly/monthly totals
- Show cost trends
- Budget projections
```

### 3. **Rate Limit Tracking**
```bash
# Optional CLI integration
show_rate_limits() {
    # 5-hour session: 85% used (resets in 2h 15m)
    # Weekly all models: 45% used (resets Monday)
    # Weekly Opus/Sonnet: 30% used (resets Monday)
}
```

### 4. **Account Information**
```bash
# From CLI or OAuth
- Email
- Organization
- Plan type
- Login method
```

## Recommended Changes

### Change 1: Parse Historical Data
**Current:** Only read total cumulative tokens
**New:** Parse `dailyModelTokens` array for daily breakdown

**Impact:**
- Weekly/monthly aggregates
- Cost trends
- Better budget tracking

### Change 2: Optional CLI Integration
**Current:** File-only
**New:** Optional CLI fallback for rate limits

**Impact:**
- Rate limit warnings (approaching 5h/weekly limit)
- Reset time displays
- More complete picture

### Change 3: Smart Caching
**Current:** None
**New:** Cache expensive operations

**Impact:**
- Cache CLI responses (5 min TTL)
- Cache pricing (1 week TTL)
- Faster subsequent runs

## Example Output (Enhanced)

```bash
burnrate

⚠️  ZERO TOKENS USED - Pure script, reads local files only

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📊 Token Burn Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Model: Sonnet 4.5
Tokens: 592,540,647
Cost: $346.79
Cache Hit: 92.4%

Rate Limits:                                    # NEW!
  5h Session:   █████░░░░░ 45% (resets in 2h)
  Weekly All:   ███░░░░░░░ 30% (resets Mon)

Account: user@example.com                       # NEW!
Organization: My Company                        # NEW!

Remember: Every token melts the ice. Cache to save the Arctic! 🐻‍❄️
```

## Conclusion

### Best Approach: **Hybrid Model**

1. **Keep current file-based approach** (primary)
   - Fast, offline, zero tokens
   - Core functionality works

2. **Add optional CLI integration** (secondary)
   - Rate limits
   - Account info
   - Enhanced features
   - Graceful fallback

3. **Parse historical data** (enhancement)
   - Daily breakdown
   - Weekly/monthly views
   - Cost trends

4. **Smart caching** (optimization)
   - Cache CLI responses
   - Cache pricing updates
   - Faster performance

### Implementation Priority
1. ✅ Fix budget tracking bugs (in progress)
2. 🔄 Parse historical data (dailyModelTokens)
3. 🔄 Weekly/monthly aggregate views
4. 🔜 Optional CLI integration
5. 🔜 Rate limit tracking
6. 🔜 Documentation

This gives us **best of both worlds**: simplicity + power!
