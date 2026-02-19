#!/usr/bin/env node

/**
 * Burnrate MCP Server
 *
 * Exposes burnrate functionality as MCP tools for Claude plugins
 * Zero tokens used - reads local stats only
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListResourcesRequestSchema,
  ListToolsRequestSchema,
  ReadResourceRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';
import { fileURLToPath } from 'url';
import os from 'os';

const execAsync = promisify(exec);

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Find burnrate CLI (check if installed or use relative path)
const BURNRATE_CLI = process.env.BURNRATE_PATH || 'burnrate';

/**
 * Execute burnrate command and return output
 */
async function executeBurnrate(args: string[]): Promise<string> {
  try {
    const { stdout, stderr } = await execAsync(`${BURNRATE_CLI} ${args.join(' ')}`);
    if (stderr && !stderr.includes('ZERO TOKENS')) {
      console.error('Burnrate stderr:', stderr);
    }
    return stdout;
  } catch (error: any) {
    throw new Error(`Failed to execute burnrate: ${error.message}`);
  }
}

/**
 * Main MCP Server
 */
class BurnrateServer {
  private server: Server;

  constructor() {
    this.server = new Server(
      {
        name: 'burnrate',
        version: '0.1.0',
      },
      {
        capabilities: {
          tools: {},
          resources: {},
        },
      }
    );

    this.setupHandlers();
    this.setupErrorHandling();
  }

  private setupErrorHandling(): void {
    this.server.onerror = (error) => {
      console.error('[MCP Error]', error);
    };

    process.on('SIGINT', async () => {
      await this.server.close();
      process.exit(0);
    });
  }

