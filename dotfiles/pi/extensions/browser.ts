import { StringEnum } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { homedir } from "node:os";
import { join } from "node:path";
import { Type } from "typebox";

const UI = join(homedir(), "tools", "ui");

type Params = {
  action: "open" | "goto" | "read" | "text" | "html" | "click" | "hover" | "type" | "select" | "press" | "scroll" | "back" | "wait" | "resize" | "ping" | "stop";
  url?: string;
  target?: string;
  index?: number;
  text?: string;
  option?: string;
  key?: string;
  dy?: number;
  secs?: number;
  preset?: "desktop" | "mobile";
  offset?: number;
  session?: string;
  headed?: boolean;
};

function required<T>(value: T | undefined, action: string, name: string): T {
  if (value === undefined || value === "") {
    throw new Error(`browser action "${action}" requires ${name}`);
  }
  return value;
}

function subcommand(p: Params): string[] {
  switch (p.action) {
    case "open":
      return ["open", ...(p.headed ? ["--headed"] : []), required(p.url, p.action, "url")];
    case "goto":
      return ["goto", required(p.url, p.action, "url")];
    case "text":
      return ["text", ...(p.offset ? [String(p.offset)] : [])];
    case "html":
      return ["html", ...(p.target ? [p.target] : []), ...(p.offset ? ["--offset", String(p.offset)] : [])];
    case "hover":
      return [
        "hover",
        required(p.target, p.action, "target"),
        ...(p.index === undefined ? [] : [String(p.index)]),
      ];
    case "click":
      return [
        "click",
        required(p.target, p.action, "target"),
        ...(p.index === undefined ? [] : [String(p.index)]),
      ];
    case "type":
      return ["type", required(p.text, p.action, "text"), ...(p.target ? ["--into", p.target] : [])];
    case "select":
      return ["select", required(p.target, p.action, "target"), required(p.option, p.action, "option")];
    case "press":
      return ["press", required(p.key, p.action, "key")];
    case "scroll":
      return ["scroll", String(required(p.dy, p.action, "dy"))];
    case "wait":
      return ["wait", ...(p.secs ? [String(p.secs)] : [])];
    case "resize":
      return ["resize", required(p.preset, p.action, "preset")];
    default:
      return [p.action];
  }
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "browser",
    label: "Browser",
    description:
      "Operate a website as a persistent browser session. Snapshots are TSV rows of the interactive " +
      "elements and headings in the viewport; ids like e12 stay valid for the whole session and are " +
      "click targets. Actions return the diff they caused; \"= N unchanged\" alone means nothing " +
      "visible changed, and state flips report themselves (e.g. ~ e5 checkbox \"Terms\" [on]). " +
      "An @ line reports the URL whenever it changes. Use action text to read the page's readable " +
      "text; snapshots deliberately omit paragraph content. New tabs and JS dialogs are handled " +
      "automatically and noted in the output.",
    promptSnippet: "Operate a website in a persistent browser session",
    promptGuidelines: [
      "Use browser for any task that means operating a website, instead of curl, fetch, or a headless-browser script.",
      "Start a browser task with action open, then act on element ids from the snapshot it returns.",
      "Use browser action text to read article or paragraph content; the snapshot only lists interactive elements and headings.",
      "When the snapshot or text is missing something you need — a link's URL, a table's structure, an unfamiliar widget — use browser action html (with target for one element, without for the whole page).",
      "To fill a field, use browser action type with target set to the field's id; to choose from a dropdown, use action select with target and option.",
      "Only elements in the viewport are listed; scroll to reveal more. Sessions persist across tool calls until action stop.",
      "If a click reports no visible change, do not repeat it; try action text, a different element, or resize to desktop when a site hides content on mobile.",
    ],
    parameters: Type.Object({
      action: StringEnum([
        "open",
        "goto",
        "read",
        "text",
        "html",
        "click",
        "hover",
        "type",
        "select",
        "press",
        "scroll",
        "back",
        "wait",
        "resize",
        "ping",
        "stop",
      ] as const, {
        description:
          "open: start a session at url (returns full snapshot). goto: navigate. read: re-snapshot the viewport. " +
          "text: readable page text (capped; use offset to continue). html: cleaned HTML of the page, or of one element when target is given — structure, hrefs, and attributes the snapshot omits. click: click an element. hover: hover an element to reveal hover menus. " +
          "type: type text, into target if given, else into the focused element. " +
          "select: choose a dropdown option by visible text. press: press a key. scroll: scroll vertically. " +
          "back: go back in history. wait: let the page change on its own (returns the diff). resize: switch viewport preset. ping: check the session. stop: end the session.",
      }),
      url: Type.Optional(Type.String({ description: "Page URL, for open and goto" })),
      target: Type.Optional(
        Type.String({ description: "Element id (e12) or label text, for click, hover, type, and select" }),
      ),
      index: Type.Optional(
        Type.Integer({ description: "1-based pick among multiple label matches" }),
      ),
      text: Type.Optional(Type.String({ description: "Text to type, for type" })),
      option: Type.Optional(Type.String({ description: "Option's visible text, for select" })),
      key: Type.Optional(Type.String({ description: "Key name such as Enter, Tab, Escape, for press" })),
      dy: Type.Optional(
        Type.Integer({ description: "Pixels to scroll down, negative scrolls up, for scroll" }),
      ),
      preset: Type.Optional(
        StringEnum(["desktop", "mobile"] as const, {
          description: "Viewport for resize: desktop (1280x900) reveals sidebars that mobile (375x812, default) layouts hide",
        }),
      ),
      secs: Type.Optional(
        Type.Number({ description: "Seconds to wait (max 10, default 2), for wait" }),
      ),
      offset: Type.Optional(
        Type.Integer({ description: "Character offset to continue reading, for text" }),
      ),
      session: Type.Optional(
        Type.String({ description: 'Named session for parallel sites (default: "default")' }),
      ),
      headed: Type.Optional(
        Type.Boolean({ description: "Show the browser window, for open" }),
      ),
    }),

    async execute(_toolCallId, params: Params, signal) {
      const args = [
        ...(params.session ? ["-s", params.session] : []),
        ...subcommand(params),
      ];
      const result = await pi.exec(UI, args, { signal });
      if (result.code !== 0) {
        throw new Error(result.stderr.trim() || `ui exited with code ${result.code}`);
      }
      const output = [result.stdout.trim(), result.stderr.trim()].filter(Boolean).join("\n");
      return {
        content: [{ type: "text" as const, text: output || "(no output)" }],
        details: { args },
      };
    },
  });
}
