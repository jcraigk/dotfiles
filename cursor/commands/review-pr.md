This command may be followed by an optional argument, which is the pull request number or branch name.

1. Retrieve info for the PR provided (either by number or branch name). If no PR specified, infer from the current branch. If no number is given ask the user for a URL or PR number before proceeding.
2. If there are uncommited changes in the current branch, STOP and warn the user. Do not proceed.
3. Checkout the associated branch if not already in it.
4. Perform a comprehensive review and respond with the results in chat. Do not create an actual review on GitHub.


## Checklist

Comprehensive checklist for conducting thorough code reviews to ensure quality, security, and maintainability.

## Review Categories

### Functionality
- [ ] Code does what it's supposed to do
- [ ] Edge cases are handled
- [ ] Error handling is appropriate
- [ ] No obvious bugs or logic errors

### Code Quality
- [ ] Code is readable and well-structured
- [ ] Functions are small and focused
- [ ] Variable names are descriptive
- [ ] No code duplication
- [ ] Follows project conventions

### Security
- [ ] No obvious security vulnerabilities
- [ ] Input validation is present
- [ ] Sensitive data is handled properly
- [ ] No hardcoded secrets
