# OSS Taxonomy

A structured, open-source taxonomy for classifying open source software projects.

This project defines a flexible and extensible classification system for open-source software across multiple dimensions (called *facets*). Each facet describes a different way of grouping or tagging software — by domain, role, technology, audience, etc.

## 📂 Structure

Each folder in this repository is a **facet**, containing YAML files that define individual **terms**.

- [Domain](oss-taxonomy/domain/) — The industry or field (e.g., `data-science`, `web-development`, `embedded-systems`)
- [Role](oss-taxonomy/role/) — The role the software plays (e.g., `framework`, `cli-tool`, `library`, `plugin`)
- [Technology](oss-taxonomy/technology/) — Technologies used or supported (e.g., `rust`, `docker`, `react`, `graphql`)
- [Audience](oss-taxonomy/audience/) — Who the software is for (e.g., `developer`, `researcher`, `end-user`, `sysadmin`)
- [Layer](oss-taxonomy/layer/) — Where it sits in the stack (e.g., `frontend`, `infrastructure`, `backend`, `data-layer`)
- [Function](oss-taxonomy/function/) — What the software does (e.g., `visualization`, `ci-cd`, `scraping`, `deployment`)

## 🛠 Usage

You can use this taxonomy to:

- Classify and tag open-source projects
- Power search and filtering interfaces
- Analyze ecosystem coverage and trends
- Find related and alternative projects
- Generate suggestions for best practices and tools
- Create visualizations of the open-source landscape
- Build recommendation engines

A combined JSON file is automatically generated (`combined.json`) for easy loading into apps.

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

### Key Descriptions

- `name`: A unique identifier for the term.
- `description`: A human-readable explanation of the term.
- `examples`: A short list of well-known software projects that fit this term.
- `related`: Other taxonomy terms that are conceptually connected.
- `aliases`: Synonyms or common alternative names.
- `ecosystems`: Related package managers or software ecosystems.
- `tags`: Freeform tags for searching, filtering, or visualization.

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
