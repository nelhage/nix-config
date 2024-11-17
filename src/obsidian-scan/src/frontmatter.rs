use anyhow::{anyhow, bail, Result};
use lazy_static::lazy_static;
use regex::Regex;
use std::option::Option;

pub struct FrontMatter {}

lazy_static! {
    static ref YAML_DELIM: Regex = Regex::new(r"(?m)^---\r?\n").unwrap();
}

fn find_frontmatter(note: &str) -> Option<&str> {
    if !note.starts_with("---") {
        return None;
    }
    let mut splits = YAML_DELIM.splitn(note, 3);

    splits.next()?;
    let frontmatter = splits.next();
    splits.next()?;
    return frontmatter;
}

pub fn extract_frontmatter(text: &str) -> Result<FrontMatter> {
    let yaml_text = find_frontmatter(text).ok_or(anyhow!("No front matter found"))?;
    bail!("unimplemented")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_findfrontmatter() {
        assert_eq!(
            find_frontmatter(
                r#"---
key: value
---
some nonsense
"#
            ),
            Some("key: value\n")
        );
        assert_eq!(
            find_frontmatter(
                r#"---
key: value
---
some nonsense
more nonsense
---
"#
            ),
            Some("key: value\n")
        );

        assert_eq!(
            find_frontmatter(
                r#"
---
key: value
---
some nonsense
"#
            ),
            None
        );

        assert_eq!(
            find_frontmatter(
                r#"---
key: value
  ---
"#
            ),
            None
        );
        assert_eq!(
            find_frontmatter(
                r#"---
key: value
"#
            ),
            None
        );
    }
}
