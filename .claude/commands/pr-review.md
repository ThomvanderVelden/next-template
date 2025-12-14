# PR Review Workflow

Automated workflow for creating a PR, waiting for automated review (if configured), and planning fixes.

## Your Mission

Create a pull request, optionally wait for automated CI checks and Claude Code review, fetch the review feedback, and create an actionable plan to address valid feedback.

## Workflow Steps

### 1. Pre-flight Checks (Linting & Build)

**CRITICAL**: Before creating the PR, ensure code quality and build success locally to avoid CI failures.

1. **Run linting checks**:
   ```bash
   pnpm lint
   ```

2. **Fix linting errors if any**:
   - If linting errors are found, automatically fix them:
     ```bash
     pnpm lint:fix
     ```
   - Review the fixes made and ensure they're correct
   - Commit the linting fixes if any were made

3. **Run build check**:
   ```bash
   pnpm build
   ```

4. **Fix build errors if any**:
   - Analyze any TypeScript errors, missing dependencies, or configuration issues
   - Fix each error systematically
   - Re-run the build to confirm fixes
   - Commit the build fixes if any were made

5. **Summary**:
   - Show the user a summary:
     ```
     ✅ Pre-flight checks complete:
     - Linting: PASSED
     - Build: PASSED

     Ready to create PR!
     ```
   - If errors were fixed, inform the user:
     ```
     🔧 Fixed issues before creating PR:
     - Fixed X linting errors
     - Fixed Y TypeScript errors
     - Committed fixes

     ✅ All checks now passing. Proceeding with PR creation...
     ```

**Important**:
- Use the TodoWrite tool to track pre-flight check tasks
- Mark each check as completed as you go
- Only proceed to PR creation if ALL checks pass
- If critical errors cannot be auto-fixed, inform the user and ask for guidance

### 2. Create Pull Request

After pre-flight checks pass, gather the necessary information and create the PR:

1. Run `git status` to check current branch and changes
2. **CRITICAL**: Identify the commits for THIS PR:
   - Run `git log origin/main..HEAD --oneline` to see NEW commits on this branch
   - These are the commits that will be included in the PR
   - Use `git show --stat <commit-hash>` for EACH new commit to see what changed
   - **DO NOT** use `git diff main...HEAD` as it shows ALL history since branch divergence
3. Analyze ONLY the changes from the new commits and draft a clear PR title and description based on what was ACTUALLY changed
4. Create the PR using `gh pr create` with appropriate title and body
5. Capture the PR number from the output

### 3. Wait for Automated Checks (Optional)

If GitHub Actions workflows are configured:

1. Show the user: "⏳ Waiting for automated checks to complete..."
2. Use `gh pr checks` to monitor the workflow status
3. Wait until ALL checks complete (success or failure)
4. Show status of each check as they complete
5. Inform the user when all checks are done

If no workflows are configured, skip to step 4.

### 4. Analyze Results & Fetch Review Feedback

Once checks are complete (or if no CI is configured):

**A. Check CI Status (if applicable):**
1. Use `gh pr checks <pr-number>` to get final status of all workflows
2. Identify any failing checks:
   - Linting errors
   - Build errors
   - Test failures
3. If checks failed, use `gh run view <run-id>` to get detailed error logs

**B. Fetch Code Review (if available):**
1. Use `gh pr view <pr-number> --comments` to fetch all comments
2. Extract any automated review comments
3. Parse and structure the feedback into categories:
   - Code quality issues
   - Potential bugs
   - Performance concerns
   - Security issues
   - Missing tests
   - Style/convention issues
   - Suggestions/improvements

### 5. Generate Action Plan

Create a structured plan to address CI failures and review feedback:

1. **Categorize all issues** into:
   - 🔴 **Critical (Must Fix First)**:
     - Failing CI checks
     - Build errors
     - Security vulnerabilities
   - ✅ **Must Fix**:
     - Bugs identified in code review
     - Breaking changes
     - Critical code quality issues
   - ⚠️ **Should Fix**:
     - Important improvements (performance, code quality)
     - Non-critical linting issues
     - Missing documentation
   - 💡 **Consider**:
     - Suggestions and nice-to-haves
     - Code style improvements
   - ❌ **Skip**:
     - Invalid or out-of-scope feedback

