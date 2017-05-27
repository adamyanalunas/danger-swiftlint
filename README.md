

### swiftlint

Surface your SwiftLint JSON report in pull requests.
If no report exists, one will be created using the existing SwiftLint install.
Results are displayed in a markdown table.

<blockquote>Run report
  <pre>
# Runs SwiftLint if necessary and processes the report using the default settings
swiftlint.report</pre>
</blockquote>

<blockquote>Run a report with a specific report file
  <pre>
# Assumes your path starts in the present directory
swiftlint.report 'path/to/report.json'</pre>
</blockquote>

<blockquote>Run a report, ignoring warnings
  <pre>
swiftlint.enabled_types = [:error]
swiftlint.report</pre>
</blockquote>

<blockquote>Run a report, defining custom warning emoji
  <pre>
swiftlint.issue_emoji[:warning] = '❓'
swiftlint.report</pre>
</blockquote>



#### Attributes

`enabled_types` - Allows you to set which issue types are displayed.
Defaults to `[:warning", :error]`

`issue_emoji` - Allows configuration of which emoji is shown for an issue type.
Defaults to `{:warning: '⚠', :error: '❌'}`




#### Methods

`report` - Lint an existing report or have one generated. Will fail if `swiftlint` is not installed.
Generates a `markdown` list of warnings and errors from the JSON report, linking to each issue's line in the PR.
Does nothing when there are no valid issues to raise.

`swiftlint_installed?` - Determine if swiftlint is currently installed in the system paths.




