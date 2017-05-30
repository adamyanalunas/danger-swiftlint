require 'json'

module Danger
  # Surface your SwiftLint JSON report in pull requests.
  # If no report exists, one will be created using the existing SwiftLint install.
  # Results are displayed in a markdown table.
  #
  # @example Run report
  #
  #          # Runs SwiftLint if necessary and processes the report using the default settings
  #          swiftlint.report
  #
  # @example Run a report with a specific report file
  #
  #          # Assumes your path starts in the present directory
  #          swiftlint.report 'path/to/report.json'
  #
  # @example Run a report, ignoring warnings
  #
  #          swiftlint.enabled_types = [:error]
  #          swiftlint.report
  #
  # @example Run a report, defining custom warning emoji
  #
  #          swiftlint.issue_emoji[:warning] = '❓'
  #          swiftlint.report
  #
  # @tags lint, linting, swift, ios, macos, xcode
  #
  class DangerSwiftLint < Plugin
    # Allows you to set which issue types are displayed.
    # Defaults to `[:warning", :error]`
    #
    # @return   [Array<Symbol>]
    attr_accessor :enabled_types

    # Allows configuration of which emoji is shown for an issue type.
    # Defaults to `{:warning: '⚠', :error: '❌'}`
    #
    # @return [Hash<Symbol, String>]
    attr_accessor :issue_emoji

    def initialize dangerfile
      super(dangerfile)

      @enabled_types = [:warning, :error]
      @issue_emoji = {warning: '⚠', error: '❌'}
    end

    # Lint an existing report or have one generated. Will fail if `swiftlint` is not installed.
    # Generates a `markdown` list of warnings and errors from the JSON report, linking to each issue's line in the PR.
    # Does nothing when there are no valid issues to raise.
    #
    # @param   [String] file
    #          A full system path to an existing SwiftLint JSON report.
    #          If nil, swiftlint will be run to generate the report.
    # @return  [void]
    #
    def report(file = nil)
      # Check that swiftlint is in the user's PATH
      # raise "swiftlint is not in the user's PATH, or it failed to install" unless swiftlint_installed?
      unless swiftlint_installed?
        fail "swiftlint is not in the user's PATH, or it failed to install"
        return
      end

      # Create a report file if none is provided
      file = generate_report if file == nil

      # Gather JSON from the report to process
      report_json = get_report_json file

      # No need to create a report if there are no issues
      return if report_json.length == 0

      # Assumes this is being run in the root of the repo, using PWD to find the relative path of repo files
      commit_path = path_for_commit
      issues = ''
      report_json.each do |entry|
        type = entry['severity'].downcase.to_sym
        next unless enabled_types.include? type

        line = entry['line']
        report_filename = entry['file']
        repo_file_path = repo_path report_filename
        issue_path = issue_path commit_path, repo_file_path, line
        reason = entry['reason']

        issues << "| #{issue_emoji[type]} | [#{repo_file_path} (line #{line})](#{issue_path}) | #{reason} |\n"
      end

      show_report issues
    end

    # Determine if swiftlint is currently installed in the system paths.
    # @return  [Bool]
    def swiftlint_installed?
      `which swiftlint`.strip.empty? == false
    end

    private
    def generate_report
      filename = 'swiftlint_report.json'
      `swiftlint lint --quiet --reporter json > ./#{filename}`
      filename
    end

    def get_report_json file
      JSON.parse File.read(file, encoding:'utf-8')
    end

    def issue_path commit_path, repo_file_path, line
      check_scm_support

      commit_path + repo_file_path + "#L#{line}"
    end

    def path_for_commit
      check_scm_support

      # Get some metadata about the local setup
      host = 'https://' + env.request_source.host
      repo_slug = env.ci_source.repo_slug

      host + '/' + repo_slug + '/' + 'tree' + '/' + env.request_source.pr_json[:head][:sha]
    end

    def repo_path report_path, root = Dir.pwd
      report_path[report_path.index(root) + root.length, report_path.length]
    end

    def show_report issues
      return if issues.empty?

      header = "### SwiftLint found issues\n\n"
      header << "| Severity | File | Message |\n"
      header << "|----------|------|---------|\n"

      markdown header + issues
    end

    def check_scm_support
      unless defined? @dangerfile.github
        raise 'This plugin only supports Github. Would love PRs to support more! https://github.com/adamyanalunas/danger-swiftlint/'
      end
    end
  end
end
