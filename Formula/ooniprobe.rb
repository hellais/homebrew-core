class Ooniprobe < Formula
  include Language::Python::Virtualenv

  desc "Network interference detection tool"
  homepage "https://ooni.org/"
  url "https://github.com/ooni/probe-cli/archive/v3.0.10.tar.gz"
  sha256 "2724199105b4708b82af456e882011bf1766849a1d72efb117343643230b8766"
  license "BSD-2-Clause"
  revision 3

  depends_on "go@1.14" => :build

  def install
    ENV["GOPATH"] = HOMEBREW_CACHE/"go_cache"
    (buildpath/"src/github.com/ooni/probe-cli").install buildpath.children

    cd "src/github.com/ooni/probe-cli" do
      system "./build.sh", "macos"

      prefix.install_metafiles
    end

    (var/"ooniprobe-daily-config.json").write <<~EOS
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

  def post_install
    ooni_home = Pathname.new "#{var}/ooniprobe"
    ooni_home.mkpath
  end

  plist_options startup: "true", manual: "ooniprobe run"

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
            <string>--config "#{HOMEBREW_PREFIX}/etc/ooniprobe-daily-config.json"</string>
            <string>--batch</string>
            <string>run</string>
        </array>

        <key>StartInterval</key>
        <integer>86400</integer>

        <key>StandardErrorPath</key>
          <string>/dev/null</string>
        <key>StandardOutPath</key>
          <string>/dev/null</string>
        <key>WorkingDirectory</key>
          <string>#{opt_prefix}</string>
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
