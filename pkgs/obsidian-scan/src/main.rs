use regex::Regex;
use serde::{Deserialize, Serialize};
use serde_json;
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;
use yaml_rust::YamlLoader;

#[derive(Debug, Serialize, Deserialize)]
struct FileMetadata {
    tags: Vec<String>,
    aliases: Vec<String>,
    links: HashMap<String, Vec<LinkInfo>>,
}

#[derive(Debug, Serialize, Deserialize)]
struct LinkInfo {
    begin: usize,
    end: usize,
    link_text: String,
    url: String,
    reference_label: Option<String>,
    title_text: Option<String>,
    bang: Option<String>,
}

struct ObsidianScanner {
    vault_dir: PathBuf,
    tag_regex: Regex,
    wiki_link_regex: Regex,
    markdown_link_regex: Regex,
}

impl ObsidianScanner {
    fn new(vault_dir: PathBuf) -> Self {
        // Regex patterns from the Emacs code
        let tag_regex =
            Regex::new(r"(?:^|[\s])#(?:[A-Za-z_/][-A-Za-z0-9_/]*[A-Za-z_/][-A-Za-z0-9_/]*)")
                .unwrap();
        let wiki_link_regex = Regex::new(r"\[\[([^\[\]]+)\]\]").unwrap();
        let markdown_link_regex = Regex::new(r"\[([^\]]+)\]\(([^\)]+)\)").unwrap();

        Self {
            vault_dir,
            tag_regex,
            wiki_link_regex,
            markdown_link_regex,
        }
    }

    fn scan_vault(&self) -> HashMap<String, FileMetadata> {
        let mut cache = HashMap::new();

        for entry in WalkDir::new(&self.vault_dir)
            .into_iter()
            .filter_map(|e| e.ok())
        {
            let path = entry.path();

            // Skip if not a markdown file
            if !path.extension().map_or(false, |ext| ext == "md") {
                continue;
            }

            // Skip .obsidian directory
            if path.components().any(|c| c.as_os_str() == ".obsidian") {
                continue;
            }

            // Skip .trash directory
            if path.components().any(|c| c.as_os_str() == ".trash") {
                continue;
            }

            if let Ok(content) = fs::read_to_string(path) {
                let metadata = self.process_file(&content, path);
                cache.insert(path.to_string_lossy().to_string(), metadata);
            }
        }

        cache
    }

    fn process_file(&self, content: &str, file_path: &Path) -> FileMetadata {
        let (front_matter, body) = self.split_front_matter(content);

        let mut tags = self.extract_front_matter_tags(&front_matter);
        tags.extend(self.extract_body_tags(&body));

        let aliases = self.extract_aliases(&front_matter);
        let links = self.extract_links(content, file_path);

        FileMetadata {
            tags,
            aliases,
            links,
        }
    }

    fn split_front_matter(&self, content: &str) -> (Option<String>, String) {
        if content.starts_with("---") {
            let parts: Vec<&str> = content.splitn(3, "---").collect();
            if parts.len() == 3 {
                return (Some(parts[1].to_string()), parts[2].to_string());
            }
        }
        (None, content.to_string())
    }

    fn extract_front_matter_tags(&self, front_matter: &Option<String>) -> Vec<String> {
        let mut tags = Vec::new();

        if let Some(fm) = front_matter {
            if let Ok(docs) = YamlLoader::load_from_str(fm) {
                if let Some(doc) = docs.first() {
                    if let Some(yaml_tags) = doc["tags"].as_vec() {
                        for tag in yaml_tags {
                            if let Some(tag_str) = tag.as_str() {
                                // Front matter tags shouldn't have # prefix
                                if !tag_str.starts_with('#') && !tag_str.contains(' ') {
                                    tags.push(tag_str.to_string());
                                }
                            }
                        }
                    }
                }
            }
        }

        tags
    }

    fn extract_body_tags(&self, body: &str) -> Vec<String> {
        let mut tags = Vec::new();

        for cap in self.tag_regex.captures_iter(body) {
            if let Some(tag_match) = cap.get(0) {
                let tag = tag_match.as_str().trim_start().trim_start_matches('#');
                tags.push(tag.to_string());
            }
        }

        tags
    }

