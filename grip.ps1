<#
.SYNOPSIS
Start a Grip preview of a Markdown file with an explicit color theme.
.EXAMPLE
grip.ps1
.EXAMPLE
grip.ps1 docs\guide.md
.EXAMPLE
grip.ps1 -Light -Port 6420 -OpenBrowser notes.md
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Path = 'README.md',
    [ValidateRange(1, 65535)]
    [int]$Port = 6419,
    [switch]$OpenBrowser,
    [switch]$Dark,
    [switch]$Light,
    [string]$Python = 'python',
    [Alias('h')]
    [switch]$Help
)

if ($Help) {
    $name = Split-Path -Leaf $PSCommandPath
    @"
Usage: $name [-Dark | -Light] [-Port <1-65535>] [-OpenBrowser] [-Python <path>] [-h] [file]

Start a Grip preview of a Markdown file. The theme defaults to dark.
Without [file], previews README.md in the current working directory.
[file] may appear before, between, or after the options.

Examples:
  $name                               # preview .\README.md (dark)
  $name docs\guide.md                 # preview a specific file
  $name -Light docs\guide.md          # light theme
  $name -Dark -Port 6420 notes.md     # dark theme on another port
  $name -OpenBrowser                  # open the browser automatically
  $name -Python C:\venv\Scripts\python.exe README.md
"@
    return
}

$ErrorActionPreference = 'Stop'
if ($Dark -and $Light) {
    throw "Specify only one of -Dark and -Light."
}
$theme = if ($Light) { 'light' } else { 'dark' }

$filePath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)
if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
    throw "File was not found: $filePath"
}
if (-not (Get-Command $Python -ErrorAction SilentlyContinue)) {
    throw "Python was not found. Specify the interpreter containing Grip with -Python <path>."
}

$previewCode = @'
import re
import socket
import sys

path, port = sys.argv[1], int(sys.argv[2])
open_browser, theme = sys.argv[3] == "1", sys.argv[4]
host = "127.0.0.1"

# Report occupied ports without stopping someone else's preview process.
try:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
        probe.bind((host, port))
except OSError as exc:
    raise SystemExit(
        f"Cannot listen on {host}:{port}: {exc}\n"
        "Stop the existing preview yourself, or pass -Port 6420."
    )

try:
    from grip import create_app
    from jinja2 import ChoiceLoader, DictLoader
except ImportError as exc:
    raise SystemExit(f"This Python interpreter cannot import Grip: {exc}")

app = create_app(path=path, autorefresh=True)

# Override templates only for this process; leave installed Grip files intact.
original_loader = app.jinja_loader
base, _, _ = original_loader.get_source(app.jinja_env, "base.html")
base, count = re.subn(
    r"<html\b[^>]*>",
    f'<html lang="en" data-color-mode="{theme}" '
    'data-light-theme="light" data-dark-theme="dark">',
    base,
    count=1,
)
if count != 1 or "</head>" not in base:
    raise SystemExit("Unsupported Grip base template: expected <html> and </head>.")

base = base.replace("</head>", f"""
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
    html {{ color-scheme: {theme}; }}
    /* A single-file preview has no repository sidebar. */
    #preview-page .Layout {{ display: block; }}
    #preview-page .container-xl {{
      max-width: 1012px;
      margin-left: auto;
      margin-right: auto;
    }}
  </style>
</head>""", 1)
app.jinja_loader = ChoiceLoader([
    DictLoader({"base.html": base}),
    original_loader,
])

print(f"Markdown preview ({theme}): http://localhost:{port}/", flush=True)
print(f"File: {path}\nPress Ctrl+C to stop.", flush=True)
app.run(host=host, port=port, debug=False, use_reloader=False,
        open_browser=open_browser)
'@

$previewCode | & $Python -u - $filePath $Port ([int]$OpenBrowser.IsPresent) $theme
if ($LASTEXITCODE -ne 0) {
    throw "Grip preview exited with code $LASTEXITCODE."
}
