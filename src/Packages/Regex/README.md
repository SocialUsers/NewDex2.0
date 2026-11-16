# Luau RegEx

Dex uses [Roblox's Luau RegEx library](https://github.com/Roblox/luau-regexp) at revision `5672cbe8d3244775bcd76c592e2992b44500508c`. See [LICENSE](LICENSE) and the license in the vendored source.

The search adapter converts codepoint positions to UTF-8 byte offsets. It keeps capture groups and respects the selection boundaries without slicing the source. Searches that hit a size or work limit return an error.

Unicode category escapes and the `u` flag are unsupported. Regex replacement accepts `$0`, `$1` through `$99`, `${name}`, `$&`, and `$$`.
