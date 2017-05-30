require File.expand_path('../spec_helper', __FILE__)

module Danger
  describe DangerSwiftLint do
    it 'is a plugin' do
      expect(Danger::DangerSwiftLint < Danger::Plugin).to be_truthy
    end

    describe 'with Dangerfile' do
      before do
        @dangerfile = testing_dangerfile
        @swiftlint = @dangerfile.swift_lint
        @report_file = Dir.pwd + '/spec/fixtures/report_fixture.json'
        @report_json = JSON.parse File.read(@report_file, encoding:'utf-8')

        @swiftlint.env.request_source.pr_json = { head: { ref: 'my_fake_branch', sha: '123abc' } }
      end

      describe 'report' do
        before do
          allow(@swiftlint).to receive(:swiftlint_installed?).and_return(true)
          allow(@swiftlint).to receive(:get_report_json).and_return(@report_json)
          allow(Dir).to receive(:pwd).and_return('/Users/user/development')
        end

        it 'should raise when swiftlint not installed' do
          allow(@swiftlint).to receive(:swiftlint_installed?).and_return(false)
          @swiftlint.report
          expect(@swiftlint.status_report[:errors]).to eq(["swiftlint is not in the user's PATH, or it failed to install"])
        end

        it 'should run swiftlint when no report is provided' do
          expect(@swiftlint).to receive(:`).with('swiftlint lint --quiet --reporter json > ./swiftlint_report.json').and_return(@report_file)
          @swiftlint.report
        end

        it 'should create a heading on the first line' do
          @swiftlint.report @report_file

          output = @swiftlint.status_report[:markdowns].first.message.split "\n"

          expect(output[0]).to eq('### SwiftLint found issues')
          expect(output[1]).to eq('')
        end

        it 'should create a markdown table under the heading' do
          @swiftlint.report @report_file

          output = @swiftlint.status_report[:markdowns].first.message.split "\n"

          expect(output[2]).to eq('| Severity | File | Message |')
          expect(output[3]).to eq('|----------|------|---------|')
        end

        it 'should contain entries and links to all issues from report' do
          @swiftlint.report @report_file

          output = @swiftlint.status_report[:markdowns].first.message.split "\n"
          issues = output.drop(4)

          expect(issues[0]).to eq("| ⚠ | [/adamyanalunas/danger-swiftlint/Controllers/Controller.swift (line 37)](https://github.com/adamyanalunas/danger-swiftlint/tree/123abc/adamyanalunas/danger-swiftlint/Controllers/Controller.swift#L37) | Limit vertical whitespace to a single empty line. Currently 2. |")
          expect(issues[1]).to eq("| ❌ | [/adamyanalunas/danger-swiftlint/Controllers/Controller.swift (line 39)](https://github.com/adamyanalunas/danger-swiftlint/tree/123abc/adamyanalunas/danger-swiftlint/Controllers/Controller.swift#L39) | Enum element name should start with a lowercase character: 'Bar' |")
          expect(issues[2]).to eq("| ⚠ | [/adamyanalunas/danger-swiftlint/Controllers/Controller.swift (line 438)](https://github.com/adamyanalunas/danger-swiftlint/tree/123abc/adamyanalunas/danger-swiftlint/Controllers/Controller.swift#L438) | File should contain 400 lines or less: currently contains 438 |")
        end

        it 'should only process errors when configured as such' do
          @swiftlint.enabled_types = [:error]
          @swiftlint.report @report_file

          output = @swiftlint.status_report[:markdowns].first.message.split "\n"
          issues = output.drop(4)

          expect(issues.length).to eq(1)
          expect(issues[0]).to eq("| ❌ | [/adamyanalunas/danger-swiftlint/Controllers/Controller.swift (line 39)](https://github.com/adamyanalunas/danger-swiftlint/tree/123abc/adamyanalunas/danger-swiftlint/Controllers/Controller.swift#L39) | Enum element name should start with a lowercase character: 'Bar' |")
        end

        it 'should only process warnings when configured as such' do
          @swiftlint.enabled_types = [:warning]
          @swiftlint.report @report_file

          output = @swiftlint.status_report[:markdowns].first.message.split "\n"
          issues = output.drop(4)

          expect(issues.length).to eq(2)
          expect(issues[0]).to eq("| ⚠ | [/adamyanalunas/danger-swiftlint/Controllers/Controller.swift (line 37)](https://github.com/adamyanalunas/danger-swiftlint/tree/123abc/adamyanalunas/danger-swiftlint/Controllers/Controller.swift#L37) | Limit vertical whitespace to a single empty line. Currently 2. |")
          expect(issues[1]).to eq("| ⚠ | [/adamyanalunas/danger-swiftlint/Controllers/Controller.swift (line 438)](https://github.com/adamyanalunas/danger-swiftlint/tree/123abc/adamyanalunas/danger-swiftlint/Controllers/Controller.swift#L438) | File should contain 400 lines or less: currently contains 438 |")
        end

        it 'should show custom emojis' do
          @swiftlint.issue_emoji = {warning: '❓', error: '🛑'}
          @swiftlint.report @report_file

          output = @swiftlint.status_report[:markdowns].first.message.split "\n"
          issues = output.drop(4)

          expect(issues[0]).to include("| ❓ |")
          expect(issues[1]).to include("| 🛑 |")
          expect(issues[2]).to include("| ❓ |")
        end
      end

      describe 'swiftlint_installed?' do
        it 'should handle swiftlint not being installed' do
          allow(@swiftlint).to receive(:`).with('which swiftlint').and_return('')
          expect(@swiftlint.swiftlint_installed?).to be_falsy
        end

        it 'should handle swiftlint being installed' do
          allow(@swiftlint).to receive(:`).with('which swiftlint').and_return('/usr/local/bin/swiftlint')
          expect(@swiftlint.swiftlint_installed?).to be_truthy
        end
      end
    end
  end
end
