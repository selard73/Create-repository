"""mcp_wrap.py SRC OUT : wrap a warn()-printing Studio script so execute_luau returns its warn lines."""
import sys
from pathlib import Path
src = Path(sys.argv[1]).read_text(encoding="utf-8")
assert "]=====]" not in src
wrapped = (
    "local _L = {}\n"
    "local function warn(...) local t = {} for i = 1, select('#', ...) do t[i] = tostring(select(i, ...)) end table.insert(_L, table.concat(t, ' ')) end\n"
    "local _ok, _err = pcall(function()\n" + src + "\nend)\n"
    "if not _ok then table.insert(_L, 'QW@ERROR ' .. tostring(_err)) end\n"
    "return table.concat(_L, string.char(10))\n"
)
Path(sys.argv[2]).write_text(wrapped, encoding="utf-8")
print(len(wrapped), "chars ->", sys.argv[2])
