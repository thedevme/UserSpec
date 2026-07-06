# CLI Prompt — Add RSpec-Style Output to UserSpec

Paste the block below into Claude Code (CLI) while inside the **UserSpec** repo.

---

I want to add RSpec-style output to UserSpec — my BDD framework built on Swift Testing. Right now results only show in Xcode's Test navigator; I want the framework itself to print the behaviors as they run, the way RSpec's `--format documentation` does. This is a real framework feature, not a script bolted on outside it.

The output I'm after, printed from UserSpec's own data (the @UserStory / @Scenario / @UIScenario descriptions I already write):

```
As a traveler, I want to select my seat so I can sit comfortably
  ✓ Economy user can select an economy seat
  ✓ Economy user cannot select a business seat
  ✗ Business user can select a business seat

3 scenarios, 1 failure
```

Nested and indented (UserStory → Scenario), present-tense behavior names, ✓ for pass and ✗ for fail, green/red color, and a summary line at the end. Model it on RSpec documentation format.

DON'T build yet. First investigate and report back:

1. Read the UserSpec source. Show me how @UserStory, @Scenario, and @UIScenario are actually implemented, and whether there's any existing event handling or reporting in the framework. Cite the file paths.

2. Use context7 to pull the CURRENT Swift Testing API for observing test events (test started / passed / failed / issue recorded). Do NOT rely on training data — this API has been moving. Tell me the exact type(s) I'd hook into and whether Swift Testing PUBLICLY supports a custom event reporter in the version this package targets. If it doesn't, tell me the real options (e.g. a Trait-based approach, or a companion terminal formatter) instead of forcing an approach that isn't supported.

3. Note the output-destination issue: I know Xcode's console buffers and interleaves stdout when you hit the Run button, so clean sequential output really wants the terminal (`swift test` / `xcodebuild test`). Factor that into the design and plan to validate the reporter from the terminal, not the Xcode Run button.

Then give me an implementation plan and WAIT for my approval:
- where the reporter lives in the package
- how it hooks into Swift Testing's event system
- how it's enabled (I want it opt-in, not forced on every run)
- how it handles both @Scenario and @UIScenario
- how color works, and that it degrades gracefully when output isn't a TTY
- what, if anything, this changes about existing behavior (it must not break current @Scenario/@UIScenario runs)

Constraints: keep it opt-in, don't break anything that works today, match the RSpec documentation format above. After I approve the plan and you build it, show me the exact terminal command to run the tests and see the output.
