use std::path::{Path, PathBuf};
use std::fs;
use std::collections::HashMap;
use std::error::Error;
use regex::Regex;
use rayon::prelude::*;
use serde::{Serialize, Deserialize};
use serde_yaml;
use clap::Parser;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(short, long)]
    vault: String,
}

#[derive(Debug, Serialize)]
struct VaultData {
    tags: Vec<String>,
    aliases: HashMap<String, String>,
    files: Vec<PathBuf>,
}

#[derive(Debug, Deserialize)]
struct FrontMatter {
    #[serde(default)]
    aliases: Option<Vec<String>>,
    #[serde(default)]
    alias: Option<String>,
    #[serde(default)]
    tags: Option<Vec<String>>,
}

fn is_markdown_file(entry: &Path) -> bool {
    entry.extension()
        .map_or(false, |ext| ext == "md")
}

fn is_valid_file(entry: &Path, vault_path: &Path) -> bool {
    let relative_path = entry.strip_prefix(vault_path).unwrap_or(entry);
    let path_str = relative_path.to_string_lossy();
    
    is_markdown_file(entry) 
        && !path_str.contains("/.trash/")
        && !path_str.contains("/.obsidian/")
        && !path_str.contains('~')
}

fn extract_tags(content: &str) -> Vec<String> {
    let tag_regex = Regex::new(r"#[[:alnum:]\-_/+]+").unwrap();
    tag_regex.find_iter(content)
        .map(|m| m.as_str().to_string())
        .collect()
}

fn extract_front_matter(content: &str) -> Option<FrontMatter> {
    if !content.starts_with("---") {
        return None;
    }

    let parts: Vec<&str> = content.splitn(3, "---").collect();
    if parts.len() != 3 {
        return None;
    }

    serde_yaml::from_str(parts[1]).ok()
}

fn process_file(path: &Path, vault_path: &Path) -> Result<(Vec<String>, Vec<(String, String)>), Box<dyn Error>> {
    let content = fs::read_to_string(path)?;
    let mut tags = extract_tags(&content);
    let mut aliases = Vec::new();

    if let Some(front_matter) = extract_front_matter(&content) {
        // Add tags from front matter
        if let Some(front_tags) = front_matter.tags {
            tags.extend(front_tags.into_iter().map(|t| format!("#{}", t)));
        }

        // Process aliases
        let rel_path = path.strip_prefix(vault_path)?.to_string_lossy().to_string();
        
        if let Some(alias_list) = front_matter.aliases {
            for alias in alias_list {
                aliases.push((alias.to_string(), rel_path.clone()));
            }
        }
        
        if let Some(single_alias) = front_matter.alias {
            aliases.push((single_alias.to_string(), rel_path.clone()));
        }
    }

    Ok((tags, aliases))
}

fn scan_vault(vault_path: &Path) -> Result<VaultData, Box<dyn Error>> {
    let mut files = Vec::new();
    
    // Collect all valid files first
    for entry in walkdir::WalkDir::new(vault_path)
        .follow_links(true)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        let path = entry.path();
        if is_valid_file(path, vault_path) {
            files.push(path.to_path_buf());
        }
    }

    // Process files in parallel
    let results: Vec<_> = files.par_iter()
        .filter_map(|file| {
            process_file(file, vault_path).ok()
        })
        .collect();

    // Combine results
    let mut all_tags = Vec::new();
    let mut all_aliases = HashMap::new();

    for (tags, aliases) in results {
        all_tags.extend(tags);
        for (alias, path) in aliases {
            all_aliases.insert(alias, path);
        }
    }

    // Remove duplicates from tags
    all_tags.sort();
    all_tags.dedup();

    Ok(VaultData {
        tags: all_tags,
        aliases: all_aliases,
        files: files,
    })
}

fn main() -> Result<(), Box<dyn Error>> {
    let args = Args::parse();
    let vault_path = Path::new(&args.vault);
    
    if !vault_path.exists() {
        eprintln!("Vault path does not exist");
        std::process::exit(1);
    }

    let data = scan_vault(vault_path)?;
    println!("{}", serde_json::to_string_pretty(&data)?);
    Ok(())
}