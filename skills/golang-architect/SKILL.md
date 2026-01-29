---
name: golang-architect
description: Golang backend architecture expert. Use when designing Go services with Gin, implementing layered architecture, configuring sqlc with PostgreSQL/Supabase, or building API authentication.
---

# Golang Backend Architecture Expert

Expert assistant for Golang backend architecture with Gin Server, Layered Architecture, sqlc, PostgreSQL (Supabase), and API authentication.

## Thinking Process

When activated, follow this structured thinking approach to design Go backend architectures:

### Step 1: Requirements Analysis

**Goal:** Fully understand what the service needs to accomplish.

**Key Questions to Ask:**
- What is the core business domain? (e-commerce, messaging, analytics, etc.)
- What are the API requirements? (REST, GraphQL, gRPC)
- What is the expected scale? (requests/sec, data volume, user count)
- What are the integration points? (databases, external APIs, message queues)
- What are the security requirements? (authentication, authorization, data sensitivity)

**Actions:**
1. List all endpoints/operations the service must support
2. Identify the data entities and their relationships
3. Map external dependencies and integrations
4. Clarify non-functional requirements (latency, availability, consistency)

**Decision Point:** You should be able to articulate:
- "This service handles [X] domain with [Y] main entities"
- "It needs to integrate with [Z] and handle [W] requests/sec"

### Step 2: Architecture Selection

**Goal:** Choose the appropriate architectural pattern for the requirements.

**Thinking Framework:**

| Requirement | Recommended Architecture |
|-------------|--------------------------|
| Simple CRUD API | Standard Layered (Handler → Service → Repository) |
| Complex business logic | Clean Architecture / Hexagonal |
| Event-driven processing | CQRS with event sourcing |
| Microservices | Domain-Driven Design boundaries |
| High-performance | Minimal layers, direct data access |

**Decision Criteria:**
- **Layered Architecture:** When business logic is straightforward, team is familiar with Go
- **Clean Architecture:** When testability is critical, business rules change frequently
- **Hexagonal:** When multiple input/output adapters are needed (HTTP, gRPC, CLI)

**Decision Point:** Select and justify:
- "I recommend [X] architecture because [Y reasons]"
- "The trade-offs are [Z]"

### Step 3: Layer Design

**Goal:** Define clear boundaries and responsibilities for each layer.

**Thinking Framework - Apply Dependency Rule:**
- Inner layers should NOT know about outer layers
- Dependencies point INWARD (Repository ← Service ← Handler)
- Interfaces are defined by the layer that USES them

**Standard Layer Responsibilities:**

1. **Handler Layer (HTTP/gRPC)**
   - Parse and validate requests
   - Call service layer
   - Format and return responses
   - Handle HTTP-specific errors (status codes)

2. **Service Layer (Business Logic)**
   - Orchestrate business operations
   - Apply business rules and validations
   - Coordinate between repositories
   - Transaction management

3. **Repository Layer (Data Access)**
   - Database queries (sqlc generated)
   - External API calls
   - Cache operations
   - Data mapping

4. **Domain Layer (Optional - for complex domains)**
   - Entity definitions
   - Value objects
   - Domain events

**Interface Design Questions:**
- "What methods does the service layer need from the repository?"
- "How can I make this testable with mocks?"

### Step 4: Database and Query Design

**Goal:** Design efficient data access with sqlc.

**Thinking Framework:**
- "What queries will the service need?"
- "How can I minimize N+1 problems?"
- "Should this be a transaction?"

**sqlc Design Checklist:**
1. Define schema migrations first
2. Write queries based on service layer needs
3. Use batch queries to avoid N+1
4. Consider read replicas for read-heavy operations
5. Plan for pagination from the start

**Decision Point:** For each entity:
- "What are the CRUD operations needed?"
- "What are the common query patterns?"
- "Where do I need transactions?"

### Step 5: Error Handling Strategy

**Goal:** Design consistent, informative error handling.

**Thinking Framework:**
- "What types of errors can occur?" (validation, not found, conflict, internal)
- "How should errors propagate between layers?"
- "What information should the client receive?"

**Error Hierarchy:**
```
Handler Layer: HTTP status codes + user-friendly messages
     ↑ transforms
Service Layer: Domain-specific errors (NotFound, Conflict, Validation)
     ↑ wraps
Repository Layer: Infrastructure errors (DB connection, timeout)
```

### Step 6: Security Design

**Goal:** Ensure the service is secure by default.

**Security Checklist:**
- [ ] Authentication: JWT validation, session management
- [ ] Authorization: Role-based or attribute-based access control
- [ ] Input validation: All inputs sanitized at handler layer
- [ ] SQL injection: Parameterized queries via sqlc
- [ ] Secrets management: Environment variables, not code
- [ ] Rate limiting: Protect against abuse
- [ ] CORS: Configure for frontend origins

### Step 7: Testing Strategy

**Goal:** Design for testability from the start.

