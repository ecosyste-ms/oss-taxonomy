# oss-taxonomy

A structured, open-source taxonomy for classifying open source software projects.

This project defines a flexible and extensible classification system for open-source software across multiple dimensions (called *facets*). Each facet describes a different way of grouping or tagging software — by domain, role, technology, audience, etc.

## 📂 Structure

Each folder in this repository is a **facet**, containing YAML files that define individual **terms**.

- [`domain/`](domain/) — The industry or field (e.g., `data-science`, `web-development`)
- [`role/`](role/) — The role the software plays (e.g., `framework`, `cli-tool`)
- [`technology/`](technology/) — Technologies used or supported (e.g., `rust`, `docker`)
- [`audience/`](audience/) — Who the software is for (e.g., `developer`, `researcher`)
- [`layer/`](layer/) — Where it sits in the stack (e.g., `frontend`, `infrastructure`)
- [`function/`](function/) — What the software does (e.g., `visualization`, `ci-cd`)

## 🛠 Usage

You can use this taxonomy to:

- Classify and tag open-source projects
- Power search and filtering interfaces
- Analyze ecosystem coverage and trends

A combined JSON file is automatically generated (`combined.json`) for easy loading into apps.

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