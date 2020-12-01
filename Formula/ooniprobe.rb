class Ooniprobe < Formula
  include Language::Python::Virtualenv

  desc "Network interference detection tool"
  homepage "https://ooni.org/"
  url "https://github.com/ooni/probe-cli/archive/v3.0.11.tar.gz"
  sha256 "870b8e2d801a5ae96a27fe0f7898f70ff2839ea12c9872e272b78f175e07deb2"
  license "BSD-2-Clause"
  revision 4

  depends_on "go@1.14" => :build

  def install
    ENV["GOPATH"] = HOMEBREW_CACHE/"go_cache"
    (buildpath/"src/github.com/ooni/probe-cli").install buildpath.children

    cd "src/github.com/ooni/probe-cli" do
      system "./build.sh macos"
      bin.install "CLI/darwin/amd64/ooniprobe"
      prefix.install_metafiles
    end
  end

  def post_install
    ooni_home = Pathname.new "#{var}/ooniprobe"
    ooni_home.mkpath

    (prefix/"share/daily-config.json").write <<~EOS
    {
      "_version": 3,
      "_informed_consent": true,
      "sharing": {
        "include_ip": false,
        "include_asn": true,
        "upload_results": true
      },
      "nettests": {
        "websites_url_limit": 0,
        "websites_enabled_category_codes": [
          "ALDR",
          "ANON",
          "COMM",
          "COMT",
          "CTRL",
          "CULTR",
          "DATE",
          "ECON",
          "ENV",
          "FILE",
          "GAME",
          "GMB",
          "GOVT",
          "GRP",
          "HACK",
          "HATE",
          "HOST",
          "HUMR",
          "IGO",
          "LGBT",
          "MILX",
          "MISC",
          "MMED",
          "NEWS",
          "POLR",
          "PORN",
          "PROV",
          "PUBH",
          "REL",
          "SRCH",
          "XED"
        ]
      },
      "advanced": {
        "send_crash_reports": true,
        "collect_usage_stats": true
      }
    }
    EOS
  end

  plist_options manual: "ooniprobe run"

  def plist
    <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>Label</key>
        <string>#{plist_name}</string>

        <key>KeepAlive</key>
        <false/>
        <key>RunAtLoad</key>
        <true/>

        <key>EnvironmentVariables</key>
        <dict>
          <key>PATH</key>
          <string>#{HOMEBREW_PREFIX}/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
          <key>OONI_HOME</key>
          <string>#{HOMEBREW_PREFIX}/var/ooniprobe</string>
        </dict>

        <key>ProgramArguments</key>
        <array>
            <string>#{opt_bin}/ooniprobe</string>
            <string>--config=#{prefix}/share/daily-config.json</string>
            <string>--log-handler=syslog</string>
            <string>run</string>
            <string>unattended</string>
        </array>

        <key>StartInterval</key>
        <integer>86400</integer>

        <key>WorkingDirectory</key>
        <string>#{HOMEBREW_PREFIX}/var/ooniprobe</string>
    </dict>
    </plist>
    EOS
  end

  test do
    (testpath/"config.json").write <<~EOS
    {
      "_version": 3,
      "_informed_consent": true,
      "sharing": {
        "include_ip": false,
        "include_asn": true,
        "upload_results": false
      },
      "nettests": {
        "websites_url_limit": 1,
        "websites_enabled_category_codes": []
      },
      "advanced": {
        "send_crash_reports": true,
        "collect_usage_stats": true
      }
    }
    EOS

    mkdir_p "#{testpath}/ooni_home"
    ENV["OONI_HOME"] = "#{testpath}/ooni_home"
    system bin/"ooniprobe", "--config", testpath/"config.json", "run", "websites"
  end

  def caveats
    <<~EOS
    By enabling the homebrew service you will not be shown the informed consent.

    WARNING:

    • OONI Probe will likely test objectionable sites and services
    • Anyone monitoring your internet activity (such as your government
      or Internet provider) may be able to tell that you are using OONI Probe
    • The network data you collect will be published automatically

    To learn more about the risks see:
        https://ooni.org/about/risks
    EOS
  end
end