    fn extract_aliases(&self, front_matter: &Option<String>) -> Vec<String> {
        let mut aliases = Vec::new();

        if let Some(fm) = front_matter {
            if let Ok(docs) = YamlLoader::load_from_str(fm) {
                if let Some(doc) = docs.first() {
                    // Check 'aliases' field (array)
                    if let Some(yaml_aliases) = doc["aliases"].as_vec() {
                        for alias in yaml_aliases {
                            if let Some(alias_str) = alias.as_str() {
                                aliases.push(alias_str.to_string());
                            }
                        }
                    }

                    // Check 'alias' field (single value)
                    if let Some(alias) = doc["alias"].as_str() {
                        aliases.push(alias.to_string());
                    }
                }
            }
        }

        // Remove duplicates
        aliases.sort();
        aliases.dedup();

        aliases
    }

    fn extract_links(&self, content: &str, file_path: &Path) -> HashMap<String, Vec<LinkInfo>> {
        let mut links_map: HashMap<String, Vec<LinkInfo>> = HashMap::new();

        // Extract wiki links
        for cap in self.wiki_link_regex.captures_iter(content) {
            if let (Some(full_match), Some(link_content)) = (cap.get(0), cap.get(1)) {
                let begin = full_match.start();
                let end = full_match.end();
                let link_str = link_content.as_str();

                // Handle aliased wiki links
                let (link_text, url) = if link_str.contains('|') {
                    let parts: Vec<&str> = link_str.split('|').collect();
                    if parts.len() == 2 {
                        // Assuming markdown-wiki-link-alias-first is false (default for obsidian.el)
                        (parts[1].trim().to_string(), parts[0].trim().to_string())
                    } else {
                        (link_str.to_string(), link_str.to_string())
                    }
                } else {
                    (link_str.to_string(), link_str.to_string())
                };

                // Add .md extension if not present
                let url_with_ext = if url.contains(':') || url.starts_with('#') {
                    url.clone()
                } else if !url.ends_with(".md") {
                    format!("{}.md", url)
                } else {
                    url.clone()
                };

                // Convert to absolute path if it's a relative link
                let absolute_url = self.resolve_link_path(&url_with_ext, file_path);

                let link_info = LinkInfo {
                    begin,
                    end,
                    link_text,
                    url: url_with_ext,
                    reference_label: None,
                    title_text: None,
                    bang: None,
                };

                links_map
                    .entry(absolute_url)
                    .or_insert_with(Vec::new)
                    .push(link_info);
            }
        }

        // Extract markdown links
        for cap in self.markdown_link_regex.captures_iter(content) {
            if let (Some(full_match), Some(text), Some(url)) = (cap.get(0), cap.get(1), cap.get(2))
            {
                let begin = full_match.start();
                let end = full_match.end();
                let link_text = text.as_str().to_string();
                let url_str = url.as_str().to_string();

                // Convert to absolute path if it's a relative link
                let absolute_url = self.resolve_link_path(&url_str, file_path);

                let link_info = LinkInfo {
                    begin,
                    end,
                    link_text,
                    url: url_str,
                    reference_label: None,
                    title_text: None,
                    bang: None,
                };

                links_map
                    .entry(absolute_url)
                    .or_insert_with(Vec::new)
                    .push(link_info);
            }
        }

        links_map
    }

    fn resolve_link_path(&self, link: &str, current_file: &Path) -> String {
        // If it's an external link or anchor, return as-is
        if link.contains(':') || link.starts_with('#') {
            return link.to_string();
        }

        // If it's an absolute path within the vault
        if link.starts_with('/') {
            return self
                .vault_dir
                .join(&link[1..])
                .to_string_lossy()
                .to_string();
        }

        // Otherwise, resolve relative to current file's directory
        if let Some(parent) = current_file.parent() {
            parent.join(link).to_string_lossy().to_string()
        } else {
            link.to_string()
        }
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();

    if args.len() != 2 {
        eprintln!("Usage: {} <obsidian-vault-directory>", args[0]);
        std::process::exit(1);
    }

    let vault_dir = PathBuf::from(&args[1]);

    if !vault_dir.exists() || !vault_dir.is_dir() {
        eprintln!("Error: {} is not a valid directory", vault_dir.display());
        std::process::exit(1);
    }

    let scanner = ObsidianScanner::new(vault_dir);
    let cache = scanner.scan_vault();

    // Output as JSON
    match serde_json::to_string_pretty(&cache) {
        Ok(json) => println!("{}", json),
        Err(e) => {
            eprintln!("Error serializing to JSON: {}", e);
            std::process::exit(1);
        }
    }
}
