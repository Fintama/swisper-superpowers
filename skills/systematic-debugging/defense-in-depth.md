# Defense-in-Depth Validation

A bug caused by invalid data is fixed at its source (`root-cause-tracing.md`). One check
there can still be bypassed later by another code path, a refactor or a mock.

**Validate at the trust boundaries and at the layer that does the damage.** A trust
boundary is where data arrives from something you don't control: an API request, user
input, a file, another service, test setup. The damage layer is the operation that
writes, deletes, executes or spends. Layers in between that only pass the value on
don't repeat the check.

## The checks

### At the trust boundary: reject bad input

```typescript
function createProject(name: string, workingDirectory: string) {
  if (!workingDirectory || workingDirectory.trim() === '') {
    throw new Error('workingDirectory cannot be empty');
  }
  if (!existsSync(workingDirectory)) {
    throw new Error(`workingDirectory does not exist: ${workingDirectory}`);
  }
  if (!statSync(workingDirectory).isDirectory()) {
    throw new Error(`workingDirectory is not a directory: ${workingDirectory}`);
  }
  // ... proceed
}
```

### At the damage layer: refuse the dangerous operation

The operation checks its own precondition, so no caller can skip it:

```typescript
async function gitInit(directory: string) {
  if (!directory) {
    throw new Error('gitInit needs a directory; an empty one means process.cwd()');
  }
  // ... proceed
}
```

A guard that only some contexts need (tests may run `git init` only inside the temp
directory) is **injected**, never chosen by checking the environment in production code
(`../test-driven-development/testing-anti-patterns.md`, Anti-Pattern 8):

```typescript
type DirectoryGuard = (directory: string) => void;

export const insideTmpdir: DirectoryGuard = (directory) => {
  if (!normalize(resolve(directory)).startsWith(normalize(resolve(tmpdir())))) {
    throw new Error(`Refusing git init outside the temp dir: ${directory}`);
  }
};

class WorktreeManager {
  constructor(private readonly guardDirectory: DirectoryGuard = () => {}) {}

  async gitInit(directory: string) {
    this.guardDirectory(directory);
    // ... proceed
  }
}

// Test setup
const manager = new WorktreeManager(insideTmpdir);
```

### Before the damage layer: evidence for next time

```typescript
logger.debug('About to git init', { directory, cwd: process.cwd(), stack: new Error().stack });
```

## Applying it

1. Trace where the bad value came from and where it does harm.
2. Mark the trust boundaries it crossed and the operation that did the damage.
3. Add the check at each of those, and the injected guard if a context needs one.
4. Test each check by getting past the one before it (call the damage layer directly
   with the bad value) and confirm it refuses.

## Example

Bug: an empty `projectDir` made `git init` run in the source tree.

- Trust boundary: `Project.create()` rejects an empty, missing or non-directory path.
- Damage layer: `gitInit` refuses an empty directory.
- Injected guard: tests construct `WorktreeManager(insideTmpdir)`, so a test can never
  initialise a repo outside the temp dir.
- Debug log before `git init`.

The intermediate `WorkspaceManager` only passes the path on, so it gets no check of its own.