2. **Prioritize CI failures first** - CI must pass before addressing review feedback

3. **Create TODO items** for each actionable item using the TodoWrite tool

4. **Show summary** to the user:
   ```
   📋 PR Review Summary

   🧪 CI Status:
   ✅ Linting: Passed
   ✅ Build: Passed
   ✅ All checks passed!

   📝 Code Review:
   Must Fix: X items
   Should Fix: X items
   Consider: X items
   Skipped: X items (with reasons)
   ```

   Or if CI failed:
   ```
   📋 PR Review Summary

   🧪 CI Status:
   ❌ Build: FAILED
   ✅ Linting: Passed

   🔴 Critical Issues (Fix First):
   - Fix TypeScript error in src/app/page.tsx:45
   - Fix missing import in src/lib/utils.ts:12

   📝 Code Review:
   Must Fix: X items
   Should Fix: X items
   ```

### 6. Ask User for Next Steps

Present the plan and ask the user what they want to do:

**Use the AskUserQuestion tool** with these options:

- **Start fixing now**: Begin implementing the fixes from the plan
- **Show me the plan**: Display the full detailed plan so the user can review
- **Let me review first**: Just show the summary, user will work on it manually
- **Modify the plan**: User wants to adjust priorities or skip certain items

### 7. Execute Based on User Choice

Depending on the user's choice:

- **If "Start fixing now"**:
  - Mark the first TODO as in_progress
  - Start implementing fixes one by one
  - Mark each as completed as you go
  - Commit changes when appropriate groups are done

- **If "Show me the plan"**:
  - Display the full detailed breakdown of each item
  - Include file references, line numbers, and specific changes needed

- **If "Let me review first"**:
  - Leave the TODOs in pending state
  - Tell the user they can start working when ready

- **If "Modify the plan"**:
  - Ask which items to prioritize/skip
  - Update the TODO list accordingly
  - Then ask again for next steps

## Important Notes

- **Follow project conventions** (see CLAUDE.md):
  - TypeScript strict mode
  - Tabs for indentation, double quotes
  - Run `pnpm lint:fix` after making changes
  - Zod schemas in `lib/validations/` as source of truth for types

- **Keep user informed**:
  - Show progress during the wait
  - Explain what's happening at each step
  - Be transparent about the review feedback

- **Be selective**:
  - Not all review feedback is always valid
  - Use judgment to categorize appropriately
  - Explain why certain feedback is skipped

## Example Usage

```bash
# User runs the command
/pr-review

# Claude runs pre-flight checks, creates PR, monitors CI, shows plan:
📋 PR Review Summary

🧪 CI Status:
✅ Linting: Passed
✅ Build: Passed
✅ All checks passed!

📝 Code Review Feedback:

Must Fix: 2 items
  - Fix potential null check in src/lib/auth.ts:45
  - Add missing error handling in src/app/api/auth/route.ts:89

Should Fix: 3 items
  - Extract duplicate validation logic into shared schema
  - Add JSDoc comments to exported functions
  - Improve variable naming in calculation logic

Consider: 1 item
  - Consider using const instead of let where possible

What would you like to do?
```

## Error Handling

- **If PR creation fails**: Check git status and guide user on resolving conflicts
- **If CI fails**:
  - Fetch detailed error logs with `gh run view <run-id> --log-failed`
  - Identify specific failing checks
  - Prioritize these as "Critical" in the action plan
  - Provide direct links to the failing workflow run
- **If gh CLI not available**: Inform user to install and authenticate gh CLI

## Prerequisites

This command requires:
- ✅ `gh` CLI installed and authenticated
- ✅ Changes committed to a feature branch (not main)
- ⚪ GitHub Actions workflows (optional, but recommended):
  - Linting workflow
  - Build/type-check workflow
  - Claude Code review workflow

If any prerequisite is missing, inform the user with clear instructions on how to set it up.
