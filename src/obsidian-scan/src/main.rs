#![allow(dead_code)]
use clap::Parser;
use std::collections::{HashMap, HashSet};
use std::fs;
use std::path::{Path, PathBuf};
use std::vec::Vec;

use lazy_static::lazy_static;
use regex::Regex;
use walkdir::{DirEntry, WalkDir};

use anyhow::Result;

use serde::Serialize;
use serde_json;

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

#[derive(Serialize)]
struct Note {
    file: PathBuf,
    #[serde(skip_serializing_if = "HashSet::is_empty")]
    tags: HashSet<String>,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    aliases: Vec<String>,
}

fn parse_note(_cli: &Cli, e: DirEntry, rel: &Path) -> Result<Note> {
    let contents = fs::read_to_string(e.path())?;
    let mut tags = HashSet::new();
    for m in TAG_REGEX.find_iter(&contents) {
        tags.insert(m.as_str().to_owned());
    }
    let mut aliases = Vec::new();
    if let Ok(frontmatter) = frontmatter::extract(&contents) {
        for tag in frontmatter.tags.iter() {
            tags.insert(tag.to_owned());
        }
        aliases = frontmatter.aliases;
    }
    Ok(Note {
        file: rel.to_owned(),
        tags,
        aliases,
    })
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    let notes = WalkDir::new(&cli.vault)
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
        .filter_map(|(e, p)| parse_note(&cli, e, &p).ok())
        .collect::<Vec<Note>>();

    let mut obj: HashMap<&'static str, &Vec<Note>> = HashMap::new();
    obj.insert("notes", &notes);

    println!("{}", serde_json::to_string(&obj)?);

    Ok(())
}