  private setupHandlers(): void {
    // List available tools
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        {
          name: 'burnrate_summary',
          description: 'Get current token usage summary with costs and cache efficiency',
          inputSchema: {
            type: 'object',
            properties: {
              format: {
                type: 'string',
                enum: ['detailed', 'compact', 'minimal', 'json'],
                description: 'Output format (default: compact)',
                default: 'compact',
              },
            },
          },
        },
        {
          name: 'burnrate_show',
          description: 'Show detailed breakdown of token usage by type (input, output, cache)',
          inputSchema: {
            type: 'object',
            properties: {},
          },
        },
        {
          name: 'burnrate_history',
          description: 'Get daily token usage history',
          inputSchema: {
            type: 'object',
            properties: {
              format: {
                type: 'string',
                enum: ['table', 'json'],
                description: 'Output format (default: table)',
                default: 'table',
              },
            },
          },
        },
        {
          name: 'burnrate_week',
          description: 'Get this week\'s aggregate token usage and costs',
          inputSchema: {
            type: 'object',
            properties: {},
          },
        },
        {
          name: 'burnrate_month',
          description: 'Get this month\'s aggregate token usage and costs',
          inputSchema: {
            type: 'object',
            properties: {},
          },
        },
        {
          name: 'burnrate_trends',
          description: 'Show spending trends and patterns over time',
          inputSchema: {
            type: 'object',
            properties: {},
          },
        },
        {
          name: 'burnrate_budget',
          description: 'Check budget status, alerts, and remaining budget',
          inputSchema: {
            type: 'object',
            properties: {},
          },
        },
        {
          name: 'burnrate_export',
          description: 'Export usage data in various formats (JSON, CSV, Markdown)',
          inputSchema: {
            type: 'object',
            properties: {
              data_type: {
                type: 'string',
                enum: ['summary', 'history', 'budget', 'full'],
                description: 'Type of data to export',
                default: 'summary',
              },
              format: {
                type: 'string',
                enum: ['json', 'csv', 'markdown'],
                description: 'Export format',
                default: 'json',
              },
              start_date: {
                type: 'string',
                description: 'Start date for history export (YYYY-MM-DD)',
              },
              end_date: {
                type: 'string',
                description: 'End date for history export (YYYY-MM-DD)',
              },
            },
            required: ['data_type', 'format'],
          },
        },
        {
          name: 'burnrate_config',
          description: 'Show current burnrate configuration settings',
          inputSchema: {
            type: 'object',
            properties: {},
          },
        },
      ],
    }));

    // Handle tool calls
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case 'burnrate_summary': {
            const format = (args as any)?.format || 'compact';
            const output = await executeBurnrate(['--format', format, '--no-anim']);
            return {
              content: [{ type: 'text', text: output }],
            };
          }

          case 'burnrate_show': {
            const output = await executeBurnrate(['show', '--no-anim']);
            return {
              content: [{ type: 'text', text: output }],
            };
          }

          case 'burnrate_history': {
            const format = (args as any)?.format || 'table';
            const output = await executeBurnrate(['history', format, '--no-anim']);
            return {
              content: [{ type: 'text', text: output }],
            };
          }

          case 'burnrate_week': {
            const output = await executeBurnrate(['week', '--no-anim']);
            return {
              content: [{ type: 'text', text: output }],
            };
          }

          case 'burnrate_month': {
            const output = await executeBurnrate(['month', '--no-anim']);
            return {
              content: [{ type: 'text', text: output }],
            };
          }

          case 'burnrate_trends': {
            const output = await executeBurnrate(['trends', '--no-anim']);
            return {
              content: [{ type: 'text', text: output }],
            };
          }

          case 'burnrate_budget': {
            const output = await executeBurnrate(['budget', '--no-anim']);
            return {
              content: [{ type: 'text', text: output }],
            };
          }

          case 'burnrate_export': {
            const { data_type, format, start_date, end_date } = args as any;
            const exportArgs = ['export', data_type, format];

            // For history exports, add date range
            if (data_type === 'history' && start_date && end_date) {
              exportArgs.push('-', start_date, end_date);
            }

            const output = await executeBurnrate(exportArgs);
            return {
              content: [{ type: 'text', text: output }],
            };
          }

          case 'burnrate_config': {
            const output = await executeBurnrate(['config']);
            return {
              content: [{ type: 'text', text: output }],
            };
          }

          default:
            throw new Error(`Unknown tool: ${name}`);
        }
      } catch (error: any) {
        return {
          content: [
            {
              type: 'text',
              text: `Error executing ${name}: ${error.message}`,
            },
          ],
          isError: true,
        };
      }
    });

    // List available resources
    this.server.setRequestHandler(ListResourcesRequestSchema, async () => ({
      resources: [
        {
          uri: 'burnrate://summary',
          name: 'Current Usage Summary',
          description: 'Current token usage, costs, and cache efficiency',
          mimeType: 'text/plain',
        },
        {
          uri: 'burnrate://history',
          name: 'Daily Usage History',
          description: 'Historical daily token usage data',
          mimeType: 'text/plain',
        },
        {
          uri: 'burnrate://budget',
          name: 'Budget Status',
          description: 'Current budget status and alerts',
          mimeType: 'text/plain',
        },
        {
          uri: 'burnrate://config',
          name: 'Configuration',
          description: 'Current burnrate configuration',
          mimeType: 'text/plain',
        },
        {
          uri: 'burnrate://export/summary.json',
          name: 'Summary Export (JSON)',
          description: 'Export summary data as JSON',
          mimeType: 'application/json',
        },
        {
          uri: 'burnrate://export/history.json',
          name: 'History Export (JSON)',
          description: 'Export historical data as JSON',
          mimeType: 'application/json',
        },
      ],
    }));

    // Handle resource reads
    this.server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
      const { uri } = request.params;

      try {
        if (uri === 'burnrate://summary') {
          const output = await executeBurnrate(['--no-anim']);
          return {
            contents: [{ uri, mimeType: 'text/plain', text: output }],
          };
        }

        if (uri === 'burnrate://history') {
          const output = await executeBurnrate(['history', '--no-anim']);
          return {
            contents: [{ uri, mimeType: 'text/plain', text: output }],
          };
        }

        if (uri === 'burnrate://budget') {
          const output = await executeBurnrate(['budget', '--no-anim']);
          return {
            contents: [{ uri, mimeType: 'text/plain', text: output }],
          };
        }

        if (uri === 'burnrate://config') {
          const output = await executeBurnrate(['config']);
          return {
            contents: [{ uri, mimeType: 'text/plain', text: output }],
          };
        }

        if (uri === 'burnrate://export/summary.json') {
          const output = await executeBurnrate(['export', 'summary', 'json']);
          return {
            contents: [{ uri, mimeType: 'application/json', text: output }],
          };
        }

        if (uri === 'burnrate://export/history.json') {
          const output = await executeBurnrate(['export', 'history', 'json']);
          return {
            contents: [{ uri, mimeType: 'application/json', text: output }],
          };
        }

        throw new Error(`Unknown resource: ${uri}`);
      } catch (error: any) {
        throw new Error(`Failed to read resource ${uri}: ${error.message}`);
      }
    });
  }

  async run(): Promise<void> {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);

    console.error('Burnrate MCP server running on stdio');
    console.error('Zero tokens used - reads local stats only');
  }
}

// Start the server
const server = new BurnrateServer();
server.run().catch(console.error);
