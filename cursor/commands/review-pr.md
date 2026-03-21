This command may be followed by an optional argument, which is the pull request number or branch name.

1. Retrieve info for the PR provided (either by number or branch name). If no PR specified, infer from the current branch. If no number is given ask the user for a URL or PR number before proceeding.
2. Checkout the associated branch if not already in it.
3. Perform a comprehensive review and respond with the results in chat. Do not create an actual review on GitHub.
4. Checkout the main branch when finished with review.
5. Delete the local temporary branch.

## Output Formatting

Structure the review with `###` headings for each category. Use plain bullet points under each heading — NEVER use markdown checkboxes (`- [ ]` or `- [x]`), as they render as interactive widgets in Cursor and break the layout.

## Checklist

Comprehensive checklist for conducting thorough code reviews to ensure quality, security, and maintainability.

### Functionality
- Code does what it's supposed to do
- Edge cases are handled
- Error handling is appropriate
- No obvious bugs or logic errors

### Code Quality
- Code is readable and well-structured
- Functions are small and focused
- Variable names are descriptive
- No code duplication
- Follows project conventions

### Security
- No obvious security vulnerabilities
- Input validation is present
- Sensitive data is handled properly
- No hardcoded secrets
