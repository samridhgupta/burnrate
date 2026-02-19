# Burnrate Plugin Architecture

Technical documentation for the burnrate Claude plugin (MCP server).

## 🏗️ Overview

The burnrate plugin is an MCP (Model Context Protocol) server that exposes the burnrate CLI functionality to Claude Desktop and other MCP-compatible clients.

```
┌─────────────────┐
│  Claude Desktop │
│                 │
│  User Prompt    │
└────────┬────────┘
         │ MCP Protocol (stdio)
         │
┌────────▼────────┐
│  Burnrate MCP   │
│     Server      │
│   (Node.js)     │
└────────┬────────┘
         │ Shell Execution
         │
┌────────▼────────┐
│  Burnrate CLI   │
│    (Bash)       │
└────────┬────────┘
         │ File Read
         │
┌────────▼────────┐
│ ~/.claude/      │
│ stats-cache.json│
└─────────────────┘
```

## 📦 Components

### 1. MCP Server (`src/index.ts`)

**Purpose**: Implements the Model Context Protocol to bridge Claude and burnrate CLI.

**Key Classes**:
- `BurnrateServer`: Main server class that handles MCP lifecycle

**Responsibilities**:
- Initialize MCP server with capabilities (tools + resources)
- Handle tool invocation requests
- Handle resource read requests
- Manage stdio transport
- Error handling and graceful shutdown

### 2. Tool Handlers

Each burnrate command is exposed as an MCP tool:

| Tool | CLI Command | Description |
|------|-------------|-------------|
| `burnrate_summary` | `burnrate` | Current usage summary |
| `burnrate_show` | `burnrate show` | Detailed breakdown |
| `burnrate_history` | `burnrate history` | Daily history |
| `burnrate_week` | `burnrate week` | Week aggregate |
| `burnrate_month` | `burnrate month` | Month aggregate |
| `burnrate_trends` | `burnrate trends` | Spending trends |
| `burnrate_budget` | `burnrate budget` | Budget status |
| `burnrate_export` | `burnrate export` | Export data |
| `burnrate_config` | `burnrate config` | Show config |

**Input Schemas**: Each tool defines a JSON Schema for its parameters.

**Execution Flow**:
1. Claude invokes tool via MCP protocol
2. Server validates parameters against schema
3. Server constructs CLI command with args
4. Server executes command via Node.js `child_process`
5. Server captures stdout/stderr
6. Server returns output as MCP response

### 3. Resource Providers

Resources provide read-only access to burnrate data:

| Resource URI | Description | MIME Type |
|-------------|-------------|-----------|
| `burnrate://summary` | Current summary | text/plain |
| `burnrate://history` | Daily history | text/plain |
| `burnrate://budget` | Budget status | text/plain |
| `burnrate://config` | Configuration | text/plain |
| `burnrate://export/summary.json` | JSON summary | application/json |
| `burnrate://export/history.json` | JSON history | application/json |

**Resource Flow**:
1. Claude requests resource by URI
2. Server maps URI to CLI command
3. Server executes command
4. Server returns content with MIME type

### 4. Transport Layer

**Protocol**: Stdio (Standard Input/Output)
**Format**: JSON-RPC 2.0

**Why Stdio?**
- Simple and reliable
- No networking required
- Direct integration with Claude Desktop
- Low overhead

**Message Format**:
```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "burnrate_summary",
    "arguments": {
      "format": "compact"
    }
  },
  "id": 1
}
```

## 🔄 Data Flow

### Tool Invocation Flow

```
1. User → Claude
   "Check my token usage"

2. Claude → MCP Server (via stdio)
   {
     "method": "tools/call",
     "params": {
       "name": "burnrate_summary",
       "arguments": {}
     }
   }

3. MCP Server → Burnrate CLI
   $ burnrate --format compact --no-anim

4. Burnrate CLI → Stats File
   Read ~/.claude/stats-cache.json

5. Stats File → Burnrate CLI
   Return JSON data

6. Burnrate CLI → MCP Server
   Return formatted output (stdout)

7. MCP Server → Claude
   {
     "result": {
       "content": [
         {
           "type": "text",
           "text": "📊 Token Burn Summary\n..."
         }
       ]
     }
   }

8. Claude → User
   Display formatted response
```

### Resource Read Flow

```
1. Claude requests resource
   GET burnrate://summary

2. MCP Server executes CLI
   $ burnrate --no-anim

3. Return content with metadata
   {
     "contents": [{
       "uri": "burnrate://summary",
       "mimeType": "text/plain",
       "text": "..."
     }]
   }
```

