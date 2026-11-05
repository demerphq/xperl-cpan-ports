# Migration recipes

Recipes document recurring XPerl compatibility issues for people and external
agents. Each recipe should state:

- The symptom and the XPerl change that causes it.
- The affected XPerl versions and source patterns to inspect.
- The preferred source change, including ordinary Perl compatibility.
- A small way to verify the port and known limits.

Use a stable lowercase filename such as `hash-storage-v1.md`. A patch set may
refer to recipes by filename without the `.md` suffix. Add a recipe only when
its guidance is supported by a tested port.
