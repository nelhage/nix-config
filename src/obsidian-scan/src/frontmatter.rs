use anyhow::{anyhow, Result};
use lazy_static::lazy_static;
use regex::Regex;
use saphyr::Yaml;
use std::option::Option;
use std::vec::Vec;

#[derive(Debug, Default)]
pub struct FrontMatter {
    pub tags: Vec<String>,
    pub aliases: Vec<String>,
}

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

fn yaml_to_strvec(yaml: &Yaml) -> Option<Vec<String>> {
    let vec = yaml.as_vec()?;
    Some(
        vec.into_iter()
            .filter_map(|e| e.as_str())
            .map(|e| e.to_owned())
            .collect(),
    )
}

pub fn extract(text: &str) -> Result<FrontMatter> {
    let yaml_text = find_frontmatter(text).ok_or(anyhow!("No front matter found"))?;
    let yaml = Yaml::load_from_str(yaml_text)?;
    let doc = yaml[0]
        .as_hash()
        .ok_or(anyhow!("frontmatter document is not a object"))?;
    let tags = doc
        .get(&Yaml::String("tags".to_owned()))
        .and_then(|doc| yaml_to_strvec(doc))
        .unwrap_or(Vec::new());
    let mut aliases = doc
        .get(&Yaml::String("aliases".to_owned()))
        .and_then(|doc| yaml_to_strvec(doc))
        .unwrap_or(Vec::new());
    if let Some(alias) = doc
        .get(&Yaml::String("alias".to_owned()))
        .and_then(|e| e.as_str())
    {
        aliases.push(alias.to_owned());
    }
    Ok(FrontMatter { tags, aliases })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_find_frontmatter() {
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

    #[test]
    fn test_extract() {
        let front = extract(
            r#"---
tags: [lemons, {}, cars]
---
some nonsense
"#,
        )
        .unwrap();
        assert_eq!(front.tags, vec!("lemons".to_owned(), "cars".to_owned()));

        let front = extract(
            r#"---
tags: [lemons, {}, cars]
aliases: [otherdoc, newdoc]
alias: Maria
---
some nonsense
"#,
        )
        .unwrap();
        assert_eq!(front.tags, vec!("lemons", "cars"));
        assert_eq!(front.aliases, vec!("otherdoc", "newdoc", "Maria"));
    }
}