**Testing Layers:**
- **Unit tests:** Service layer with mocked repositories
- **Integration tests:** Repository layer with test database
- **E2E tests:** Handler layer with test server

**Dependency Injection Pattern:**
```go
// Define interface in service layer
type UserRepository interface {
    GetByID(ctx context.Context, id string) (*User, error)
}

// Service accepts interface
type UserService struct {
    repo UserRepository
}

// Easy to mock in tests
```

### Step 8: Implementation Sequence

**Goal:** Provide a clear order of implementation.

**Recommended Order:**
1. Schema migrations and sqlc queries
2. Repository layer (generated code + custom queries)
3. Service layer with business logic
4. Handler layer with validation
5. Middleware (auth, logging, error handling)
6. Integration tests
7. Documentation (OpenAPI spec)

## Usage


### Initialize SQLC

```bash
bash /mnt/skills/user/golang-architect/scripts/sqlc-init.sh [project-dir] [db-engine]
```

**Arguments:**
- `project-dir` - Project directory (default: current directory)
- `db-engine` - Database engine: postgresql, mysql, sqlite3 (default: postgresql)

**Examples:**
```bash
bash /mnt/skills/user/golang-architect/scripts/sqlc-init.sh
bash /mnt/skills/user/golang-architect/scripts/sqlc-init.sh ./my-project postgresql
```

## Documentation Resources

**Context7 Library ID:** `/websites/gin-gonic_en` (117 snippets, Score: 90.8)

**Official Documentation:**
- Gin: `https://gin-gonic.com/en/docs/`
- sqlc: `https://docs.sqlc.dev/`
- Supabase: Use `mcp__supabase__*` tools
- go-symphony: `https://github.com/Tomlord1122/go-symphony`

## Layered Architecture Template

```
project/
├── cmd/
│   └── api/
│       └── main.go           # Entry point
├── internal/
│   ├── handler/              # HTTP handlers (Gin)
│   │   └── user_handler.go
│   ├── service/              # Business logic
│   │   └── user_service.go
│   ├── repository/           # Data access (sqlc)
│   │   └── user_repository.go
│   ├── middleware/           # Auth, logging, CORS
│   │   └── auth.go
│   └── dto/                  # Data Transfer Objects
│       └── user_dto.go
├── pkg/                      # Shared utilities
├── db/
│   ├── migrations/           # SQL migrations
│   └── queries/              # sqlc SQL files
├── sqlc.yaml
└── go.mod
```

## sqlc Configuration

```yaml
# sqlc.yaml
version: "2"
sql:
  - engine: "postgresql"
    queries: "db/queries/"
    schema: "db/migrations/"
    gen:
      go:
        package: "repository"
        out: "internal/repository"
        sql_package: "pgx/v5"
        emit_json_tags: true
        emit_interface: true
```

## Handler Pattern

```go
type UserHandler struct {
    service *service.UserService
}

func NewUserHandler(s *service.UserService) *UserHandler {
    return &UserHandler{service: s}
}

func (h *UserHandler) GetUser(c *gin.Context) {
    id := c.Param("id")
    user, err := h.service.GetUser(c.Request.Context(), id)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
        return
    }
    c.JSON(http.StatusOK, user)
}
```

## Middleware Pattern

```go
func AuthMiddleware(jwtSecret string) gin.HandlerFunc {
    return func(c *gin.Context) {
        token := c.GetHeader("Authorization")
        if token == "" {
            c.AbortWithStatusJSON(401, gin.H{"error": "unauthorized"})
            return
        }
        // Validate token...
        c.Set("userID", claims.UserID)
        c.Next()
    }
}
```

## Error Handling

```go
// Custom error types
type AppError struct {
    Code    int    `json:"code"`
    Message string `json:"message"`
}

func (e *AppError) Error() string {
    return e.Message
}

// Error middleware
func ErrorHandler() gin.HandlerFunc {
    return func(c *gin.Context) {
        c.Next()
        if len(c.Errors) > 0 {
            err := c.Errors.Last().Err
            if appErr, ok := err.(*AppError); ok {
                c.JSON(appErr.Code, appErr)
                return
            }
            c.JSON(500, gin.H{"error": "internal server error"})
        }
    }
}
```

## Present Results to User

When providing Go backend solutions:
- Follow Go conventions (Effective Go, uber-go/guide)
- Use dependency injection for testability
- Provide complete error handling examples
- Include context propagation for cancellation
- Show corresponding tests when appropriate

## Troubleshooting

**"sqlc generate fails"**
- Verify PostgreSQL syntax in queries
- Check schema matches query expectations
- Run `sqlc vet` for detailed errors

**"Gin handler not receiving body"**
- Ensure `Content-Type: application/json` header
- Check if body was already read (bind only once)
- Use `ShouldBindJSON` instead of `BindJSON` for error control

**"Context cancelled"**
- Propagate context through all layers
- Check for long-running operations without timeout
