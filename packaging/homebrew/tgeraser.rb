class Tgeraser < Formula
  desc "Delete all your Telegram messages without admin privileges"
  homepage "https://github.com/en9inerd/go-tgeraser"
  license "MIT"
  version "VERSION_PLACEHOLDER"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/en9inerd/go-tgeraser/releases/download/vVERSION_PLACEHOLDER/tgeraser-darwin-arm64"
      sha256 "SHA256_MACOS_ARM64"
    else
      url "https://github.com/en9inerd/go-tgeraser/releases/download/vVERSION_PLACEHOLDER/tgeraser-darwin-amd64"
      sha256 "SHA256_MACOS_AMD64"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/en9inerd/go-tgeraser/releases/download/vVERSION_PLACEHOLDER/tgeraser-linux-arm64"
      sha256 "SHA256_LINUX_ARM64"
    else
      url "https://github.com/en9inerd/go-tgeraser/releases/download/vVERSION_PLACEHOLDER/tgeraser-linux-amd64"
      sha256 "SHA256_LINUX_AMD64"
    end
  end

  def install
    binary = Dir["tgeraser*"].first
    bin.install binary => "tgeraser"
  end

  test do
    assert_match "tgeraser version", shell_output("#{bin}/tgeraser --version")
  end
end
