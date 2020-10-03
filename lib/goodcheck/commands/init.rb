module Goodcheck
  module Commands
    class Init
      CONFIG = <<-EOC
rules:
  # id, pattern, message are required attributes.
  - id: example.github
    pattern: Github
    message: Do you want to write GitHub?
    glob:
      - "**/*.rb"
      - "**/*.{yaml,yml}"
      - "public/**/*.html"
    fail:
      - Signup via Github
    pass:
      - Signup via GitHub

  # You can have *justification* to explain the exceptional cases.
  - id: example.localStorage
    pattern:
      token: localStorage
    message: |
      Using localStorage may raise error (example: with Safari in private mode)
    justification:
      - If you catch the errors.
      - When you implement admin console, where end users won't access.
    glob:
      - "**/*.js"
    fail:
      - |
        localStorage.setItem(key, value);

  # You can put `not` pattern to detect something is missing.
  - id: example.strict-mode
    not:
      pattern: use strict
    message: Use *strict mode* if possible.
    glob: "**/*.js"
    fail:
      - |
        const var = "This is *sloppy* mode."

  # You can omit pattern, which prints the message on the files specified by glob.
  - id: example.package-lock.json
    message: Some of the packages are updated!
    justification:
      - If you update some of the packages.
    glob: "package-lock.json"

# You can import rules.
# import:
#   - https://example.com/example-rules.yml

# You can skip checking files.
# exclude:
#   - node_modules
#   - vendor
      EOC

      include ExitStatus

      attr_reader :stdout
      attr_reader :stderr
      attr_reader :path
      attr_reader :force

      def initialize(stdout:, stderr:, path:, force:)
        @stdout = stdout
        @stderr = stderr
        @path = path
        @force = force
      end

      def run
        if path.file? && !force
          stderr.puts "#{path} already exists. Try --force option to overwrite the file."
          return EXIT_ERROR
        end

        path.open("w") do |io|
          io.print(CONFIG)
        end

        stdout.puts "Wrote #{path}. ✍️"

        EXIT_SUCCESS
      end
    end
  end
end
