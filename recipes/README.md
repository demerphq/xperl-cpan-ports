# Migration recipes

Recipes document recurring porting and test-environment issues for people
and external agents. Each recipe should state:

- The symptom and its cause, including an XPerl change when relevant.
- The affected XPerl versions and source patterns to inspect.
- The preferred source change, including ordinary Perl compatibility.
- A small way to verify the port and known limits.

Use a stable lowercase filename such as `hash-storage-v1.md`. A patch set may
refer to recipes by filename without the `.md` suffix. Add a recipe only when
its guidance is supported by a tested port.

When tests depend on environment settings, fix the affected tests to set up
their own conditions. Keep installation behavior independent of those test
assumptions.
