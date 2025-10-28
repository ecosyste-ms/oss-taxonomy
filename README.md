# OSS Taxonomy

A structured, open-source taxonomy for classifying open source software projects.

## Why This Exists

The open source ecosystem contains millions of projects across dozens of software ecosystems, but there's no standardized way to classify and discover them beyond simple keyword searches. Traditional registries organize software by language or ecosystem, but lack semantic understanding of what projects *do*, *who* they're for, or *where* they fit in a technology stack.

This taxonomy solves that problem by providing a **multi-dimensional classification system** that captures the full context of open source software. Whether you're building a project discovery platform, analyzing ecosystem trends, or helping developers find the right tools, this taxonomy gives you a common vocabulary.

By establishing a shared classification framework, this taxonomy enables consistent understanding across the entire open source community — from project maintainers documenting their work, to developers searching for solutions, to researchers analyzing ecosystem health, to funders identifying gaps in critical infrastructure. When everyone speaks the same language, the ecosystem becomes more discoverable, understandable, and navigable for all.

## How It Works

This project defines a flexible and extensible classification system across multiple dimensions (called *facets*). Each facet describes a different way of grouping or tagging software — by domain, role, technology, audience, etc.

Instead of forcing software into a single category, the taxonomy allows projects to be tagged with **multiple terms per facet and across facets**. For example, a web framework project might be classified as:

- **Domain**: `web-development`, `api-development`
- **Role**: `framework`, `library`
- **Technology**: `python`, `docker`
- **Audience**: `developer`, `enterprise`
- **Layer**: `backend`, `full-stack`
- **Function**: `api-development`, `authentication`, `database-management`

This multi-faceted approach creates a rich, queryable classification that enables powerful discovery, analysis, and recommendation features.

## 📂 Structure

Each folder in this repository is a **facet**, containing YAML files that define individual **terms**.

- [Domain](oss-taxonomy/domain/) — The industry or field
  - `blockchain`, `cloud-computing`, `content-management`, `data-science`, `database`, `desktop-development`, `devops`, `embedded-systems`, `game-development`, `machine-learning`, ...
- [Role](oss-taxonomy/role/) — The role the software plays
  - `application`, `build-tool`, `cli-tool`, `compiler`, `database-system`, `editor`, `framework`, `library`, `orchestrator`, `package-manager`, ...
- [Technology](oss-taxonomy/technology/) — Technologies used or supported
  - `angular`, `ansible`, `aws`, `azure`, `bootstrap`, `c`, `cpp`, `csharp`, `css`, `dart`, ...
- [Audience](oss-taxonomy/audience/) — Who the software is for
  - `content-creator`, `data-scientist`, `designer`, `developer`, `educator`, `end-user`, `enterprise`, `hobbyist`, `researcher`, `student`, ...
- [Layer](oss-taxonomy/layer/) — Where it sits in the stack
  - `backend`, `data-layer`, `frontend`, `full-stack`, `hardware`, `infrastructure`, `middleware`, `network-layer`, `operating-system`, `platform`
- [Function](oss-taxonomy/function/) — What the software does
  - `api-development`, `authentication`, `automation`, `caching`, `ci-cd`, `containerization`, `database-management`, `deployment`, `documentation`, `logging`, ...

## 🛠 Usage

You can use this taxonomy to:

- Classify and tag open-source projects
- Power search and filtering interfaces
- Analyze ecosystem coverage and trends
- Find related and alternative projects
- Generate suggestions for best practices and tools
- Create visualizations of the open-source landscape
- Build recommendation engines

A combined JSON file is automatically generated ([`combined-taxonomy.json`](./combined-taxonomy.json)) for easy loading into apps. This file is always up-to-date and reflects the latest taxonomy changes. You can find it in the root of the repository.

The taxonomy structure is formally defined in [`schema.json`](./schema.json), a JSON Schema file that can be used to validate the combined taxonomy data or integrate it into your tools and editors.

## 📘 Term Format

Each `.yml` file in a facet folder defines a single **term**. Here's the recommended structure:

```yaml
name: web-development
description: Software for building websites, web apps, and APIs.
examples:
  - react
  - nextjs
  - rails
related:
  - frontend
  - backend
aliases:
  - webdev
  - webdevelopment
ecosystems:
  - npm
  - rubygems
tags:
  - html
  - css
  - javascript
```

### Field Descriptions

- **`name`** (required): A unique identifier for the term in kebab-case (e.g., `web-development`, `cli-tool`). Must be unique within its facet.

- **`description`** (required): A clear, concise human-readable explanation of what the term represents. Should be 1-2 sentences.

- **`examples`** (optional): A list of well-known software projects, tools, or libraries that exemplify this term. Include 2-5 recognizable examples to help users understand the term's scope.

- **`related`** (optional): Other taxonomy terms (from any facet) that are conceptually connected or commonly used together. Helps build relationships across the taxonomy.

- **`aliases`** (optional): Alternative names, synonyms, or common variations of the term. Useful for search and discovery (e.g., `js` for `javascript`, `k8s` for `kubernetes`).

- **`ecosystems`** (optional): Package managers or software ecosystems where this term is commonly found. Must use valid ecosystem identifiers from [packages.ecosyste.ms](https://packages.ecosyste.ms/). See below for the complete list.

- **`tags`** (optional): Freeform keywords for enhanced searching, filtering, and categorization. Can include related concepts, use cases, or characteristics.

#### Valid Ecosystem Values

These ecosystem identifiers come from [packages.ecosyste.ms](https://packages.ecosyste.ms/) and align with [Package URL (purl) types](https://github.com/package-url/purl-spec):

`npm`, `go`, `docker`, `nuget`, `pypi`, `maven`, `packagist`, `cargo`, `rubygems`, `cocoapods`, `pub`, `bower`, `cpan`, `alpine`, `actions`, `cran`, `clojars`, `conda`, `hex`, `hackage`, `julia`, `swiftpm`, `spack`, `homebrew`, `puppet`, `openvsx`, `deno`, `elm`, `racket`, `vcpkg`, `bioconductor`, `carthage`, `postmarketos`, `elpa`, `adelie`

## 🤝 Contributing

We welcome contributions! To add or improve a term:

1. Pick the appropriate facet folder.
2. Add or edit a `.yml` file for the term.
3. Include a `description`, `examples`, and optionally `related` terms.
4. Run `generate_combined_taxonomy.rb` to update the combined file.
5. Open a pull request.

## 📄 License

CC0 1.0 Universal
Public Domain Dedication. You can use this taxonomy freely without restrictions.
See [LICENSE](LICENSE) for details.
