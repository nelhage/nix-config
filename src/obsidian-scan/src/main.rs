#![allow(dead_code)]
use clap::Parser;
use std::collections::HashSet;
use std::fs;
use std::path::{Path, PathBuf};
use std::vec::Vec;

use lazy_static::lazy_static;
use regex::Regex;
use walkdir::{DirEntry, WalkDir};

use anyhow::Result;

mod frontmatter;

#[derive(Parser)]
#[command(name = "obsidian-scan")]
#[command(about = "Scans your Obsidian vault and produces an inventory", long_about = None)]
struct Cli {
    #[arg(value_name = "VAULT")]
    vault: PathBuf,
}

fn should_walk(ent: &DirEntry) -> bool {
    if let Some(name) = ent.file_name().to_str() {
        if ent.file_type().is_dir() {
            return !(name == ".trash" || name == ".obsidian");
        } else {
            return name.ends_with(".md");
        }
    } else {
        return false;
    }
}

lazy_static! {
    static ref TAG_REGEX: Regex = Regex::new(r"#[[:alnum:]-_/+]+").unwrap();
}

struct Note {
    file: PathBuf,
    tags: HashSet<String>,
    aliases: Vec<String>,
}

fn parse_note(_cli: &Cli, e: DirEntry, rel: &Path) -> Result<Note> {
    let contents = fs::read_to_string(e.path())?;
    let mut tags = HashSet::new();
    for m in TAG_REGEX.find_iter(&contents) {
        tags.insert(m.as_str().to_owned());
    }
    Ok(Note {
        file: rel.to_owned(),
        tags,
        aliases: Vec::new(),
    })
}

fn main() {
    let cli = Cli::parse();

    println!("Scanning: {}", cli.vault.display());

    let walker = WalkDir::new(&cli.vault)
        .into_iter()
        .filter_entry(should_walk)
        .filter_map(|e| e.ok())
        .filter(|e| e.file_type().is_file())
        .filter_map(|e| {
            let path = e.path();
            match path.strip_prefix(&cli.vault) {
                Ok(p) => Some((e.clone(), p.to_owned())),
                Err(_) => None,
            }
        })
        .map(|(e, p)| parse_note(&cli, e, &p));

    for note in walker {
        if let Ok(note) = note {
            println!("Found: {}\n  tags: {:?}", note.file.display(), note.tags);
        }
    }
}
