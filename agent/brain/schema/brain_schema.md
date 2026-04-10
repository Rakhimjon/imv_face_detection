# 🧠 Brain Schema & Meta-Rules

This document defines the philosophy and procedural rules for the **Xizmat Safari Development Brain**. It is inspired by the "Knowledge Compounding" model, where every development session should either leverage or evolve the existing knowledge base.

## 📖 Philosophy: Knowledge Compounding

The "Brain" is not just documentation; it is **Semantic Memory**. 
- **Episodic -> Semantic**: When we solve a new problem (e.g., an iOS-specific bug), we capture it first as an *Episode*. Once we see the pattern repeat, we promote it to *Semantic* core principles in the Wiki.
- **Synthesis**: Avoid raw "chat logs." Distill implementation details into high-level patterns and low-level "gotchas."
- **Supersession**: Knowledge is not static. When a pattern evolves (e.g., a new library replaces an old one), the old pattern is not deleted; it is marked as `SUPERSESEDED` with a link to the new standard to maintain context for legacy code.

---

## 🏗️ Memory Tiers

### 1. Semantic Memory (`wiki/`)
Long-term, stable facts about the project.
- **Architecture**: The structural laws.
- **Patterns**: Reusable logic/UI solutions.
- **Standards**: Naming, styling, testing protocols.

### 2. Episodic Memory (`episodic/`)
Historical context and complex "Case Studies."
- **Format**: `XXX_feature_name.md` (e.g., `001_oneid_integration.md`).
- **Purpose**: To remember *why* something was done a certain way, especially for non-obvious hacks or integration hurdles.

### 3. Procedural Memory (`schema/`)
This document and other "meta" instructions for the agent and developers.

---

## 🛠️ Procedural Rules

1.  **Mandatory Synthesis**: After finishing a major task, the agent should ask to "synthesize insights" into the brain.
2.  **No Dead Links**: All internal brain documents must use relative file links (e.g., `[Clean Architecture](./wiki/architecture.md)`).
3.  **The "Why" First**: Every wiki entry must explain the **Rationale** before the **Implementation**.
4.  **Supersession Logic**: 
    -   When updating a pattern:
        1. Add a `> [!CAUTION] SUPERSESEDED` alert to the top of the old section.
        2. Provide a link to the new section.
        3. Explain *why* the change was made (e.g., "Performance," "Maintainability").

---

## 🔗 Root Reference
- [Wiki Index](../wiki/)
- [Episodic Logs](../episodic/)
