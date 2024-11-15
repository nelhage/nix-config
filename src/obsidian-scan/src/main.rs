use std::path::PathBuf;

use clap::Parser;

use walkdir::{DirEntry, WalkDir};

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
        });

    for (_ent, rel) in walker {
        println!("Found: {}", rel.display());
    }
}
