class Burnrate < Formula
  desc "Track Claude Code token costs with zero API calls"
  homepage "https://github.com/samridhgupta/burnrate"
  url "https://github.com/samridhgupta/burnrate/archive/refs/tags/v0.8.1.tar.gz"
  sha256 "796d2555338e41c0cb268228a2735e8dc7024f4fb1104d8bc982aac47830aeed"
  license "MIT"
  version "0.8.1"

  # Runtime dependency — used for all floating-point arithmetic
  depends_on "bc"

  # Works on macOS (bash 3.2+) and Linux
  # Windows: use WSL2 — https://learn.microsoft.com/windows/wsl/install

  def install
    # Main executable
    bin.install "burnrate"

    # Libraries and bundled config (themes, example config)
    # Installed to $(prefix)/share/burnrate/ so the binary can locate them
    # via the ../share/burnrate/lib fallback path baked into the script
    (share/"burnrate").install "lib"
    (share/"burnrate").install "config"
  end

  def post_install
    # Ensure user config directory exists
    config_dir = Pathname.new(ENV["HOME"]) / ".config" / "burnrate"
    config_dir.mkpath unless config_dir.exist?
  end

  def caveats
    <<~EOS
      burnrate reads Claude Code's local stats file:
        ~/.claude/stats-cache.json

      Run Claude Code at least once to generate this file, then:
        burnrate          # Today's summary
        burnrate show     # Detailed report
        burnrate budget   # Budget status
        burnrate --help   # All commands

      Set spending limits (optional):
        burnrate config   # Show current config
        Edit: ~/.config/burnrate/burnrate.conf

      Zero tokens used — pure bash, 100% offline.
    EOS
  end

  test do
    # Version flag must exit 0 and print version string
    output = shell_output("#{bin}/burnrate --version 2>&1")
    assert_match "burnrate version", output

    # Help must exit 0
    system "#{bin}/burnrate", "--help"
  end
end