## 🔒 Security Model

### Isolation

```
┌─────────────────────────────────┐
│      Burnrate Plugin            │
│                                 │
│  ┌───────────────────────────┐ │
│  │   MCP Server Process      │ │
│  │   - Runs as user          │ │
│  │   - No elevated privs     │ │
│  │   - Sandboxed by OS       │ │
│  └───────────────────────────┘ │
│                                 │
│  Permissions:                   │
│  ✓ Read: ~/.claude/stats-cache │
│  ✓ Read: ~/.config/burnrate/   │
│  ✓ Write: ~/.config/burnrate/  │
│  ✗ Network: None                │
│  ✗ Root: No                     │
└─────────────────────────────────┘
```

### Trust Boundaries

1. **Claude Desktop → Plugin**
   - Trust: MCP protocol is secure
   - Validation: Input schemas enforced
   - Isolation: Separate process

2. **Plugin → Burnrate CLI**
   - Trust: CLI is part of same package
   - Validation: Command args are sanitized
   - Isolation: Shell execution is controlled

3. **Burnrate CLI → Stats File**
   - Trust: File is owned by user
   - Validation: JSON parsing with error handling
   - Isolation: Read-only access

### Attack Surface

**Minimal**:
- No network exposure
- No external dependencies with known CVEs
- No user input passed directly to shell
- All file operations are constrained

**Mitigations**:
- Input validation via JSON Schema
- Command arguments are constructed programmatically (no string interpolation)
- Error messages don't leak sensitive paths
- Stderr is filtered (only show relevant errors)

## 🧪 Testing Strategy

### Unit Tests (Future)

```typescript
describe('BurnrateServer', () => {
  test('lists all tools', async () => {
    const response = await server.listTools();
    expect(response.tools).toHaveLength(9);
  });

  test('executes burnrate_summary', async () => {
    const response = await server.callTool('burnrate_summary', {});
    expect(response.content[0].text).toContain('Token Burn Summary');
  });
});
```

### Integration Tests

```bash
# Test full MCP protocol flow
echo '{"jsonrpc":"2.0","method":"tools/list","id":1}' | node dist/index.js

# Test tool invocation
echo '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"burnrate_summary","arguments":{}},"id":1}' | node dist/index.js

# Test resource read
echo '{"jsonrpc":"2.0","method":"resources/read","params":{"uri":"burnrate://summary"},"id":1}' | node dist/index.js
```

### E2E Tests

Use Claude Desktop to test real user scenarios:
1. Install plugin
2. Ask Claude to check token usage
3. Verify correct tool is invoked
4. Verify output is formatted correctly

## 🚀 Performance

### Latency

- **Tool Invocation**: ~50-100ms
  - MCP overhead: ~5ms
  - CLI execution: ~30-80ms
  - I/O (read stats): ~10-15ms

- **Resource Read**: ~40-90ms
  - Similar to tool invocation
  - No additional protocol overhead

### Memory

- **Server Process**: ~30-50MB
  - Node.js runtime: ~25MB
  - MCP SDK: ~5MB
  - Application code: <1MB

- **Per Request**: ~1-2MB
  - Temporary buffers
  - Command output capture

### Optimization Opportunities

1. **Caching**: Cache stats file reads for 1-2 seconds
2. **Batching**: Support batch tool calls (not in MCP spec yet)
3. **Streaming**: Stream large outputs (future)

## 🔮 Future Enhancements

### Planned Features

1. **Notifications**
   - Push budget alerts to Claude
   - Notify on unusual spending patterns

2. **Subscriptions**
   - Real-time updates when stats change
   - Webhook-style notifications

3. **Enhanced Resources**
   - `burnrate://charts/week.svg` - Visual charts
   - `burnrate://reports/monthly.pdf` - PDF reports

4. **Tool Composition**
   - Combine multiple operations
   - Transaction-like batching

### Protocol Extensions

When MCP spec evolves:
- Streaming responses for large data
- Progress notifications for long operations
- Resource mutations (not just reads)

## 📚 References

- [MCP Specification](https://modelcontextprotocol.io/)
- [Burnrate CLI Documentation](../README.md)
- [Claude Plugin Marketplace](https://claude.com/plugins)

## 🤝 Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for plugin development guidelines.

---

**Architecture Version**: 1.0
**Last Updated**: 2025-02-06
