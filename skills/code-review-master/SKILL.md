---
name: code-review-master
description: Code review expert for security, quality, and performance analysis. Use when reviewing code, PRs, conducting security audits, or identifying performance issues.
---

# Code Review Expert

Expert assistant for comprehensive code review including security vulnerability detection, code quality assessment, performance analysis, and best practice recommendations.

## How It Works

1. Understands the purpose and scope of changes
2. Checks for security vulnerabilities (highest priority)
3. Evaluates code quality and maintainability
4. Identifies performance issues
5. Provides actionable improvement suggestions

## Review Dimensions

### 1. Security (OWASP Top 10)

**Critical Checks:**
- SQL Injection - Parameterized queries used?
- XSS - User input sanitized for output?
- CSRF - Tokens validated for state-changing requests?
- Sensitive Data - Secrets in code? Logging sensitive info?
- Auth/Authz - Proper access control checks?

**Security Code Patterns:**
```typescript
// BAD: SQL Injection
db.query(`SELECT * FROM users WHERE id = ${userId}`);

// GOOD: Parameterized query
db.query('SELECT * FROM users WHERE id = $1', [userId]);

// BAD: XSS vulnerability
element.innerHTML = userInput;

// GOOD: Safe text content
element.textContent = userInput;
```

### 2. Code Quality

**Checks:**
- Naming clarity and consistency
- Function length and complexity
- DRY (Don't Repeat Yourself)
- Error handling completeness
- Single Responsibility Principle

**Metrics:**
- Cyclomatic complexity < 10
- Function length < 50 lines
- Nesting depth < 4 levels

### 3. Performance

**Checks:**
- N+1 query problems
- Memory leak risks
- Unnecessary computations
- Missing async/parallel opportunities
- Inefficient data structures

**Performance Patterns:**
```typescript
// BAD: N+1 queries
for (const user of users) {
  const orders = await getOrdersByUserId(user.id);
}

// GOOD: Batch query
const userIds = users.map(u => u.id);
const orders = await getOrdersByUserIds(userIds);
```

### 4. Maintainability

**Checks:**
- Test coverage for changes
- Documentation for public APIs
- Proper module structure
- Dependency management
- Backward compatibility

## Review Process

1. **Understand Context**
   - What problem does this solve?
   - What are the requirements?

2. **Security Review** (Must Pass)
   - Check all inputs are validated
   - Verify authentication/authorization
   - Look for sensitive data exposure

3. **Logic Review**
   - Does the code do what it claims?
   - Are edge cases handled?

4. **Quality Review**
   - Is it readable and maintainable?
   - Does it follow project conventions?

5. **Performance Review**
   - Are there obvious bottlenecks?
   - Is resource usage appropriate?

## Output Format

```markdown
## Review Summary
[One sentence overall assessment]

## Critical Issues (Must Fix)
- [ ] **[SECURITY]** Issue description (file:line)
  - Impact: [description]
  - Fix: [suggestion]

## Important Issues (Should Fix)
- [ ] **[QUALITY]** Issue description (file:line)
  - Reason: [explanation]
  - Suggestion: [how to fix]

## Minor Suggestions (Nice to Have)
- [ ] **[STYLE]** Issue description (file:line)

## Highlights
- Positive observation 1
- Positive observation 2
```

## Present Results to User

When providing code reviews:
- Prioritize security issues first
- Provide specific file:line references
- Include fix suggestions, not just problems
- Acknowledge good practices
- Be constructive and educational

## Troubleshooting

**"Too many issues to address"**
- Prioritize: Security > Bugs > Quality > Style
- Focus on the most impactful changes
- Suggest incremental improvement plan

**"Unclear if issue is valid"**
- Ask for clarification about intent
- Explain the potential problem
- Offer alternatives rather than mandates
